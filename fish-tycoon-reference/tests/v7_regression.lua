package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Care=require('core.care')
local JSON=require('core.json')
local Catalog=require('core.catalog')
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then io.stderr:write('FALHOU '..name..': '..tostring(err)..'\n');os.exit(1) end
 count=count+1;print('OK - '..name)
end
local function dice(game,number)
 game.int=function(_,a,b) return math.max(a,math.min(b,number)) end
end

test('novo jogo e migracao v6 para schema v7',function()
 local g=Game.new(33)
 eq(g.s.version,9)
 local old=JSON.decode(JSON.encode(g.s))
 old.version=6;old.supplies.mutagen=nil;old.stats.treatments=nil
 old.cash=1244;old.gear.heater=true
 local restored,err=Game.fromTable(old);assert(restored,err)
 eq(restored.s.version,9);eq(restored.s.cash,1244)
 eq(restored.s.gear.heater,true);eq(restored.s.supplies.mutagen,0)
 eq(restored.s.stats.treatments,0)
 eq(#restored.s.tanks.main,4)
end)
test('comida do JAR soma 50 e penaliza 2 se extrapola 100',function()
 local g=Game.new(1);local f=g.s.tanks.main[1]
 f.fed=30;f.health=90
 assert(g:feed(f.id));eq(f.fed,80);eq(f.health,90)
 f.fed=80
 assert(g:feed(f.id));eq(f.fed,100);eq(f.health,88)
 local left=g.s.supplies.food
 assert(not g:feed(f.id));eq(g.s.supplies.food,left)
end)
test('Ick: dose errada e peixe errado nao gastam estoque',function()
 local g=Game.new(2);local f=g.s.tanks.main[1]
 f.disease='ick';g.s.supplies.ick=1;g.s.supplies.fungus=1
 assert(not g:medicine(f.id,'fungus'))
 assert(not g:medicine(999,'ick'))
 eq(g.s.supplies.fungus,1);eq(g.s.supplies.ick,1)
end)
test('Ick: 40% de chance, fracasso consome dose sem curar',function()
 local g=Game.new(2);local f=g.s.tanks.main[1]
 f.health=40;f.disease='ick';g.s.supplies.ick=1;dice(g,40)
 local ok,msg=g:medicine(f.id,'ick')
 assert(ok and msg:find('nao fez efeito'))
 eq(f.disease,'ick');eq(f.health,40);eq(g.s.supplies.ick,0)
 eq(g.s.stats.healed,0);eq(g.s.stats.failed_treatments,1)
end)
test('Fungo: limite 39 do sorteio recuperado causa cura',function()
 local g=Game.new(2);local f=g.s.tanks.main[1]
 f.health=44;f.disease='fungus';g.s.supplies.fungus=1;dice(g,39)
 assert(g:medicine(f.id,'fungus'))
 eq(f.disease,false);eq(f.health,44);eq(g.s.stats.healed,1)
 eq(g.s.stats.treatments,1)
end)
test('vitaminas recuperam entre 6 e 15, respeitando teto de 100',function()
 local g=Game.new(3);local f=g.s.tanks.main[1]
 g.s.supplies.vitamin=3;f.health=45;dice(g,0)
 assert(g:medicine(f.id,'vitamin'));eq(f.health,51)
 dice(g,9);assert(g:medicine(f.id,'vitamin'));eq(f.health,66)
 f.health=99;assert(g:medicine(f.id,'vitamin'));eq(f.health,100)
 eq(g.s.supplies.vitamin,0)
end)
test('hormonio aumenta 2 a 6 e rejeita peixe acima de 40',function()
 local g=Game.new(4);local f=g.s.tanks.main[1]
 g.s.supplies.hormone=3;f.age=40;dice(g,0)
 assert(g:medicine(f.id,'hormone'));eq(f.age,42)
 local left=g.s.supplies.hormone
 assert(not g:medicine(f.id,'hormone'));eq(g.s.supplies.hormone,left)
 f.age=18;dice(g,4)
 assert(g:medicine(f.id,'hormone'));eq(f.age,24)
end)
test('mutageno: chance de 26% respeita a falha e consome dose',function()
 local g=Game.new(5);local f=g.s.tanks.main[1]
 g.s.supplies.mutagen=1;dice(g,26)
 local oldbody,oldtail=f.body,f.tail
 assert(g:medicine(f.id,'mutagen'))
 eq(f.body,oldbody);eq(f.tail,oldtail)
 eq(g.s.supplies.mutagen,0);eq(g.s.stats.mutations,0)
end)
test('mutageno: altera parte selecionada e atualiza catalogo e cotacao',function()
 local g=Game.new(5);local f=g.s.tanks.main[1]
 f.body=1;f.tail=21;f.age=20
 g.s.supplies.mutagen=2
 local queue={0,0} -- sucesso, corpo (1 vira 2)
 g.int=function(_,a,b) return table.remove(queue,1) or 0 end
 assert(g:medicine(f.id,'mutagen'))
 eq(f.body,2);eq(f.tail,21);eq(g.s.stats.mutations,1)
 assert(g.s.seen['2-21']);eq(f.price,Catalog.basePrice(2,21))
 assert(g.s.market.quotes['2-21']~=nil)
 -- Nova dose: escolhe barbatana; 21 deve virar 20.
 queue={25,99};assert(g:medicine(f.id,'mutagen'))
 eq(f.tail,20);eq(g.s.stats.mutations,2)
end)
test('quimico desconhecido na loja entrega UMA dose',function()
 local g=Game.new(6);g.s.cash=300
 assert(g:purchase('mutagen'));eq(g.s.supplies.mutagen,1)
 eq(g.s.cash,150)
end)
test('aerador e aquecedor recuperam +1 se o sorteio for 0..40',function()
 local g=Game.new(7);local f=g.s.tanks.main[2]
 f.health=70;f.fed=100
 g.s.gear.heater=true;g.s.gear.aerator=true
 g.s.research.environment=2
 dice(g,40);g.random=function() return 1 end
 Care.step(g,f,'main');eq(f.health,72)
 dice(g,41);Care.step(g,f,'main');eq(f.health,72)
end)
test('planta nutritiva recupera 5 de reserva quando ela esta quase vazia',function()
 local g=Game.new(8);local f=g.s.tanks.main[1]
 f.health=99;f.fed=2;g.s.gear.plant=true
 dice(g,20);g.random=function() return 1 end
 Care.step(g,f,'main');eq(f.fed,6) -- alimento cai 1, planta +5
end)
test('caracol e planta de cura diminuem risco de doenca',function()
 local g=Game.new(9);local f=g.s.tanks.main[1]
 f.age=20;f.health=100;f.fed=100;f.body=2;f.tail=1
 g.s.research.environment=2;g.s.research.food=0
 -- Java first rolls j.c(10000)=20; for the snail j.c(100)=0.
 -- The old floating-point game.random override no longer applies.
 g.int=function(_,a,b)
  if a==0 and b==9999 then return 20 end
  return a
 end
 Care.step(g,f,'main');eq(f.disease,'ick')
 f.disease=false;g.s.gear.curing_plant=true
 Care.step(g,f,'main');eq(f.disease,false)
 f.disease=false;g.s.gear.curing_plant=false;g.s.gear.snail=true
 Care.step(g,f,'main');eq(f.disease,false)
end)
test('idade acima de 600 aumenta risco base sem mudar demais regras',function()
 local g=Game.new(10);local f=g.s.tanks.main[1]
 f.body=1;f.tail=1;f.health=100;f.fed=100;f.age=601
 g.s.research.environment=2;g.s.research.food=0
 -- j.c(10000)=17 exceeds base risk 10, but not risk 25 at age 601.
 g.int=function(_,a,b)
  if a==0 and b==9999 then return 17 end
  return a
 end
 Care.step(g,f,'main');assert(f.disease)
end)
test('planta de fertilidade permite um segundo nascimento sem peixe magico',function()
 local g=Game.new(11)
 local a=g.s.tanks.main[1].id;local b=g.s.tanks.main[2].id
 g.s.gear.fertility_plant=true
 assert(g:move(a,'isolation'));assert(g:move(b,'isolation'))
 assert(g:breed());g:advance(4*600)
 eq(g.s.stats.born,2)
 eq(#g.s.tanks.main,4)
end)
test('o bonus da planta de fertilidade combina com peixe magico',function()
 local g=Game.new(11);g.s.tanks.main={}
 local magic=Catalog.magic[1]
 local parent=assert(g:addFish('main',magic.body,magic.tail,20))
 local partner=assert(g:addFish('main',1,1,20))
 g.s.gear.fertility_plant=true
 assert(g:move(parent.id,'isolation'));assert(g:move(partner.id,'isolation'))
 assert(g:breed());g:advance(4*600)
 eq(g.s.stats.born,3)
 eq(#g.s.tanks.main,3)
end)
test('save v7 preserva remedios, mutacoes e equipamentos',function()
 local g=Game.new(5)
 g.s.stats.mutations=3;g.s.stats.failed_treatments=2
 g.s.supplies.mutagen=4;g.s.gear.curing_plant=true
 local recovered,err=Game.fromTable(JSON.decode(JSON.encode(g.s)));assert(recovered,err)
 eq(recovered.s.version,9);eq(recovered.s.stats.mutations,3)
 eq(recovered.s.stats.failed_treatments,2)
 eq(recovered.s.supplies.mutagen,4);eq(recovered.s.gear.curing_plant,true)
end)
print('\nFase 7: '..count..' testes adicionais passaram.')
