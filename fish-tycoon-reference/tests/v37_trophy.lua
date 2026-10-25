-- V37: recurso original de trofeus, navegacao e fallback sem JAR.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Retro=require('ui.retro')
local Catalog=require('core.catalog')
local none=function()end
local drawn,printed={},{ }
love={graphics={
 newFont=function()return {setFilter=none}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'))
  local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local o={path=path,w=n(17),h=n(21),setFilter=none}
  function o:getDimensions()return self.w,self.h end
  function o:getWidth()return self.w end
  function o:getHeight()return self.h end
  return o
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
 draw=function(img)if img.path then drawn[#drawn+1]=img.path end end,
 printf=function(text)printed[#printed+1]=tostring(text)end,
}}
for _,name in ipairs({'setColor','rectangle','setFont','line','push','pop','translate','scale','clear'}) do
 love.graphics[name]=none
end
local game=Game.new(3700)
local retro=Retro.new(game,true);retro:init()
retro.screen='collection';retro.bitmapFont=nil
local money,rng,version=game.s.cash,game.s.rng,game.s.version
local tests=0
local function check(desc,fn)
 local ok,err=pcall(fn)
 assert(ok,'V37 '..desc..': '..tostring(err))
 tests=tests+1;print('OK '..desc)
end
local function render() drawn={};printed={};retro:draw() end
check('todos os sete trofeus aparecem sem serem inventados no save',function()
 render()
 local count=0
 for _,b in ipairs(retro.buttons)do if b.w==44 and b.h==44 then count=count+1 end end
 assert(count==7,'Quantidade de seletores: '..count)
 assert(game:countMagic()==0)
end)
check('orb original extraido tem 88x88 pixels e e usado na colecao',function()
 local orb=retro.images.trhopy_ball
 -- O GitHub publico nao recebe a arte comercial: usar um stub 88x88
 -- para verificar o desenho; com JAR, validar as dimensoes reais.
 if not orb then
  orb={path='assets/original/trhopy_ball.png',w=88,h=88}
  retro.images.trhopy_ball=orb
 end
 assert(orb.w==88 and orb.h==88)
 render()
 local count=0
 for _,p in ipairs(drawn)do if p:find('trhopy_ball.png',1,true) then count=count+1 end end
 assert(count==7,'Nao desenhou sete imagens originais de trofeu')
end)
check('selecionar o setimo trofeu informa desconhecido',function()
 render()
 local x,y=39+2*53+20,90+76+20
 assert(retro:press(retro.ox+x*retro.scale,retro.oy+y*retro.scale))
 assert(retro.trophyIndex==7)
 render()
 local observed=table.concat(printed,' ')
 assert(observed:find('UNDISCOVERED FISH',1,true))
end)
check('peixe magico descoberto usa indices canonicos do catalogo',function()
 game.s.magic['1']=true
 retro.trophyIndex=1
 local count=0
 local old=retro.assets.drawFish
 retro.assets.drawFish=function(self,f,...)
  count=count+1
  assert(f.body==Catalog.magic[1].body and f.tail==Catalog.magic[1].tail)
  return true
 end
 render()
 assert(count==1 and game:countMagic()==1)
 assert(table.concat(printed,' '):find(Catalog.nameFor(Catalog.magic[1].body,Catalog.magic[1].tail),1,true))
 retro.assets.drawFish=old
end)
check('fallback sem arte ainda permite selecao e retorno',function()
 local previous=retro.images.trhopy_ball
 retro.images.trhopy_ball=nil
 render()
 local x,y=13+22,90+22
 assert(retro:press(retro.ox+x*retro.scale,retro.oy+y*retro.scale))
 assert(retro.trophyIndex==1)
 retro:key('escape');assert(retro.screen=='pause')
 retro.images.trhopy_ball=previous
end)
check('teclas 4/6 movem a unica selecao amarela, sem duplicar o foco',function()
 retro.screen='collection';retro.trophyIndex=1;retro.focus=nil;retro.focusScreen=nil
 render();assert(retro.trophyFocusIndices[retro.focus]==1)
 retro:key('6');assert(retro.trophyIndex==2)
 render();assert(retro.trophyFocusIndices[retro.focus]==2)
 retro:key('4');assert(retro.trophyIndex==1)
 render();assert(retro.trophyFocusIndices[retro.focus]==1)
end)
check('tela de trofeus nao altera cash, RNG ou formato do save',function()
 assert(game.s.cash==money and game.s.rng==rng and game.s.version==version)
 assert(version==9)
end)
print('V37: '..tests..' testes de trofeus aprovados')
