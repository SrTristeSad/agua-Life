-- V64: 60 FPS and fractional updates must not reorder births/market RNG.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local Clock=require('core.sim_clock')
assert(Clock.snap(0.0166666666666667)==0.0166666666666667,
 'Subsecond game time must not be rounded at every frame')
assert(Clock.snap(0.999999999999)==1)
assert(Clock.snap(180.00000000001)==180)

for scenario=1,6 do
 local base=Game.new(6490+scenario)
 base.s.sale_open=(scenario%2==0)
 if base.s.sale_open then
  assert(base:move(base.s.tanks.main[2].id,'sale'))
 end
 if scenario%3==0 then assert(base:startResearch('food')) end
 if scenario%3==1 then
  base.s.eggs[#base.s.eggs+1]={body=1,tail=1,at=180}
 end
 local initial=JSON.encode(base.s)
 local once=assert(Game.fromTable(JSON.decode(initial)))
 local tenths=assert(Game.fromTable(JSON.decode(initial)))
 local frames=assert(Game.fromTable(JSON.decode(initial)))
 once:advance(1200)
 for tick=1,12000 do tenths:advance(0.1) end
 for tick=1,72000 do frames:advance(1/60) end
 local expected=JSON.encode(once.s)
 assert(JSON.encode(tenths.s)==expected,
  '0.1s updates differ from 1x1200s: scenario '..scenario)
 assert(JSON.encode(frames.s)==expected,
  '60fps updates differ from 1x1200s: scenario '..scenario)
 assert(once.s.time==1200 and tenths.s.time==1200
   and frames.s.time==1200)
 assert(once.s.growth_elapsed==0 and frames.s.growth_elapsed==0)
 if base.s.sale_open then
  assert(once.s.market.visits==240)
 end
 if scenario%3==1 then
  -- A eclosao acontece exatamente aos 180 segundos, antes da visita
  -- de mercado que ocorre na mesma fronteira (caso 4).
  local found=false
  for _,e in ipairs(once.s.events) do
   if e.text=='Um ovo comprado acaba de eclodir!' then
    assert(e.time==180)
    found=true
   end
  end
  assert(found,'Purchased egg did not hatch at intended deadline')
 end
end
print('OK v64: 1 step, 0.1s and 60 FPS have identical births, market, RNG and saves')
