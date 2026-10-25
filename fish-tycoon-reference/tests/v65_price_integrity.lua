-- V65: fractional prices used to poison stats.earned and invalidate saves.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local g=Game.new(6599)
local fish=assert(g:addFish('sale',1,1,20))
local id=fish.id
local before=JSON.encode(g.s)
for _,invalid in ipairs({2.5,-0.1,math.huge,-math.huge,0/0}) do
 local ok,reason=g:changePrice(id,invalid)
 assert(not ok and reason=='Ajuste de preco invalido')
 assert(JSON.encode(g.s)==before,'Rejected price command modified the game')
end
assert(g:changePrice(id,2))
assert(fish.price==6)
local sold,earned=g:sell(id)
assert(sold and earned==6 and g.s.stats.earned==6)
assert(g.s.cash==206 and g.s.stats.sold==1)
local restored,why=Game.fromTable(JSON.decode(JSON.encode(g.s)))
assert(restored,why)
-- If another component bypasses changePrice, sell must remain atomic.
local corrupt=Game.new(6600)
local badFish=assert(corrupt:addFish('sale',1,1,20))
badFish.price=6.5
local number=corrupt:countFish()
local cash=corrupt.s.cash
local ok,reason=corrupt:sell(badFish.id)
assert(not ok and reason=='Preco invalido')
assert(corrupt:countFish()==number and corrupt.s.cash==cash)
local state=JSON.decode(JSON.encode(corrupt.s))
assert(not Game.fromTable(state),'A fractional asking price must not load as valid')
state=JSON.decode(JSON.encode(g.s))
state.cash=10.5
assert(not Game.fromTable(state),'A fractional wallet must not load as valid')
print('OK v65: fractional prices rejected, fish/money conserved, saves recoverable')
