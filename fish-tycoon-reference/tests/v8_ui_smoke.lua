-- Testa elementos novos da tela sem simular um dispositivo real.
package.path='./?.lua;./?/init.lua;'..package.path
local noop=function() end
local drawn={}
love={graphics={newFont=function() return {setFilter=noop} end,getDimensions=function() return 420,800 end}}
for _,k in ipairs({'setColor','rectangle','setFont','setLineWidth','line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[k]=noop
end
love.graphics.print=function(s) drawn[#drawn+1]=tostring(s) end
love.graphics.printf=love.graphics.print
local Game=require('core.game')
local View=require('ui.view')
local g=Game.new(80)
local v=View.new(g);v:init()
local function draw()
 drawn={};v:draw()
end
local function contains(part)
 for _,s in ipairs(drawn) do if s:find(part,1,true) then return true end end
 return false
end
v.page='tank';v.room='sale';draw()
assert(contains('Clientes: 0'))
assert(contains('Loja fechada'))
g.s.sale_open=true
g:advance(10)
draw()
assert(contains('Clientes: 2'))
assert(contains('Proxima visita'))
-- Pesquisa em curso e barra percentual depois da metade.
g.s.cash=900
assert(g:startResearch('food'))
g:advance(120)
v.page='research';draw()
assert(contains('Trabalho em andamento'))
assert(contains('Progresso 50%'))
-- Depois do cruzamento, a ficha individual descreve a incubacao.
assert(g:move(1,'isolation'));assert(g:move(2,'isolation'))
assert(g:breed())
v.page='tank';v.room='isolation';v.selected=g.s.tanks.isolation[1].id
draw()
assert(contains('OVOS: 4 ciclos para eclosao'))
print('UI v8 OK: compradores, barra de pesquisa e incubacao no painel.')
