-- Agua Life: regras jogaveis independentes de LOVE, com economia, DNA e ciclo.
local C=require('art.catalog')
local DNA=require('genetics.dna')
local Health=require('genetics.health')
local Play={};Play.__index=Play
Play.INTERVAL=6
Play.PRICES={food=25,medicine=45,egg=55,nursery=180,care=110}
Play.CAPACITY={main=14,nursery=14}
Play.MAGIC={
 {body=21,fin=17,name='Aurora das Marés',bonus='Saúde'},
 {body=15,fin=15,name='Véu Violeta',bonus='Genética'},
 {body=12,fin=12,name='Rubi Solar',bonus='Valor'},
 {body=11,fin=10,name='Pérola Antiga',bonus='Resistência'},
 {body=6,fin=9,name='Coração Azul',bonus='Recuperação'},
 {body=14,fin=7,name='Sombra Pintada',bonus='Raridade'},
 {body=8,fin=8,name='Sol Dourado',bonus='Fertilidade'},
}
local function finite(n)return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge end
local function int(n,lo,hi)return finite(n) and n%1==0 and n>=(lo or 0) and (not hi or n<=hi) end
local function dense(t)
 if type(t)~='table' then return false end
 local n=0
 for k in pairs(t) do
  if not int(k,1) then return false end
  n=n+1
 end
 return n==#t
end
local function copy(x)
 if type(x)~='table' then return x end
 local t={}
 for k,v in pairs(x) do t[k]=copy(v) end
 return t
end
local function matches(g,spec)
 local v=DNA.express(g)
 return v.body==spec.body and v.fin==spec.fin and
   v.palette==spec.palette and v.pattern==spec.pattern
end
local function newState(seed)
 seed=math.floor(tonumber(seed) or os.time())%2147483646+1
 return {version=1,seed=seed,rng=seed,elapsed=0,days=0,
  cash=280,food=12,medicine=2,nextId=1,
  fish={},jobs={},deaths={},events={},discovered={},
  upgrades={nursery=false,care=0},
  stats={born=0,sold=0,lost=0,earned=0,spent=0,treated=0}}
end
function Play.new(seed)
 local self=setmetatable({s=newState(seed)},Play)
 -- Dois adultos permitem cruzar logo ao iniciar; jovens dão progressão.
 assert(self:addFish(C.get(1,1,3,1),30,'main'))
 assert(self:addFish(C.get(4,7,2,2),27,'main'))
 assert(self:addFish(C.get(8,8,6,3),23,'main'))
 assert(self:addFish(C.get(12,15,5,4),8,'main'))
 self:message('Bem-vindo! Selecione um adulto, clique em CRUZAR e escolha outro adulto.')
 return self
end
function Play:random()
 self.s.rng=(self.s.rng*48271)%2147483647
 return self.s.rng/2147483647
end
function Play:int(a,b)
 return a+math.floor(self:random()*(b-a+1))
