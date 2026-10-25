-- V30: geometria e ordem da selecao do peixe baseada na captura J2ME 240x320.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Retro=require('ui.retro')
local noop=function()end
local rectangles={}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'))
  local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function num(pos)
   local a,b,c,d=h:byte(pos,pos+3)
   return ((a*256+b)*256+c)*256+d
  end
  local img={w=num(17),h=num(21),setFilter=noop}
  function img:getDimensions()return self.w,self.h end
  function img:getWidth()return self.w end
  function img:getHeight()return self.h end
  return img
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
 rectangle=function(mode,x,y,w,h)
  if mode=='line' then rectangles[#rectangles+1]={x=x,y=y,w=w,h=h} end
 end,
}}
for _,op in ipairs({'setColor','line','draw','push','pop','translate','scale','setFont','clear','printf'}) do
 love.graphics[op]=noop
end
local g=Game.new(3001)
local view=Retro.new(g,true);view:init()
local first=g.s.tanks.main[1]
local other=g.s.tanks.main[2]
assert(first and other)
first.age=23;other.age=21
local beforeVersion,initialCash=g.s.version,g.s.cash
local hits={}
local oldDraw=view.assets.drawFish
view.assets.drawFish=function(self,f,x,y,scale,face)
 hits[#hits+1]={id=f.id,x=x,y=y,scale=scale}
 return oldDraw(self,f,x,y,scale,face)
end
local passed=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V30 '..name..': '..tostring(err))
 passed=passed+1; print('OK '..name)
end
local function focusedOutline()
 for _,r in ipairs(rectangles) do
  if r.x==63.5 and r.y==34.5 and r.w==55 and r.h==36 then return true end
 end
 return false
end
check('selecionado adulto usa ancora e contorno amarelo da referencia',function()
 view.screen='detail';view.room='main';view.selected=first.id
 view.screen='tank';view.selected=nil;view:draw()
 local natural={}
 for _,h in ipairs(view.fishHits) do natural[h.id]={x=h.x,y=h.y} end
 view.screen='detail';view.selected=first.id
 rectangles={};hits={};view:draw()
 assert(focusedOutline(),'Moldura x=63..119 e y=34..71 nao encontrada')
 local last=hits[#hits]
 assert(last.id==first.id and last.x==91 and last.y==53 and last.scale==1)
 -- Na v34 o exemplar destacado e desenhado por ultimo, com o fundo
 -- original restaurado na moldura. Os demais nao mudam de coordenada.
 for _,h in ipairs(view.fishHits) do
  if h.id~=first.id then
   local expected=assert(natural[h.id])
   assert(math.abs(expected.x-h.x)<.001 and math.abs(expected.y-h.y)<.001)
  end
 end
end)
check('o selecionado e sempre desenhado por ultimo',function()
 view.selected=other.id
 rectangles={};hits={};view:draw()
 assert(hits[#hits].id==other.id)
 assert(#hits==#g.s.tanks.main)
 assert(focusedOutline())
end)
check('navegar entre peixes move somente a apresentacao selecionada',function()
 view.selected=first.id;view.browseIndex=1
 assert(view:browseFish(1))
 assert(view.selected==other.id)
 hits={};view:draw()
 assert(hits[#hits].id==other.id and hits[#hits].x==91)
 assert(view:browseFish(-1))
 assert(view.selected==first.id)
end)
check('voltar ao tanque libera a ancora de detalhe',function()
 view.time=3.2;view.screen='detail';view.selected=first.id
 view:draw()
 view:key('escape')
 assert(view.screen=='tank')
 hits={};rectangles={};view:draw()
 assert(not focusedOutline())
 local original
 for _,hit in ipairs(hits)do if hit.id==first.id then original=hit end end
 assert(original and (original.x~=91 or original.y~=53))
end)
check('o save e o motor nao mudam pelo desenho e navegacao',function()
 assert(g.s.version==9 and g.s.version==beforeVersion)
 assert(g.s.cash==initialCash)
 assert(g.s.tanks.main[1].age==23)
 assert(g.s.tanks.main[2].age==21)
end)
print('V30: '..passed..' testes de posicionamento e selecao passaram')
