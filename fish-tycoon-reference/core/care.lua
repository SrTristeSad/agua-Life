-- Fish Tycoon J2ME 1.0.1: logica reconstruida a partir de n.c(m),
-- n.a(m,boolean) e n.a(m,int), com adaptacoes declaradas abaixo.
-- O Java usa indices de 0 a 20. Os peixes Lua usam indices 1 a 21.
local Care = {}
local function clamp(v) return math.max(0,math.min(100,math.floor(v))) end

-- n.a(m,boolean), opcao b.g(17): a reserva alimentar cai sempre no
-- nivel 1, se rand(100)<=60 no 2, e se rand(100)<=30 no 3.
function Care.foodDrainChance(level)
 if (level or 0)>=3 then return 20 end -- 4o nivel: extrapolacao Lua, nao JAR
 if (level or 0)>=2 then return 31 end
 if (level or 0)>=1 then return 61 end
 return 100
end

-- n.c(m), opcao b.g(26): parte da resistencia biologica e dependente
-- do corpo e da barbatana. Retorna a variacao *original* de condicao
-- por atualizacao, sem equipamentos, fome ou doencas.
function Care.environmentDelta(body,tail,level)
 assert(type(body)=='number' and type(tail)=='number' and body>=1 and body<=21 and tail>=1 and tail<=21)
 local b,t=body-1,tail-1
 level=math.max(1,math.min(3,math.floor(level or 1)))
 if b%2==1 or t%2==1 then return ({-19,-6,0})[level] end
 if (b-2)%4==0 or (t-2)%4==0 then return ({-1,1,3})[level] end
 if b%4==0 or t%4==0 then return ({1,3,5})[level] end
 return 0
end

-- n.c(m), offsets 256..303 (javap): depois dos ganhos ocasionais de
-- equipamento, se o peixe estiver doente ou com reserva g[7] < 5,
-- QUALQUER delta positivo e zerado. Depois, a doenca subtrai 1 ponto.
-- Os bonuses sao aplicados antes deste bloqueio, como no Java.
-- Este metodo apenas representa o nucleo J2ME; sem as penalidades de
-- fome critica e bonus extras adotados pelo port Lua.
function Care.originalConditionDelta(body,tail,level,fed,diseased,bonuses)
 local delta=Care.environmentDelta(body,tail,level)+math.max(0,math.floor(bonuses or 0))
 if (diseased or (fed or 100)<5) and delta>0 then delta=0 end
 if diseased then delta=delta-1 end
 return delta
end

-- n.a(m,int) se baseia na forma e na pesquisa de nutricao para
-- definir risco inicial (por 10000). Outros modificadores do JAR
-- ainda nao foram integralmente mapeados.
function Care.originalDiseaseThreshold(body,foodLevel,exposure,age)
 local b=body-1
 local level=math.max(1,math.min(3,math.floor((foodLevel or 0)+1)))
 local base=2
 if b%4==0 then base=({10,5,1})[level]
 elseif (b-2)%4==0 then base=({20,10,3})[level]
 elseif b%2==1 then base=({30,20,5})[level] end
 -- n.a(m,int): risco = base + 6*numero de doentes + (idade>600 ? 15 : 0).
 -- Em n.a(o) este numero e calculado ANTES de atualizar os peixes.
 return base+6*math.max(0,math.floor(exposure or 0))
   +((age or 0)>600 and 15 or 0)
end

-- n.a(o): antes dos ciclos biologicos, o Java conta m.g() entre as
-- tres matrizes o.i[0..2]. O peixe de isolamento vive em l.b, fora
-- destas matrizes. Nesta versao as tres salas sao main, second e sale.
function Care.diseaseExposure(game)
 local count=0
 for _,room in ipairs({'main','second','sale'}) do
  for _,fish in ipairs(game.s.tanks[room]) do
   if fish.disease then count=count+1 end
  end
 end
 return count
end

