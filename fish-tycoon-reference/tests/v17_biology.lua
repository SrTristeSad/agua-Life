package.path='./?.lua;./?/init.lua;'..package.path
local Care=require('core.care')
local Game=require('core.game')
local JSON=require('core.json')
local checks=0
local function test(title,fn)
 local ok,err=pcall(fn)
 if not ok then error('V17 '..title..': '..tostring(err),0) end
 checks=checks+1;print('OK '..title)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end

test('biologia JAR impede recuperacao doente ou com fome (g7<5)',function()
 eq(Care.originalConditionDelta(1,1,2,100,false),3)
 eq(Care.originalConditionDelta(1,1,2,4,false),0)
 eq(Care.originalConditionDelta(1,1,2,5,false),3)
 eq(Care.originalConditionDelta(1,1,2,100,true),-1)
 eq(Care.originalConditionDelta(1,1,2,4,true),-1)
end)
test('bonus de equipamento e aplicado antes do bloqueio',function()
 eq(Care.originalConditionDelta(3,3,1,100,false,2),1)
 eq(Care.originalConditionDelta(3,3,1,4,false,2),0)
 eq(Care.originalConditionDelta(3,3,1,100,true,2),-1)
end)
test('penalidades negativas persistem e acumulam -1 por doenca',function()
 eq(Care.originalConditionDelta(2,2,1,2,false),-19)
 eq(Care.originalConditionDelta(2,2,1,2,true),-20)
end)
test('risco de doenca inclui +6 por exposicao e +15 apos 600',function()
 eq(Care.originalDiseaseThreshold(1,0),10)
 eq(Care.originalDiseaseThreshold(1,0,2,20),22)
 eq(Care.originalDiseaseThreshold(1,0,2,600),22)
 eq(Care.originalDiseaseThreshold(1,0,2,601),37)
 eq(Care.originalDiseaseThreshold(2,2,3,601),38)
end)
test('motor impede cura positiva de peixe doente sem extras',function()
 local g=Game.new(179)
 local f=g.s.tanks.main[1]
 f.body=1;f.tail=1;f.fed=100;f.health=60;f.disease='ick'
 g.int=function(_,lo,hi) return hi end
 g.random=function() return 1 end
 g.s.research.environment=1 -- JAR nivel 2 (delta +3)
 local d=Care.step(g,f,'main')
 eq(d,-1);eq(f.health,59);eq(f.disease,'ick')
 f.disease=false;f.health=60;f.fed=4
 -- alimentacao nivel 2, sorteio 99, nao gasta reserva
 g.s.research.food=1
 d=Care.step(g,f,'main')
 eq(d,-2);eq(f.health,58)
end)
test('niveis confirmados e extrapolacao aparecem na pesquisa',function()
 local g=Game.new(211)
 for level,drain in ipairs({100,61,31,20}) do
  g.s.research.food=level-1
  eq(Care.foodDrainChance(level-1),drain)
  local proj=g:researchProjection('food')
  assert(proj.current:find(tostring(drain),1,true))
  assert(proj.source:find('JAR',1,true))
 end
 local ads=g:researchProjection('advertising')
 assert(ads.source:find('experimental',1,true))
end)
test('save antigo e carregavel apos revisao da saude',function()
 local g=Game.new(923)
 local f=g.s.tanks.main[1]
 f.health=71;f.fed=4;f.disease='fungus'
 local restore,err=Game.fromTable(JSON.decode(JSON.encode(g.s)))
 assert(restore,err)
 eq(restore.s.version,9)
 eq(restore.s.tanks.main[1].health,71)
 eq(restore.s.tanks.main[1].disease,'fungus')
end)
print('V17: '..checks..' testes de biologia e pesquisas passaram.')
