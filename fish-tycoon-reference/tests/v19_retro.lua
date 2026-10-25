package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Storage=require('core.storage')
local Retro=require('ui.retro')
local function noop() end
local width,height=480,640
local files={}
love={timer={getTime=function()return 0 end},
 filesystem={getInfo=function(p)return files[p] and {size=#files[p]} or nil end,
  read=function(p)return files[p] end,
  write=function(p,data)files[p]=data;return true end},
 graphics={newFont=function()return {setFilter=noop} end,
 getDimensions=function()return width,height end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local bytes=f:read(24);f:close()
  assert(bytes:sub(1,8)=='\137PNG\r\n\26\n')
  local function d(o)local a,b,c,d=bytes:byte(o,o+3);return ((a*256+b)*256+c)*256+d end
  local img={w=d(17),h=d(21),setFilter=noop}
  function img:getDimensions()return self.w,self.h end
  function img:getWidth()return self.w end
  function img:getHeight()return self.h end
  return img
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end}}
for _,f in ipairs({'setColor','rectangle','line','printf','print','draw','push','pop','translate','scale',
 'setFont','setLineWidth','clear','ellipse','polygon','circle','arc'}) do love.graphics[f]=noop end
local g=Game.new(19)
local retro=Retro.new(g,false);retro:init()
local n=0
local function check(desc,fn)
 local ok,err=pcall(fn);assert(ok,'V19 '..desc..': '..tostring(err))
 print('OK '..desc);n=n+1
end
local function press(x,y)
 retro:draw()
 return retro:press(retro.ox+x*retro.scale,retro.oy+y*retro.scale)
end
check('jogo comeca no menu, sem Continuar quando nao existe save',function()
 assert(retro.screen=='title' and not retro.hasSave)
 assert(not press(120,50))
 assert(retro.screen=='title')
end)
check('novo jogo precisa ser salvo antes de entrar no aquario',function()
 retro.onNewGame=function()
  local newer=Game.new(77)
  local ok,e=Storage.startNewGame(newer)
  if not ok then return false,e end
  return true,nil,newer
 end
 assert(press(120,110))
 assert(retro.screen=='tank' and retro.hasSave)
 assert(files[Storage.filename])
end)
check('selecionar peixe abre painel de idade e comando SELECT',function()
 retro:draw();local hit=retro.fishHits[1];assert(hit)
 assert(press(hit.x,hit.y));assert(retro.screen=='detail')
 assert(press(30,308));assert(retro.screen=='actions')
 retro:key('escape');assert(retro.screen=='detail')
 retro:key('escape');assert(retro.screen=='tank')
end)
check('controles do JAR: menu, suprimentos, pesquisa e opcoes',function()
 assert(press(201,308));assert(retro.screen=='pause')
 assert(press(181,12));assert(retro.screen=='shop')
 retro:key('escape');assert(retro.screen=='pause')
 assert(press(203,12));assert(retro.screen=='research')
 retro:key('escape');assert(retro.screen=='pause')
 assert(press(114,126));assert(retro.screen=='settings')
 assert(press(114,100));assert(retro.soundEnabled) -- without sound callback unchanged
 retro:key('escape');assert(retro.screen=='pause')
end)
check('volta ao titulo e pede confirmacao ao criar novo jogo',function()
 assert(press(115,261));assert(retro.screen=='title')
 assert(press(117,135));assert(retro.screen=='confirm')
 assert(press(100,210));assert(retro.screen=='title')
end)
check('novo jogo cria backup de arquivo anterior antes de reiniciar',function()
 retro.g.s.cash=retro.g.s.cash+123
 assert(Storage.save(retro.g))
 local previous=files[Storage.filename]
 assert(press(117,135));assert(retro.screen=='confirm')
 assert(press(113,186));assert(retro.screen=='tank')
 assert(files[Storage.archive] and #files[Storage.archive]>100)
 assert(files[Storage.filename]~=previous)
end)
check('falha de arquivamento nao substitui save nem inicia partida',function()
 retro.screen='confirm'
 local earlier=files[Storage.filename]
 local writer=love.filesystem.write
 love.filesystem.write=function(path,data)
  if path==Storage.archive then return false,'sem espaco' end
  return writer(path,data)
 end
 assert(press(117,186));assert(retro.screen=='confirm')
 assert(files[Storage.filename]==earlier)
 love.filesystem.write=writer
end)
check('tanque de vendas abre e fecha clientes pelo rodape',function()
 retro.screen='tank';retro.room='sale'
 local open=retro.g.s.sale_open
 assert(press(30,308))
 assert(retro.g.s.sale_open~=open)
 assert(press(30,308))
 assert(retro.g.s.sale_open==open)
end)
check('isolamento permite iniciar cruzamento sem esconder acao',function()
 retro.screen='tank';retro.room='isolation';retro:draw()
 assert(#retro.buttons>0)
 local old=retro.g.breed
 local called=0
 retro.g.breed=function()called=called+1;return false,'NEED TWO ADULTS' end
 assert(press(30,308))
 assert(called==1)
 assert(retro.toast=='NEED TWO ADULTS')
 retro.g.breed=old
end)
check('letterbox nao clica fora da tela',function()
 width,height=1280,640
 retro:draw()
 assert(not retro:press(5,5))
 width,height=480,640
end)
print('V19: '..n..' suites de interface J2ME passaram.')
