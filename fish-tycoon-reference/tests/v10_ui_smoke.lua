package.path='./?.lua;./?/init.lua;'..package.path
local calls={}
local nop=function() end
love={graphics={newFont=function() return {setFilter=nop} end,getDimensions=function() return 420,800 end}}
for _,method in ipairs({'setColor','rectangle','setFont','setLineWidth','line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[method]=nop
end
love.graphics.print=function(s) calls[#calls+1]=tostring(s) end
love.graphics.printf=love.graphics.print
local Game=require('core.game')
local View=require('ui.view')
local Swim=require('ui.swim')
local g=Game.new(39)
local v=View.new(g);v:init()
local tests=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('ERRO '..name..': '..tostring(err)) end
 tests=tests+1
 print('OK '..name)
end
local function draw() calls={};v:draw() end
local function has(needle)
 for _,s in ipairs(calls) do if s:find(needle,1,true) then return true end end
 return false
end
local function click(x,y)
 draw();return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
test('selecao acompanha centro do peixe em movimento',function()
 local f=g.s.tanks.main[1]
 for _,t in ipairs({.0,1.5,3.7,9.1,21.6}) do
  v.pulse=t
  local x,y=Swim.position(f,1,'main',t)
  assert(click(x,y),"not clicked at "..t);assert(v.selected==f.id,"wrong fish at "..t.." selected="..tostring(v.selected).." expected="..f.id)
  assert(click(x,y));assert(v.selected==nil,"not unselected at "..t.." got="..tostring(v.selected))
 end
end)
test('selecao prioriza proximidade mesmo com dois alvos sobrepostos',function()
 g.s.tanks.main={}
 local a=assert(g:addFish('main',1,1,20))
 local b=assert(g:addFish('main',1,1,20))
 local overlapTime=nil
 for t=0,120,.1 do
  local ax,ay=Swim.position(a,1,'main',t)
  local bx,by=Swim.position(b,2,'main',t)
  if math.abs(ax-bx)<66 and math.abs(ay-by)<46 then overlapTime=t;break end
 end
 assert(overlapTime)
 v.pulse=overlapTime
 local x,y=Swim.position(a,1,'main',overlapTime)
 assert(click(x,y));assert(v.selected==a.id)
end)
test('marcadores de doenca e fome nao interrompem o desenho',function()
 local a=g.s.tanks.main[1]
 a.disease='ick';a.fed=0;draw()
 assert(#v.fishHits==#g.s.tanks.main)
 a.disease=false;draw()
 assert(#v.fishHits==#g.s.tanks.main)
end)
test('galeria de 441 combinacoes usa descobertas existentes',function()
 v.page='catalog';v.catalogPage=3;v.catalogBody=1
 g.s.seen['1-17']=true
 draw();assert(has('FORMA 00'));assert(has('BARB. 16'));assert(has('17 de 21')==false)
 assert(has('2 de 21')) -- a variedade 1-1 inicial e a 1-17 marcada
 assert(click(321,631));assert(v.catalogBody==2)
 draw();assert(has('FORMA 01'))
 assert(click(103,631));assert(v.catalogBody==1)
end)
test('navegacao do catalogo passa pelas tres abas',function()
 v.page='catalog';v.catalogPage=1
 assert(click(170,674));assert(v.catalogPage==2)
 assert(click(170,674));assert(v.catalogPage==3)
 assert(click(170,674));assert(v.catalogPage==1)
end)
test('ultimo e primeiro corpo sao contiguos',function()
 v.catalogPage=3;v.catalogBody=1
 assert(click(104,631));assert(v.catalogBody==21)
 assert(click(315,631));assert(v.catalogBody==1)
end)
test('modal bloqueia selecao dos peixes',function()
 v.page='tank';v.room='main';v.selected=nil;v.modal='medicine'
 draw();local pos=v.fishHits[1]
 assert(pos and not v:press(pos.x,pos.y))
 assert(v.selected==nil)
end)
print('V10: '..tests..' testes adicionais de interface passaram.')
