package.path='./?.lua;./?/init.lua;'..package.path
local nop=function() end
local drawn={}
local function capture(s) drawn[#drawn+1]=tostring(s) end
love={graphics={newFont=function() return {setFilter=nop} end,getDimensions=function() return 420,800 end}}
for _,k in ipairs({'setColor','rectangle','setFont','setLineWidth','line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[k]=nop
end
love.graphics.print=capture;love.graphics.printf=capture
local Game=require('core.game')
local View=require('ui.view')
local g=Game.new(26);local v=View.new(g);v:init()
local function contains(q)
 for _,line in ipairs(drawn) do if line:find(q,1,true) then return true end end
 return false
end
v:draw()
assert(contains('Alimento 100%') and contains('Doentes 0'),'Ausente resumo sanitário')
v.selected=g.s.tanks.main[2].id;drawn={};v:draw()
assert(contains('Resistencia -19'),'Falta indicador de resistencia por especie')
v.page='research';drawn={};v:draw()
assert(contains('100% dos ciclos'),'Pesquisa de alimento nao mostra taxa atual')
g.s.research.food=2;g.s.research.environment=3;drawn={};v:draw()
assert(contains('31% dos ciclos'),'Pesquisa de alimentacao nao atualiza')
assert(contains('Protecao +2'),'Pesquisa de ambiente final nao descreve bonus')
print('UI v6 OK: condicoes do tanque, resistencia por peixe, nivel de pesquisa.')
