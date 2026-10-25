-- V33: verificacao do recorte original da bandeja e do peixe selecionado.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Retro=require('ui.retro')
local Geometry=require('ui.fish_geometry')
local noop=function()end
love={graphics={
 newFont=function() return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function num(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local im={w=num(17),h=num(21),setFilter=noop}
  function im:getDimensions()return self.w,self.h end
  function im:getWidth()return self.w end
  function im:getHeight()return self.h end
  return im
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
}}
for _,op in ipairs({'setColor','rectangle','line','draw','push','pop','translate','scale','setFont','clear','printf'})do love.graphics[op]=noop end
local g=Game.new(3300)
local f1=assert(g:addFish('isolation',12,21,20))
local f2=assert(g:addFish('isolation',8,12,20))
local v=Retro.new(g,true);v:init();v.room='isolation';v.screen='tank'
local capture={}
local drawFish=v.assets.drawFish
v.assets.drawFish=function(self,f,x,y,scale,face)
 capture[f.id]={x=x,y=y,scale=scale,face=face}
 return drawFish(self,f,x,y,scale,face)
end
local passes=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V33 '..name..': '..tostring(err))
 passes=passes+1;print('OK '..name)
end
check('441 corpos/barbatanas cabem em x=70..168 e y=274..298',function()
 for b=1,21 do for tail=1,21 do
  f1.body=b;f1.tail=tail;f1.age=20
  capture={};v:draw()
  local c=capture[f1.id];assert(c)
  local w,h=Geometry.size(f1)
  assert(c.x-w*c.scale/2>=70-.001 and c.x+w*c.scale/2<=168+.001)
  assert(c.y-h*c.scale/2>=274-.001 and c.y+h*c.scale/2<=298+.001)
  assert(v.fishHits[1].rx==math.max(10,w*c.scale/2))
  assert(v.fishHits[1].ry==math.max(8,h*c.scale/2))
 end end
end)
check('duas vagas separadas permanecem sobre a bandeja visivel',function()
 f1.body=12;f1.tail=21;f2.body=1;f2.tail=1
 capture={};v:draw()
 assert(#v.fishHits==2 and capture[f1.id].x==96 and capture[f2.id].x==144)
 local left,right=v.fishHits[1],v.fishHits[2]
 assert(left.x+left.rx<=right.x-right.rx+.001)
 assert(left.y==286 and right.y==286)
end)
check('selecionar isolamento leva o peixe a ancora J2ME superior',function()
 v.screen='tank';capture={};v:draw()
 local h=v.fishHits[1]
 assert(v:press(v.ox+h.x*v.scale,v.oy+h.y*v.scale))
 assert(v.screen=='detail' and v.selected==f1.id)
 capture={};v:draw()
 local s=capture[f1.id]
 assert(s and s.x==91 and s.y==53 and s.scale==1)
 assert(capture[f2.id].y==286)
 assert(v.fishHits[#v.fishHits].id==f1.id)
end)
check('softkeys do peixe isolado continuam navegaveis',function()
 v:key('f1');assert(v.screen=='actions')
 v:draw();v:key('f2');assert(v.screen=='detail')
 v:draw();v:key('f2');assert(v.screen=='tank' and not v.selected)
end)
check('desenhar nao modifica biologia, dinheiro nem saves',function()
 local beforeRng,beforeTime,beforeCash=g.s.rng,g.s.time,g.s.cash
 local id1,id2=f1.id,f2.id
 for i=1,10 do v.time=i*.2;v:draw() end
 assert(g.s.rng==beforeRng and g.s.time==beforeTime and g.s.cash==beforeCash)
 assert(g.s.version==9 and f1.id==id1 and f2.id==id2)
end)
print('V33: '..passes..' verificacoes de bandeja/seleção aprovadas.')
