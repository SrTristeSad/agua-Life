-- V25: limites do HUD, selecao proporcional e softkeys no retro J2ME.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local noop=function()end
local printed={}
love={graphics={
 newFont=function()return {setFilter=noop} end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'))
  local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local im={w=n(17),h=n(21),setFilter=noop}
  function im:getDimensions() return self.w,self.h end
  function im:getWidth()return self.w end
  function im:getHeight()return self.h end
  return im
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
 printf=function(s)printed[#printed+1]=tostring(s)end,
}}
for _,name in ipairs({'setColor','rectangle','line','draw','push','pop',
 'translate','scale','setFont','clear'})do love.graphics[name]=noop end
local g=Game.new(251)
local v=Retro.new(g,true);v:init()
local savedCash,saveVersion=g.s.cash,g.s.version
local passed=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,name..': '..tostring(err))
 passed=passed+1;print('OK '..name)
end
local function click(x,y)
 return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
check('barra original usa 3 miniaturas e ocupa os 240 pixels sem frestas',function()
 v.screen='tank';v.room='main';v:draw()
 local limits={0,18,36,54,77,100,123,146,169,192,216,240}
 for i=1,11 do
  local b=v.buttons[i]
  assert(b.x==limits[i] and b.w==limits[i+1]-limits[i],i)
  assert(b.y==2 and b.h==21)
 end
 assert(v.buttons[11].x+v.buttons[11].w==240)
end)
check('filhote usa hitbox menor que adulto e seleciona pelo sprite',function()
 g.s.tanks.main={g.s.tanks.main[1]}
 local f=g.s.tanks.main[1]
 f.age=2;v.screen='tank';v.selected=nil;v:draw()
 local hit=v.fishHits[1]
 assert(hit.rx>=10 and hit.rx<18)
 assert(hit.ry>=8 and hit.ry<15)
 assert(not click(hit.x+21,hit.y))
 assert(v.screen=='tank' and not v.selected)
 assert(click(hit.x+7,hit.y));assert(v.selected==f.id and v.screen=='detail')
 v.screen='tank';v.selected=nil;f.age=20;v:draw()
 hit=v.fishHits[1]
 assert(hit.rx>20)
 assert(click(hit.x+20,hit.y));assert(v.screen=='detail')
end)
check('F1 e F2 ativam somente os comandos inferiores visiveis',function()
 v.room='main';v.screen='tank';v.selected=nil;v:draw()
 v:key('f1');assert(v.screen=='detail')
 v:draw();v:key('f1');assert(v.screen=='actions')
 v:draw();v:key('f2');assert(v.screen=='detail')
 v:draw();v:key('f2');assert(v.screen=='tank')
 v:draw();v:key('f2');assert(v.screen=='pause')
 v.screen='title';v:draw();v:key('f1');assert(v.screen=='tank') -- SELECT escolhe RESUME no menu WELCOME
end)
check('placas For Sale ja pertencem ao fundo tank3 sem texto flutuante',function()
 local f=assert(g:addFish('sale',4,3,20))
 assert(v.assets.images.tank3,'Fundo tank3 original deve existir')
 v.bitmapFont=nil
 v.room='sale';v.screen='detail';v.selected=f.id
 printed={};v:draw()
 for _,s in ipairs(printed) do
  assert(s~='For Sale!','Texto duplicado acompanhando o peixe')
 end
 assert(#v.fishHits>0)
end)
check('nenhum controle modifica por si as regras ou versao de salvamento',function()
 assert(g.s.cash==savedCash)
 assert(g.s.version==saveVersion and saveVersion==9)
end)
print('V25: '..passed..' cenarios de HUD e controles aprovados.')
