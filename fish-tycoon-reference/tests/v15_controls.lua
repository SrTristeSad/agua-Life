-- Fase 15: validacao de alvo de toque, letterbox e margens dos peixes.
-- Usa os PNGs de verdade com uma API grafica simulada; nao substitui
-- teste numa janela real do LÖVE 11.x ou num aparelho Android.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local View=require('ui.view')
local Swim=require('ui.swim')
local Config=require('core.config')
local checks=0
local function verify(label,fn)
 local ok,err=pcall(fn)
 if not ok then error('V15 '..label..': '..tostring(err),0) end
 checks=checks+1;print('OK '..label)
end
local function noop() end
local font={setFilter=noop}
local width,height=420,800
love={graphics={
 newFont=function() return font end,
 getDimensions=function() return width,height end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'))
  local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(offset)
   local a,b,c,d=h:byte(offset,offset+3)
   return ((a*256+b)*256+c)*256+d
  end
  local img={w=n(17),h=n(21),setFilter=noop}
  function img:getDimensions() return self.w,self.h end
  function img:getWidth() return self.w end
  function img:getHeight() return self.h end
  return img
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
}}
for _,op in ipairs({'setColor','rectangle','setFont','setLineWidth','line',
 'ellipse','circle','arc','polygon','push','pop','translate','scale',
 'clear','print','printf','draw'}) do love.graphics[op]=noop end
local game=Game.new(1715)
local view=View.new(game);view:init()
local function draw() view:draw() end
local function touch(x,y)
 draw()
 return view:press(view.ox+x*view.scale,view.oy+y*view.scale)
end
verify('18 peixes nunca escapam da area segura do aquario',function()
 for room,capacity in pairs(Config.CAPACITY) do
  local fishes={}
  for i=1,capacity do
   fishes[i]={id=100+i,age=20,health=100}
  end
  for t=0,240,.7 do
   for i,f in ipairs(fishes) do
    local x,y=Swim.position(f,i,room,t)
    assert(x>=70 and x<=351 and y>=233 and y<=453,
      ('%s #%s (%f,%f)'):format(room,i,x,y))
   end
  end
 end
end)
verify('todas as quatro abas reagem ao toque redimensionado',function()
 for _,sz in ipairs({{360,620},{420,800},{468,858},{1000,600},{1280,960}}) do
  width,height=sz[1],sz[2]
  view.page='tank';view.modal=nil
  for i,target in ipairs({'tank','shop','research','catalog'}) do
   assert(touch(14+(i-1)*103+48,753))
   assert(view.page==target,sz[1]..'x'..sz[2]..' '..target)
  end
 end
end)
verify('toques nas barras pretas nao atingem comandos',function()
 width,height=1000,600
 view.page='tank';view.modal=nil;draw()
 local page=view.page
 assert(not view:press(5,5))
 assert(view.page==page)
 assert(not view:press(width-5,height-5))
 assert(view.page==page)
end)
verify('tanques e selecao de peixe seguem o toque em resolucao pequena',function()
 width,height=360,620
 view.page='tank';view.room='main';view.modal=nil
 local a=game.s.tanks.main[1]
 local x,y=Swim.position(a,1,'main',view.pulse)
 assert(touch(x,y))
 assert(view.selected==a.id)
 assert(touch(x,y))
 assert(view.selected==nil)
 assert(touch(166,139))
 assert(view.room=='main' or view.room=='second')
 assert(touch(267,139))
 assert(view.room=='isolation')
end)
verify('modal bloqueia toque de fundo e troca de pagina',function()
 width,height=420,800
 view.page='tank';view.room='main';view.selected=nil
 view.modal='medicine'
 draw()
 local speed=game.s.game_speed
 local page=view.page
 assert(not touch(62,751))
 assert(view.page==page)
 assert(not touch(88,100))
 assert(game.s.game_speed==speed)
 view:key('4')
 assert(view.page==page and view.modal=='medicine')
 assert(touch(367,210))
 assert(view.modal==nil)
end)
verify('alvos interativos se mantem na area logica',function()
 width,height=420,800
 view.page='tank';view.modal=nil;draw()
 assert(#view.buttons>5)
 for _,b in ipairs(view.buttons) do
  assert(b.w>0 and b.h>0)
  assert(b.x>=0 and b.y>=0 and b.x+b.w<=420+1 and b.y+b.h<=800+1,
   ('Botao fora da tela: %g %g %g %g'):format(b.x,b.y,b.w,b.h))
 end
end)
print('V15: '..checks..' validacoes de controles e margens passaram.')
