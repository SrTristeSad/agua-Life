-- Reconstrucao n.a(o)/n.a(m,int) a partir de JAR 1.0.1.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Care=require('core.care')
local JSON=require('core.json')
local checks=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('V18 '..name..': '..tostring(err),0) end
 checks=checks+1; print('OK '..name)
end
local function eq(x,y) assert(x==y,tostring(x)..' ~= '..tostring(y)) end

test('contagem JAR observa os tres tanques, nao o isolamento',function()
 local g=Game.new(1801)
 local a=g.s.tanks.main[1];a.disease='ick'
 g.s.unlocked.second=true
 local b=assert(g:addFish('second',1,1,20));b.disease='fungus'
 local c=assert(g:addFish('sale',1,1,20));c.disease='ick'
 local d=assert(g:addFish('isolation',1,1,20));d.disease='ick'
 eq(Care.diseaseExposure(g),3)
 b.disease=false;eq(Care.diseaseExposure(g),2)
end)

test('risco biologico tem +6 por doente e +15 depois de 600',function()
 eq(Care.originalDiseaseThreshold(1,2,0,600),1)
 eq(Care.originalDiseaseThreshold(1,2,1,600),7)
 eq(Care.originalDiseaseThreshold(1,2,3,601),34)
end)

test('filhotes nao contraem doenca por sorteio de adulto',function()
 local g=Game.new(1802)
 local f=g.s.tanks.main[1];f.age=18;f.disease=false
 g.int=function(_,lo,hi)
  if lo==0 and hi==9999 then return 0 end
  return hi
 end
 local infections=g.s.stats.infections
 Care.step(g,f,'main',999)
 eq(f.disease,false)
 eq(g.s.stats.infections,infections)
 f.age=20
 Care.step(g,f,'main',999)
 assert(f.disease=='ick' or f.disease=='fungus')
 eq(g.s.stats.infections,infections+1)
end)

test('infeccoes novas nao elevam a exposicao no mesmo ciclo',function()
 local g=Game.new(1803)
 local source=g.s.tanks.main[1]
 local first=g.s.tanks.main[2]
 local second=g.s.tanks.main[3]
 g.s.tanks.main={source,first,second}
 for _,f in ipairs(g.s.tanks.main) do
  f.body=1;f.tail=1;f.age=20;f.fed=100;f.health=100;f.disease=false
 end
 source.disease='ick'
 g.s.research.food=2 -- base=1: exposição 1 => risco 7; exposição 2 => 13
 local rolls=0
 g.int=function(_,lo,hi)
  if lo==0 and hi==9999 then
   rolls=rolls+1
   return rolls==1 and 6 or 10
  end
  return hi
 end
 eq(Care.diseaseExposure(g),1)
 g:_tick() -- ordem reversa: second infecta com 6 < 7; first resiste 10 >= 7
 assert(second.disease)
 eq(first.disease,false)
 eq(Care.diseaseExposure(g),2)
 eq(g.s.stats.infections,1)
end)

test('peixe isolado continua com estado e save inalterados',function()
 local g=Game.new(1804)
 local f=g.s.tanks.main[1];f.disease='ick';f.age=20
 local restored,err=Game.fromTable(JSON.decode(JSON.encode(g.s)))
 assert(restored,err)
 eq(restored.s.version,9)
 eq(Care.diseaseExposure(restored),1)
 eq(restored.s.tanks.main[1].disease,'ick')
end)
print('V18: '..checks..' verificacoes passaram.')
