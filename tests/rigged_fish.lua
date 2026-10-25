package.path='./?.lua;./?/init.lua;'..package.path
local Rig=require('art.rigged_fish')
local DNA=require('genetics.dna')
local Catalog=require('art.catalog')
assert(Rig.supports(Catalog.get(1,1,3,1)))
assert(not Rig.supports(Catalog.get(2,1,3,1)))
assert(not Rig.supports(Catalog.get(1,2,3,1)))
local count=0
for palette=1,12 do
 for pattern=1,6 do
  local spec=Catalog.get(1,1,palette,pattern)
  local genome=DNA.founder(spec)
  local expressed=DNA.express(genome)
  assert(Rig.supports(expressed) and expressed.palette==palette and
    expressed.pattern==pattern)
  count=count+1
 end
end
assert(count==72)
local still=Rig.pose(0,false)
local swimming=Rig.pose(1,false)
local sick=Rig.pose(1,true)
assert(math.abs(still.tail-swimming.tail)>.01)
assert(math.abs(sick.tail)<math.abs(swimming.tail))
assert(Rig.pivots.tail[1]==110 and Rig.pivots.eye[1]==273)
assert(Rig.bounds.body[3]>Rig.pivots.eye[1])
assert(#Rig.order==7)
print('OK Azul-Rubi: 72 variantes, articulacoes, nado e movimento de peixe doente')
