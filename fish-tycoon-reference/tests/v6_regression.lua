package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Care=require('core.care')
local JSON=require('core.json')
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' != '..tostring(b)) end
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then io.stderr:write('FALHOU '..name..': '..tostring(err)..'\n');os.exit(1) end
 count=count+1;print('OK - '..name)
end

test('probabilidades de reserva alimentar JAR 100/61/31 e extra Lua 20',function()
 eq(Care.foodDrainChance(0),100);eq(Care.foodDrainChance(1),61)
 eq(Care.foodDrainChance(2),31);eq(Care.foodDrainChance(3),20)
end)
test('resistencia JAR conforme indices paridade e modulo',function()
 for level,v in ipairs({-19,-6,0}) do eq(Care.environmentDelta(2,2,level),v) end
 for level,v in ipairs({-1,1,3}) do eq(Care.environmentDelta(3,3,level),v) end
 for level,v in ipairs({1,3,5}) do eq(Care.environmentDelta(1,1,level),v) end
 eq(Care.environmentDelta(2,1,1),-19)
end)
test('risco base de doenca JAR distingue familias biologicas',function()
 eq(Care.originalDiseaseThreshold(1,0),10)
 eq(Care.originalDiseaseThreshold(1,2),1)
 eq(Care.originalDiseaseThreshold(3,0),20)
 eq(Care.originalDiseaseThreshold(2,0),30)
 eq(Care.originalDiseaseThreshold(2,2),5)
end)
test('nutricao melhora efetivamente com pesquisa',function()
 local game=Game.new(777);local f=game.s.tanks.main[1]
 f.fed=50
 game.int=function(_,min,max) return max end
 game.random=function() return 1 end
 Care.step(game,f,'main');eq(f.fed,49) -- 100% no nivel inicial
 game.s.research.food=1
 Care.step(game,f,'main');eq(f.fed,49) -- sorteio 99 nao consome
 game.s.research.food=3
 eq(Care.foodDrainChance(game.s.research.food),20)
end)
test('ambiente e equipamento alteram condicao do peixe',function()
 local game=Game.new(123);local f=game.s.tanks.main[2]
 game.int=function(_,min,max) return max end
 game.random=function() return 1 end
 f.health=90;f.fed=100
 Care.step(game,f,'main');eq(f.health,71)
 game.s.research.environment=2
 Care.step(game,f,'main');eq(f.health,71)
 game.s.research.environment=3
 Care.step(game,f,'main');eq(f.health,73)
 game.s.gear.heater=true;game.s.gear.aerator=true
 Care.step(game,f,'main');eq(f.health,75) -- sorteio 99 nao ativa aerador/aquecedor
end)
test('relatorio do tanque calcula medias e peixes em risco',function()
 local game=Game.new(5)
 local report=game:tankReport('main')
 eq(report.count,4);eq(report.health,100);eq(report.food,100)
 game.s.tanks.main[1].health=15
 game.s.tanks.main[2].fed=0
 game.s.tanks.main[3].disease='fungus'
 report=game:tankReport('main')
 eq(report.urgent,3);eq(report.sick,1)
 eq(report.health,79);eq(report.food,75)
 eq(game:tankReport('isolation').count,0)
 assert(game:tankReport('inexistente')==nil)
end)
test('salvamento v5 migra a v6 sem alterar cotacoes e gestacao',function()
 local game=Game.new(121)
 assert(game:move(game.s.tanks.main[1].id,'isolation'))
 assert(game:move(game.s.tanks.main[1].id,'isolation'))
 assert(game:breed())
 local old=JSON.decode(JSON.encode(game.s));old.version=5
 local restored,err=Game.fromTable(old);assert(restored,err)
 eq(restored.s.version,9);eq(restored.s.rng,game.s.rng)
 eq(restored.s.tanks.isolation[1].gestation_end_age,game.s.tanks.isolation[1].gestation_end_age)
 eq(restored.s.tanks.isolation[1].mate.parent_id,game.s.tanks.isolation[1].mate.parent_id)
 eq(restored.s.stats.infections,0)
 eq(restored.s.market.quotes['1-1'],game.s.market.quotes['1-1'])
end)
test('salvamento v6 com registros epidemiologicos faz roundtrip',function()
 local game=Game.new(2);game.s.stats.infections=8
 local restored,err=Game.fromTable(JSON.decode(JSON.encode(game.s)));assert(restored,err)
 eq(restored.s.stats.infections,8);eq(restored.s.version,9)
end)
test('progresso 600 segundos uma vez ou dividido e deterministico',function()
 local g=Game.new(72);local h=Game.new(72)
 g:advance(600);h:advance(140);h:advance(460)
 eq(JSON.encode(g.s.tanks),JSON.encode(h.s.tanks))
 eq(g.s.rng,h.s.rng)
end)
print('\nFase 6: '..count..' testes adicionais passaram.')
