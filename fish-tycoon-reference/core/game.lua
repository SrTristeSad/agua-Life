local C=require('core.config')
local Catalog=require('core.catalog')
local Market=require('core.market')
local Clock=require('core.sim_clock')
local SpawnRng=require('core.j2me_spawn_rng')
local JavaRng=require('core.j2me_random')
local Care=require('core.care')
local Treatments=require('core.treatments')
local Game={};Game.__index=Game
local ORDER={'main','second','isolation','sale'}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function copy(t)
  if type(t)~='table' then return t end
  local o={};for k,v in pairs(t) do o[k]=copy(v) end;return o
end
local function newStats()
 return {born=0,sold=0,earned=0,spent=0,food_given=0,healed=0,lost=0,high_price=0,infections=0,treatments=0,failed_treatments=0,mutations=0}
end
local function growthSeconds(state)
 local minutes=state.growth_minutes or 10
 if minutes~=5 and minutes~=10 and minutes~=15 then minutes=10 end
 return minutes*60
end
local function finite(v)
 return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge
end
local function whole(v,lo,hi)
 return finite(v) and v%1==0 and v>=(lo or 0) and (not hi or v<=hi)
end
-- Listas do save devem ser sequenciais. Um objeto {"1":{...}} carrega
-- como tabela Lua com chave string; #tank=0 e ipairs() ignora os peixes.
-- Sem esta checagem, o jogo considerava esses tanques vazios e aceitava
-- a partida mutilada, sobrescrevendo o ultimo progresso recuperavel.
local function denseArray(t)
 if type(t)~='table' then return false end
 -- JSON {} and [] used to be indistinguishable for an empty collection.
 -- Keep untagged tables supported for direct Lua calls and older fixtures.
 local meta=getmetatable(t)
 if type(meta)=='table' and meta.__json_kind=='object' then return false end
 local count,n=0,#t
 for key in pairs(t) do
  if type(key)~='number' or key%1~=0 or key<1 or key>n then
   return false
  end
  count=count+1
 end
 return count==n
end
-- Lua genealogy metadata is not part of Java m.class, but optional
-- allele tables in Lua saves must never carry malformed or cyclic input.
local function validGenes(g)
 return type(g)=='table'
  and denseArray(g.body) and denseArray(g.tail)
  and #g.body==2 and #g.tail==2
  and whole(g.body[1],1,21) and whole(g.body[2],1,21)
  and whole(g.tail[1],1,21) and whole(g.tail[2],1,21)
  and (g.mutated==nil or type(g.mutated)=='boolean')
end
local function cloneGenes(g)
 return {body={g.body[1],g.body[2]},tail={g.tail[1],g.tail[2]},
  mutated=g.mutated}
end
-- O backup precisa ser usado quando o JSON e sintaticamente valido, mas
-- possui estado inconsistente. Validar antes de entregar o save ao motor.
local function validateSave(data)
 if not whole(data.cash,0) or not whole(data.next_id,1,9007199254740991)
    or not finite(data.time) or data.time<0
     or (data.rng_kind~=nil and data.rng_kind~='j2me48')
     or (data.rng_kind=='j2me48' and not whole(data.rng,0,JavaRng.MOD-1))
     or (data.rng_kind==nil and not whole(data.rng,1,2147483646)) then
  return false,'Dados principais invalidos'
 end
 local ids={}
 local maxId=0
 for _,room in ipairs(ORDER) do
  local tank=data.tanks[room]
  if not denseArray(tank) or #tank>C.CAPACITY[room] then
   return false,'Tanque invalido ou excede a capacidade'
  end
  for _,f in ipairs(tank) do
   if type(f)~='table' or not whole(f.id,1) or ids[f.id]
      or not whole(f.body,1,21) or not whole(f.tail,1,21)
      or not finite(f.age) or f.age<0
      or (f.fed~=nil and (not finite(f.fed) or f.fed<0 or f.fed>100))
      or (f.health~=nil and (not finite(f.health) or f.health<0 or f.health>100))
      or (f.price~=nil and not whole(f.price,0))
      or (f.eggs_at and (not finite(f.eggs_at) or f.eggs_at<0))
      or (f.gestation_end_age~=nil and (not finite(f.gestation_end_age) or f.gestation_end_age<0))
      or (f.disease and f.disease~='ick' and f.disease~='fungus')
      or (f.genes~=nil and not validGenes(f.genes)) then
    return false,'Peixe invalido ou ID duplicado'
   end
   if f.mate then
    if type(f.mate)~='table'
      or (f.mate.body_index~=nil and not whole(f.mate.body_index,1,21))
      or (f.mate.tail_index~=nil and not whole(f.mate.tail_index,1,21))
      or (f.mate.parent_id~=nil and not whole(f.mate.parent_id,0)) then
      return false,'Parceiro de gestacao invalido'
    end
   end
   ids[f.id]=true
   maxId=math.max(maxId,f.id)
  end
 end
 if data.next_id<=maxId then return false,'Proximo ID invalido' end
 if type(data.sale_open)~='boolean' then return false,'Estado da loja invalido' end
 if data.research_job~=false and data.research_job~=nil and type(data.research_job)~='table' then
  return false,'Pesquisa ativa invalida'
 end
 if type(data.research)~='table' or type(data.supplies)~='table' or
    type(data.market)~='table' or type(data.market.quotes)~='table' then
  return false,'Dados auxiliares invalidos'
 end
 if type(data.stats)~='table' or not denseArray(data.events)
    or type(data.seen)~='table' or type(data.magic)~='table'
    or type(data.gear)~='table' or type(data.unlocked)~='table'
    or not denseArray(data.market.history) then
  return false,'Estrutura de progresso invalida'
 end
 if data.wall~=nil and not finite(data.wall) then return false,'Relogio invalido' end
 if data.unlocked.second~=nil and type(data.unlocked.second)~='boolean' then
  return false,'Desbloqueio invalido'
 end
 for _,value in pairs(data.gear) do
  if type(value)~='boolean' then return false,'Equipamento invalido' end
 end
 for key,_ in pairs(newStats()) do
  if not whole(data.stats[key],0,9007199254740991) then return false,'Estatistica invalida: '..key end
 end
 for _,value in pairs(data.stats) do
  if not whole(value,0,9007199254740991) then return false,'Estatistica invalida' end
 end
 for _,e in ipairs(data.events) do
  if type(e)~='table' or type(e.text)~='string' or not finite(e.time) then
   return false,'Historico de eventos invalido'
  end
 end
 for _,value in pairs(data.seen) do
  if type(value)~='boolean' then return false,'Catalogo invalido' end
 end
 for _,name in ipairs({'environment','food','advertising'}) do
  local v=data.research[name]
  if v~=nil and not whole(v,0,C.RESEARCH_MAX) then
   return false,'Nivel de pesquisa invalido'
  end
 end
 if data.research_job then
  local job=data.research_job
  if type(job)~='table' or not ({environment=true,food=true,advertising=true})[job.id]
     or not finite(job.at) then return false,'Pesquisa ativa invalida' end
 end
 for _,v in pairs(data.supplies) do
  if not whole(v,0) then return false,'Estoque invalido' end
 end
 for _,v in pairs(data.market.quotes) do
  if not whole(v,0) then return false,'Cotacao invalida' end
 end
 if not denseArray(data.eggs) then return false,'Lista de ovos invalida' end
 for _,egg in ipairs(data.eggs) do
  if type(egg)~='table' or not whole(egg.body,1,21)
    or not whole(egg.tail,1,21) or not finite(egg.at) or egg.at<0
    or (egg.waiting~=nil and type(egg.waiting)~='boolean') then
   return false,'Ovo invalido'
  end
 end
 return true