end
function Play:message(msg)
 local e=self.s.events
 e[#e+1]={day=self.s.days,text=tostring(msg)}
 while #e>12 do table.remove(e,1) end
end
function Play:roomCount(room)
 local n=0
 for _,f in ipairs(self.s.fish) do if f.room==room then n=n+1 end end
 return n
end
function Play:canAdd(room)
 if room~='main' and room~='nursery' then return false end
 if room=='nursery' and not self.s.upgrades.nursery then return false end
 return self:roomCount(room)<Play.CAPACITY[room]
end
function Play:find(id)
 for i,f in ipairs(self.s.fish) do if f.id==id then return f,i end end
end
function Play:addFish(spec,age,room,genome)
 room=room or 'main';age=age or 0
 if not C.valid(spec) or not int(age,0) or not self:canAdd(room) then
  return nil,'Aquario cheio, bloqueado ou peixe invalido'
 end
 genome=genome or DNA.founder(spec)
 if not DNA.valid(genome) or not matches(genome,spec) then
  return nil,'DNA incompatível com o peixe'
 end
 local id=self.s.nextId
 local fish={id=id,spec=copy(spec),genome=copy(genome),
  health=Health.new(),room=room,
  x=self:int(125,735),y=self:int(265,595),
  speed=self:int(18,36),direction=self:int(0,1)==1 and 1 or -1,
  phase=id*.67}
 fish.health.age=age
 self.s.nextId=id+1
 self.s.fish[#self.s.fish+1]=fish
 self.s.discovered[spec.body..'-'..spec.fin]=true
 return fish
end
function Play:price(f)
 local base=18+f.spec.body*2+f.spec.fin*3
 local grow=f.health.age>=20 and 1 or .45
 local health=math.max(.35,(f.health.hp or 0)/100)
 local gen=1+((f.genome.generation or 1)-1)*.08
 local magic=self:magicFor(f.spec)
 if magic then base=base*2.3 end
 return math.max(5,math.floor(base*grow*health*gen))
end
function Play:magicFor(spec)
 for _,m in ipairs(Play.MAGIC) do
  if m.body==spec.body and m.fin==spec.fin then return m end
 end
end
function Play:feed(id)
 local f=self:find(id)
 if not f then return false,'Peixe não encontrado' end
 if self.s.food<=0 then return false,'Sem ração. Compre mais na loja.' end
 if f.health.fed>=100 then return false,'Este peixe já está alimentado.' end
 self.s.food=self.s.food-1;Health.feed(f)
 self:message('Peixe #'..id..' alimentado.')
 return true
end
function Play:treat(id)
 local f=self:find(id)
 if not f then return false,'Peixe não encontrado' end
 if self.s.medicine<=0 then return false,'Sem remédio. Compre mais na loja.' end
 if not f.health.disease then return false,'Este peixe não está doente.' end
 self.s.medicine=self.s.medicine-1
 local ok,info=Health.treat(f,function()return self:random()end)
 if ok then self.s.stats.treated=self.s.stats.treated+1 end
 self:message(info..' (peixe #'..id..')')
 return ok,info
end
function Play:breed(idA,idB)
 if idA==idB then return false,'Escolha dois peixes diferentes.' end
 local a=self:find(idA);local b=self:find(idB)
 if not a or not b then return false,'Peixe não encontrado.' end
 if a.room~=b.room then return false,'Os pais precisam estar no mesmo aquário.' end
 if a.health.age<20 or b.health.age<20 then return false,'Ambos precisam ser adultos (20 ciclos).' end
 if a.health.hp<35 or b.health.hp<35 or a.health.disease or b.health.disease then
  return false,'Os dois pais precisam estar saudáveis.'
 end
 if #self.s.jobs>=3 then return false,'Há três cruzamentos incubando.' end
 if not self:canAdd(a.room) then return false,'Não existe espaço para o filhote.' end
 for _,j in ipairs(self.s.jobs) do
  if j.a==idA or j.b==idA or j.a==idB or j.b==idB then
   return false,'Um dos pais já está em reprodução.'
  end
 end
 local fee=12
 if self.s.cash<fee then return false,'Dinheiro insuficiente para reprodução ($12).' end
 self.s.cash=self.s.cash-fee;self.s.stats.spent=self.s.stats.spent+fee
 local child=DNA.child(a.genome,b.genome,function(lo,hi)return self:int(lo,hi)end)
 child.parents={idA,idB}
 self.s.jobs[#self.s.jobs+1]={a=idA,b=idB,room=a.room,cycles=4,genome=child}
 self:message('Cruzamento iniciado: nascerá um filhote em 4 ciclos.')
 return true
end
function Play:sell(id)
 local f,index=self:find(id)
 if not f then return false,'Peixe não encontrado.' end
 if f.health.age<20 then return false,'Somente peixes adultos podem ser vendidos.' end
 local value=self:price(f)
 self.s.cash=self.s.cash+value
 self.s.stats.sold=self.s.stats.sold+1
 self.s.stats.earned=self.s.stats.earned+value
 table.remove(self.s.fish,index)
 self:message('Peixe #'..id..' vendido por $'..value..'.')
 return true,value
end
function Play:transfer(id)
 local f=self:find(id)
 if not f then return false,'Peixe não encontrado.' end
 local dest=f.room=='main' and 'nursery' or 'main'
 if not self:canAdd(dest) then return false,'Desbloqueie outro aquário ou libere espaço.' end
 f.room=dest
 self:message('Peixe #'..id..' transferido para '..(dest=='main' and 'Aquário 1' or 'Aquário 2')..'.')
 return true
end
function Play:buy(kind)
 local s=self.s
 local cost=Play.PRICES[kind]
 if not cost then return false,'Produto desconhecido.' end
 if kind=='nursery' and s.upgrades.nursery then return false,'Aquário 2 já desbloqueado.' end
 if kind=='care' and s.upgrades.care>=3 then return false,'Pesquisa de cuidados no máximo.' end
 if kind=='egg' and not self:canAdd('main') and not self:canAdd('nursery') then
  return false,'Nenhum aquário possui espaço para ovos.'
 end
 local price=kind=='care' and cost*(s.upgrades.care+1) or cost
 if s.cash<price then return false,'Dinheiro insuficiente ($'..price..').' end
 s.cash=s.cash-price;s.stats.spent=s.stats.spent+price
 if kind=='food' then s.food=s.food+6
 elseif kind=='medicine' then s.medicine=s.medicine+3
 elseif kind=='nursery' then s.upgrades.nursery=true
 elseif kind=='care' then s.upgrades.care=s.upgrades.care+1
 elseif kind=='egg' then
  local types={{2,2,9,1},{7,8,6,4},{15,15,5,3},{21,17,3,2},{5,12,7,5}}
  local t=types[self:int(1,#types)]
  local room=self:canAdd('main') and 'main' or 'nursery'
  local fish=assert(self:addFish(C.get(t[1],t[2],t[3],t[4]),0,room))
  self:message('Ovo chocado: novo filhote #'..fish.id..'.')
  return true,fish
 end
 self:message('Compra concluída: '..kind..'.')
 return true
end
local function cleanFish(self)
 local s=self.s
 for i=#s.fish,1,-1 do
  local f=s.fish[i]
  if not Health.cycle(f,function()return self:random()end) then
   local report=Health.autopsy(f)
   report.day=s.days;report.room=f.room
   s.deaths[#s.deaths+1]=report
   while #s.deaths>30 do table.remove(s.deaths,1) end
   table.remove(s.fish,i);s.stats.lost=s.stats.lost+1
   self:message('Peixe #'..f.id..' morreu. Consulte a necropsia.')
  elseif s.upgrades.care>0 and f.health.hp<100 and f.health.fed>20 and
         not f.health.disease then
   f.health.hp=math.min(100,f.health.hp+s.upgrades.care)
  end
 end
end
function Play:cycle()
 local s=self.s;s.days=s.days+1
 cleanFish(self)
 for i=#s.jobs,1,-1 do
  local j=s.jobs[i]
  if j.cycles>0 then j.cycles=j.cycles-1 end
  if j.cycles<=0 and self:canAdd(j.room) then
   local baby=assert(self:addFish(DNA.express(j.genome),0,j.room,j.genome))
   s.stats.born=s.stats.born+1
   self:message('Nasceu peixe #'..baby.id..' (geração '..baby.genome.generation..').')
   table.remove(s.jobs,i)
  end
 end
end
function Play:advance(seconds)
 if not finite(seconds) or seconds<=0 then return 0 end
 -- Limita atrasos do aplicativo e evita morte maciça após perder foco.
 seconds=math.min(seconds,Play.INTERVAL*5)
 local s=self.s
 s.elapsed=s.elapsed+seconds
 local steps=0
 while s.elapsed>=Play.INTERVAL and steps<5 do
  s.elapsed=s.elapsed-Play.INTERVAL
  self:cycle();steps=steps+1
 end
 return steps
end
local function validFish(f)
 if type(f)~='table' or not int(f.id,1) or not C.valid(f.spec)
    or not DNA.valid(f.genome) or not matches(f.genome,f.spec)
    or (f.room~='main' and f.room~='nursery')
    or type(f.health)~='table' or not int(f.health.age,0,100000)
    or not int(f.health.hp,0,100) or not int(f.health.fed,0,100)
    or not int(f.health.sickCycles,0,100000)
    or (f.health.disease~=false and f.health.disease~='ick' and f.health.disease~='fungus')
    or not finite(f.x) or not finite(f.y) or not finite(f.speed) or
    (f.direction~=1 and f.direction~=-1) or not finite(f.phase) then return false end
 return true
end
local function validState(s)
 if type(s)~='table' or s.version~=1 or not int(s.rng,1,2147483646)
  or not int(s.nextId,1,99999999) or not int(s.days,0,99999999)
  or not finite(s.elapsed) or s.elapsed<0 or s.elapsed>=Play.INTERVAL
  or not int(s.cash,0,1000000000) or not int(s.food,0,1000000)
  or not int(s.medicine,0,1000000) or type(s.upgrades)~='table'
  or type(s.upgrades.nursery)~='boolean' or not int(s.upgrades.care,0,3)
  or not dense(s.fish) or #s.fish>28 or not dense(s.jobs) or #s.jobs>3
  or not dense(s.events) or #s.events>12 or not dense(s.deaths) or #s.deaths>30
  or type(s.discovered)~='table' or type(s.stats)~='table' then
   return false,'Dados de jogo inválidos.'
 end
 for _,name in ipairs({'born','sold','lost','earned','spent','treated'}) do
  if not int(s.stats[name],0,1000000000) then return false,'Estatísticas inválidas.' end
 end
 local ids={};local main,nursery=0,0
 for _,f in ipairs(s.fish) do
  if not validFish(f) or ids[f.id] or f.id>=s.nextId then return false,'Peixe ou DNA inválido.' end
  ids[f.id]=true
  if f.room=='main' then main=main+1 else nursery=nursery+1 end
 end
 if main>Play.CAPACITY.main or nursery>Play.CAPACITY.nursery or
  (not s.upgrades.nursery and nursery>0) then return false,'Capacidade inválida.' end
 for _,job in ipairs(s.jobs) do
  if type(job)~='table' or not int(job.a,1) or not int(job.b,1)
   or job.a==job.b or not int(job.cycles,0,4)
   or (job.room~='main' and job.room~='nursery')
   or not DNA.valid(job.genome) then return false,'Gestação inválida.' end
 end
 for _,event in ipairs(s.events) do
  if type(event)~='table' or type(event.text)~='string' or
     not int(event.day,0) then return false,'Histórico inválido.' end
 end
 for _,report in ipairs(s.deaths) do
  if type(report)~='table' or not int(report.id,1)
    or type(report.cause)~='string' or not int(report.day,0) then
   return false,'Necropsia inválida.'
  end
 end
 for k,v in pairs(s.discovered) do
  if type(k)~='string' or type(v)~='boolean' then return false,'Descobertas inválidas.' end
 end
 return true
end
function Play.fromTable(data)
 local ok,why=validState(data)
 if not ok then return nil,why end
 return setmetatable({s=data},Play)
end
function Play:state()
 return copy(self.s)
end
return Play
