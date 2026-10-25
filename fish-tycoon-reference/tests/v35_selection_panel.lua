-- V35: geometria da moldura de selecao do J2ME e fixture na sala correta.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local Catalog=require('core.catalog')
local noop=function() end
local rects,labels,images={}, {}, {}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local im={w=n(17),h=n(21),path=path,setFilter=noop}
  function im:getDimensions()return self.w,self.h end
  function im:getWidth()return self.w end
  function im:getHeight()return self.h end
  return im
 end,
 newQuad=function(x,y,w,h,iw,ih)assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih);return {x=x,y=y,w=w,h=h}end,
 rectangle=function(mode,x,y,w,h)rects[#rects+1]={mode=mode,x=x,y=y,w=w,h=h}end,
 draw=function(img)if img.path then images[#images+1]=img.path end end,
 printf=function(value)labels[#labels+1]=tostring(value) end,
 getScissor=function()return nil end,
 setScissor=noop,
}}
for _,name in ipairs({'setColor','line','push','pop','translate','scale','setFont','clear'})do love.graphics[name]=noop end
local g=Game.new(3500)
local f=assert(g:addFish('sale',9,17,21))
for i=2,5 do assert(g:addFish('sale',(i%21)+1,((i*2)%21)+1,21))end
f.fed=100;f.health=100
local v=Retro.new(g,true);v:init()
v.room='sale';v.screen='detail';v.selected=f.id;v.time=1.5
local oldMoney,oldRng,oldTime=g.s.cash,g.s.rng,g.s.time
local count=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V35 '..name..': '..tostring(err))
 count=count+1;print('OK '..name)
end
local function render()rects={};labels={};images={};v:draw()end
local function rect(mode,x,y,w,h)
 for _,r in ipairs(rects) do
  if r.mode==mode and r.x==x and r.y==y and r.w==w and r.h==h then return true end
 end
 return false
end
check('moldura superior 216x33 nao invade o destaque amarelo',function()
 render()
 assert(rect('fill',12,0,216,33),'origem do painel diferente da referencia')
 assert(rect('fill',13,29,214,2),'realce inferior ausente')
 assert(rect('line',63.5,34.5,55,36),'contorno da selecao nao encontrado')
end)
check('referencia e tank3, mesma sala de vendas da imagem Java',function()
 local bg=false
 for _,path in ipairs(images) do if path:find('tank3.png',1,true) then bg=true end end
 assert(bg,'a fixture J2ME precisa usar o tanque de vendas')
 assert(Catalog.nameFor(f.body,f.tail)=='GREENFIN FRUITFISH')
 assert(f.age==21 and v.room=='sale')
 assert(v.fishHits[#v.fishHits].id==f.id)
end)
check('barra FED e HEALTH nao alteram atributos do peixe',function()
 render()
 local fed,health=false,false
 for _,s in ipairs(labels) do
  if s=='FED' then fed=true end
  if s=='HEALTH' then health=true end
 end
 -- Fontes bitmap locais podem ignorar printf do mock, mas a posicao
 -- da barra verde sempre e registravel no renderizador.
 assert((fed and health) or v.bitmapFont,'titulos do painel ausentes')
 assert(rect('fill',60,7,16,3),'barra de alimento ausente')
 assert(rect('fill',60,20,16,3),'barra de saude ausente')
 assert(f.fed==100 and f.health==100)
end)
check('mudar de sala nao altera simulacao nem saves',function()
 v.screen='tank';v.selected=nil;render()
 assert(g.s.cash==oldMoney and g.s.rng==oldRng and g.s.time==oldTime)
 assert(g.s.version==9)
 assert(#g.s.tanks.sale==5)
end)
print('V35: '..count..' verificacoes do painel e fixture aprovadas')
