package.path='./?.lua;./?/init.lua;'..package.path
local captured={}
local nop=function() end
love={graphics={newFont=function() return {setFilter=nop} end,getDimensions=function() return 420,800 end}}
for _,name in ipairs({'setColor','rectangle','setFont','setLineWidth','line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[name]=nop
end
love.graphics.print=function(s) captured[#captured+1]=tostring(s) end
love.graphics.printf=love.graphics.print
local Game=require('core.game')
local View=require('ui.view')
local g=Game.new(10)
local v=View.new(g);v:init()
v.page='research'
local function draw() captured={};v:draw() end
local function shown(value)
 for _,v in ipairs(captured) do if v:find(value,1,true) then return true end end
 return false
end
draw()
assert(shown('Prox.: 61% dos ciclos consomem reserva'))
assert(shown('Indice de publico'))
assert(shown('Delta biologico medio'))
g.s.research.food=3
draw()
assert(shown('Atual: 20% dos ciclos consomem reserva'))
g.s.research.food=0
assert(g:startResearch('food'))
g:advance(120)
draw()
assert(shown('2 min simulados'))
print('V11: 5 verificacoes de interface de pesquisa passaram.')
