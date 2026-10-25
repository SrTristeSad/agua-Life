-- V34: sem movimento falso dos peixes; selecao invalida e backdrop do HUD.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Retro=require('ui.retro')
local Motion=require('ui.j2me_motion')
local noop=function()end
local screen={w=468,h=858}
local masks,images={},{}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return screen.w,screen.h end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local image={w=n(17),h=n(21),path=path,setFilter=noop}
  function image:getDimensions()return self.w,self.h end
  function image:getWidth()return self.w end
  function image:getHeight()return self.h end
  return image
 end,
 newQuad=function(x,y,w,h,iw,ih)assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih);return {x=x,y=y,w=w,h=h}end,
 setScissor=function(...) masks[#masks+1]={...} end,
 getScissor=function()return nil end,
 draw=function(img)if img.path then images[#images+1]=img.path end end,
}}
for _,name in ipairs({'setColor','rectangle','line','push','pop','translate','scale','setFont','clear','printf'})do love.graphics[name]=noop end
local g=Game.new(3400)
local view=Retro.new(g,true);view:init();view.room='main';view.time=4.5
local first=g.s.tanks.main[1]
local other=g.s.tanks.main[2]
first.age=21;other.age=21
local count=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V34 '..name..': '..tostring(err))
 count=count+1;print('OK '..name)
end
check('selecionar nao muda coordenadas dos outros peixes',function()
 view.screen='tank';view:draw()
 local before={}
 for _,h in ipairs(view.fishHits)do before[h.id]={h.x,h.y}end
 view.screen='detail';view.selected=first.id;view:draw()
 for _,h in ipairs(view.fishHits)do
  if h.id~=first.id then
   local old=assert(before[h.id]);assert(old[1]==h.x and old[2]==h.y)
  end
 end
 assert(view.fishHits[#view.fishHits].id==first.id)
end)
check('moldura selecionada recupera agua original com scissor fracionario',function()
 local old=Motion.position
 Motion.position=function()return 91,53,1 end -- força colisao grafica
 masks={};images={};view:draw()
 Motion.position=old
 assert(#masks>=2,'Mascara do painel nao executada')
 local x,y,w,h=table.unpack(masks[1])
 assert(x==math.floor(view.ox+64*view.scale))
 assert(y==math.floor(view.oy+35*view.scale))
 assert(w>100 and h>60)
 assert(#masks[#masks]==0,'Mascara deve ser restaurada ao sair')
 local sky=0
 for _,p in ipairs(images)do if p:find('tanktop.png',1,true)then sky=sky+1 end end
 assert(sky>=2,'O mesmo tanktop.png deve cobrir o fundo e a moldura')
end)
check('morte do selecionado limpa estado em vez de manter ID orfao',function()
 view.screen='detail';view.selected=first.id
 for i,f in ipairs(g.s.tanks.main) do
  if f.id==first.id then table.remove(g.s.tanks.main,i);break end
 end
 view:draw()
 assert(view.screen=='tank' and view.selected==nil)
end)
check('transferencia do selecionado limpa selecao no aquario de origem',function()
 view.selected=other.id;view.screen='detail';view.room='main'
 assert(g:move(other.id,'isolation'))
 view:draw()
 assert(view.screen=='tank' and view.selected==nil and view.room=='main')
end)
check('fixture selecionada tem nome exato da imagem de referencia',function()
 local Catalog=require('core.catalog')
 assert(Catalog.nameFor(9,17)=='GREENFIN FRUITFISH')
 assert(g.s.version==9)
end)
print('V34: '..count..' testes de HUD, selecao e trajeto aprovados')
