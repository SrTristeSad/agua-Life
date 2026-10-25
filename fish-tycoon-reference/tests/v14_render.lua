-- Teste de renderizacao usando sprites PNG REAIS e uma API grafica estrita.
-- Nao substitui abrir uma janela do LÖVE, mas confere os recortes,
-- recursos, chamadas de desenho, composicao das telas e foco modal.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Assets=require('core.assets')
local View=require('ui.view')
local Atlas=require('core.atlas')
local checks=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('V14 '..name..': '..tostring(err),0) end
 checks=checks+1
 print('OK '..name)
end
local function pngDimensions(path)
 local f=assert(io.open(path,'rb'),'PNG ausente: '..path)
 local header=f:read(24);f:close()
 assert(header and header:sub(1,8)=='\137PNG\r\n\26\n','PNG invalido: '..path)
 local function number(n)
  local a,b,c,d=header:byte(n,n+3)
  return ((a*256+b)*256+c)*256+d
 end
 return number(17),number(21)
end
local currentlyDrawn={}
local function noop(...) end
local font={setFilter=noop}
love={
 graphics={
  newFont=function(size) assert(size>0);return font end,
  getDimensions=function() return 468,858 end,
  newImage=function(path)
   local w,h=pngDimensions(path)
   local img={path=path,w=w,h=h,setFilter=noop}
   function img:getDimensions() return self.w,self.h end
   function img:getWidth() return self.w end
   function img:getHeight() return self.h end
   return img
  end,
  newQuad=function(x,y,w,h,iw,ih)
   assert(x>=0 and y>=0 and w>0 and h>0 and x+w<=iw and y+h<=ih,
     ('recorte fora do atlas %g,%g %gx%g dentro de %gx%g'):format(x,y,w,h,iw,ih))
   return {quad=true,x=x,y=y,w=w,h=h}
  end,
  draw=function(img,...)
   assert(type(img)=='table' and img.path,'Imagem inexistente')
   local args={...}
   if type(args[1])=='table' and args[1].quad then
    local q=table.remove(args,1)
    assert(q.x+q.w<=img.w and q.y+q.h<=img.h)
   end
   for i=1,#args do assert(type(args[i])=='number','Argumento de desenho invalido') end
   currentlyDrawn[img.path]=(currentlyDrawn[img.path] or 0)+1
  end,
  ellipse=function(mode,x,y,rx,ry,segments)
   assert(mode=='fill' or mode=='line')
   assert(rx>0 and ry>0)
   assert(segments==nil or (segments%1==0 and segments>=3), 'Segmentos fracionarios na elipse')
  end,
 }}
for _,key in ipairs({'setColor','rectangle','print','printf','setFont','setLineWidth','line',
 'circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[key]=noop
end
local g=Game.new(1400)
local v=View.new(g)
v:init()
test('arquivos de imagem sao lidos de verdade',function()
 assert(v.assets.available)
 for _,name in ipairs({'fish','fins','tank1','tank2','tank3','tanktop','isolation_tank'}) do
  assert(v.assets.images[name],'Recurso ausente: '..name)
 end
end)
test('recortes de corpos, juvenis e barbatanas nao ultrapassam os atlas',function()
 assert(#Atlas.fish==21 and #Atlas.juvenile==21)
 assert(v.assets.body[21] and v.assets.juvenile[21])
 assert(v.assets.fin[20]==nil and v.assets.fin[21]) -- atlas original nao tem barbatana 20
end)
test('441 variacoes adultas nas duas direcoes e 21 juvenis e filhotes',function()
 for body=1,21 do
  for tail=1,21 do
   for _,facing in ipairs({-1,1}) do
    assert(v.assets:drawFish({body=body,tail=tail,age=20},120,330,1,facing))
   end
  end
  assert(v.assets:drawFish({body=body,tail=body,age=6},120,330,1,1))
  assert(v.assets:drawFish({body=body,tail=body,age=2},120,330,1,1))
 end
end)
test('os quatro ambientes usam suas artes correspondentes',function()
 local expected={main='tank1',second='tank2',sale='tank3',isolation='isolation_tank'}
 for room,name in pairs(expected) do
  currentlyDrawn={}
  assert(v.assets:tankBackground(room,23,170,374,331))
  assert(currentlyDrawn['assets/original/'..name..'.png'], 'Fundo incorreto para '..room)
  if room=='isolation' then assert(not currentlyDrawn['assets/original/tank1.png']) end
 end
end)
test('todas as paginas, tanques e modais desenham sem erros graficos',function()
 g.s.unlocked.second=true
 for _,page in ipairs({'tank','shop','research','catalog'}) do
  v.page=page
  if page=='tank' then
   for _,room in ipairs({'main','second','isolation','sale'}) do
    v.room=room;v:draw()
   end
  else v:draw() end
 end
 v.page='tank';v.room='main';v.selected=g.s.tanks.main[1].id
 for _,modal in ipairs({'move','medicine','history','offline'}) do
  v.modal=modal
  if modal=='offline' then v.offlineReport={seconds=3600,lines={'1','2','3'}} end
  v:draw()
 end
 v.modal=nil
end)
test('atalhos nao mudam a pagina ou velocidade atras de um modal',function()
 v.page='tank';v.modal='medicine';local speed=g.s.game_speed
 v:key('2');v:key('4');v:key('space')
 assert(v.page=='tank' and v.modal=='medicine' and g.s.game_speed==speed)
 v:key('escape');assert(v.modal==nil)
 v:key('2');assert(v.page=='shop' and v.selected==nil)
end)
test('redimensionamento nao muda o desenho logico nem cria cliques invisiveis',function()
 for _,size in ipairs({{360,620},{420,800},{468,858},{1000,600},{1280,960}}) do
  love.graphics.getDimensions=function() return size[1],size[2] end
  v.page='tank';v.modal=nil;v.room='main'
  v:draw()
  assert(v.scale>0 and v.ox>=0 and v.oy>=0)
  local nx=v.ox+55*v.scale
  local ny=v.oy+753*v.scale
  assert(v:press(nx,ny) and v.page=='tank')
 end
end)
print('V14: '..checks..' testes rigorosos de composicao passaram.')
