-- V36: recorte da moldura J2ME, coordenadas LÖVE e seguranca.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local Atlas=require('core.atlas')
local noop=function()end
local width,height=480,640
local rect,calls=nil,{}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return width,height end,
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
 newQuad=function(x,y,w,h,iw,ih)assert(x+w<=iw and y+h<=ih);return {x=x,y=y,w=w,h=h}end,
 getScissor=function()if rect then return table.unpack(rect)end end,
 setScissor=function(...)
  local args={...}
  rect=#args>0 and args or nil
  calls[#calls+1]=rect and {table.unpack(rect)} or 'restore'
 end,
 draw=noop,
}}
for _,name in ipairs({'setColor','rectangle','setFont','line','push','pop','translate','scale','clear','printf'})do love.graphics[name]=noop end
local g=Game.new(3600)
local fish=assert(g:addFish('sale',9,21,21))
local other=assert(g:addFish('sale',2,1,21))
local v=Retro.new(g,true);v:init()
v.room='sale';v.screen='detail';v.selected=fish.id;v.time=1.5
local count=0
local function check(name,fn)
 local ok,err=pcall(fn);assert(ok,name..': '..tostring(err))
 count=count+1;print('OK '..name)
end
local function hasClip(x,y,w,h)
 for _,a in ipairs(calls)do
  if type(a)=='table' and a[1]==x and a[2]==y and a[3]==w and a[4]==h then return true end
 end
 return false
end
check('Barbatana do atlas excede o interior de 35px',function()
 assert(Atlas.fins[21][4]==39)
end)
check('Moldura 240x320 usa 54x35px em janela 2x',function()
 calls={};v:draw()
 assert(hasClip(128,70,108,70))
 assert(rect==nil)
end)
check('Moldura usa escala fracionaria sem deslocamento',function()
 width,height=468,858;calls={};v:draw()
 local sc=468/240
 local oy=math.floor((858-320*sc)/2)
 local x=math.floor(64*sc);local y=math.floor(oy+35*sc)
 local right=math.ceil(118*sc);local bottom=math.ceil(oy+70*sc)
 assert(hasClip(x,y,right-x,bottom-y))
 assert(rect==nil)
end)
check('Recorte preexistente continua valido apos desenhar',function()
 width,height=480,640;rect={0,0,480,640};calls={}
 v:draw()
 assert(rect[1]==0 and rect[2]==0 and rect[3]==480 and rect[4]==640)
 rect=nil
end)
check('Ancora e estado do jogo nao mudam',function()
 v:draw()
 local hit=v.fishHits[#v.fishHits]
 assert(hit.id==fish.id and hit.x==91 and hit.y==53)
 assert(hit.rx==25 and hit.ry==19.5)
 assert(g:find(other.id)==other and g.s.version==9)
 v:key('escape');assert(v.screen=='tank')
end)
print('V36: '..count..' testes de selecao aprovados')
