package.path='./?.lua;./?/init.lua;'..package.path
love={graphics={}}
local HD=require('art.hd_matrix')
local Catalog=require('art.catalog')
assert(HD.getIndex(Catalog.get(1,1,1,1))==1)
assert(HD.getIndex(Catalog.get(21,21,1,1))==441)
for i,p in ipairs(HD.magicPairs) do
 assert(HD.getIndex(Catalog.get(p[1],p[2],1,1))==441+i)
end
assert(HD.getIndex({body=22,fin=1})==nil)
assert(HD.getIndex({body=1,fin=0})==nil)
assert(HD.tileSize[1]==512 and HD.tileSize[2]==256)
assert(HD.CACHE_LIMIT<=64)
local peakNormal,peakSick=0,0
for i=1,400 do
 local t=i*.03
 local healthy=HD.pose(t,nil)
 local sick=HD.pose(t,{disease='fungus'})
 peakNormal=math.max(peakNormal,math.abs(healthy.tail))
 peakSick=math.max(peakSick,math.abs(sick.tail))
end
assert(peakNormal>22 and peakSick<peakNormal*.52)
assert(HD.cacheSize()==0,'sprites devem ser carregados so quando usados')
print('OK HD 512x256, 21x21 sprites e 7 magicos; animacao responsiva')