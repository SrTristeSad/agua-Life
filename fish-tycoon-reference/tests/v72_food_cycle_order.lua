-- V72: in n.a(o), calls c(m), a(m,int), then a(m,boolean).
-- n.a(m,boolean) at food research level 1 decrements food without RNG.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Care=require('core.care')
local JSON=require('core.json')
local function subject(seed,age,foodlevel,fed)
 local g=Game.new(seed)
 g.s.research.environment=0
 g.s.research.food=foodlevel
 g.s.gear={}
 local f=g.s.tanks.main[1]
 f.body=1;f.tail=1;f.age=age;f.fed=fed or 80;f.health=90
 f.disease=false
 g.hasMagic=function() return false end
 return g,f
end
local function draws(game,script)
 local index=0
 game.int=function(_,low,high)
  index=index+1
  local wanted=script[index]
  assert(wanted,'unexpected draw #'..index..' with range '..low..'..'..high)
  assert(low==wanted[1] and high==wanted[2],
   'wrong draw #'..index..' expected '..wanted[1]..'..'..wanted[2]..
   ' but got '..low..'..'..high)
  return wanted[3]
 end
 return function()assert(index==#script,'missing RNG draw(s): '..index..'/'..#script) end
end

-- At the initial food research level, java switch default decrements
-- g[7] directly and NEVER invokes j.c(100).
local baby,young=subject(72001,8,0,70)
local done=draws(baby,{})
Care.step(baby,young,'main',0)
done()
assert(young.fed==69)
assert(Game.fromTable(JSON.decode(JSON.encode(baby.s))))

-- Adults draw j.c(10000) for infection, but NOT j.c(100) for food.
local adult,fish=subject(72002,20,0,70)
done=draws(adult,{{0,9999,9999}})
Care.step(adult,fish,'main',0)
done()
assert(fish.fed==69 and fish.disease==false)

-- Research food level 2: disease before j.c(100)<=60.
local second,fish2=subject(72003,20,1,80)
done=draws(second,{{0,9999,9999},{0,99,60}})
Care.step(second,fish2,'main',0)
done()
assert(fish2.fed==79)
-- Research food level 3: disease before j.c(100)<=30.
local third,fish3=subject(72004,20,2,80)
done=draws(third,{{0,9999,9999},{0,99,31}})
Care.step(third,fish3,'main',0)
done()
assert(fish3.fed==80)
local thirdHit,fish4=subject(72005,20,2,80)
done=draws(thirdHit,{{0,9999,9999},{0,99,30}})
Care.step(thirdHit,fish4,'main',0)
done()
assert(fish4.fed==79)

-- The condition check uses pre-feeding g[7], as in Java's c(m).
-- At 5 food the fish can still gain condition before nutrition drops it
-- to 4. The Lua-specific hungry penalty stays based on the old reserve.
local transition,edge=subject(72006,8,0,5)
done=draws(transition,{})
local applied=Care.step(transition,edge,'main',0)
done()
assert(applied==-1,'health delta must be +1 condition -2 Lua hunger')
assert(edge.health==89 and edge.fed==4,
 'nutrition unexpectedly affected the same tick health calculation')
-- A feed/plant roll happens AFTER the disease roll in adult fish.
local plant,withPlant=subject(72007,20,0,3)
plant.s.gear.plant=true
done=draws(plant,{{0,9999,9999},{0,99,0}})
Care.step(plant,withPlant,'main',0)
done()
assert(withPlant.fed==7,'low food should drop to 2, then plant +5')

-- Two ways to advance through the same biological boundaries must
-- produce the same persisted state with exactly the same RNG.
for scenario=1,12 do
 local game=Game.new(72300+scenario)
 game.s.research.food=(scenario-1)%3
 game.s.gear.aerator=(scenario%3==0)
 game.s.gear.heater=(scenario%4==0)
 game.s.gear.plant=(scenario%5==0)
 local snapshot=JSON.encode(game.s)
 local one=assert(Game.fromTable(JSON.decode(snapshot)))
 local many=assert(Game.fromTable(JSON.decode(snapshot)))
 one:advance(1800)
 for i=1,180 do many:advance(10) end
 assert(JSON.encode(one.s)==JSON.encode(many.s),
  'growth, disease and food diverged in scenario '..scenario)
 assert(Game.fromTable(JSON.decode(JSON.encode(one.s))))
end
print('OK v72: no RNG at food level 1, Java adult order, food edge, plants, 12 timelines')
