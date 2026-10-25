-- Controles novos de mercado e alimentar tanque, com LÖVE simulado.
package.path='./?.lua;./?/init.lua;'..package.path
local nop=function() end
love={graphics={newFont=function() return {setFilter=nop} end,getDimensions=function() return 420,800 end}}
for _,k in ipairs({'setColor','rectangle','print','printf','setFont','setLineWidth','line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[k]=nop
end
local Game=require('core.game')
local View=require('ui.view')
local g=Game.new(101)
local v=View.new(g);v:init();v:draw()
local function click(x,y) v:draw();return v:press(x,y) end
local f=g.s.tanks.main[1];f.fed=12
assert(click(82,655)) -- Alimentar tanque na tela sem peixe selecionado
assert(f.fed==62)
assert(g.s.supplies.food==4)
local id=f.id
assert(g:move(id,'sale'))
v.room='sale';v.selected=id
f.price=800
v:draw();assert(click(188,667)) -- botao Justo
assert(f.price==g:marketQuote(f))
assert(click(275,667)) -- venda direta
assert(not g:find(id));assert(g.s.stats.sold==1)
assert(g.s.market.last_sale.automatic==false)
print('UI v5 OK: alimentacao coletiva, preco justo e venda direta.')
