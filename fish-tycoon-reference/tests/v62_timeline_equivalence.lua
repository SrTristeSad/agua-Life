-- V62: deterministic engine must agree between continuous time and 1s updates.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
for case=1,8 do
 local baseline=Game.new(62000+case)
 baseline.s.unlocked.second=true
 baseline.s.research.advertising=2
 if case%2==0 then
  local first,second=baseline.s.tanks.main[1],baseline.s.tanks.main[2]
  assert(baseline:move(first.id,'isolation'))
  assert(baseline:move(second.id,'isolation'))
  assert(baseline:breed())
 end
 if case%3==0 then
  -- Numa gestacao os dois adultos podem estar no isolamento.
  -- Criar um adulto no tanque de vendas em vez de mover um filhote.
  assert(baseline:addFish('sale',1,1,20))
  baseline.s.sale_open=true
 end
 if case%4==0 then
  baseline.s.eggs[#baseline.s.eggs+1]={body=1,tail=1,at=40}
  assert(baseline:startResearch('environment'))
 end
 local payload=JSON.encode(baseline.s)
 local a=assert(Game.fromTable(JSON.decode(payload)))
 local b=assert(Game.fromTable(JSON.decode(payload)))
 local seconds=case*181
 a:advance(seconds)
 for i=1,seconds do b:advance(1) end
 assert(JSON.encode(a.s)==JSON.encode(b.s),
  'Continuous and incremental simulations diverged in scenario '..case)
end
print('OK v62: 8 timeline scenarios match incremental growth, births, sales and research')