end

local function initial(seed)
 return {
   version=9,rng_kind='j2me48',rng=JavaRng.seed(math.floor(seed or os.time())),
   time=0,year_tick=0,growth_minutes=10,growth_elapsed=0,wall=os.time(),cash=200,next_id=1,
   tanks={main={},second={},isolation={},sale={}},
   unlocked={second=false},gear={},research={environment=0,food=0,advertising=0},
   research_job=false,
   supplies={food=5,ick=0,fungus=0,vitamin=1,hormone=0,mutagen=0},
   eggs={},seen={},magic={},sale_open=false,game_speed=1,
   stats=newStats(),events={},
   market={quotes={},visits=0,rejected=0,last_sale=false,elapsed=0,history={},last_visit=false},
 }
end
function Game.new(seed)
 local self=setmetatable({s=initial(seed)},Game)
 self:addFish('main',1,1,20,nil,'F')
 self:addFish('main',2,2,20,nil,'M')
 self:addFish('main',3,3,8)
 self:addFish('main',1,1,2)
 self:message('Bem-vindo! Separe 2 adultos para cruzar.')
 return self
end
function Game.fromTable(data)
 if type(data)~='table' or (data.version~=2 and data.version~=3 and data.version~=4 and data.version~=5 and data.version~=6 and data.version~=7 and data.version~=8 and data.version~=9) or type(data.tanks)~='table' then
   return nil,'Salvamento ausente ou incompativel'
 end
 for _,id in ipairs(ORDER) do if type(data.tanks[id])~='table' then return nil,'Tanque invalido' end end
 -- Um save da versao atual nao precisa de migracao. Rejeitar valores
 -- inconsistentes ANTES de qualquer sanitizacao que ocultaria o dano
 -- e impediria o fallback para o backup valido.
 if data.version==9 then
  if not (data.growth_minutes==5 or data.growth_minutes==10
    or data.growth_minutes==15)
    or not finite(data.growth_elapsed)
    or data.growth_elapsed<0
    or data.growth_elapsed>=growthSeconds(data)
    or not whole(data.year_tick,0,9007199254740991)
    or (data.game_speed~=1 and data.game_speed~=5 and data.game_speed~=20) then
   return nil,'Contadores de tempo do save invalidos'
  end
  -- Saves v9 ja possuem campos obrigatorios. Nao converter os dados
  -- corrompidos em zero: isso apagava estatisticas, estoque e historico.
  if type(data.stats)~='table' then return nil,'Estatisticas v9 invalidas' end
  for key in pairs(newStats()) do
   if not whole(data.stats[key],0,9007199254740991) then
    return nil,'Estatistica v9 corrompida: '..key
   end
  end
  if type(data.supplies)~='table' or not whole(data.supplies.mutagen,0) then
   return nil,'Estoque v9 corrompido'
  end
  local market=data.market
  if type(market)~='table' or not denseArray(market.history)
    or not finite(market.elapsed)
    or market.elapsed<0 or market.elapsed>=Market.VISIT_SECONDS
    or not whole(market.visits,0,9007199254740991)
    or not whole(market.rejected,0,9007199254740991) then
   return nil,'Contadores do mercado invalidos'
  end
  -- Nao filtrar entradas danificadas de um historico v9 valido.
  local function marketEntry(entry)
   return type(entry)=='table' and whole(entry.visit,1,9007199254740991)
     and finite(entry.time) and entry.time>=0
     and (entry.status=='sold' or entry.status=='passed' or entry.status=='empty')
  end
  for _,entry in ipairs(market.history) do
   if not marketEntry(entry) then return nil,'Historico do mercado corrompido' end
  end
  if market.last_visit~=false and not marketEntry(market.last_visit) then
   return nil,'Ultima visita do mercado corrompida'
  end
  if market.last_sale~=false and type(market.last_sale)~='table' then
   return nil,'Ultima venda do mercado corrompida'
  end
 end
 -- Mantemos as validacoes anteriores, mas a verificacao completa ocorre
 -- depois das migracoes e dos valores opcionais terem sido inicializados.
 -- Salvamentos anteriores usam 6 especies experimentais e outra tabela especial.
 if data.version==2 then
  data.prototype_magic=copy(data.magic or {})
  data.magic={}
  data.version=3
  data.events=data.events or {}
  data.events[#data.events+1]={text='Save anterior migrado; descubrimentos experimentais arquivados.',time=data.time}
 end
 -- Versao 4 guarda o progresso parcial de idade e parametros JAR.
 if data.version<4 then
  data.growth_minutes=10
  -- Salvamentos v3 tinham um ciclo de 30 min. Preservamos a idade e
  -- transladamos apenas a fracao incompleta para o novo ciclo de 10 min.
  data.growth_elapsed=((data.time % (30*60))/(30*60))*(10*60)
  for _,room in ipairs(ORDER) do
   for _,f in ipairs(data.tanks[room]) do
    -- Ciclos antigos tinham dois alelos arbitrarios; preservamos a variedade
    -- expressa e uma gestacao em curso, nao reescrevemos os peixes do jogador.
    f.genes=f.genes or {body={f.body,f.body},tail={f.tail,f.tail}}
    if f.eggs_at and type(f.mate)=='table' and not f.mate.body_index then
     local inherited=f.mate
     f.mate={body_index=(inherited.body and inherited.body[1]) or f.body,
       tail_index=(inherited.tail and inherited.tail[1]) or f.tail}
    end
   end
  end
  data.version=4
  data.events=data.events or {}
  data.events[#data.events+1]={text='Save migrado para a simulacao Lua v4.',time=data.time}
 end
 data.growth_minutes=(data.growth_minutes==5 or data.growth_minutes==10 or data.growth_minutes==15) and data.growth_minutes or 10
 data.growth_elapsed=math.max(0,math.min(growthSeconds(data)-.001,tonumber(data.growth_elapsed) or 0))
 data.unlocked=data.unlocked or {second=false}
 data.gear=data.gear or {}
 data.research=data.research or {environment=0,food=0,advertising=0}
 data.supplies=data.supplies or {food=0,ick=0,fungus=0,vitamin=0,hormone=0}
 data.eggs=data.eggs or {};data.seen=data.seen or {};data.magic=data.magic or {}
 if data.stats~=nil and type(data.stats)~='table' then return nil,'Estatisticas invalidas' end
 if data.events~=nil and type(data.events)~='table' then return nil,'Eventos invalidos' end
 if data.supplies~=nil and type(data.supplies)~='table' then return nil,'Estoque invalido' end
 if data.research~=nil and type(data.research)~='table' then return nil,'Pesquisas invalidas' end
 data.stats=data.stats or newStats();data.events=data.events or {}
 -- Saves antigos podem nao ter contadores criados nas fases recentes.
 for key,default in pairs(newStats()) do
  if data.stats[key]==nil then data.stats[key]=default end
 end
 if data.research_job==nil then data.research_job=false end
 data.game_speed=(data.game_speed==5 or data.game_speed==20) and data.game_speed or 1
 data.year_tick=math.floor(tonumber(data.year_tick) or 0)
 if data.version<5 then
  data.market={quotes={},visits=0,rejected=0,last_sale=false}
  data.version=5
  data.events[#data.events+1]={text='Mercado v5 ativado; ofertas antigas preservadas.',time=data.time}
 end
 if type(data.market)~='table' then data.market={} end
 if type(data.market.quotes)~='table' then data.market.quotes={} end
 data.market.visits=math.max(0,math.floor(tonumber(data.market.visits) or 0))
 data.market.rejected=math.max(0,math.floor(tonumber(data.market.rejected) or 0))
 data.market.last_sale=data.market.last_sale or false
 data.market.elapsed=math.max(0,math.min(Market.VISIT_SECONDS,tonumber(data.market.elapsed) or 0))
 if data.version<6 then
  data.version=6
  data.events[#data.events+1]={text='Cuidados v6 ativados: nutricao e resistencia por variedade.',time=data.time}
 end
 if data.version<7 then
  data.version=7
  data.events[#data.events+1]={text='Medicamentos v7: efeitos do JAR e novo quimico mutagenico.',time=data.time}
 end
 data.supplies.mutagen=math.max(0,math.floor(tonumber(data.supplies.mutagen) or 0))
 data.stats.treatments=math.max(0,math.floor(tonumber(data.stats.treatments) or 0))
 data.stats.failed_treatments=math.max(0,math.floor(tonumber(data.stats.failed_treatments) or 0))
 data.stats.mutations=math.max(0,math.floor(tonumber(data.stats.mutations) or 0))
 data.stats.infections=math.max(0,math.floor(tonumber(data.stats.infections) or 0))
 if data.version<8 then
  data.version=8
  data.market.elapsed=0
  data.events[#data.events+1]={text='Loja v8: compradores independentes do crescimento.',time=data.time}
 end
 if data.version<9 then
  data.version=9
  data.events[#data.events+1]={text='Loja v9: historico de visitas e vendas.',time=data.time}
 end
 -- O historico tem tamanho limitado para manter o save pequeno mesmo
 -- apos muitas horas de visitas em segundo plano.
 if type(data.market.history)~='table' then data.market.history={} end
 local history={}
 for i=math.max(1,#data.market.history-11),#data.market.history do
  local entry=data.market.history[i]
  if type(entry)=='table' and type(entry.visit)=='number'
    and type(entry.time)=='number' and type(entry.status)=='string' then
   history[#history+1]=entry
  end
 end
 data.market.history=history
 if type(data.market.last_visit)~='table' then data.market.last_visit=false end
 for _,room in ipairs(ORDER) do
  for _,f in ipairs(data.tanks[room]) do
   if not f.sex then f.sex=(f.id%2==1) and 'F' or 'M' end
   if f.fed==nil then f.fed=100 end
   if f.health==nil then f.health=100 end
  end
 end
 local valid,why=validateSave(data)
 if not valid then return nil,why end
 local self=setmetatable({s=data},Game)
 return self
end
function Game:random()
 local s=self.s
 if s.rng_kind=='j2me48' then
  local bits
  s.rng,bits=JavaRng.nextBits(s.rng,31)
  return bits/JavaRng.BITS31
 end
 -- Legacy v2-v9 saves without rng_kind retain their exact old PRNG.
 s.rng=(s.rng*48271)%2147483647
 return s.rng/2147483647
end
function Game:int(a,b)
 if self.s.rng_kind=='j2me48' then
  assert(whole(a) and whole(b) and b>=a
    and b-a+1<=2147483647,'Intervalo de RNG invalido')
  local result
  self.s.rng,result=JavaRng.nextInt(self.s.rng,b-a+1)
  return a+result
 end
 return a+math.floor(self:random()*(b-a+1))
end
function Game:nextBits(bits)
 if self.s.rng_kind=='j2me48' then
  local result
  self.s.rng,result=JavaRng.nextBits(self.s.rng,bits)
  return result
 end
 -- The legacy Park-Miller implementation did not have next(bits).
 return self:int(0,2^bits-1)
end
function Game:message(msg)
 local events=self.s.events
 events[#events+1]={text=msg,time=self.s.time}
 while #events>14 do table.remove(events,1) end
end
function Game:room(room) return self.s.tanks[room] end
function Game:capacity(room) return C.CAPACITY[room] end
function Game:hasSpace(room)
 return self.s.tanks[room]~=nil and (room~='second' or self.s.unlocked.second)
   and #self.s.tanks[room]<C.CAPACITY[room]
end
function Game:fishStage(f)
 if f.age<6 then return 'Filhote' elseif f.age<20 then return 'Jovem' end
 return 'Adulto'
end
function Game:isAdult(f) return f.age>=20 end
function Game:marketQuote(f)
 if not f or not f.body or not f.tail then return nil end
 return Market.peek(self,f.body,f.tail) or (f.age>=20 and Market.ensure(self,f.body,f.tail)) or Catalog.basePrice(f.body,f.tail)
end
function Game:matchMarketPrice(id)
 local f=self:find(id)
 if not f or not self:isAdult(f) then return false,'Escolha um peixe adulto' end
 f.price=self:marketQuote(f)
 return true,f.price
end
function Game:fishPrice(f)
 -- n.a(): matriz base 21x21 n.b, sem ajuste aleatorio do mercado.
 return Catalog.basePrice(f.body,f.tail) or 4
end
function Game:addFish(room,body,tail,age,genes,sex)
 if not whole(body,1,21) or not whole(tail,1,21) then
  return nil,'Forma ou barbatana invalida'
 end
 -- Uma idade NaN/infinita permanece no save e impede serializacao futura.
 -- Rejeitar antes de consumir RNG ou ID da partida.
 if age~=nil and (not finite(age) or age<0) then
  return nil,'Idade do peixe invalida'
 end
 if genes~=nil and not validGenes(genes) then
  return nil,'Genetica do peixe invalida'
 end
 if not self:hasSpace(room) then return nil,'Tanque cheio ou bloqueado' end
 local s=self.s
 -- m.a(IIIII) consumes five RNG draws for fish appearance and motion,
 -- even though motion is currently drawn separately by the Lua UI.
 -- Consume them only AFTER validation/capacity checks and before quotes.
 SpawnRng.roll(self)
 -- JAR m.class has no sex field. Lua sex is presentation-only metadata:
 -- choosing it must not consume gameplay RNG used by genetics and sales.
 -- Use the same deterministic fallback as Game.fromTable for legacy fish.
 local f={id=s.next_id,body=body,tail=tail,age=age or 0,sex=sex or (s.next_id%2==1 and 'F' or 'M'),fed=100,
  health=100,disease=false,eggs_at=false,mate=false,
  -- Make a private copy of inherited genes: external edits must not mutate
  -- another fish or silently change its inherited characteristics.
  genes=genes and cloneGenes(genes) or {body={body,body},tail={tail,tail}},price=0}
 f.price=self:fishPrice(f)
 s.next_id=s.next_id+1
 table.insert(s.tanks[room],f)
 s.seen[body..'-'..tail]=true
 -- A tabela original de valores de mercado e preenchida no primeiro adulto.
 if f.age>=20 then Market.ensure(self,body,tail) end
 if f.age>=20 then self:_discoverMagic(f) end
 return f
end
function Game:_discoverMagic(f)
 local magicId,magic=Catalog.magicFor(f.body,f.tail)
 if magicId and not self.s.magic[tostring(magicId)] then
  self.s.magic[tostring(magicId)]=true
  self:message('Descoberta especial: '..magic.name..'!')
 end
end
function Game:hasMagic(effect, room)
 -- O JAR n.c(o,int) testa a PRESENCA da variedade especial em um tanque.
 -- Descoberta no catalogo nao equivale a um efeito ativo permanente.
 local category
 for _,m in ipairs(Catalog.magic) do
  if m.effect==effect then category=m;break end
 end
 if not category then return false end
 local function inTank(tank)
  for _,f in ipairs(tank or {}) do
   if f.age>=20 and f.health>0 and f.body==category.body and f.tail==category.tail then
    return true
   end
  end
  return false
 end
 if room then return inTank(self.s.tanks[room]) end
 for _,tank in pairs(self.s.tanks) do if inTank(tank) then return true end end
 return false
end
function Game:find(id)
 for _,room in ipairs(ORDER) do
  for i,f in ipairs(self.s.tanks[room]) do
   if f.id==id then return f,room,i end
  end
 end
 return nil
end
function Game:move(id,to)
 local f,from,i=self:find(id)
 if not f then return false,'Peixe nao encontrado' end
 if from==to then return false,'Ele ja esta nesse tanque' end
 if not self:hasSpace(to) then return false,'O destino esta cheio ou bloqueado' end
 if f.eggs_at and from=='isolation' then return false,'Aguarde a eclosao dos ovos' end
 if to=='sale' and not self:isAdult(f) then return false,'A venda aceita apenas adultos' end
 table.remove(self.s.tanks[from],i)
 table.insert(self.s.tanks[to],f)
 self:message('Peixe transferido para '..({main='tanque 1',second='tanque 2',isolation='isolamento',sale='venda'})[to]..'.')
 return true
end
-- O JAR grava os indices do parceiro em m.g[5]. O registro m.g[0..8]
-- nao possui um campo "sexo" separado; nao bloqueamos cruzamentos por sexo.
-- Criacao do descendente: m.a(int,int,int,int,int) usa media inteira dos
-- indices (corpo do pai A + corpo do pai B)/2 e (barbatana A+B)/2.
function Game:breed()
 local pair=self.s.tanks.isolation
 if #pair~=2 or not self:isAdult(pair[1]) or not self:isAdult(pair[2]) then
  return false,'Isolamento exige dois peixes adultos'
 end
 if pair[1].eggs_at or pair[2].eggs_at then return false,'Ja existe uma gestacao' end
 if pair[1].health<=20 or pair[2].health<=20 then return false,'Os dois peixes precisam estar saudaveis' end
 local carrier,partner=pair[1],pair[2]
 -- o.a(m,int,int): g[3]=idade+3; m.h() testa g[3]<g[0].
 -- Com isso a eclosao ocorre apos QUATRO incrementos de idade.
 carrier.gestation_end_age=carrier.age+3
 carrier.eggs_at=self.s.time+4*growthSeconds(self.s)
 carrier.mate={body_index=partner.body,tail_index=partner.tail,parent_id=partner.id}
 self:message('Cruzamento iniciado. Incubacao em andamento.')
 return true
end
function Game:inherit(a,b)
 -- Compatibilidade com chamadas antigas que enviam dois pares de alelos.
 local function pick(input,part)
  local v=input[part]
  if type(v)=='table' then return v[self:int(1,#v)] end
  return v or 1
 end
 local bodyA,bodyB=pick(a,'body'),pick(b,'body')
 local tailA,tailB=pick(a,'tail'),pick(b,'tail')
 return self:combineParents(bodyA,tailA,bodyB,tailB)
end
function Game:combineParents(bodyA,tailA,bodyB,tailB)
 -- n.a(m,o,int): o sexto peixe especial presente pode alterar um dos
 -- indices herdados em +/-1 em ~16% dos nascimentos, antes da media.
 local mutated=false
 if self:hasMagic('mutation','isolation') and self:int(0,99)<=15 then
  -- n.a(m,o,int), bytecode 1430+: o parceiro esta em m.g[5].
  -- Na borda inferior (indice J2ME 0), o Java AINDA sorteia j.c(100)
  -- antes de forcar +1; na borda superior (20) ele NAO sorteia e usa -1.
  -- Para indices internos, <=49 aumenta e >49 diminui.
  local function alter(value)
   if value==21 then return 20 end
   local roll=self:int(0,99)
   if value==1 or roll<=49 then return value+1 end
   return value-1
  end
  if self:int(0,99)<=49 then tailB=alter(tailB) else bodyB=alter(bodyB) end
  mutated=true
 end
 local body=math.floor((bodyA+bodyB)/2)
 local tail=math.floor((tailA+tailB)/2)
 return {body={bodyA,bodyB},tail={tailA,tailB},mutated=mutated},body,tail
end
function Game:_hatch(parent)
 -- n.a(m,o,int): 1 filhote base; +1 com peixe de fertilidade j[0];
 -- +1 com planta de fertilidade b.d(16), conforme o fluxo Java.
 local count=1+(self:hasMagic('fertility','isolation') and 1 or 0)
   +(self.s.gear.fertility_plant and 1 or 0)
 local born=0
 local mate=parent.mate or {body_index=parent.body,tail_index=parent.tail}
 -- JAR n.a(m,o,int): a mutacao do parceiro ocorre UMA unica vez
 -- antes das chamadas repetidas de o.a(...). Logo todos os irmaos
 -- desta gestacao compartilham a mesma variedade herdada.
 local genes,body,tail=self:combineParents(parent.body,parent.tail,
   mate.body_index or parent.body,mate.tail_index or parent.tail)
 for _=1,count do
  if self:hasSpace('main') then
   local child=self:addFish('main',body,tail,0,genes)
   if child then child.parent_ids={parent.id,mate.parent_id or 0}; born=born+1 end
  end
 end
 parent.eggs_at=false;parent.mate=false;parent.gestation_end_age=nil
 self.s.stats.born=self.s.stats.born+born
 if born<count then self:message('Tanque lotado: '..(count-born)..' filhote(s) perdido(s).') end
 self:message('Ovos eclodiram: '..born..' novo(s) peixe(s)!')
end
function Game:_events()
 local s=self.s
 for _,room in ipairs(ORDER) do
  for _,f in ipairs(s.tanks[room]) do
   if f.eggs_at then
    -- Salvamentos legados mantem o limite por tempo; novas gestacoes v4
    -- aguardam a idade ultrapassar estritamente g[3].
    if (f.gestation_end_age and f.age>f.gestation_end_age)
      or (not f.gestation_end_age and s.time>=f.eggs_at) then
      self:_hatch(f)
    end
   end
  end
 end
 -- Purchased eggs are queued in purchase order. The reverse scan
 -- hatched the most recently acquired egg first when tank 1 had only
 -- one free slot, silently starving the oldest eggs of capacity.
 -- Iterate forward, removing a successfully hatched egg in place.
 local eggs=s.eggs
 local i=1
 while i<=#eggs do
  local egg=eggs[i]
  if s.time>=egg.at then
   if self:hasSpace('main') then
    local child=self:addFish('main',egg.body,egg.tail,0)
    if child then
     s.stats.born=s.stats.born+1
     self:message('Um ovo comprado acaba de eclodir!')
     table.remove(eggs,i)
    else
     -- A failed insertion must never consume or erase a purchased egg.
     i=i+1
    end
   else
    if not egg.waiting then
     egg.waiting=true
     self:message('Ovo pronto: aguardando vaga no tanque 1.')
    end
    i=i+1
   end
  else
   i=i+1
  end
 end
 local job=s.research_job
 if job and s.time>=job.at then
  s.research[job.id]=(s.research[job.id] or 0)+1
  self:message('Pesquisa concluida: nivel '..s.research[job.id]..'.')
  s.research_job=false
 end
end
function Game:_tick()
 local s=self.s
 -- n.a(o) conta peixes doentes uma vez ANTES de iterar os tres tanques.
 -- Um novo caso surgido durante este ciclo so aumenta o risco no proximo.
 local exposure=Care.diseaseExposure(self)
 for _,room in ipairs(ORDER) do
  local fishes=s.tanks[room]
  for i=#fishes,1,-1 do
   local f=fishes[i]
   local wasYoung=f.age<20
   f.age=f.age+1+(self:hasMagic('growth',room) and (self:random()<.2 and 1 or 0) or 0)
   if wasYoung and f.age>=20 then
    Market.ensure(self,f.body,f.tail)
    self:_discoverMagic(f)
   end
   -- No Java (n.a(o)), a(m,o,int) processa os nascimentos ANTES
   -- da atualizacao de condicao. A implementacao Lua processava Care.step
   -- primeiro: se a mae morresse ao completar a gestacao no mesmo ciclo,
   -- todos os filhotes desapareciam sem nascimento.
   if f.eggs_at and f.gestation_end_age and f.age>f.gestation_end_age then
    self:_hatch(f)
   end
   -- Resistencias, alimentacao e risco de doenca centralizados para
   -- isolar regras do JAR das aproximacoes de gameplay.
   Care.step(self,f,room,exposure)
   if f.health==0 then
    table.remove(fishes,i);s.stats.lost=s.stats.lost+1
    self:message('Um peixe morreu no '..room..'.')
   end
  end
 end
 self:_events()
end
function Game:advance(seconds)
 -- Um delta NaN/infinito nao representa tempo transcorrido. A versao
 -- anterior convertia +infinito em 24 horas e podia matar todos os peixes.
 if not finite(seconds) or seconds<=0 then return end
 seconds=math.min(seconds,C.MAX_OFFLINE)
 local s=self.s
 local interval=growthSeconds(s)
 local remaining=seconds
 local EPS=0.0000001
 -- V11: use a simulated timeline, not a batch of sales followed by a
 -- batch of growth. This matters when a research finishes between two
 -- growth cycles, and when a fish becomes eligible for sale mid-update.
 -- The boundaries are: store visit, growth, research and purchased eggs.
 -- No new persistent fields or RNG calls are required.
 if not s.sale_open then s.market.elapsed=0 end
 self:_events()
 while remaining>EPS do
  local untilGrowth=interval-s.growth_elapsed
  if untilGrowth<=EPS then untilGrowth=interval end
  local step=math.min(remaining,untilGrowth)
  if s.sale_open then
   local untilVisit=Market.VISIT_SECONDS-(s.market.elapsed or 0)
   if untilVisit>EPS then step=math.min(step,untilVisit) end
  end
  local job=s.research_job
  if type(job)=='table' and job.at and job.at>s.time+EPS then
   step=math.min(step,job.at-s.time)
  end
  for _,egg in ipairs(s.eggs) do
   if type(egg.at)=='number' and egg.at>s.time+EPS then
    step=math.min(step,egg.at-s.time)
   end
  end
  -- Guard against corrupted/imprecise legacy accumulators. Never loop
  -- forever on a zero-length step.
  if step<=EPS then step=math.min(remaining,untilGrowth) end
  -- Snap subsecond precision to make deadline/RNG ordering independent
  -- of whether the game advances once or receives many fractional frames.
  s.time=Clock.snap(s.time+step)
  s.growth_elapsed=Clock.snap(s.growth_elapsed+step)
  remaining=math.max(0,remaining-step)
  -- Resolve deadline-based events BEFORE the next biological cycle;
  -- e.g. nutrition research completed at 04:00 affects growth at 10:00.
  self:_events()
  Market.advance(self,step)
  if s.growth_elapsed>=interval-EPS then
   s.growth_elapsed=0
   s.year_tick=s.year_tick+1
   self:_tick()
  end
 end
end

function Game:setGrowthMinutes(minutes)
 if minutes~=5 and minutes~=10 and minutes~=15 then
  return false,'Intervalo deve ser 5, 10 ou 15 min'
 end
 local s=self.s
 local fraction=(s.growth_elapsed or 0)/growthSeconds(s)
 s.growth_minutes=minutes
 s.growth_elapsed=fraction*growthSeconds(s)
 return true
end
function Game:offline(now)
 now=now or os.time()
 if not finite(now) then return 0 end
 local saved=self.s.wall or now
 -- Relogio do dispositivo atrasado: nao mover a ancora para tras, pois
 -- isso cobraria o mesmo intervalo duas vezes quando a hora normalizar.
 if now<=saved then return 0 end
 local elapsed=clamp(now-saved,0,C.MAX_OFFLINE)
 -- O modo rapido so vale com o aplicativo aberto.
 self:advance(elapsed)
 self.s.wall=now
 return elapsed
end
function Game:incubationInfo(id)
 local f=self:find(id)
 if not f or not f.eggs_at then return nil end
 local remaining
 if f.gestation_end_age then
  remaining=math.max(0,f.gestation_end_age-f.age+1)
 else
  remaining=math.max(0,math.ceil((f.eggs_at-self.s.time)/growthSeconds(self.s)))
 end
 return {remaining=remaining,seconds=remaining*growthSeconds(self.s)}
end
function Game:researchProjection(id)
 return require('core.research_preview').preview(self,id)
end
function Game:researchInfo()
 local job=self.s.research_job
 if not job then return nil end
 local level=self.s.research[job.id] or 0
 local full=C.RESEARCH_SECONDS[level+1] or 1
 local left=math.max(0,job.at-self.s.time)
 return {id=job.id,level=level+1,remaining=left,total=full,progress=clamp(1-left/full,0,1)}
end
function Game:tankReport(room) return Care.tankReport(self,room) end
function Game:fishEnvironmentDelta(id)
 local f=self:find(id)
 if not f then return nil end
 return Care.environmentDelta(f.body,f.tail,(self.s.research.environment or 0)+1)
end
function Game:feed(id)
 local f=self:find(id)
 if not f then return false,'Peixe nao encontrado' end
 if (self.s.supplies.food or 0)<1 then return false,'Compre racao na loja' end
 if f.fed>=100 then return false,'Peixe ja alimentado' end
 local ok,msg=Treatments.feed(f)
 if not ok then return false,msg end
 self.s.supplies.food=self.s.supplies.food-1
 self.s.stats.food_given=self.s.stats.food_given+1
 return true,msg
end
-- Atalho opcional para alimentar um tanque inteiro, respeitando os estoques.
function Game:feedTank(room)
 local tank=self.s.tanks[room]
 if not tank then return false,'Tanque inexistente' end
 local count=0
 for _,f in ipairs(tank) do
  if f.fed<90 and (self.s.supplies.food or 0)>0 then
   local ok=self:feed(f.id)
   if ok then count=count+1 end
  end
 end
 if count==0 then return false,'Sem peixes com fome ou racao insuficiente' end
 self:message(count..' peixe(s) alimentado(s) no tanque.')
 return true,count
end
function Game:medicine(id,kind)
 local f=self:find(id)
 if not f then return false,'Peixe nao encontrado' end
 if kind~='ick' and kind~='fungus' and kind~='vitamin' and kind~='hormone' and kind~='mutagen' then
  return false,'Medicamento invalido'
 end
 if (self.s.supplies[kind] or 0)<1 then return false,'Voce nao tem esse medicamento' end
 if (kind=='ick' or kind=='fungus') and f.disease~=kind then
  return false,'Tratamento nao corresponde a doenca'
 end
 if kind=='hormone' and f.age>40 then
  return false,'Hormonio so funciona ate 40 unidades de idade'
 end
 local msg
 if kind=='ick' or kind=='fungus' then
  local cured
  cured,msg=Treatments.cure(self,f,kind)
  if cured then
   self.s.stats.healed=self.s.stats.healed+1
  else
   self.s.stats.failed_treatments=self.s.stats.failed_treatments+1
  end
 elseif kind=='vitamin' then
  local points=Treatments.vitamin(self,f)
  msg='Vitaminas: saude +'..points
 elseif kind=='hormone' then
  local ok,points=Treatments.hormone(self,f)
  if not ok then return false,points end
  if f.age>=20 then Market.ensure(self,f.body,f.tail);self:_discoverMagic(f) end
  msg='Hormonio: idade +'..points
 else
  local changed,part=Treatments.mutagen(self,f)
  if changed then
   self.s.stats.mutations=self.s.stats.mutations+1
   self.s.seen[f.body..'-'..f.tail]=true
   f.genes={body={f.body,f.body},tail={f.tail,f.tail}}
   if f.age>=20 then
    Market.ensure(self,f.body,f.tail)
    self:_discoverMagic(f)
   end
   f.price=self:fishPrice(f)
   msg='Mutacao! '..(part=='body' and 'Corpo' or 'Barbatana')..' alterado(a)'
  else
   msg='Quimico aplicado, sem mutacao desta vez (26% de chance)'
  end
 end
 self.s.supplies[kind]=self.s.supplies[kind]-1
 self.s.stats.treatments=self.s.stats.treatments+1
 return true,msg
end
function Game:sell(id,auto)
 local f,room,i=self:find(id)
 if not f or room~='sale' or not self:isAdult(f) then return false,'Apenas adultos na area de venda' end
 local price=f.price or self:fishPrice(f)
 if not whole(price,0) then return false,'Preco invalido' end
 -- O bonus depende do estado ANTES da remocao; se o ultimo peixe
 -- magico for vendido, a presenca ainda vale para esta venda.
 local wealthActive=self:hasMagic('wealth','sale')
 if wealthActive then price=math.floor(price*115/100) end
 table.remove(self.s.tanks.sale,i)
 self.s.cash=self.s.cash+price
 local st=self.s.stats
 st.sold=st.sold+1;st.earned=st.earned+price
 st.high_price=math.max(st.high_price,price)
 self.s.market.last_sale={id=f.id,body=f.body,fin=f.tail,amount=price,
  asked=f.price,wealth=wealthActive,time=self.s.time,automatic=not not auto}
 self:message((auto and 'Cliente comprou ' or 'Peixe vendido por ')..'$'..price)
 return true,price
end
function Game:changePrice(id,delta)
 local f=self:find(id)
 if not f then return false,'Peixe nao encontrado' end
 -- A funçao math.min/max do Lua converte NaN em um dos limites:
 -- um ajuste invalido chegava a colocar o peixe em $9999.
 if not finite(delta) or delta%1~=0 then return false,'Ajuste de preco invalido' end
 f.price=clamp((f.price or self:fishPrice(f))+delta,5,9999)
 return true,f.price
end
function Game:purchase(id)
 local item
 for _,v in ipairs(Catalog.supplies) do if v.id==id then item=v;break end end
 if not item then return false,'Item desconhecido' end
 local s=self.s
 if s.cash<item.price then return false,'Dinheiro insuficiente' end
 if id=='second' and s.unlocked.second then return false,'Ja comprado' end
 if s.gear[id] then return false,'Equipamento ja instalado' end
 if id=='eggs' and (#s.eggs+#s.tanks.main)>C.CAPACITY.main-2 then
  return false,'Reserve 2 vagas no tanque 1' end
 s.cash=s.cash-item.price;s.stats.spent=s.stats.spent+item.price
 if id=='food' then s.supplies.food=(s.supplies.food or 0)+5
 elseif id=='ick' or id=='fungus' or id=='vitamin' or id=='hormone' or id=='mutagen' then
   s.supplies[id]=(s.supplies[id] or 0)+(id=='mutagen' and 1 or 3)
 elseif id=='eggs' then
  for _=1,2 do s.eggs[#s.eggs+1]={body=self:int(1,3),tail=self:int(1,3),at=s.time+C.EGG} end
 elseif id=='second' then s.unlocked.second=true
 else s.gear[id]=true end
 self:message('Comprado: '..item.title..'.')
 return true
end
function Game:startResearch(id)
 if self.s.research_job then return false,'A pesquisa atual precisa terminar' end
 if self.s.research[id]==nil then return false,'Pesquisa desconhecida' end
 local nextLevel=self.s.research[id]+1
 if nextLevel>C.RESEARCH_MAX then return false,'Nivel maximo atingido' end
 local price=C.RESEARCH_COSTS[id][nextLevel]
 if self.s.cash<price then return false,'Dinheiro insuficiente' end
 self.s.cash=self.s.cash-price
 self.s.stats.spent=self.s.stats.spent+price
 self.s.research_job={id=id,at=self.s.time+C.RESEARCH_SECONDS[nextLevel]}
 self:message('Pesquisa iniciada!')
 return true
end
function Game:countMagic()
 local n=0
 for i=1,#Catalog.magic do if self.s.magic[tostring(i)] then n=n+1 end end
 return n
end
function Game:countFish()
 local n=0;for _,room in ipairs(ORDER) do n=n+#self.s.tanks[room] end
 return n
end
return Game
