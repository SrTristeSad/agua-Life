package.path='./?.lua;./?/init.lua;'..package.path
local nop=function() end
local drawn={}
love={graphics={newFont=function() return {setFilter=nop} end,getDimensions=function() return 420,800 end}}
for _,method in ipairs({'setColor','rectangle','setFont','setLineWidth','line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[method]=nop
end
love.graphics.print=function(s) drawn[#drawn+1]=tostring(s) end
love.graphics.printf=love.graphics.print
local Game=require('core.game')
local Market=require('core.market')
local View=require('ui.view')
local g=Game.new(55)
local v=View.new(g);v:init()
v.room='sale';v.page='tank'
local function draw() drawn={};v:draw() end
local function contains(part)
 for _,s in ipairs(drawn) do if s:find(part,1,true) then return true end end
 return false
end
local function click(x,y)
 draw();return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
draw();assert(contains('CONTROLE DE VENDAS'))
assert(contains('Ainda nao houve visitas'))
assert(click(287,652));assert(v.modal=='history')
draw();assert(contains('HISTORICO DA LOJA'))
assert(contains('Nenhum cliente'))
assert(click(364,204));assert(v.modal==nil)
local f=assert(g:addFish('sale',1,1,20));f.price=9999
g.s.sale_open=true;Market.step(g)
draw();assert(contains('nao comprou'))
assert(click(279,655));draw();assert(contains('Cliente saiu sem comprar'))
assert(click(364,204))
g.int=function(_,a,b) return a end
f.price=1
assert(Market.step(g))
v:update(.1)
draw()
assert(contains('VENDA  +$1'))
assert(contains('Cliente comprou por $1'))
assert(click(280,658));draw();assert(contains('VENDA  Forma 1 / Barbatana 1'))
-- Dialog blocks clicks behind itself.
assert(not click(167,749))
print('UI v9 OK: controle de loja, historico, vendas animadas e modal.')
