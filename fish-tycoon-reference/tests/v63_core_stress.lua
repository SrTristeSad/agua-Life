-- V63: deterministic integration stress test for the Lua core.
-- Operate on live game state, round-trip it through the exact save codec,
-- and verify that subsequent simulation remains identical.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')

local rooms={'main','second','isolation','sale'}
local items={'food','eggs','ick','fungus','vitamin','hormone','mutagen',
 'aerator','heater','plant','snail','decor','second'}
local function reload(g,case,step)
 local before=JSON.encode(g.s)
 local restored,err=Game.fromTable(JSON.decode(before))
 assert(restored,('save rejected in case %d step %d: %s'):format(case,step,tostring(err)))
 local after=JSON.encode(restored.s)
 assert(after==before,('valid save altered by loading: case %d, step %d'):format(case,step))
 assert(restored:countFish()==g:countFish())
 return restored
end

for case=1,20 do
 local g=Game.new(63000+case)
 g.s.cash=25000
 assert(g:purchase('second'))
 g.s.sale_open=true
 for step=1,85 do
  local op=(step+case)%11
  local fishlist={}
  for _,room in ipairs(rooms) do
   for _,f in ipairs(g.s.tanks[room]) do fishlist[#fishlist+1]=f end
  end
  local selected=fishlist[1]
  if op==0 then
   g:advance(60+(step%5)*135)
  elseif op==1 then
   g:addFish('main',g:int(1,21),g:int(1,21),20)
  elseif op==2 then
   g:purchase(items[(step%#items)+1])
  elseif op==3 and selected then
   g:changePrice(selected.id,(step%2==0) and 15 or -5)
  elseif op==4 and selected then
   g:move(selected.id,rooms[(step%4)+1])
  elseif op==5 then
   local one=g.s.tanks.main[1]
   if one then g:move(one.id,'isolation') end
  elseif op==6 then
   g:breed()
  elseif op==7 and selected then
   g:feed(selected.id)
  elseif op==8 and selected then
   g:medicine(selected.id,(step%2==0) and 'mutagen' or 'hormone')
  elseif op==9 then
   g:startResearch(({'food','environment','advertising'})[(step%3)+1])
  elseif op==10 then
   local sell=g.s.tanks.sale[1]
   if sell then g:sell(sell.id) end
  end
  assert(g.s.cash>=0,'negative money')
  if step%5==0 then
   g=reload(g,case,step)
  end
 end
 g=reload(g,case,85)
 local fork=assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))
 g:advance(725)
 for i=1,725 do fork:advance(1) end
 assert(JSON.encode(g.s)==JSON.encode(fork.s),
  'resumed saved game behaves differently under continuous vs 1s time')
end
print('OK v63: 1700 operations, 340 save roundtrips, 20 deterministic timeline forks')
