-- V71: disease RNG call order taken from Fish Tycoon Java n.a(m,int).
-- The Java bytecode calls j.c(10000) BEFORE j.c(100) for the snail,
-- and the curing plant bypasses the snail branch entirely.
package.path='./?.lua;./?/init.lua;'..package.path
local Care=require('core.care')
local Game=require('core.game')
local J2ME=require('core.j2me_random')
local JSON=require('core.json')
local function isolated(seed,gear)
 local game=Game.new(seed)
 game.s.gear=gear or {}
 local fish=game.s.tanks.main[1]
 fish.body=1;fish.tail=1;fish.age=20;fish.health=100;fish.fed=100
 fish.disease=false
 game.hasMagic=function()return false end
 return game,fish
end
local function scripted(name,gear,rolls,expected,expectedDisease,expectedRisk)
 local game,fish=isolated(71000,gear)
 local calls={}
 game.int=function(_,lo,hi)
  local index=#calls+1
  calls[index]={lo,hi}
  local item=rolls[index]
  assert(item,name..': unexpected RNG call #'..index)
  assert(lo==item[1] and hi==item[2],
   name..': RNG call order differs at '..index)
  return item[3]
 end
 Care.step(game,fish,'main',0)
 assert(#calls==#rolls,name..': missing RNG calls')
 assert((fish.disease or false)==(expectedDisease or false),
  name..': wrong illness outcome')
 assert(game.s.stats.infections==((expectedDisease and 1) or 0),
  name..': infection counter inconsistent')
 if expectedRisk then
  assert(Care.originalDiseaseThreshold(1,0,0,20)==10)
 end
 return game,fish
end
-- Java calls disease before feeding. Level 1 food has NO RNG call.
scripted('healthy',{},{{0,9999,9999}},2,false,true)
scripted('infection',{},{{0,9999,0},{0,1,0}},3,'ick',true)
-- Snail protection: illness draw already happened when j.c(100) runs.
scripted('snail', {snail=true},
 {{0,9999,4},{0,99,0},{0,1,1}},4,'fungus',true)
-- The plant short-circuits the snail: only ONE halving and no j.c(100).
scripted('plant and snail no illness',{snail=true,curing_plant=true},
 {{0,9999,5}},2,false,true)
scripted('plant and snail illness',{snail=true,curing_plant=true},
 {{0,9999,4},{0,1,1}},3,'fungus',true)
-- With only snail and failed 50% roll, base risk remains 10.
scripted('snail does not protect',{snail=true},
 {{0,9999,8},{0,99,99},{0,1,0}},4,'ick',true)
-- Juvenile/diseased fish never request j.c(10000).
local young,youngFish=isolated(71002,{snail=true})
youngFish.age=8
local youngCalls=0
young.int=function(_,a,b)youngCalls=youngCalls+1;error('Juvenile drew unexpected RNG') end
Care.step(young,youngFish,'main',0)
assert(youngCalls==0 and not youngFish.disease)
local sick,sickFish=isolated(71003,{snail=true})
sickFish.disease='ick'
local sickCalls=0
sick.int=function(_,a,b)sickCalls=sickCalls+1;error('Already ill adult drew unexpected RNG') end
Care.step(sick,sickFish,'main',0)
assert(sickCalls==0 and sickFish.disease=='ick')

-- Cross-check the new 48-bit RNG's state with the exact expected
-- sequence: nextInt(10000), optional nextInt(100). No food RNG at level 1.
for seed=1,48 do
 for _,gear in ipairs({{}, {snail=true}, {snail=true,curing_plant=true}}) do
  local g,fish=isolated(71200+seed,gear)
  local state=g.s.rng
  local risk,snail
  state,risk=J2ME.nextInt(state,10000)
  local limit=10
  if gear.curing_plant then
   limit=5
  elseif gear.snail then
   state,snail=J2ME.nextInt(state,100)
   if snail<=49 then limit=5 end
  end
  local infection=risk<limit
  local kind
  if infection then
   state,kind=J2ME.nextInt(state,2)
  end
  Care.step(g,fish,'main',0)
  assert(g.s.rng==state,
   ('Java RNG mismatch: seed=%d plant=%s snail=%s')
    :format(seed,tostring(gear.curing_plant),tostring(gear.snail)))
  assert(fish.fed==99 and fish.disease==
    (infection and (kind==0 and 'ick' or 'fungus') or false))
  assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))
 end
end
-- Old saved games keep the previous Park-Miller engine without migration.
local legacy,legacyFish=isolated(71999,{snail=true})
legacy.s.rng_kind=nil;legacy.s.rng=12345
local loaded=assert(Game.fromTable(JSON.decode(JSON.encode(legacy.s))))
loaded.hasMagic=function()return false end
Care.step(loaded,loaded.s.tanks.main[1],'main',0)
assert(loaded.s.rng_kind==nil and loaded.s.rng<=2147483646)
assert(Game.fromTable(JSON.decode(JSON.encode(loaded.s))))
print('OK v71: exact disease roll order, curing-plant short circuit, 144 Java seed scenarios and legacy saves')
