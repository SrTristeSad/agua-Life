package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Market=require('core.market')
local JSON=require('core.json')
local Catalog=require('core.catalog')
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then io.stderr:write('FALHOU '..name..': '..tostring(err)..'\n');os.exit(1) end
 count=count+1;print('OK '..name)
end
local function setup()
 local g=Game.new(47)
 g.s.tanks.sale={}
 local f=assert(g:addFish('sale',1,1,20))
 g.s.sale_open=true
 return g,f
end

test('schema 9 criado com historico de visitas',function()
 local g=Game.new(1)
 eq(g.s.version,9);eq(#g.s.market.history,0);eq(g.s.market.last_visit,false)
end)
test('visitante registra recusa e publico analisado',function()
 local g,f=setup();f.price=9999
 assert(not Market.step(g))
 local v=g.s.market.last_visit
 eq(v.visit,1);eq(v.status,'passed');eq(v.offered,1)
 eq(#g.s.market.history,1)
end)
test('loja sem peixes registra visita vazia',function()
 local g=setup();g.s.tanks.sale={}
 Market.step(g)
 eq(g.s.market.last_visit.status,'empty')
 eq(g.s.market.rejected,1)
end)
test('venda registra variedade, preco ofertado e receita',function()
 local g,f=setup()
 f.price=1
 local id=f.id
 g.int=function(_,a,b) return a end
 assert(Market.step(g))
 local h=g.s.market.history[1]
 eq(h.status,'sold');eq(h.id,id);eq(h.asked,1)
 eq(h.amount,1);eq(h.body,1);eq(h.fin,1)
 eq(g.s.market.last_sale.id,id)
end)
test('historico limitado a doze e preserva a ordem',function()
 local g,f=setup();f.price=9999
 for _=1,200 do Market.step(g) end
 eq(#g.s.market.history,12)
 eq(g.s.market.history[1].visit,189)
 eq(g.s.market.history[12].visit,200)
end)
test('ultimas visitas continuam depois de salvar e carregar',function()
 local g,f=setup();f.price=9999
 Market.step(g);Market.step(g)
 local restored=assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))
 eq(restored.s.version,9);eq(#restored.s.market.history,2)
 eq(restored.s.market.last_visit.visit,2)
 Market.step(restored)
 eq(restored.s.market.history[3].visit,3)
end)
test('save v8 migra com cotacoes intactas e cria historico vazio',function()
 local g,f=setup();g.s.cash=321
 local old=JSON.decode(JSON.encode(g.s))
 old.version=8;old.market.history=nil;old.market.last_visit=nil
 local recovered=assert(Game.fromTable(old))
 eq(recovered.s.version,9);eq(recovered.s.cash,321)
 eq(#recovered.s.market.history,0);eq(recovered.s.market.last_visit,false)
 eq(#recovered.s.tanks.sale,1)
 eq(recovered.s.tanks.sale[1].id,f.id)
end)
test('save v9 com historico malformado nao perde dados silenciosamente',function()
 local g=setup();local old=JSON.decode(JSON.encode(g.s))
 old.market.history={'erro',{}, {visit=2,time=10,status='passed'}}
 old.market.last_visit='erro'
 local restored,reason=Game.fromTable(old)
 assert(not restored and type(reason)=='string')
 -- Saves anteriores a v9 nunca tinham historico confiavel.
 -- Eles podem migrar e reconstruir o historico vazio.
 old.version=8
 local migrated=assert(Game.fromTable(old))
 eq(#migrated.s.market.history,1);eq(migrated.s.market.last_visit,false)
end)
test('bonus de riqueza vale quando o proprio ultimo magico e vendido',function()
 local g=Game.new(2)
 g.s.tanks.sale={}
 local m=Catalog.magic[7]
 local f=assert(g:addFish('sale',m.body,m.tail,20))
 f.price=200
 local ok,paid=g:sell(f.id)
 assert(ok);eq(paid,230)
 eq(g.s.market.last_sale.wealth,true)
 eq(#g.s.tanks.sale,0)
end)
test('bonus nao e aplicado depois que ultimo peixe magico saiu',function()
 local g=Game.new(2)
 g.s.tanks.sale={}
 local m=Catalog.magic[7]
 local f=assert(g:addFish('sale',m.body,m.tail,20))
 local other=assert(g:addFish('sale',1,1,20))
 other.price=100
 assert(g:sell(f.id))
 local ok,paid=g:sell(other.id)
 assert(ok);eq(paid,100)
 eq(g.s.market.last_sale.wealth,false)
end)
test('vendas automaticas e manuais mantem receita e status coerentes',function()
 local g,f=setup();f.price=5
 g.int=function(_,a,b) return a end
 assert(Market.step(g))
 eq(g.s.market.history[1].status,'sold')
 eq(g.s.market.last_sale.automatic,true)
 local f2=assert(g:addFish('sale',2,2,20))
 assert(g:sell(f2.id))
 eq(g.s.market.last_sale.automatic,false)
 eq(g.s.stats.sold,2)
end)
test('v8 fracionamento de tempo continua deterministico com historico',function()
 local a,fa=setup();local b,fb=setup()
 fa.price=9999;fb.price=9999
 a:advance(123)
 b:advance(45);b:advance(78)
 eq(JSON.encode(a.s.market.history),JSON.encode(b.s.market.history))
 eq(a.s.rng,b.s.rng)
end)
print('\nFase 9: '..count..' testes adicionais passaram.')
