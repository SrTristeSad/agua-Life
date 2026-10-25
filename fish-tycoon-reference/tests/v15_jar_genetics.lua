-- Testes derivados de n.a(m,o,int) e m.a(IIIII) no JAR Java.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Care=require('core.care')
local calls=0
local function check(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('V15 JAR '..name..': '..tostring(err),0) end
 calls=calls+1;print('OK '..name)
end
check('formula original de heranca usa media inteira',function()
 local g=Game.new(117)
 for a=1,21 do for b=1,21 do
  local dna,body,fin=g:combineParents(a,21,b,1)
  assert(body==math.floor((a+b)/2))
  assert(fin==11)
  assert(not dna.mutated)
 end end
end)
check('gestacao muta somente uma vez antes dos nascimentos extras',function()
 local g=Game.new(118)
 local a=g.s.tanks.main[1];local b=g.s.tanks.main[2]
 a.body=14;a.tail=7  -- peixe especial da mutacao no tanque de isolamento
 b.body=8;b.tail=1
 assert(g:move(a.id,'isolation'))
 assert(g:move(b.id,'isolation'))
 g.s.gear.fertility_plant=true
 assert(g:breed())
 local mother=g.s.tanks.isolation[1]
 local count=0
 g.int=function(self,lo,hi)
  count=count+1
  return lo
 end
 local initial=#g.s.tanks.main
 g:_hatch(mother)
 assert(#g.s.tanks.main==initial+2)
 -- j.c(100) is also called for the low-bound partner fin (index 0).
 -- The Java code forces +1 after that direction roll, but still spends it.
 assert(count==11,'3 mutacoes + 4 j.c(n) por filhote; j.b(16) e separado')
 local p=g.s.tanks.main[initial+1]
 local q=g.s.tanks.main[initial+2]
 assert(p.body==q.body and p.tail==q.tail)
 assert(p.body==11 and p.tail==4) -- media(14,8), media(7,2)
 assert(p.genes.mutated and q.genes.mutated)
 assert(p.genes~=q.genes and p.genes.body~=q.genes.body)
end)
check('n.c(m) conserva a tabela biologica das pesquisas',function()
 -- corpo/cauda 1 em Lua correspondem ao indice 0 no Java
 assert(Care.environmentDelta(2,1,1)==-19)
 assert(Care.environmentDelta(2,1,2)==-6)
 assert(Care.environmentDelta(2,1,3)==0)
 assert(Care.environmentDelta(3,1,1)==-1)
 assert(Care.environmentDelta(3,1,2)==1)
 assert(Care.environmentDelta(3,1,3)==3)
 assert(Care.environmentDelta(1,1,1)==1)
 assert(Care.environmentDelta(1,1,3)==5)
end)
check('pesquisa alimentar usa probabilidades do JAR',function()
 assert(Care.foodDrainChance(0)==100)
 assert(Care.foodDrainChance(1)==61)
 assert(Care.foodDrainChance(2)==31)
 -- Extra do port Lua, nao atribuido ao JAR original.
 assert(Care.foodDrainChance(3)==20)
end)
print('V15 JAR: '..calls..' verificacoes de genetica e pesquisa passaram.')
