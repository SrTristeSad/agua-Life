package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' != '..tostring(b)) end
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then io.stderr:write('FALHOU '..name..': '..tostring(err)..'\n');os.exit(1) end
 print('OK '..name);count=count+1
end
local function noSales(g)
 g.s.sale_open=true
 local fish=g:addFish('sale',1,1,21)
 fish.price=9999
 return fish
end

test('visitas registram seus instantes reais, nao o final do lote',function()
 local g=Game.new(101);noSales(g)
 g:advance(60)
 eq(g.s.market.visits,12)
 for i,h in ipairs(g.s.market.history) do
  eq(h.time,i*5)
 end
end)
test('pesquisa concluida antes do ciclo ja beneficia peixe',function()
 local g=Game.new(102)
 assert(g:startResearch('food'))
 g.int=function(_,a,b) return math.min(b,90) end
 local fish=g.s.tanks.main[1]
 g:advance(600)
 eq(g.s.research.food,1)
 eq(fish.fed,100)
end)
test('mercado reconhece peixe que amadurece durante um lote',function()
 local g=Game.new(103)
 g.s.sale_open=true
 local f=g:addFish('sale',1,1,19)
 f.price=1
 g.int=function(_,a,b) return a end
 g:advance(604)
 eq(g.s.stats.sold,0)
 eq(f.age,20)
 g:advance(1)
 eq(g.s.stats.sold,1)
 eq(g.s.market.last_sale.time,605)
end)
test('lote grande e varios lotes produzem mesmo estado com venda e pesquisa',function()
 local a,b=Game.new(104),Game.new(104)
 for _,g in ipairs({a,b}) do
  local fish=g:addFish('sale',1,1,19)
  fish.price=1
  g.s.sale_open=true
  assert(g:startResearch('food'))
  g.int=function(_,lo,hi) return lo end
 end
 a:advance(1235)
 for _,seconds in ipairs({103,37,222,445,15,413}) do b:advance(seconds) end
 eq(a.s.time,b.s.time)
 eq(a.s.cash,b.s.cash)
 eq(a.s.stats.sold,b.s.stats.sold)
 eq(a.s.rng,b.s.rng)
 eq(JSON.encode(a.s.tanks),JSON.encode(b.s.tanks))
 eq(JSON.encode(a.s.market.history),JSON.encode(b.s.market.history))
end)
test('evento de ovo comprado e processado no prazo exato',function()
 local g=Game.new(105)
 g.s.cash=500;assert(g:purchase('eggs'))
 g:advance(1799)
 eq(#g.s.eggs,2)
 g:advance(1)
 eq(#g.s.eggs,0)
 eq(g.s.stats.born,2)
end)
test('pesquisa, visitas e ovos sobrevivem ao roundtrip no meio do tempo',function()
 local a=Game.new(106)
 a.s.cash=500
 noSales(a)
 assert(a:startResearch('food'))
 assert(a:purchase('eggs'))
 a:advance(133)
 local copy=assert(Game.fromTable(JSON.decode(JSON.encode(a.s))))
 a:advance(580)
 copy:advance(580)
 eq(a.s.time,copy.s.time)
 eq(JSON.encode(a.s.research),JSON.encode(copy.s.research))
 eq(JSON.encode(a.s.eggs),JSON.encode(copy.s.eggs))
 eq(JSON.encode(a.s.market),JSON.encode(copy.s.market))
end)
test('loja fechada nao acumula visitas durante pesquisa',function()
 local g=Game.new(107)
 assert(g:startResearch('food'))
 g:advance(300)
 eq(g.s.market.visits,0)
 eq(g.s.market.elapsed,0)
 eq(g.s.research.food,1)
end)
print('V11 timeline: '..count..' testes passaram.')
