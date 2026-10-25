package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local g=Game.new(111)
for i=1,18 do
 local f=assert(g:addFish('sale',i,1,25))
 f.price=9999
end
g.s.sale_open=true
local start=os.clock()
g:advance(86400)
assert(g.s.market.visits==17280)
assert(g.s.stats.sold==0)
print('Tempo de 24h simulado:',math.floor((os.clock()-start)*1000),'ms; visitas:',g.s.market.visits)
