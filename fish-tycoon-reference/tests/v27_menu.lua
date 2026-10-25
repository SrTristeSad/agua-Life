-- Fluxo do menu J2ME a partir da tabela oficial inglesa do JAR.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local noop=function()end
local observed={}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local im={w=n(17),h=n(21),setFilter=noop}
  function im:getDimensions()return self.w,self.h end
  function im:getWidth()return self.w end
  function im:getHeight()return self.h end
  return im
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
 printf=function(s)observed[#observed+1]=tostring(s) end,
}}
for _,m in ipairs({'setColor','rectangle','line','draw','push','pop','translate','scale','setFont','clear'}) do
 love.graphics[m]=noop
end
local g=Game.new(2700)
local v=Retro.new(g,true);v:init();v.bitmapFont=nil
local checks=0
local function test(name,callback)
 local ok,err=pcall(callback)
 if not ok then error('V27 '..name..': '..tostring(err),0) end
 checks=checks+1;print('OK '..name)
end
local function tap(x,y)
 v:draw();return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
local function inPause()
 v.screen='pause';v:draw()
end
local function labels()
 observed={};v:draw();return table.concat(observed,'|')
end
test('menu JAR contem oito opcoes funcionais nos limites 240x320',function()
 inPause()
 local t=labels()
 for _,word in ipairs({'RESUME','START NEW GAME','OPTIONS','TROPHY','STATS','HELP','ABOUT','SAVE & EXIT'}) do
  assert(t:find(word,1,true),word)
 end
 for i=1,8 do
  local b=v.buttons[11+i]
  assert(b and b.x==31 and b.y==61+(i-1)*27 and b.w==178 and b.h==23,i)
 end
end)
test('Novo Jogo via menu confirma e cancelar volta para o mesmo menu',function()
 assert(tap(110,100));assert(v.screen=='confirm' and v.confirmFrom=='pause')
 assert(tap(109,209));assert(v.screen=='pause')
 inPause();assert(tap(108,98));assert(v.screen=='confirm')
 local newGame=Game.new(2711)
 v.onNewGame=function()return true,nil,newGame end
 assert(tap(90,185));assert(v.screen=='tank' and v.g==newGame)
end)
test('TROPHY, STATS e HELP mostram dados e permitem voltar',function()
 inPause();assert(tap(110,153));assert(v.screen=='collection')
 v:key('escape');assert(v.screen=='pause')
 assert(tap(110,181));assert(v.screen=='stats')
 local t=labels();assert(t:find('FISH ALIVE',1,true));assert(t:find('FISH SOLD',1,true))
 v:key('escape');assert(v.screen=='pause')
 assert(tap(110,207));assert(v.screen=='help')
 t=labels();assert(t:find('F1 : LEFT SOFTKEY',1,true))
 v:key('escape');assert(v.screen=='pause')
end)
test('ABOUT volta para menu de origem',function()
 inPause();assert(tap(110,233));assert(v.screen=='about' and v.from=='pause')
 v:key('escape');assert(v.screen=='pause')
 v.screen='title';v.welcomeIndex=7;v:draw()
 local b=v.buttons[v.focus]
 assert(tap(b.x+10,b.y+8));assert(v.screen=='about')
 v:key('escape');assert(v.screen=='title')
end)
test('suprimentos e pesquisas ainda abrem pela barra superior',function()
 inPause();assert(tap(181,12));assert(v.screen=='shop')
 inPause();assert(tap(203,12));assert(v.screen=='research')
end)
test('SAVE & EXIT exige salvamento bem-sucedido',function()
 v.screen='pause';v.onSave=function()return false,'Disk full' end
 assert(tap(110,261));assert(v.screen=='pause')
 v.onSave=function()return true end
 assert(tap(110,261));assert(v.screen=='title')
 assert(g.s.version==9)
end)
print('V27: '..checks..' suites de navegacao do menu J2ME aprovadas.')
