package.path='./?.lua;./?/init.lua;'..package.path
love={graphics={}}
local Matrix=require('art.matrix')
assert(Matrix.getIndex({body=1,fin=1})==1)
assert(Matrix.getIndex({body=21,fin=21})==441)
assert(Matrix.getIndex({body=21,fin=17})==442)
assert(Matrix.getIndex({body=15,fin=15})==443)
assert(Matrix.getIndex({body=12,fin=12})==444)
assert(Matrix.getIndex({body=11,fin=10})==445)
assert(Matrix.getIndex({body=6,fin=9})==446)
assert(Matrix.getIndex({body=14,fin=7})==447)
assert(Matrix.getIndex({body=8,fin=8})==448)
assert(Matrix.getIndex({body=0,fin=1})==nil)
assert(Matrix.getIndex({body=1,fin=22})==nil)
assert(Matrix.tileSize[1]==128 and Matrix.tileSize[2]==64)
assert(Matrix.magicTileSize[1]==384)
local healthy=Matrix.pose(1.0,nil)
local ill=Matrix.pose(1.0,{disease='fungus'})
assert(healthy.amplitude==1 and ill.amplitude==.45)
assert(healthy.tail~=0 and healthy.dorsal~=0 and healthy.ventral~=0)
local maxNormal,maxSick=0,0
for step=1,240 do
 local tm=step*.025
 maxNormal=math.max(maxNormal,math.abs(Matrix.pose(tm,nil).tail))
 maxSick=math.max(maxSick,math.abs(Matrix.pose(tm,{disease='fungus'}).tail))
end
assert(maxSick<maxNormal*.50,'Peixe doente deve nadar com menor amplitude')
print('OK 441 combinacoes + 7 magicos; pose corporal, cauda, dorsal e ventral')