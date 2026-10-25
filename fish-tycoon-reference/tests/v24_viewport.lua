-- v24: dimensoes fisicas e sprites selecionados no port J2ME.
-- V22: teclado classico J2ME sem dependencia de uma janela grafica.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro');local Game=require('core.game')
local Geometry=require('ui.fish_geometry')
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
check('scale aproveita area de janela que nao e multiplo de 240',function()
 local orig=love.graphics.getDimensions
 for _,d in ipairs({{240,320,1},{480,640,2},{468,858,1.95},
                    {360,620,1.5},{960,600,1.875}}) do
  love.graphics.getDimensions=function() return d[1],d[2] end
  v:draw()
  assert(math.abs(v.scale-d[3])<.001,('scale %dx%d = %.3f'):format(d[1],d[2],v.scale))
  assert(v.ox>=0 and v.oy>=0)
  assert(v.ox+240*v.scale<=d[1]+1)
  assert(v.oy+320*v.scale<=d[2]+1)
 end
 love.graphics.getDimensions=orig
end)
check('centro do adulto e juvenil sempre inteiro na agua',function()
 v.screen='tank';v.room='main';v.selected=nil
 local tank=v.g.s.tanks.main
 for i=4,18 do
  v.g:addFish('main',1+(i%21),1+(i%21),20)
 end
 for i,f in ipairs(tank) do
  f.age=(i%3==0 and 5 or i%3==1 and 12 or 21)
 end
 for t=0,600,17 do
  v.time=t;v:draw()
  for i,f in ipairs(tank) do
   local hit=v.fishHits[i]
   local w,h=Geometry.size(f)
   local half=w/2
   assert(hit.x-half>=-1 and hit.x+half<=241)
   assert(hit.y>=35 and hit.y<270)
  end
 end
end)
check('peixe selecionado fica clicavel na posicao desenhada',function()
 v.screen='tank';v.room='main';v:draw()
 local h=v.fishHits[1];assert(h)
 assert(v:press(v.ox+h.x*v.scale,v.oy+h.y*v.scale))
 assert(v.screen=='detail' and v.selected==h.id)
 v:draw();local selected
 for _,hit in ipairs(v.fishHits) do
  if hit.id==v.selected then selected=hit;break end
 end
 assert(selected and selected.x>=27 and selected.x<=213)
 -- Softkey de SELECT permanece acessivel com o viewport escalado.
 assert(v:press(v.ox+31*v.scale,v.oy+307*v.scale))
 assert(v.screen=='actions')
 v:key('escape');assert(v.screen=='detail')
 v:key('escape');assert(v.screen=='tank')
end)
check('sem mutacao de dados do motor ou formato de salvamento',function()
 local before=v.g.s.version
 v:draw();v:key('escape');v:draw();v:key('escape')
 assert(v.g.s.version==before and before==9)
end)
print('V24: '..count..' verificacoes de viewport e selecao aprovadas.')
