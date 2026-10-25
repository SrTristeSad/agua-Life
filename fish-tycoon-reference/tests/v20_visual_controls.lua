-- Fase 20: nomes JAR, atlas de icones, teclado J2ME e sobreposicao de isolamento.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Catalog=require('core.catalog')
local Retro=require('ui.retro')
local noop=function()end
local printText={}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local o={w=n(17),h=n(21),path=path,setFilter=noop}
  function o:getDimensions()return self.w,self.h end
  function o:getWidth()return self.w end
  function o:getHeight()return self.h end
  return o
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
 printf=function(s) printText[#printText+1]=tostring(s) end,
}}
for _,m in ipairs({'setColor','rectangle','line','draw','push','pop','translate','scale','setFont','clear'}) do love.graphics[m]=noop end
local n=0
local function check(desc,fn)
 local ok,err=pcall(fn);assert(ok,desc..': '..tostring(err));n=n+1;print('OK '..desc)
end
local g=Game.new(2000)
local v=Retro.new(g,true);v:init()
-- Teste historico de rotulos via printf, sem tipografia privada opcional.
v.bitmapFont=nil
local function press(x,y)
 v:draw();return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
check('nomes reais EN do JAR nas 441 combinacoes',function()
 assert(#Catalog.bodyNames==21 and #Catalog.finNames==21)
 assert(Catalog.nameFor(9,17)=='GREENFIN FRUITFISH')
 for b=1,21 do for f=1,21 do
  local s=Catalog.nameFor(b,f)
  assert(#s>3 and not s:find('Forma'))
 end end
end)
check('atlas de icones e miniaturas usa apenas recortes validos',function()
 if v.images.assets then
  assert(v.quads.slot and v.quads.cart and v.quads.hourglass)
  assert(v.quads.fish and v.quads.food and v.quads.money)
 else
  -- assets.png nao e distribuido no GitHub publico; botoes de reserva
  -- devem continuar funcionando no CI sem o atlas comercial.
  assert(next(v.quads)==nil)
 end
 assert(#v.tankIcons==3)
end)
check('barra mostra icones e dinheiro mas nao letras provisórias',function()
 v.screen='tank';v:draw()
 assert(#v.buttons>=11)
 local letters={F=false,R=false,S=false}
 for _,s in ipairs(printText) do
  if letters[s]~=nil then letters[s]=true end
 end
 if v.images.assets then
  assert(not letters.F and not letters.R and not letters.S)
 else
  assert(letters.F and letters.R and letters.S)
 end
end)
check('selecao via teclado, navegacao 4/6 e 5 para acao',function()
 v.screen='tank';v.room='main';v.selected=nil
 v:key('f');assert(v.screen=='detail')
 local old=v.selected
 v:key('6');assert(v.screen=='detail' and v.selected~=old)
 v:key('4');assert(v.selected==old)
 v:key('5');assert(v.screen=='actions')
 v:key('escape');assert(v.screen=='detail')
 v:key('escape');assert(v.screen=='tank' and v.selected==nil)
end)
check('icones de aquario selecionam area e permitem retornar',function()
 v.screen='tank';v.room='main'
 assert(press(47,10));assert(v.room=='sale')
 assert(press(9,10));assert(v.room=='main')
end)
check('atalho de alimentacao nao altera a tela',function()
 v.screen='tank';v.room='main';v.selected=nil
 local old=g.s.stats.food_given
 assert(press(98,10));assert(v.screen=='tank')
 assert(g.s.stats.food_given>=old)
end)
check('peixes de isolamento aparecem acima do recipiente',function()
 v.screen='tank';v.room='isolation'
 local oldTray,oldFish=v.tray,v.fishDraw
 local order={}
 v.tray=function(self) order[#order+1]='tray';return oldTray(self) end
 v.fishDraw=function(self) order[#order+1]='fish';return oldFish(self) end
 v:draw()
 assert(order[1]=='tray' and order[2]=='fish')
 v.tray=oldTray;v.fishDraw=oldFish
end)
check('HUD exibe GREENFIN FRUITFISH e nao rotulos FORM/FIN',function()
 local f=g.s.tanks.main[1];f.body=9;f.tail=17;f.age=21
 v.screen='detail';v.selected=f.id;v.room='main';printText={}
 v:draw()
 local text=table.concat(printText,';')
 assert(text:find('GREENFIN',1,true) and text:find('FRUITFISH',1,true))
 assert(not text:find('FORM 08',1,true))
end)
print('V20: '..n..' verificacoes novas passaram.')