-- Equipamentos, medicamentos e efeitos magicos ainda incluem algumas
-- adaptacoes jogaveis que nao sao formulas autenticadas do MIDlet.
-- `exposure` deve ser coletado UMA VEZ antes dos passos do ciclo, tal
-- como n.a(o) faz com a contagem de m.g() antes de iterar os peixes.
function Care.step(game,f,room,exposure)
 local s=game.s
 local foodLevel=s.research.food or 0
 local environmentLevel=s.research.environment or 0
 -- Java n.a(o) calls c(m) for condition, then a(m,int) for disease,
 -- and only afterwards a(m,boolean) for nutrition. Changing food first
 -- could make a fish lose health a full biological cycle too early.
 -- O Java aplica os bonus de equipamentos ANTES de bloquear cura em
 -- peixes doentes ou com menos de 5 unidades de alimento.
 local bonus=0
 if environmentLevel>=3 then bonus=bonus+2 end -- extra Lua, nao JAR
 -- b.d(9/10): aerador e temperatura, +1 com chance de 41% cada.
 -- n.c(m) bytecode checks b.d(10) first (aerator), then b.d(9) (heater).
 if s.gear.aerator and game:int(0,99)<=40 then bonus=bonus+1 end
 if s.gear.heater and game:int(0,99)<=40 then bonus=bonus+1 end
 if game:hasMagic('vitality',room) then bonus=bonus+1 end -- extra Lua
 local delta=Care.originalConditionDelta(f.body,f.tail,environmentLevel+1,
   f.fed,not not f.disease,bonus)
 -- Penalidade adicional de fome critica: regra EXCLUSIVA do port Lua.
 if f.fed<=2 then delta=delta-4
 elseif f.fed<20 then delta=delta-2 end
 f.health=clamp((f.health or 100)+delta)
 -- n.a(m,int) so e chamado se m.d()==true: peixes adultos (idade>=20).
 -- O risco e base + 6 por peixe doente no conjunto dos tres tanques
 -- + 15 quando idade>600. Sem multiplicador de lotacao do port antigo.
 if f.age>=20 and not f.disease then
  -- Original n.a(m,int), Java offsets 8..18:
  -- j.c(10000) is drawn BEFORE calculating risk and BEFORE the snail
  -- draw j.c(100). A float*10000 is not equivalent to nextInt(10000).
  local roll=game:int(0,9999)
  local risk=Care.originalDiseaseThreshold(f.body,foodLevel,
   exposure or Care.diseaseExposure(game),f.age)
  -- Java n.a(m,int) offsets 205..247: curing plant and snail form
  -- an OR. With the plant equipped, Java immediately halves the risk,
  -- skipping both the snail draw AND a second halving.
  if s.gear.curing_plant then
   risk=math.floor(risk/2)
  elseif s.gear.snail and game:int(0,99)<=49 then
   risk=math.floor(risk/2)
  end
  if roll<risk then
   f.disease=game:int(0,1)==0 and 'ick' or 'fungus'
   s.stats.infections=(s.stats.infections or 0)+1
   game:message('Sinais de '..(f.disease=='ick' and 'Ick' or 'fungos')..' em um peixe!')
  end
 end
 -- Java a(m,boolean), called LAST in the adult cycle: level 1
 -- always decrements fed with no RNG draw. Only levels 2 and 3 call
 -- j.c(100) to check thresholds 60 and 30 respectively.
 -- Level 4 remains an explicitly Lua-only extension.
 local drain=Care.foodDrainChance(foodLevel)
 if foodLevel<=0 or game:int(0,99)<drain then
  f.fed=clamp((f.fed or 100)-1)
 end
 -- b.d(13): nutrition plant increases reserve +5 when g[7]<=2.
 if s.gear.plant and f.fed<=2 and game:int(0,99)<=20 then
  f.fed=clamp(f.fed+5)
 end
 if f.disease and game:hasMagic('cure',room) and game:random()<.2 then
  f.disease=false
  s.stats.healed=s.stats.healed+1
 end
 return delta
end

function Care.tankReport(game,room)
 local tank=game.s.tanks[room]
 if not tank then return nil end
 local count,health,food,sick,urgent=0,0,0,0,0
 for _,f in ipairs(tank) do
  count=count+1;health=health+f.health;food=food+f.fed
  if f.disease then sick=sick+1 end
  if f.health<=35 or f.fed<=15 or f.disease then urgent=urgent+1 end
 end
 return {count=count,health=count>0 and math.floor(health/count+.5) or 0,
   food=count>0 and math.floor(food/count+.5) or 0,sick=sick,urgent=urgent}
end
return Care
