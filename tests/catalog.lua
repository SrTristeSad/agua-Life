package.path='./?.lua;./?/init.lua;'..package.path
local C=require('art.catalog')
assert(#C.bodies==21)
assert(#C.fins==21)
assert(#C.palettes==12)
local seen={}
for b=1,21 do
 for fin=1,21 do
  local v=C.get(b,fin,1,1)
  assert(C.valid(v))
  assert(not seen[b..':'..fin])
  seen[b..':'..fin]=true
 end
end
assert(C.wrap(22,21)==1)
assert(C.wrap(0,21)==21)
assert(C.valid(C.get(-1,44,-3,99)))
print('OK: 441 combinacoes; 21 corpos; 21 caudas; 12 paletas')
