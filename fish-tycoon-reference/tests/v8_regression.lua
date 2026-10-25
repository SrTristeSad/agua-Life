package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Market=require('core.market')
local JSON=require('core.json')
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then io.stderr:write('FALHOU '..name..': '..tostring(err)..'\n');os.exit(1) end
 count=count+1;print('OK '..name)
end
local function prepare(seed)
 local g=Game.new(seed or 42)
 g.s.tanks.sale={}
 local f=assert(g:addFish('sale',1,1,25))
 return g,f
end

test('save novo usa schema 8 e cronometro da loja',function()
 local g=Game.new(11)
 eq(g.s.version,9);eq(g.s.market.elapsed,0)
end)
test('v7 para v8 preserva cotacoes, peixe, remedios e dinheiro',function()
 local g,f=prepare(12)
 g.s.supplies.mutagen=4;g.s.cash=987
 local q=g:marketQuote(f)
 local old=JSON.decode(JSON.encode(g.s))
 old.version=7;old.market.elapsed=nil
 local restored,err=Game.fromTable(old)
 assert(restored,err)
 eq(restored.s.version,9);eq(restored.s.market.elapsed,0)
 eq(restored.s.cash,987);eq(restored.s.supplies.mutagen,4)
 eq(#restored.s.tanks.sale,1)
 eq(restored:marketQuote(restored.s.tanks.sale[1]),q)
end)
test('loja fechada nao recebe compradores nem acumula segundos',function()
 local g=prepare(3)
 g:advance(60)
 eq(g.s.market.elapsed,0);eq(g.s.market.visits,0)
end)
test('sem cinco segundos nao ocorre visita, com cinco ocorre uma',function()
 local g,f=prepare(4)
 g.s.sale_open=true;f.price=9999
 g:advance(4.75)
 eq(g.s.market.visits,0)
 g:advance(.25)
 eq(g.s.market.visits,1)
 eq(g.s.market.elapsed,0)
end)
test('loja recebe visitantes antes de ocorrer crescimento',function()
 local g,f=prepare(5)
 g.s.sale_open=true;f.price=9999
 local age=f.age
 g:advance(20)
 eq(f.age,age);eq(g.s.market.visits,4)
end)
test('mercado nao vende peixes que custem o dobro do preco base',function()
 local g,f=prepare(6)
 f.price=9999;g.s.sale_open=true
 g:advance(120)
 eq(g.s.stats.sold,0);eq(#g.s.tanks.sale,1)
 eq(g.s.market.visits,24)
end)
test('nivel baixo de oferta tem demanda 30 e nivel medio tem 10',function()
 local g,f=prepare(7)
 local b=20
 f.price=2
 local _,d=Market.chancePerVisit(f,20,b,0,false,1)
 eq(d,30)
 f.price=17
 local _,m=Market.chancePerVisit(f,20,b,0,false,1)
 eq(m,10)
end)
test('faixas altas 4, 1, zero seguem comparadores JAR',function()
 local f={price=20}
 local _,d=Market.chancePerVisit(f,20,20,0,false,1);eq(d,4)
 f.price=35
 local _,m=Market.chancePerVisit(f,20,20,0,false,1);eq(m,1)
 f.price=40
 local p,z=Market.chancePerVisit(f,20,20,0,false,1);eq(z,0);eq(p,0)
end)
test('publicidade e decoracao aumentam a intensidade de visitantes',function()
 local f={price=1}
 local lo=Market.chancePerVisit(f,20,20,0,false,1)
 local hi=Market.chancePerVisit(f,20,20,3,true,15)
 assert(hi>lo)
end)
test('cada visitante compra no maximo um peixe',function()
 local g,f=prepare(21)
 g.s.tanks.sale={}
 for i=1,10 do
  local fish=assert(g:addFish('sale',1,1,25))
  fish.price=1
 end
 g.s.sale_open=true
 g.int=function(_,a,b) return a end
 local sold=Market.step(g)
 assert(sold)
 eq(g.s.stats.sold,1);eq(#g.s.tanks.sale,9)
 eq(g.s.market.visits,1)
end)
test('comprador testa o proximo peixe se rejeita a primeira oferta',function()
 local g=Game.new(3)
 local f1=assert(g:addFish('sale',1,1,21))
 local f2=assert(g:addFish('sale',2,2,22))
 f1.price=9999;f2.price=1
 g.s.sale_open=true
 g.int=function(_,a,b) return a end
 assert(Market.step(g))
 eq(g.s.stats.sold,1)
 eq(g.s.tanks.sale[1].id,f1.id)
end)
test('fracionamento do tempo preserva RNG, caixa e ofertas',function()
 local a,fa=prepare(34)
 local b,fb=prepare(34)
 a.s.sale_open=true;b.s.sale_open=true
 fa.price=1;fb.price=1
 a:advance(600)
 b:advance(17);b:advance(70);b:advance(120);b:advance(393)
 eq(JSON.encode(a.s.tanks),JSON.encode(b.s.tanks))
 eq(a.s.market.visits,b.s.market.visits)
 eq(a.s.market.rejected,b.s.market.rejected)
 eq(a.s.cash,b.s.cash)
 eq(a.s.rng,b.s.rng)
end)
test('accumulator de visita volta apos serialize/deserialize',function()
 local g,f=prepare(35)
 f.price=9999;g.s.sale_open=true
 g:advance(2.5)
 local restored=assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))
 eq(restored.s.market.elapsed,2.5)
 restored:advance(2.5)
 eq(restored.s.market.visits,1)
end)
test('fechar loja zera fracao para evitar visitas acumuladas',function()
 local g,f=prepare(36)
 f.price=9999;g.s.sale_open=true
 g:advance(4)
 g.s.sale_open=false;g:advance(1)
 eq(g.s.market.elapsed,0)
 g.s.sale_open=true;g:advance(1)
 eq(g.s.market.visits,0)
end)
test('incubacao mostra ciclos ainda necessarios',function()
 local g=Game.new(37)
 assert(g:move(1,'isolation'));assert(g:move(2,'isolation'))
 assert(g:breed())
 local id=g.s.tanks.isolation[1].id
 eq(g:incubationInfo(id).remaining,4)
 g:advance(600)
 eq(g:incubationInfo(id).remaining,3)
 g:advance(3*600)
 assert(not g:incubationInfo(id))
end)
test('pesquisa informa progresso 0%, 50% e fim',function()
 local g=Game.new(38)
 assert(g:startResearch('food'))
 local job=g:researchInfo()
 eq(job.level,1);eq(job.progress,0)
 g:advance(job.total/2)
 assert(math.abs(g:researchInfo().progress-.5)<1e-7)
 g:advance(job.total/2)
 assert(not g:researchInfo())
 eq(g.s.research.food,1)
end)
test('ovos pagos aguardam vaga em vez de se perderem',function()
 local g=Game.new(39)
 g.s.cash=300
 assert(g:purchase('eggs'))
 for i=1,14 do assert(g:addFish('main',1,1,20)) end
 eq(#g.s.tanks.main,18)
 g:advance(1800)
 eq(#g.s.eggs,2)
 assert(g.s.eggs[1].waiting)
 eq(g.s.stats.born,0)
 local fid=g.s.tanks.main[1].id
 assert(g:move(fid,'sale'))
 g:advance(1)
 eq(#g.s.eggs,1)
 eq(g.s.stats.born,1)
end)
test('ovos pendentes permanecem no save e eclodem depois',function()
 local g=Game.new(40);g.s.cash=300
 assert(g:purchase('eggs'))
 for i=1,14 do assert(g:addFish('main',1,1,20)) end
 g:advance(1800)
 local saved=assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))
 eq(#saved.s.eggs,2)
 assert(saved:move(saved.s.tanks.main[1].id,'sale'))
 saved:advance(1)
 eq(#saved.s.eggs,1)
end)
print('\nFase 8: '..count..' testes adicionais passaram.')
