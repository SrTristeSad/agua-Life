package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Market=require('core.market')
local JSON=require('core.json')
local Catalog=require('core.catalog')
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' != '..tostring(b)) end
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then io.stderr:write('FALHOU '..name..': '..tostring(err)..'\n');os.exit(1) end
 count=count+1;print('OK - '..name)
end

test('a versao 5 mantem o elenco inicial e os precos base',function()
 local g=Game.new(3)
 eq(g.s.version,9);eq(#g.s.tanks.main,4)
 eq(g.s.tanks.main[1].price,Catalog.basePrice(1,1))
end)
test('mercado cria cotacoes persistentes com variacao original +/- base/5',function()
 local g=Game.new(7)
 for body=1,21 do for fin=1,21 do
  local f=assert(g:addFish('sale',body,fin,20))
  local q=g:marketQuote(f)
  local b=Catalog.basePrice(body,fin)
  assert(q>=math.max(1,b-math.floor(b/5)))
  assert(q<=b+math.floor(b/5))
  eq(q,g:marketQuote(f))
  -- Precisa liberar capacidade do tanque para testar todas as variedades.
  g.s.tanks.sale={}
 end end
 eq(#g.s.market.quotes,0) -- dicionario, nao lista
 local total=0;for _ in pairs(g.s.market.quotes) do total=total+1 end
 eq(total,441)
end)
test('variedades jovens adquirem cotacao apenas na maturidade',function()
 local g=Game.new(11)
 local f=assert(g:addFish('main',16,12,19))
 assert(Market.peek(g,16,12)==nil)
 g:advance(600)
 assert(Market.peek(g,16,12)~=nil)
end)
test('oferta pode ser igualada ao mercado sem alterar outros peixes',function()
 local g=Game.new(23)
 local f=g.s.tanks.main[1]
 f.price=500
 local ok,q=g:matchMarketPrice(f.id)
 assert(ok);eq(f.price,q);eq(q,g:marketQuote(f))
 assert(not g:matchMarketPrice(9999))
end)
test('compradores penalizam preco alto e valorizam preco baixo',function()
 local sample={price=2}
 local q=20;local b=20
 local cheap=Market.chancePerVisit(sample,q,b,0,false)
 sample.price=21
 local expensive=Market.chancePerVisit(sample,q,b,0,false)
 sample.price=9999
 local impossible=Market.chancePerVisit(sample,q,b,0,false)
 assert(cheap>expensive and expensive>impossible and impossible==0)
end)
test('area fechada nao recebe visitas e aberta vende preco competitivo',function()
 local g=Game.new(2)
 g.s.tanks.sale={}
 local f=assert(g:addFish('sale',1,1,22))
 g.s.sale_open=false
 for _=1,100 do Market.step(g) end
 eq(#g.s.tanks.sale,1);eq(g.s.market.visits,0)
 f.price=1
 g.s.sale_open=true
 for _=1,400 do if #g.s.tanks.sale==0 then break end; Market.step(g) end
 eq(#g.s.tanks.sale,0)
 assert(g.s.market.visits>0)
 assert(g.s.stats.sold>=1)
 eq(g.s.market.last_sale.automatic,true)
end)
test('precos inviaveis nao geram venda mesmo apos milhares de visitas',function()
 local g=Game.new(51)
 local f=assert(g:addFish('sale',8,8,20))
 f.price=9999
 g.s.sale_open=true
 for _=1,200 do Market.step(g) end
 eq(#g.s.tanks.sale,1)
 eq(g.s.stats.sold,0)
end)
test('cruzamento comum produz um alevino, sem sorteio de ate tres',function()
 local g=Game.new(17)
 assert(g:move(1,'isolation'));assert(g:move(2,'isolation'))
 assert(g:breed())
 g:advance(4*600)
 eq(#g.s.tanks.main,3)
 eq(g.s.stats.born,1)
end)
test('magia de fertilidade exige adulto presente no mesmo isolamento',function()
 local g=Game.new(29)
 local magic=Catalog.magic[1]
 g.s.tanks.main={}
 local special=assert(g:addFish('main',magic.body,magic.tail,20))
 assert(g:hasMagic('fertility','main'))
 assert(not g:hasMagic('fertility','isolation'))
 assert(g:move(special.id,'isolation'))
 assert(g:hasMagic('fertility','isolation'))
 assert(g:breed()==false) -- nao ha segundo adulto
 local partner=assert(g:addFish('main',1,1,20))
 assert(g:move(partner.id,'isolation'))
 assert(g:breed())
 g:advance(4*600)
 eq(#g.s.tanks.main,2) -- 1 normal + 1 extra, conforme n.j[0]
end)
test('descoberta de filhote especial so entra no catalogo na maturidade',function()
 local g=Game.new(33)
 local magic=Catalog.magic[2]
 local k='2'
 assert(not g.s.magic[k])
 local f=assert(g:addFish('main',magic.body,magic.tail,19))
 assert(not g.s.magic[k])
 g:advance(600)
 assert(g.s.magic[k]);eq(f.age,20)
end)
test('alimentacao de tanque usa ração e nao alimenta peixes saciados',function()
 local g=Game.new(6)
 g.s.supplies.food=2
 g.s.tanks.main[1].fed=10
 g.s.tanks.main[2].fed=20
 g.s.tanks.main[3].fed=30
 g.s.tanks.main[4].fed=100
 local ok,countFed=g:feedTank('main')
 assert(ok);eq(countFed,2)
 eq(g.s.supplies.food,0)
 eq(g.s.tanks.main[3].fed,30)
 assert(not g:feedTank('invalid'))
end)
test('migração v4=>v5 preserva preços, peixes, dinheiro e gravidez',function()
 local g=Game.new(21)
 assert(g:move(1,'isolation'));assert(g:move(2,'isolation'))
 assert(g:breed())
 local old=JSON.decode(JSON.encode(g.s))
 old.version=4;old.market=nil
 old.tanks.isolation[1].price=999
 old.cash=450
 local restored,err=Game.fromTable(old)
 assert(restored,err)
 eq(restored.s.version,9);eq(restored.s.cash,450)
 eq(restored.s.tanks.isolation[1].price,999)
 assert(restored.s.tanks.isolation[1].eggs_at)
 eq(#restored.s.tanks.main,2)
end)
test('save v5 preserva cotacao e RNG: compra apos reabertura e deterministica',function()
 local g=Game.new(6)
 local f=assert(g:addFish('sale',8,8,20))
 local q=g:marketQuote(f)
 local restored=assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))
 eq(restored:marketQuote(restored.s.tanks.sale[1]),q)
 eq(restored:random(),g:random())
end)
print('\nFase 5: '..count..' testes passaram.')
