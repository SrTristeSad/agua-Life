-- Mock da API grafica para testar layouts, navegacao e botoes sem LÖVE instalado.
package.path='./?.lua;./?/init.lua;'..package.path
local no_op=function() end
local font={setFilter=no_op}
local function font_create() return font end
love={graphics={newFont=font_create,getDimensions=function() return 468,858 end}}
for _,key in ipairs({'setColor','rectangle','print','printf','setFont','setLineWidth',
 'line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[key]=no_op
end
local Game=require('core.game')
local View=require('ui.view')
local g=Game.new(17)
local v=View.new(g)
v:init()
v:draw()
assert(#v.buttons>=14,'Sem controles no aquario')
local function click(x,y)
 v:draw();return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
assert(click(185,753)) -- loja
assert(v.page=='shop')
v:draw()
assert(click(315,222)) -- compra racao na primeira pagina
assert(g.s.supplies.food==10)
assert(click(326,665)) -- pagina 2
assert(v.shopPage==2)
assert(click(282,753)) -- pesquisa
assert(v.page=='research');v:draw()
assert(click(100,292)) -- pesquisa ambiente $120
assert(g.s.research_job.id=='environment')
assert(click(384,753)) -- colecao
assert(v.page=='catalog');v:draw()
assert(click(169,665));assert(v.catalogPage==2)
assert(click(55,754));assert(v.page=='tank')
assert(click(342,139));assert(v.room=='sale')
assert(click(140,660));assert(g.s.sale_open)
assert(click(53,140));assert(v.room=='main')
-- seleção: primeiro peixe
local f=g.s.tanks.main[1]
local Swim=require('ui.swim')
local x,y=Swim.position(f,1,'main',v.pulse)
assert(click(x,y));assert(v.selected==f.id)
assert(click(300,661));assert(v.modal=='move')
-- Dialogo impede pressionar a navegacao do rodape por tras da modal.
assert(not click(190,754));assert(v.page=='tank')
assert(click(180,443));assert(v.modal==nil);assert(v.room=='isolation')
print('UI OK: aquario, selecao, transferencia, loja, pesquisa, colecao, dialogos.')
