-- V22: teclado classico J2ME sem dependencia de uma janela grafica.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro');local Game=require('core.game')
local noop=function() end
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local o={w=n(17),h=n(21),setFilter=noop}
  function o:getDimensions()return self.w,self.h end
  function o:getWidth()return self.w end
  function o:getHeight()return self.h end
  return o
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,printf=noop}}
for _,op in ipairs({'setColor','rectangle','line','draw','push','pop','translate','scale','setFont','clear'}) do love.graphics[op]=noop end
local initial=Game.new(2200);local v=Retro.new(initial,false);v:init()
local count=0
local function check(name,fn)
 local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));count=count+1;print('OK '..name)
end
check('sem save o foco inicial vai para NEW GAME',function()
 v:draw();assert(v.buttons[v.focus].y==100)
end)
check('2/8 move foco; 5 abre OPTIONS; Esc volta',function()
 v:key('8');v:draw();assert(v.buttons[v.focus].y==125)
 v:key('5');assert(v.screen=='settings');v:draw()
 v:key('escape');assert(v.screen=='title')
end)
check('5 inicia novo jogo quando nao havia save',function()
 v.onNewGame=function()return true,nil,Game.new(2201)end
 v:key('2');v:draw();v:key('5');assert(v.screen=='tank' and v.hasSave and v.g~=initial)
end)
check('com save Enter escolhe RESUME',function()
 v.screen='title';v.focus=nil;v.focusScreen=nil;v:draw()
 assert(v.buttons[v.focus].y==100)
 v:key('return');assert(v.screen=='tank')
end)
check('Esc abre menu JAR; 8 e 5 abrem OPTIONS',function()
 v:key('escape');assert(v.screen=='pause');v:draw()
 assert(v.buttons[v.focus].y==61)
 v:key('8');v:draw();assert(v.buttons[v.focus].y==88)
 v:key('8');v:draw();assert(v.buttons[v.focus].y==115)
 v:key('5');assert(v.screen=='settings')
 v:key('escape');assert(v.screen=='pause')
 v:key('escape');assert(v.screen=='tank')
 v:draw();v:press(v.ox+181*v.scale,v.oy+12*v.scale)
 assert(v.screen=='shop')
end)
check('loja seleciona antes de comprar',function()
 v.g.s.cash=2000;v.shopPage=1;v.selectedShopIndex=1;v:draw()
 local cash=v.g.s.cash;assert(v.buttons[v.focus].y==83)
 v:key('5');assert(v.g.s.cash==cash)
 v:draw();v:key('6');v:draw();assert(v.buttons[v.focus].x==171)
 v:key('5');assert(v.g.s.cash<cash)
end)
check('4/6 e 5 continuam navegando por peixes',function()
 v.screen='tank';v:draw();v:key('f');assert(v.screen=='detail')
 local id=v.selected;v:key('6');assert(v.selected~=id)
 v:key('4');assert(v.selected==id)
 v:key('5');assert(v.screen=='actions')
end)
check('teclas direcionais nao alteram saldo nem savestate',function()
 v.screen='pause';v:draw();local cash=v.g.s.cash
 for _,key in ipairs({'2','4','6','8'}) do v:key(key) end
 assert(v.g.s.cash==cash and v.g.s.version==9)
end)
print('V22: '..count..' verificacoes de menus e teclado passaram.')
