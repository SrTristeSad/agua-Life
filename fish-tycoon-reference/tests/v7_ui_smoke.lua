package.path='./?.lua;./?/init.lua;'..package.path
local nop=function() end
local drawn={}
love={graphics={newFont=function() return {setFilter=nop} end,getDimensions=function() return 420,800 end}}
for _,k in ipairs({'setColor','rectangle','setFont','setLineWidth','line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[k]=nop
end
love.graphics.print=function(s) drawn[#drawn+1]=tostring(s) end
love.graphics.printf=love.graphics.print
local Game=require('core.game')
local View=require('ui.view')
local g=Game.new(91)
g.s.cash=999
local view=View.new(g);view:init()
local function draw()
 drawn={};view:draw()
end
local function contains(s)
 for _,label in ipairs(drawn) do if label:find(s,1,true) then return true end end
 return false
end
local function click(x,y) draw();assert(view:press(x,y),'Nao clicavel: '..x..','..y) end
view.page='shop';draw()
assert(contains('Quimico desconhecido'),'Item nao esta disponivel')
click(329,590) -- indice 6 da pagina 1
assert(g.s.supplies.mutagen==1,'Nao comprou quimico')
view.shopPage=2;draw()
assert(contains('Planta de cura'),'Planta de cura nao aparece')
click(330,590) -- sexto item da pagina 2
assert(g.s.gear.curing_plant,'Planta de cura nao foi instalada')
view.shopPage=3;draw()
assert(contains('Planta de fertilidade'),'Planta de fertilidade nao aparece')
click(335,232) -- primeiro item da pagina 3
assert(g.s.gear.fertility_plant,'Planta de fertilidade nao foi instalada')
local f=g.s.tanks.main[1]
view.page='tank';view.room='main';view.selected=f.id
view.modal='medicine';draw()
assert(contains('Cura 40% por dose'),'Interface nao explica percentual do tratamento')
assert(contains('Quimico desconhecido'),'Tratamento quimico ausente do dialogo')
g.int=function() return 0 end
click(90,531)
assert(view.modal==nil,'Dialogo de tratamento nao fechou')
assert(f.body==2,'A dose nao mudou o corpo')
assert(g.s.supplies.mutagen==0,'Dose nao foi consumida')
print('UI v7 OK: nova loja (3 paginas), tratamentos (5 opcoes) e aplicacao do mutageno.')
