-- Reconstrucao da interface J2ME 240x320. Fonte visual: assets.png,
-- splash.png, tanktop.png, tank1..3.png, isolation_tank.png do JAR.
-- A simulacao original do port fica isolada em core/game.lua.
local Assets=require('core.assets')
local Swim=require('ui.j2me_motion')
local FishGeometry=require('ui.fish_geometry')
local Catalog=require('core.catalog')
local Config=require('core.config')
local BitmapFont=require('ui.bitmap_font')
local Retro={}; Retro.__index=Retro
local W,H=240,320
local bitmapFont -- inicializada somente quando 1.dat foi importado localmente
local function rgb(r,g,b,a) love.graphics.setColor(r/255,g/255,b/255,a or 1) end
local function fill(x,y,w,h,r,g,b,a)
 rgb(r,g,b,a);love.graphics.rectangle('fill',x,y,w,h)
end
local function stroke(x,y,w,h,r,g,b)
 rgb(r,g,b);love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1)
end
local function fontText(s,x,y,width,align,tint)
 if tint then rgb(tint[1],tint[2],tint[3]) else rgb(245,245,242) end
 if bitmapFont then
  bitmapFont:print(tostring(s),x,y,width or 220,align or 'left')
 else
  love.graphics.printf(tostring(s),x,y,width or 220,align or 'left')
 end
end
local function centered(s,y,tint) fontText(s,10,y,220,'center',tint) end
-- A moldura J2ME ocupa x=63..119 / y=34..71. Convertemos seu
-- interior para pixels de janela ao usar Scissor (API do LÖVE); assim
-- o peixe de barbatana alta nao pinta sobre a borda ou o HUD.
local function logicalScissor(view,x,y,w,h,fn)
 local gfx=love.graphics
 if not (gfx.getScissor and gfx.setScissor) then return fn() end
 local ox,oy,ow,oh=gfx.getScissor()
 local left=math.floor(view.ox+x*view.scale)
 local top=math.floor(view.oy+y*view.scale)
 local right=math.ceil(view.ox+(x+w)*view.scale)
 local bottom=math.ceil(view.oy+(y+h)*view.scale)
 if ox then
  left=math.max(left,ox);top=math.max(top,oy)
  right=math.min(right,ox+ow);bottom=math.min(bottom,oy+oh)
 end
 gfx.setScissor(left,top,math.max(0,right-left),math.max(0,bottom-top))
 local ok,err=pcall(fn)
 if ox then gfx.setScissor(ox,oy,ow,oh) else gfx.setScissor() end
 if not ok then error(err,0) end
end
local function load(name)
 local ok,img=pcall(love.graphics.newImage,'assets/original/'..name..'.png')
 if ok and img then img:setFilter('nearest','nearest');return img end
end
local rooms={'main','second','sale'}
local function roomName(r) return ({main='TANK 1',second='TANK 2',sale='SALE TANK',isolation='ISOLATION'})[r] or r end
function Retro.new(game,hasSave)
 return setmetatable({g=game,hasSave=not not hasSave,screen='title',room='main',selected=nil,
  popup=nil,popupFrom=nil,buttons={},fishHits={},softkeys={},images={},assets=Assets.new(),
  speed=1,soundEnabled=true,shopPage=1,selectedShopIndex=1,trophyIndex=1,toast='',toastTime=0,time=0,browseIndex=1,
  confirmFrom='title',utilityReturn=nil,welcomeIndex=1,welcomeTop=1,
  scale=1,ox=0,oy=0,focus=nil,focusScreen=nil,onSave=nil,onNewGame=nil,onSound=nil},Retro)
end
function Retro:init()
 self.assets:init()
 for _,name in ipairs({'oberon','splash','assets','gameMenuTank','menutank','store','trhopy_ball'}) do
  self.images[name]=load(name)
 end
 self.font=love.graphics.newFont(9)
 self.font:setFilter('nearest','nearest')
 -- Enquanto a fonte de 1.dat nao estiver importada, manter a lista
 -- legivel no tamanho maior do menu em vez de reaproveitar os 9px do HUD.
 self.welcomeFont=love.graphics.newFont(15)
 self.welcomeFont:setFilter('nearest','nearest')
 self.bitmapFont=BitmapFont.new()
 bitmapFont=self.bitmapFont
 -- Partes do atlas PNG original; alternativas simples sao exibidas
 -- quando o proprietario ainda nao importou assets.png de seu JAR.
 self.quads={}
 local atlas=self.images.assets
 if atlas and love.graphics.newQuad then
  local iw,ih=atlas:getDimensions()
  local coords={slot={20,153,18,25},fish={88,219,16,23},
   food={112,195,23,26},cart={31,218,23,24},
   hourglass={125,94,11,14},money={110,156,22,24},
   breed={113,113,23,18},medicine={113,98,23,18},
   arrow={94,123,24,12},heart={104,132,28,25}}
  for name,c in pairs(coords) do
   if c[1]+c[3]<=iw and c[2]+c[4]<=ih then
    self.quads[name]={q=love.graphics.newQuad(c[1],c[2],c[3],c[4],iw,ih),w=c[3],h=c[4]}
   end
  end
 end
 -- Itens recortados do atlas store.png do JAR (113x123).
 -- As coordenadas sao do arquivo original, e NAO de imagens recriadas.
 -- Nem todos os produtos tiveram sprite individual identificado: nesses
 -- casos, o layout usa o quadro de reserva sem desenhar sprite incorreto.
 self.storeQuads={}
 local store=self.images.store
 if store and love.graphics.newQuad then
  local iw,ih=store:getDimensions()
  local coords={food={97,52,15,20},ick={86,52,23,25},fungus={92,46,18,23},
   vitamin={23,73,22,25},hormone={23,46,24,29},mutagen={52,1,23,24},
   eggs={84,0,23,25},aerator={57,21,18,23},heater={94,83,17,23},
   snail={77,104,18,16},plant={61,53,21,29},
   curing_plant={31,28,25,22},fertility_plant={31,52,22,23},
   decor={64,100,19,20},second={25,1,30,19}}
  for id,q in pairs(coords) do
   if q[1]+q[3]<=iw and q[2]+q[4]<=ih then
    self.storeQuads[id]={quad=love.graphics.newQuad(q[1],q[2],q[3],q[4],iw,ih),w=q[3],h=q[4]}
   end
  end
 end
 -- Miniaturas nativas dos tres tanques na barra de ferramentas.
 self.tankIcons={}
 for i,name in ipairs({'tank1','tank2','tank3'}) do
  local image=self.assets.images[name]
  if image and love.graphics.newQuad then
   local iw,ih=image:getDimensions()
   self.tankIcons[i]={image=image,quad=love.graphics.newQuad(45,35,70,75,iw,ih)}
  end
 end
end
function Retro:setGame(game,hasSave)
 self.g=game;self.hasSave=not not hasSave
 self.selected=nil;self.browseIndex=1;self.room='main';self.screen='tank';self.popup=nil
 self.focus=nil;self.focusScreen=nil;self.utilityReturn=nil
end
-- Loja/pesquisas devem retornar ao aquario ou menu que as abriu,
-- sem prender o jogador no menu de pausa (regressao da v28).
function Retro:openUtility(target)
 assert(target=='shop' or target=='research')
 if self.screen~='shop' and self.screen~='research' then
  self.utilityReturn=self.screen
 end
 self.screen=target
 self.focus=nil;self.focusScreen=nil
end
function Retro:leaveUtility()
 local dest=self.utilityReturn or 'pause'
 if dest=='shop' or dest=='research' then dest='pause' end
 self.utilityReturn=nil
 self.screen=dest
 self.focus=nil;self.focusScreen=nil
end
-- Sequencia do MIDlet: 30 (Oberon) -> 34 (DO YOU WANT SOUND?)
-- -> 31 (Splash) -> 32 (WELCOME/menu). Estado 33 pode preceder
-- 34 quando o idioma nao estiver configurado (ainda nao portado).
function Retro:beginIntro()
 self.introElapsed=0
 if self.images.oberon then self.screen='intro_oberon'
 elseif self.images.splash then self.screen='intro_sound'
 else self.screen='title' end
 self.focus=nil;self.focusScreen=nil
end
function Retro:chooseIntroSound(enabled)
 if self.screen~='intro_sound' then return false end
 if self.soundEnabled~=enabled then
  if self.onSound then self.soundEnabled=self.onSound()
  else self.soundEnabled=enabled end
 end
 self.introElapsed=0
 self.screen=self.images.splash and 'intro_splash' or 'title'
 self.focus=nil;self.focusScreen=nil
 return true
end
function Retro:isPlaying()
 return self.hasSave and self.screen~='title' and self.screen~='confirm'
  and self.screen~='settings' and self.screen~='intro_oberon'
  and self.screen~='intro_sound' and self.screen~='intro_splash'
end
function Retro:notify(message) self.toast=tostring(message or '');self.toastTime=3.3 end
function Retro:update(dt)
 self.time=self.time+dt;self.toastTime=math.max(0,self.toastTime-dt)
 if self.screen=='intro_oberon' or self.screen=='intro_splash' then
  self.introElapsed=(self.introElapsed or 0)+dt
  while self.introElapsed>=3 and
   (self.screen=='intro_oberon' or self.screen=='intro_splash') do
   self.introElapsed=self.introElapsed-3
   if self.screen=='intro_oberon' then
    self.screen='intro_sound'
   else
    self.screen='title'
   end
  end
 end
end
function Retro:hit(x,y,w,h,fn,role)
 self.buttons[#self.buttons+1]={x=x,y=y,w=w,h=h,fn=fn,role=role}
end
function Retro:menuButton(label,x,y,w,h,fn,disabled)
 fill(x,y,w,h,63,34,93)
 stroke(x,y,w,h,150,99,184)
 fill(x+2,y+2,w-4,2,129,85,164)
 fontText(label,x+3,y+math.floor((h-10)/2),w-6,'center',disabled and {141,126,149} or {185,252,150})
 if fn and not disabled then self:hit(x,y,w,h,fn) end
end
-- Linha ilustrada: os icones sao obtidos do atlas J2ME ja importado,
-- e nao de desenhos substitutos novos. Reserva de texto sem esse atlas.
function Retro:iconRow(label,x,y,w,h,fn,disabled,icon)
 fill(x,y,w,h,63,34,93)
 stroke(x,y,w,h,150,99,184)
 fill(x+2,y+2,w-4,2,129,85,164)
 local shown=false
 if icon then
  if icon.kind=='store' then
   shown=self:storeIcon(icon.name,x+4,y+3,21,h-6)
  elseif icon.kind=='tank' then
   shown=self:roomIcon(icon.name,x+5,y+3,19,h-6)
  elseif icon.kind=='atlas' then
   shown=self:atlasIcon(icon.name,x+7,y+math.floor((h-16)/2),16,16)
  end
  if not shown then fontText(icon.fallback or '?',x+6,y+math.floor((h-10)/2),17,'center',
   disabled and {134,116,139} or {223,210,148}) end
 end
 fontText(label,x+32,y+math.floor((h-10)/2),w-37,'left',
  disabled and {141,126,149} or {185,252,150})
 if fn and not disabled then self:hit(x,y,w,h,fn) end
end
function Retro:roomIcon(room,x,y,w,h)
 local ids={main=1,second=2,sale=3}
 local idx=ids[room]
 if idx and self.tankIcons[idx] then
  local img=self.tankIcons[idx]
  rgb(255,255,255)
  love.graphics.draw(img.image,img.quad,x,y,0,w/70,h/75)
  return true
 end
 if room=='isolation' then
  local img=self.assets.images.isolation_tank
  if img then
   local iw,ih=img:getDimensions()
   rgb(255,255,255)
   love.graphics.draw(img,x,y,0,w/iw,h/ih)
   return true
  end
 end
 return false
end
function Retro:buttonHint(left,right)
 self.softkeys={left=left,right=right}
 fill(0,298,240,22,37,20,64)
 fill(0,299,240,2,118,79,164)
 fill(0,301,240,2,67,36,97)
 fill(0,303,240,17,54,26,82)
 if left then self:menuButton(left.label,0,299,63,21,left.fn,left.disabled) end
 if right then self:menuButton(right.label,177,299,63,21,right.fn,right.disabled) end
end
function Retro:background(room)
 local sky=self.assets.images.tanktop
 -- Nunca representar um tanque ausente usando a arte de outro tanque.
 -- Um fundo neutro indica recurso ainda nao importado, sem falsear a referencia.
 local source=({main='tank1',second='tank2',sale='tank3'})[room]
 local floor=room=='isolation' and
  (self.images.gameMenuTank or self.assets.images.menutank) or
  (source and self.assets.images[source])
 rgb(255,255,255)
 if sky then love.graphics.draw(sky,0,24) else fill(0,24,240,110,12,100,160) end
 if floor then
  love.graphics.draw(floor,0,122)
 else fill(0,122,240,154,12,76,130) end
end
function Retro:tray()
 local im=self.assets.images.isolation_tank
 if im then rgb(255,255,255);love.graphics.draw(im,70,274) end
 -- O recipiente funciona como atalho apenas no aquario normal.
 -- Nos detalhes, ele permanece visivel mas nao troca a sala selecionada.
 if self.screen=='tank' then
  self:hit(69,272,102,47,function()
   if self.room=='isolation' then self.room='main' else self.room='isolation' end
   self.selected=nil;self.screen='tank'
  end,'tray')
 end
end
-- Desenha os icones do atlas comercial, sem modificar nenhum sprite PNG.
function Retro:atlasIcon(name,x,y,w,h)
 local atlas=self.images.assets
 local entry=self.quads and self.quads[name]
 if not atlas or not entry then return false end
 rgb(255,255,255)
 love.graphics.draw(atlas,entry.q,x,y,0,w/entry.w,h/entry.h)
 return true
end
function Retro:toolbar()
 fill(0,0,240,25,41,22,69)
 fill(0,0,240,2,124,82,163)
 fill(0,23,240,2,17,9,37)
 local menu={
  {tip='1',kind='tank',room='main'},
  {tip='2',kind='tank',room='second'},
  {tip='3',kind='tank',room='sale'},
  {tip='F',kind='fish',icon='fish'},
  {tip='E',kind='feed',icon='food'},
  {tip='M',kind='medicine',icon='medicine'},
  {tip='B',kind='breed',icon='breed'},
  {tip='?',kind='species',icon='heart'},
  {tip='S',kind='shop',icon='cart'},
  {tip='R',kind='research',icon='hourglass'},
  {tip='$',kind='cash',icon='money'},
 }
 -- Na barra J2ME da referencia, as tres miniaturas de tanque usam
 -- colunas de 18 pixels; os oito controles seguintes usam 23-24px.
 -- Bordas inteiras evitam frestas de clique ou sobreposicao de slots.
 local edges={0,18,36,54,77,100,123,146,169,192,216,240}
 for i,item in ipairs(menu) do
  local x=edges[i]
  local slotW=edges[i+1]-x
  if not self:atlasIcon('slot',x,1,slotW,22) then
   fill(x,2,slotW,20,76,44,102);stroke(x,2,slotW,20,153,99,188)
  end
  local active=(item.room and item.room==self.room) or
   (item.kind=='fish' and self.screen=='detail')
  if active then stroke(x+1,3,slotW-2,18,239,222,70) end
  if item.kind=='tank' then
   local idx=i
   local preview=self.tankIcons[idx]
   if preview then
    rgb(255,255,255)
    love.graphics.draw(preview.image,preview.quad,x+4,5,0,14/70,13/75)
   else fontText(item.tip,x+2,7,slotW-4,'center',{224,252,180}) end
   fontText(item.tip,x+slotW-8,13,6,'right',{255,249,153})
  elseif not self:atlasIcon(item.icon,x+math.floor((slotW-15)/2),4,15,15) then
   fontText(item.tip,x+2,7,slotW-4,'center',{230,223,185})
  end
  self:hit(x,2,slotW,21,function()
   if item.kind=='tank' then
    if item.room=='second' and not self.g.s.unlocked.second then
     self:notify('TANK 2: BUY AT STORE')
    else self.room=item.room;self.screen='tank';self.selected=nil;self.browseIndex=1 end
   elseif item.kind=='fish' then self:beginBrowse()
   elseif item.kind=='feed' then
    local ok,msg
    if self.selected then ok,msg=self.g:feed(self.selected)
    else ok,msg=self.g:feedTank(self.room) end
    self:notify(msg or (ok and 'FISH FED' or 'NO FOOD'))
   elseif item.kind=='medicine' then
    if self.selected then self.screen='treat' else self:notify('SELECT A FISH FIRST') end
   elseif item.kind=='breed' then
    if self.room=='isolation' then
     local ok,msg=self.g:breed();self:notify(msg or (ok and 'BREEDING' or 'NEED TWO ADULTS'))
    else self:notify('BREED IN ISOLATION') end
   elseif item.kind=='species' then
    if self.selected then self.screen='detail' else self:notify('SELECT A FISH FIRST') end
   elseif item.kind=='shop' or item.kind=='cash' then self:openUtility('shop');self.shopPage=1
   elseif item.kind=='research' then self:openUtility('research') end
  end)
 end
 -- O J2ME usa o ultimo quadrado para o icone de dinheiro.
 -- A quantia fica na tela da loja, sem sobrepor a barra superior.
end
function Retro:beginBrowse()
 local tank=self.g.s.tanks[self.room]
 if not tank or #tank==0 then return self:notify('NO FISH IN TANK') end
 self.browseIndex=math.max(1,math.min(self.browseIndex,#tank))
 self.selected=tank[self.browseIndex].id
 self.screen='detail'
end
function Retro:browseFish(direction)
 local tank=self.g.s.tanks[self.room]
 if not tank or #tank==0 then self.selected=nil;self.screen='tank';return false end
 for i,f in ipairs(tank) do if f.id==self.selected then self.browseIndex=i;break end end
 self.browseIndex=(self.browseIndex-1+(direction or 0))%#tank+1
 self.selected=tank[self.browseIndex].id
 return true
end
function Retro:fishDraw()
 self.fishHits={}
 local tank=self.g.s.tanks[self.room]
 if self.room=='second' and not self.g.s.unlocked.second then
  fill(25,114,190,34,34,24,65,.9);centered('TANK 2 LOCKED',119)
  self:menuButton('GO TO STORE',75,156,90,22,function()self:openUtility('shop') end)
  return
 end
 local selectedIndex=nil
 local selectedFish=nil
 if self.screen=='detail' and self.selected then
  for i,f in ipairs(tank) do
   if f.id==self.selected then selectedIndex=i;selectedFish=f;break end
  end
 end
 local function renderFish(i,f,selected)
  local x,y,face=Swim.position(f,i,self.room,self.time)
  local sx,sy
  local fishWidth,fishHeight=FishGeometry.size(f)
  -- Na pequena bandeja inferior, ha somente dois espacos uteis de 48px.
  -- Os sprites de ate 50x39px nao cabem com escala 1 nesse recorte:
  -- ajustar APENAS a apresentacao na bandeja, nunca nos aquarios.
  local scale=1
  if self.room=='isolation' and not selected then
   sx=96+((i-1)%2)*48
   sy=286
   scale=math.min(1,48/fishWidth,24/fishHeight)
  else
   -- J2ME: coordenadas diretas 240x320; sem grade ou escala artificial.
   sx,sy=x,y
  end
  -- A referencia original da selecao (x=63..119, y=34..71) tambem
  -- se aplica ao exemplar retirado da bandeja de isolamento.
  if selected then sx,sy=91,53;scale=1 end
  local half,halfY=fishWidth*scale/2,fishHeight*scale/2
  if self.room~='isolation' or selected then
   sx=math.max(half+2,math.min(W-half-2,sx))
   -- Reserva o HUD superior e a bandeja inferior em todos os tamanhos.
   if not selected then sy=math.max(35+halfY,math.min(270-halfY,sy)) end
   -- A tela de detalhes nao altera a trajetoria dos outros peixes:
   -- a moldura e tratada como um overlay, sem teletransportar ninguem.
  end
  if selected then
   -- A borda amarela nao pode ser coberta pela barbatana do peixe.
   stroke(sx-28,sy-19,56,37,242,208,28)
   logicalScissor(self,sx-27,sy-18,54,35,function()
    self.assets:drawFish(f,sx,sy,scale,face)
   end)
  else
   self.assets:drawFish(f,sx,sy,scale,face)
  end
  -- As placas For Sale! ja estao pintadas em tank3.png, no cascalho.
  self.fishHits[#self.fishHits+1]={id=f.id,x=sx,y=sy,
    rx=math.max(10,half),ry=math.max(8,halfY)}
 end
 -- Os peixes continuam nadando nas coordenadas normais. Para a
 -- selecao ficar legivel, restauramos somente a agua atras da moldura
 -- com o proprio tanktop.png (sem empurrar outras trajetorias).
 for i,f in ipairs(tank) do
  if i~=selectedIndex then renderFish(i,f,false) end
 end
 if selectedFish then
  if self.room~='isolation' then
   local sky=self.assets.images.tanktop
   local gfx=love.graphics
   if sky and gfx.getScissor and gfx.setScissor then
    -- Remover o que foi desenhado anteriormente sob a area da selecao.
    -- A area restaurada usa o MESMO recorte do peixe selecionado;
    -- assim nao sobra uma faixa fantasma de 1px nas extremidades.
    logicalScissor(self,64,35,54,35,function()
     rgb(255,255,255)
     gfx.draw(sky,0,24)
    end)
   elseif not sky then
    -- Fundo azul de reserva, apenas quando o recurso JAR nao existe.
    fill(64,35,54,35,11,110,181)
   end
  end
  renderFish(selectedIndex,selectedFish,true)
 end
end
function Retro:statsBar(f)
 -- Bezel da tela de selecao J2ME (imagem de referencia 240x320):
 -- x=12..227, y=0..33, interior escuro e borda roxa com brilho inferior.
 -- O painel anterior era um retangulo plano de 34px iniciado em y=1,
 -- avançando sobre a moldura amarela que comeca em y=34.
 fill(12,0,216,33,140,67,227)
 fill(13,1,214,31,132,75,207)
 fill(14,2,212,29,18,0,61)
 fill(15,3,210,26,81,59,121)
 fill(16,4,208,24,94,66,139)
 fill(14,2,1,29,20,0,63)
 fill(225,2,1,29,20,0,63)
 fill(13,29,214,2,189,132,245)
 fill(14,31,212,1,173,122,229)
 fill(16,32,208,1,117,89,199)
 fontText('FED',17,4,30)
 fontText('HEALTH',17,17,42)
 fill(60,7,16,3,22,7,43);fill(60,7,math.max(0,16*(f.fed or 0)/100),3,160,220,102)
 fill(60,20,16,3,22,7,43)
 if (f.health or 0)>=35 then
  fill(60,20,math.max(0,16*(f.health or 0)/100),3,160,220,102)
 else
  fill(60,20,math.max(0,16*(f.health or 0)/100),3,210,140,122)
 end
 -- Nomes recuperados da tabela inglesa do JAR, indices 51..92.
 local fullname=Catalog.nameFor(f.body,f.tail)
 local finName=Catalog.finNames[f.tail] or 'FIN'
 local bodyName=Catalog.bodyNames[f.body] or 'FISH'
 fontText(finName,90,4,69,'center',{243,246,222})
 fontText(bodyName,90,18,69,'center',{243,246,222})
 fontText('AGE:'..math.floor(f.age),165,6,58)
end
function Retro:drawTank()
 self:background(self.room)
 if self.screen=='detail' then
  local f,activeRoom=self.g:find(self.selected)
  if f and activeRoom==self.room then self:statsBar(f)
  else
   -- Um peixe pode morrer ou ser transferido enquanto a tela esta aberta.
   -- Nunca deixar selecionado um ID ausente ou de outro aquario.
   self.selected=nil;self.screen='tank';self:toolbar()
  end
 else self:toolbar() end
 self:tray() -- o peixe isolado deve ser desenhado SOBRE o recipiente
 self:fishDraw()
 if self.screen=='detail' and self.selected then
  self:buttonHint({label='SELECT',fn=function()self.screen='actions' end},
   {label='BACK',fn=function()self.screen='tank';self.selected=nil end})
 else
  local left
  if self.room=='isolation' then
   left={label='BREED',fn=function()
    local ok,msg=self.g:breed()
    self:notify(msg or (ok and 'BREEDING STARTED' or 'SELECT 2 ADULT FISH'))
   end}
  elseif self.room=='sale' then
   left={label=self.g.s.sale_open and 'CLOSE' or 'OPEN',fn=function()
    self.g.s.sale_open=not self.g.s.sale_open
    self:notify(self.g.s.sale_open and 'SALES OPEN' or 'SALES CLOSED')
   end}
  else
   left={label='FISH',fn=function()
    local tank=self.g.s.tanks[self.room]
    self:beginBrowse()
   end}
  end
  self:buttonHint(left,{label='MENU',fn=function()self.screen='pause' end})
 end
end
function Retro:introSound()
 -- Texto e softkeys confirmados em E (tabela inglesa) e d.class estado 34.
 -- Geometria provisoria ate confrontar a renderizacao real do MIDlet.
 self:background('main')
 fill(15,104,210,110,35,20,72,.93)
 stroke(15,104,210,110,169,113,194)
 centered('DO YOU WANT SOUND?',148,{252,226,166})
 self:buttonHint(
  {label='YES',fn=function()self:chooseIntroSound(true) end},
  {label='NO',fn=function()self:chooseIntroSound(false) end})
end
-- d.class, estado 32, chama f(32): strings 1..9 do recurso E.
-- RESUME depende de save, MORE GAMES so existe em determinadas edicoes.
-- Os nomes sao exatos; a geometria segue provisoria ate captura do MIDlet.
function Retro:titleEntries()
 local entries={}
 if self.hasSave then
  entries[#entries+1]={'RESUME',function()self.screen='tank';self.room='main' end}
 end
 entries[#entries+1]={'START NEW GAME',function()
  if self.hasSave then self.confirmFrom='title';self.screen='confirm'
  else self:startNewGame() end
 end}
 entries[#entries+1]={'OPTIONS',function()self.from='title';self.screen='settings' end}
 entries[#entries+1]={'TROPHY',function()self.screen='collection' end}
 entries[#entries+1]={'STATS',function()self.screen='stats' end}
 entries[#entries+1]={'HELP',function()self.screen='help' end}
 entries[#entries+1]={'ABOUT',function()self.from='title';self.screen='about' end}
 if self.onMoreGames then entries[#entries+1]={'MORE GAMES',self.onMoreGames} end
 entries[#entries+1]={'EXIT',function()
  if self.onSave and self.hasSave then
   local ok,err=self.onSave()
   if not ok then self:notify(err or 'SAVE ERROR');return end
  end
  if self.onExit then self.onExit()
  elseif love and love.event and love.event.quit then love.event.quit() end
 end}
 return entries
end
-- d.class: f(32) monta a lista com a rotina a([[B,1,...,120,160,...,3,5).
-- O modo 1 mede o texto mais largo e soma 16px de margem; a lista ocupa
-- a regiao central, em vez de usar botoes de 178px inventados pelo port.
-- O comprimento visual vem da fonte original quando importada.
function Retro:welcomeLayout(entries)
 local maxText=0
 for _,entry in ipairs(entries) do
  local width
  if self.bitmapFont then width=self.bitmapFont:measure(entry[1],1)
  elseif self.welcomeFont and self.welcomeFont.getWidth then width=self.welcomeFont:getWidth(entry[1])
  elseif self.font and self.font.getWidth then width=self.font:getWidth(entry[1])
  else width=#entry[1]*6 end
  maxText=math.max(maxText,width)
 end
 local width=math.min(220,math.max(90,math.ceil(maxText)+16))
-- d.class: menu mode=1 has W=5 (visible rows), V=5 (row spacing).
 -- Its N coordinate is centered against a window of five rows, not
 -- the full list of seven to nine choices.
 local rowHeight,gap=20,5
 local visible=math.min(5,#entries)
 local total=visible*rowHeight+math.max(0,visible-1)*gap
 return {x=math.floor(120-width/2),y=math.floor(160-total/2),
  w=width,h=rowHeight,step=rowHeight+gap,visible=visible}
end
function Retro:title()
 local art=self.images.menutank or self.assets.images.menutank
 if art then
  rgb(255,255,255);love.graphics.draw(art,0,24)
 else self:background('main') end
 -- Cabecalho do MIDlet acima do menu central; sem banner translucido artificial.
 centered('WELCOME',20,{246,226,164})
 local entries=self:titleEntries()
 local layout=self:welcomeLayout(entries)
 self.welcomeIndex=math.max(1,math.min(#entries,self.welcomeIndex or 1))
 local maxFirst=math.max(1,#entries-layout.visible+1)
 local first=math.max(1,math.min(maxFirst,
  self.welcomeIndex-math.floor((layout.visible-1)/2)))
 self.welcomeTop=first
 for i=first,math.min(#entries,first+layout.visible-1) do
  local entry=entries[i]
  local x,y=layout.x,layout.y+(i-first)*layout.step
  -- Keep the 20px original font and a readable fallback without 1.dat.
  if self.bitmapFont then
   rgb(239,237,222)
   self.bitmapFont:print(entry[1],x+8,y+1,layout.w-16,'left',1)
  else
   if self.welcomeFont then love.graphics.setFont(self.welcomeFont) end
   fontText(entry[1],x+8,y+2,layout.w-16,'left',{239,237,222})
   if self.welcomeFont then love.graphics.setFont(self.font) end
  end
  self:hit(x,y,layout.w,layout.h,function()
   self.welcomeIndex=i
   entry[2]()
  end,'welcome')
 end
 self.focusScreen='title'
 self.focus=self.welcomeIndex-first+1
 self:buttonHint({label='SELECT',fn=function()
  local selected=self:titleEntries()[self.welcomeIndex]
  if selected then selected[2]() end
 end},{label='EXIT',fn=entries[#entries][2]})
end
function Retro:startNewGame()
 if not self.onNewGame then return self:notify('NEW GAME NOT AVAILABLE') end
 local ok,err,newGame=self.onNewGame()
 if not ok then return self:notify(err or 'SAVE ERROR') end
 self:setGame(newGame,true)
 self:notify('NEW GAME STARTED')
end
function Retro:confirm()
 self:background('main')
 fill(11,81,218,147,41,22,74,.93);stroke(11,81,218,147,181,108,193)
 centered('START A NEW GAME?',93,{252,218,147})
 centered('CURRENT GAME WILL BE',124)
 centered('ARCHIVED BEFORE RESET.',139)
 self:menuButton('YES, NEW GAME',34,173,173,23,function()self:startNewGame() end)
 self:menuButton('CANCEL',34,201,173,23,function()self.screen=self.confirmFrom or 'title' end)
end
function Retro:panelTitle(title)
 -- menutank.png e um fundo de 240x256 usado nos menus J2ME.
 -- Evita exibir os corais do aquario de jogo atras de loja e pesquisa.
 if self.images.menutank then
  rgb(255,255,255)
  love.graphics.draw(self.images.menutank,0,24)
 else self:background('main') end
 self:toolbar()
 fill(9,37,222,242,37,22,70,.88);stroke(9,37,222,242,168,116,187)
 centered(title,49,{246,226,164})
end
-- A tabela inglesa do JAR (strings 1..9) confirma a nomenclatura
-- RESUME, START NEW GAME, OPTIONS, TROPHY, STATS, HELP, ABOUT, EXIT.
-- Organizacao visual compacta para 240x320: ainda nao foi validada
-- pixel a pixel contra todas as telas originais do MIDlet.
function Retro:pause()
 self:panelTitle('GAME MENU')
 local entries={
  {'RESUME',function()self.screen='tank' end},
  {'START NEW GAME',function()
   if self.hasSave then self.confirmFrom='pause';self.screen='confirm'
   else self:startNewGame() end
  end},
  {'OPTIONS',function()self.from='pause';self.screen='settings' end},
  {'TROPHY',function()self.screen='collection' end},
  {'STATS',function()self.screen='stats' end},
  {'HELP',function()self.screen='help' end},
  {'ABOUT',function()self.from='pause';self.screen='about' end},
  {'SAVE & EXIT',function()
   if self.onSave then local ok,err=self.onSave();if not ok then return self:notify(err) end end
   -- Retorna ao menu inicial para permitir continuar ou abrir novo jogo.
   self.screen='title';self.selected=nil
  end}
 }
 for i,v in ipairs(entries) do self:menuButton(v[1],31,61+(i-1)*27,178,23,v[2]) end
 self:buttonHint(nil,{label='BACK',fn=function()self.screen='tank' end})
end
function Retro:settings()
 self:panelTitle('OPTIONS')
 self:menuButton('MUSIC: '..(self.soundEnabled and 'ON' or 'OFF'),25,85,190,30,function()
  if self.onSound then self.soundEnabled=self.onSound() end
 end)
 self:menuButton('GAME SPEED: '..(self.g.s.game_speed or 1)..'X',25,122,190,30,function()
  local a=self.g.s.game_speed
  self.g.s.game_speed=a==1 and 5 or (a==5 and 20 or 1)
 end)
 self:menuButton('GROWTH: '..self.g.s.growth_minutes..' MIN',25,159,190,30,function()
  local a=self.g.s.growth_minutes
  self.g:setGrowthMinutes(a==5 and 10 or (a==10 and 15 or 5))
 end)
 centered('Settings are saved with the game.',223,{211,202,211})
 self:buttonHint(nil,{label='BACK',fn=function()self.screen=self.from or 'title' end})
end
function Retro:about()
 self:panelTitle('FISH TYCOON')
 centered('J2ME 240x320 INTERFACE',110)
 centered('ENGINE: LUA + LOVE2D',130)
 centered('ORIGINAL ART: STUDY ONLY',153)
 centered('NOT AN OFFICIAL PORT',175)
 self:buttonHint(nil,{label='BACK',fn=function()self.screen=self.from or 'title' end})
end
-- Menu compacto baseado nos textos do proprio motor, sem botoes gigantes.
-- Layout 240x320 e provisoriamente J2ME, pendente de referencia visual.
function Retro:fishHeader(f)
 local name=Catalog.nameFor(f.body,f.tail)
 fontText(name,17,65,206,'center',{250,237,185})
 fontText('AGE '..math.floor(f.age)..'   HEALTH '..math.floor(f.health or 0)..
  '   $'..(f.price or 0),14,80,212,'center',{220,223,215})
end
function Retro:drawActions()
 self:panelTitle('FISH MENU')
 local f,room
 if self.selected then f,room=self.g:find(self.selected) end
 if not f then self.selected=nil;self.screen='tank';return end
 self:fishHeader(f)
 local saleEligible=room=='sale' and self.g:isAdult(f)
 local food=(self.g.s.supplies.food or 0)
 local list={
  {label='FEED   x'..food,icon={kind='atlas',name='food',fallback='F'},fn=function()
    local ok,msg=self.g:feed(f.id);self:notify(msg or (ok and 'FED' or 'NO FOOD'))
   end,disabled=food<1 or (f.fed or 100)>=100},
  {label='TREAT FISH',icon={kind='atlas',name='medicine',fallback='+'},fn=function()self.screen='treat' end},
  {label='MOVE FISH',icon={kind='atlas',name='arrow',fallback='>'},fn=function()self.screen='move' end},
  {label='PRICE -5',icon={kind='atlas',name='money',fallback='$'},fn=function()
    local ok,n=self.g:changePrice(f.id,-5);self:notify(ok and '$'..n or n)
   end,disabled=not saleEligible},
  {label='PRICE +5',icon={kind='atlas',name='money',fallback='$'},fn=function()
    local ok,n=self.g:changePrice(f.id,5);self:notify(ok and '$'..n or n)
   end,disabled=not saleEligible},
  {label='SELL NOW',icon={kind='atlas',name='cart',fallback='$'},fn=function()
    local ok,n=self.g:sell(f.id)
    self:notify(ok and 'SOLD!' or n)
    if ok then self.selected=nil;self.screen='tank' end
   end,disabled=not saleEligible},
 }
 for i,item in ipairs(list) do
  self:iconRow(item.label,23,97+(i-1)*30,194,25,item.fn,item.disabled,item.icon)
 end
 self:buttonHint(nil,{label='BACK',fn=function()self.screen='detail' end})
end
function Retro:drawMove()
 self:panelTitle('MOVE FISH')
 local f,from
 if self.selected then f,from=self.g:find(self.selected) end
 if not f then self.selected=nil;self.screen='tank';return end
 self:fishHeader(f)
 local list={{'TANK 1','main'},{'TANK 2','second'},
             {'ISOLATION','isolation'},{'SALE TANK','sale'}}
 for i,item in ipairs(list) do
  local room=item[2]
  local count=#self.g.s.tanks[room]
  local capacity=Config.CAPACITY[room]
  local locked=room=='second' and not self.g.s.unlocked.second
  local blocked=room==from or locked or count>=capacity or
    (room=='sale' and not self.g:isAdult(f)) or
    (from=='isolation' and f.eggs_at~=nil)
  local name=item[1]..'    '..count..'/'..capacity
  if room==from then name=item[1]..'  (CURRENT)'
  elseif locked then name=item[1]..'  (LOCKED)'
  elseif count>=capacity then name=item[1]..'  (FULL)'
  elseif room=='sale' and not self.g:isAdult(f) then name=item[1]..'  (ADULT ONLY)'
  elseif from=='isolation' and f.eggs_at then name=item[1]..'  (EGGS)' end
  self:iconRow(name,18,103+(i-1)*36,204,29,function()
   local ok,msg=self.g:move(self.selected,room)
   self:notify(msg or (ok and 'MOVED!' or 'CANNOT MOVE'))
   if ok then self.room=room;self.screen='tank';self.selected=nil end
  end,blocked,{kind='tank',name=room,fallback=tostring(i)})
 end
 centered('SELECT A TANK WITH SPACE',259,{213,209,223})
 self:buttonHint(nil,{label='BACK',fn=function()self.screen='actions' end})
end
function Retro:drawTreat()
 self:panelTitle('TREAT FISH')
 local f=self.selected and self.g:find(self.selected)
 if not f then self.selected=nil;self.screen='tank';return end
 self:fishHeader(f)
 local disease=f.disease or 'NONE'
 fontText('CONDITION: '..string.upper(disease),17,96,206,'center',
  disease=='NONE' and {173,235,175} or {247,185,130})
 local list={{'ICK','ick'},{'FUNGUS','fungus'},
             {'VITAMINS','vitamin'},{'HORMONE','hormone'},
             {'CHEMICAL','mutagen'}}
 for i,item in ipairs(list) do
  local kind=item[2]
  local quantity=self.g.s.supplies[kind] or 0
  local compatible=(kind~='ick' and kind~='fungus') or f.disease==kind
  if kind=='hormone' and f.age>40 then compatible=false end
  local disabled=quantity<1 or not compatible
  local label=item[1]..'     x'..quantity
  if not compatible then label=label..'  (N/A)' end
  self:iconRow(label,23,115+(i-1)*31,194,26,function()
   local ok,msg=self.g:medicine(self.selected,kind)
   self:notify(msg or (ok and 'APPLIED' or 'FAILED'))
   if ok then self.screen='actions' end
  end,disabled,{kind='store',name=kind,fallback='+'})
 end
 centered('BUY MEDICINE AT STORE',279,{208,202,213})
 self:buttonHint(nil,{label='BACK',fn=function()self.screen='actions' end})
end
-- Rótulos compactos no idioma das capturas fornecidas; custos do motor
-- Lua permanecem provisórios, não apresentados como valores do JAR.
local supplyLabels={food='FISH FOOD',ick='ICK TREATMENT',fungus='FUNGUS CURE',
 vitamin='VITAMINS',hormone='GROWTH HORMONE',mutagen='UNKNOWN CHEMICAL',
 eggs='FISH EGGS',aerator='AERATOR',heater='HEATER',snail='CLEANER SNAIL',
 plant='NUTRIENT PLANT',curing_plant='MEDICINAL PLANT',
 fertility_plant='FERTILITY PLANT',decor='DECORATIONS',second='TANK 2'}
local supplyNotes={food='FOOD FOR THE TANK',ick='TREAT FISH WITH ICK',
 fungus='TREAT FUNGUS',vitamin='IMPROVE FISH HEALTH',
 hormone='SPEED UP GROWTH',mutagen='MAY CHANGE FISH',
 eggs='HATCH NEW FISH',aerator='IMPROVE WATER',heater='CONTROL TEMPERATURE',
 snail='KEEP WATER CLEAN',plant='HELP FEED FISH',
 curing_plant='SUPPORT FISH HEALTH',fertility_plant='MORE BABY FISH',
 decor='ATTRACT CUSTOMERS',second='UNLOCK ANOTHER TANK'}
function Retro:storeIcon(id,x,y,boxW,boxH)
 local atlas=self.images.store
 local sprite=self.storeQuads and self.storeQuads[id]
 if not atlas or not sprite then return false end
 rgb(255,255,255)
 boxW,boxH=boxW or 28,boxH or 29
 local sc=math.min(boxW/sprite.w,boxH/sprite.h,1.35)
 love.graphics.draw(atlas,sprite.quad,x+(boxW-sprite.w*sc)/2,
  y+(boxH-sprite.h*sc)/2,0,sc,sc)
 return true
end
function Retro:shop()
 self:panelTitle('FISH SUPPLIES')
 local total=#Catalog.supplies
 local pages=math.ceil(total/4)
 self.shopPage=math.max(1,math.min(self.shopPage,pages))
 local startIndex=(self.shopPage-1)*4+1
 if not self.selectedShopIndex or self.selectedShopIndex<startIndex
    or self.selectedShopIndex>startIndex+3 then
  self.selectedShopIndex=startIndex
 end
 fontText('CASH $'..math.floor(self.g.s.cash),20,66,201,'right',{255,238,139})
 for row=0,3 do
  local i=startIndex+row
  local item=Catalog.supplies[i]
  if item then
   local y=83+row*43
   fill(15,y,210,39,48,25,80,.9)
   stroke(15,y,210,39,117,75,145)
   if self.selectedShopIndex==i then
    stroke(16,y+1,208,37,241,210,45)
   end
   if not self:storeIcon(item.id,20,y+4) then
    fill(21,y+5,27,28,69,45,104)
    fontText('?',27,y+13,15,'center',{222,205,152})
   end
   fontText(supplyLabels[item.id] or item.title:upper(),54,y+6,156,'left',
    {245,241,207})
   -- Os estados abaixo refletem as precondicoes reais de Game:purchase,
   -- nao estimativas de preco ou regras novas. O botao fica indisponivel
   -- antes do clique, em vez de prometer uma compra impossivel.
   local state=self.g.s
   local owned=(item.id=='second' and state.unlocked.second) or
    (state.gear[item.id] == true)
   local eggFull=item.id=='eggs' and
    (#state.eggs+#state.tanks.main)>Config.CAPACITY.main-2
   local shortCash=state.cash<item.price
   local stock=state.supplies[item.id]
   local stockText=type(stock)=='number' and ('  x'..math.floor(stock)) or
    (item.id=='eggs' and ('  x'..#state.eggs) or '')
   fontText('$'..tostring(item.price)..stockText,54,y+22,114,'left',{254,220,119})
   local buyLabel=owned and 'OWN' or eggFull and 'FULL' or
    shortCash and 'NO $' or 'BUY'
   local cannotBuy=owned or eggFull or shortCash
   self:menuButton(buyLabel,171,y+20,48,18,function()
    self.selectedShopIndex=i
    local ok,msg=self.g:purchase(item.id)
    self:notify(ok and 'PURCHASED' or msg)
   end,cannotBuy)
   self:hit(15,y,153,39,function() self.selectedShopIndex=i end)
  end
 end
 local item=Catalog.supplies[self.selectedShopIndex]
 fill(15,257,210,22,32,17,59,.94)
 stroke(15,257,210,22,120,83,156)
 if item then
  fontText(supplyNotes[item.id] or (item.desc or ''):upper():sub(1,33),19,265,202,'center',{215,213,191})
 end
 self:menuButton('<',55,281,36,17,function()
  self.shopPage=math.max(1,self.shopPage-1)
  self.selectedShopIndex=(self.shopPage-1)*4+1
 end,self.shopPage<=1)
 fontText(self.shopPage..'/'..pages,100,284,40,'center',{246,228,180})
 self:menuButton('>',148,281,36,17,function()
  self.shopPage=math.min(pages,self.shopPage+1)
  self.selectedShopIndex=(self.shopPage-1)*4+1
 end,self.shopPage>=pages)
 self:buttonHint(nil,{label='BACK',fn=function()self:leaveUtility() end})
end
function Retro:research()
 self:panelTitle('RESEARCH')
 local active=self.g:researchInfo()
 fontText('CASH $'..math.floor(self.g.s.cash),20,61,200,'right',{255,238,139})
 for i,entry in ipairs(Catalog.research) do
  local lvl=self.g.s.research[entry.id] or 0
  local y=77+(i-1)*65
  fill(16,y,208,60,49,29,84,.95)
  stroke(16,y,208,60,134,94,161)
  fontText(entry.title:upper(),23,y+5,116,'left',{249,225,154})
  fontText('LEVEL '..lvl..'/'..Config.RESEARCH_MAX,137,y+5,78,'right')
  -- Barra de nivel, inspirada na apresentacao compacta J2ME.
  fill(23,y+21,130,5,17,9,34)
  local progress=math.floor(130*lvl/Config.RESEARCH_MAX)
  fill(23,y+21,progress,5,112,197,87)
  local preview=self.g:researchProjection(entry.id)
  if preview then
   -- Texto curto: nao invadir o botao START na tela 240x320.
   local summary
   if entry.id=='food' then
    summary='FOOD USE '..(preview.current:match('(%d+)%%') or '?')..'%/CYCLE'
   elseif entry.id=='environment' then
    summary='HEALTH '..(preview.current:match('([%+%-]?%d+%.?%d*)/ciclo') or '?')..'/CYCLE'
   else
    summary='SHOP INTEREST '..(preview.current:match('(%d+)$') or '?')
   end
   fontText(summary,23,y+29,186,'left',{201,219,190})
  end
  -- Mostrar custo/tempo reais do proximo nivel do motor Lua.
  -- O JAR ainda nao autenticou esses valores; nao os atribuir ao Java.
  local complete=lvl>=Config.RESEARCH_MAX
  local nextLevel=lvl+1
  local cost=not complete and Config.RESEARCH_COSTS[entry.id][nextLevel] or nil
  local duration=not complete and Config.RESEARCH_SECONDS[nextLevel] or nil
  local running=self.g.s.research_job~=false and self.g.s.research_job~=nil
  local poor=cost and self.g.s.cash<cost
  local status=complete and 'MAX LEVEL' or
    ('$'..cost..' / '..math.ceil(duration/60)..' MIN')
  fontText(status,23,y+45,129,'left',poor and {245,159,147} or {245,219,153})
  local disabled=complete or running or poor
  self:menuButton(complete and 'MAX' or running and 'BUSY' or
   poor and 'NO $' or 'START',157,y+42,57,16,function()
   local ok,msg=self.g:startResearch(entry.id)
   self:notify(ok and 'RESEARCH STARTED' or msg)
  end,disabled)
 end
 fill(16,275,208,21,34,20,61,.96)
 if active then
  fontText('IN PROGRESS: '..math.ceil(active.remaining/60)..' MIN',18,281,204,'center',
   {225,227,167})
 else
  fontText('CHOOSE A FIELD TO RESEARCH',18,281,204,'center',{211,204,189})
 end
 self:buttonHint(nil,{label='BACK',fn=function()self:leaveUtility() end})
end
-- TROPHY usa a colecao das sete especies magicas ja existente.
-- STATS e HELP exibem os dados e os controles do port sem fingir que
-- seus painéis graficos foram extraidos do bytecode J2ME.
function Retro:statistics()
 self:panelTitle('STATS')
 local stats=self.g.s.stats or {}
 local total=0
 for _,tank in pairs(self.g.s.tanks) do total=total+#tank end
 local lines={
  {'FISH ALIVE',total},
  {'MAGIC BREEDS FOUND',self.g:countMagic()..' / 7'},
  {'FISH BORN',stats.born or 0},
  {'FISH SOLD',stats.sold or 0},
  {'FISH LOST',stats.lost or 0},
  {'TOTAL EARNED','$'..(stats.earned or 0)},
  {'TOTAL SPENT','$'..(stats.spent or 0)},
 }
 for i,line in ipairs(lines) do
  local y=78+(i-1)*27
  fill(18,y,204,23,42,26,75,.9)
  fontText(line[1],23,y+7,133,'left',{234,224,192})
  fontText(tostring(line[2]),157,y+7,59,'right',{245,224,133})
 end
 self:buttonHint(nil,{label='BACK',fn=function()self.screen='pause' end})
end
function Retro:help()
 self:panelTitle('HELP')
 local lines={
  '2 / 8 : UP / DOWN',
  '4 / 6 : LEFT / RIGHT',
  '5 : SELECT',
  'F1 : LEFT SOFTKEY',
  'F2 : RIGHT SOFTKEY',
  'SELECT FISH TO VIEW INFO',
  'USE FISH MENU TO MOVE',
  'BUY FOOD IN SUPPLIES',
 }
 for i,line in ipairs(lines) do
  fontText(line,24,79+(i-1)*23,193,'left',{229,226,194})
 end
 self:buttonHint(nil,{label='BACK',fn=function()self.screen='pause' end})
end
-- O JAR possui /trhopy_ball.png (88x88). A tela antiga da versao Lua
-- era somente uma lista; aqui os sete trofeus recebem a arte original.
-- A grade 4+3 e a interacao de selecao sao adaptacoes de navegacao: nao
-- afirmamos que suas coordenadas sejam as do menu original do MIDlet.
function Retro:collection()
 self:panelTitle('TROPHY')
 centered(self.g:countMagic()..' / 7 DISCOVERED',69,{241,219,144})
 local ball=self.images.trhopy_ball
 self.trophyIndex=math.max(1,math.min(7,self.trophyIndex or 1))
 self.trophyFocusIndices={}
 for i,magic in ipairs(Catalog.magic) do
  -- Quatro esferas na primeira fileira e tres centralizadas na segunda.
  local col=(i-1)%4
  local row=math.floor((i-1)/4)
  local x=(row==0 and 13 or 39)+col*53
  local y=90+row*76
  local found=self.g.s.magic[tostring(i)]
  if self.trophyIndex==i then stroke(x-2,y-2,48,48,245,207,45) end
  if ball then
   rgb(found and 255 or 148,found and 255 or 148,found and 255 or 168)
   love.graphics.draw(ball,x,y,0,44/88,44/88)
  else
   fill(x,y,44,44,found and 29 or 25,found and 103 or 57,found and 190 or 100)
   stroke(x,y,44,44,found and 98 or 64,found and 187 or 111,found and 252 or 155)
  end
  if found then
   -- Somente o sprite original ja implementado; nao inventar um novo peixe.
   self.assets:drawFish({body=magic.body,tail=magic.tail,age=21},x+22,y+22,.59,1)
  else
   fontText('?',x+14,y+17,16,'center',{238,232,184})
  end
  fontText(tostring(i),x+16,y+48,12,'center',{235,221,170})
  self:hit(x,y,44,44,function()self.trophyIndex=i end)
  self.trophyFocusIndices[#self.buttons]=i
 end
 local active=Catalog.magic[self.trophyIndex]
 local acquired=self.g.s.magic[tostring(self.trophyIndex)]
 fill(15,246,210,32,34,19,64,.93);stroke(15,246,210,32,122,91,155)
 local name=acquired and Catalog.nameFor(active.body,active.tail) or 'UNDISCOVERED FISH'
 fontText(name,20,252,200,'center',acquired and {236,233,155} or {194,183,200})
 fontText('MAGIC FISH '..self.trophyIndex..' / 7',20,266,200,'center',{221,211,183})
 self:buttonHint(nil,{label='BACK',fn=function()self.screen='pause' end})
end
-- Navegacao de celulares Java: destaque amarelo no botao ativo.
-- Atua SOMENTE na interface; nao altera genetica ou salvamentos.
function Retro:focusableButtons()
 if self.screen=='collection' and self.trophyFocusIndices then
  local indices={}
  for index in pairs(self.trophyFocusIndices) do indices[#indices+1]=index end
  table.sort(indices)
  if #indices>0 then return indices end
 end
 local out={}
 for i,b in ipairs(self.buttons) do
  if b.y>26 and b.y<299 and b.w>=15 and b.h>=12 then out[#out+1]=i end
 end
 if #out==0 then for i=1,#self.buttons do out[#out+1]=i end end
 return out
end
function Retro:ensureFocus()
 if self.focusScreen~=self.screen then
  self.focus=nil
  self.focusScreen=self.screen
 end
 local valid=false
 for _,i in ipairs(self:focusableButtons()) do if self.focus==i then valid=true;break end end
 if not valid then
  if self.screen=='collection' and self.trophyFocusIndices then
   for n,i in pairs(self.trophyFocusIndices) do
    if i==self.trophyIndex then self.focus=n;return end
   end
  end
  local candidates=self:focusableButtons()
  self.focus=candidates[1]
  -- Os itens centrais do menu devem receber destaque antes da barra superior.
  local chosen=math.huge
  for _,i in ipairs(candidates) do
   local b=self.buttons[i]
   local metric=b.y*100+math.abs((b.x+b.w/2)-120)
   if metric<chosen then chosen=metric;self.focus=i end
  end
 end
end
function Retro:drawFocus()
 if self.screen=='tank' or self.screen=='detail' then return end
 if self.screen=='collection' then self:ensureFocus();return end
 self:ensureFocus()
 local b=self.focus and self.buttons[self.focus]
 if b then
  rgb(255,216,47)
  love.graphics.rectangle('line',b.x+.5,b.y+.5,b.w-1,b.h-1)
 end
end
function Retro:moveFocus(dx,dy)
 self:ensureFocus()
 local current=self.focus and self.buttons[self.focus]
 if not current then return false end
 local cx,cy=current.x+current.w/2,current.y+current.h/2
 local bestIndex,bestScore=nil,math.huge
 for _,i in ipairs(self:focusableButtons()) do
  local b=self.buttons[i]
  if i~=self.focus then
   local ox,oy=(b.x+b.w/2)-cx,(b.y+b.h/2)-cy
   local forward=ox*dx+oy*dy
   if forward>1 then
    local side=math.abs(ox*dy-oy*dx)
    local score=forward+side*2.1
    if score<bestScore then bestScore=score;bestIndex=i end
   end
  end
 end
 if bestIndex then
  self.focus=bestIndex
  if self.screen=='collection' and self.trophyFocusIndices then
   self.trophyIndex=self.trophyFocusIndices[bestIndex] or self.trophyIndex
  end
  return true
 end
 return false
end
function Retro:activateFocus()
 self:ensureFocus()
 local b=self.focus and self.buttons[self.focus]
 if not b then return false end
 b.fn()
 -- A tela pode ter mudado: descartar o destaque antigo.
 if self.focusScreen~=self.screen then self.focus=nil end
 return true
end
function Retro:draw()
 local gw,gh=love.graphics.getDimensions()
 -- Usar toda a altura/largura disponivel inclusive em telas fracionarias:
 -- 468x858 deve renderizar ~468px de largura, nao apenas 240px.
 -- Filtros nearest das texturas mantem pixels definidos. Escala inteira
 -- surge naturalmente em 480x640 e 720x960; sem barras adicionais.
 self.scale=math.min(gw/W,gh/H)
 self.ox=math.floor((gw-W*self.scale)/2);self.oy=math.floor((gh-H*self.scale)/2)
 love.graphics.clear(.04,.03,.10,1)
 self.buttons={};self.fishHits={};self.softkeys={}
 love.graphics.push();love.graphics.translate(self.ox,self.oy);love.graphics.scale(self.scale)
 love.graphics.setFont(self.font)
 bitmapFont=self.bitmapFont
 if self.screen=='intro_oberon' or self.screen=='intro_splash' then
   local intro=self.images[self.screen=='intro_oberon' and 'oberon' or 'splash']
   if intro then rgb(255,255,255);love.graphics.draw(intro,0,0) end
  elseif self.screen=='intro_sound' then self:introSound()
  elseif self.screen=='title' then self:title()
 elseif self.screen=='confirm' then self:confirm()
 elseif self.screen=='tank' or self.screen=='detail' then self:drawTank()
 elseif self.screen=='pause' then self:pause()
 elseif self.screen=='settings' then self:settings()
 elseif self.screen=='about' then self:about()
 elseif self.screen=='actions' then self:drawActions()
 elseif self.screen=='move' then self:drawMove()
 elseif self.screen=='treat' then self:drawTreat()
 elseif self.screen=='shop' then self:shop()
 elseif self.screen=='research' then self:research()
 elseif self.screen=='collection' then self:collection()
 elseif self.screen=='stats' then self:statistics()
 elseif self.screen=='help' then self:help()
 end
 self:drawFocus()
 if self.toastTime>0 then
  fill(10,263,220,23,46,23,71,.95)
  fontText(self.toast:sub(1,52),14,268,212,'center',{251,229,153})
 end
 love.graphics.pop()
end
function Retro:press(px,py)
 if self.screen=='intro_oberon' or self.screen=='intro_splash' then return false end
 local x=(px-self.ox)/self.scale
 local y=(py-self.oy)/self.scale
 if x<0 or x>=W or y<0 or y>=H then return false end
 -- UI controls must take precedence over fish sprites at overlapping edges.
 -- Otherwise a fish near a softkey can intercept a MENU or SELECT tap.
 for i=#self.buttons,1,-1 do
  local b=self.buttons[i]
  if b.role~='tray' and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
   self.focus=i;self.focusScreen=self.screen
   b.fn();return true
  end
 end
 if self.screen=='tank' then
  local closest,best=nil,math.huge
  for _,hit in ipairs(self.fishHits) do
   local dx,dy=x-hit.x,y-hit.y
   local distance=dx*dx+dy*dy
   if math.abs(dx)<(hit.rx or 26) and math.abs(dy)<(hit.ry or 16) and distance<best then
    closest,best=hit,distance
   end
  end
  if closest then
   self.selected=closest.id;self.screen='detail'
   for i,f in ipairs(self.g.s.tanks[self.room]) do
    if f.id==closest.id then self.browseIndex=i;break end
   end
   return true
  end
 end
 -- The isolation tray is a background target, not a HUD command.
 -- Select a fish first; only empty tray space switches rooms.
 for i=#self.buttons,1,-1 do
  local b=self.buttons[i]
  if b.role=='tray' and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
   b.fn();return true
  end
 end
 return false
end
function Retro:key(k)
 if self.screen=='title' then
  local step=({up=-1,left=-1,['2']=-1,['4']=-1,kp2=-1,kp4=-1,
   down=1,right=1,['8']=1,['6']=1,kp8=1,kp6=1})[k]
  if step then
   self.welcomeIndex=math.max(1,math.min(#self:titleEntries(),(self.welcomeIndex or 1)+step))
   self.focus=nil;return
  end
  if k=='5' or k=='kp5' or k=='return' or k=='kpenter' or k=='space' then
   local selected=self:titleEntries()[self.welcomeIndex or 1]
   if selected then selected[2]() end
   self.focus=nil;return
  end
 end
 if self.screen=='intro_oberon' or self.screen=='intro_splash' then return end
 -- A tecla de retorno equivale ao softkey direito (NO) no prompt Java.
 if self.screen=='intro_sound' and (k=='escape' or k=='back') then
  self:chooseIntroSound(false);return
 end
 -- Softkeys classicas esquerda/direita do celular, equivalentes a F1/F2
 -- no teclado de PC. So acionam comandos visiveis e habilitados.
 if k=='f1' or k=='f2' then
  local soft=self.softkeys and self.softkeys[k=='f1' and 'left' or 'right']
  if soft and soft.fn and not soft.disabled then
   soft.fn();self.focus=nil;return
  end
  return
 end
 -- 2/4/6/8 e 5 correspondem ao teclado direcional J2ME.
 -- Em tela de peixe os direcionais ainda percorrem peixes (abaixo).
 if self.screen~='tank' and self.screen~='detail' then
  local direction={up={0,-1},down={0,1},left={-1,0},right={1,0},
   ['2']={0,-1},['8']={0,1},['4']={-1,0},['6']={1,0},
   kp8={0,1},kp2={0,-1},kp4={-1,0},kp6={1,0}}
  local dir=direction[k]
  if dir then self:moveFocus(dir[1],dir[2]);return end
  if k=='5' or k=='kp5' or k=='return' or k=='kpenter' or k=='space' then
   if self:activateFocus() then return end
  end
 end
 -- Navegacao classica dos aparelhos Java: 4/6 (anterior/proximo),
 -- 2/8 para percorrer e 5 para selecionar. Mouse e toque continuam.
 if self.screen=='detail' and (k=='left' or k=='right' or k=='up' or k=='down' or k=='4' or k=='6' or k=='2' or k=='8' or k=='kp4' or k=='kp6' or k=='kp2' or k=='kp8') then
  self:browseFish((k=='left' or k=='up' or k=='4' or k=='2' or k=='kp4' or k=='kp2') and -1 or 1)
  return
 end
 if self.screen=='tank' and (k=='f' or k=='space' or k=='5' or k=='kp5' or k=='return' or k=='kpenter') then
  self:beginBrowse();return
 end
 if self.screen=='detail' and (k=='5' or k=='kp5' or k=='return' or k=='kpenter' or k=='space') then
  self.screen='actions';return
 end
 if (k=='escape' or k=='back') and (self.screen=='shop' or self.screen=='research') then
  self:leaveUtility();return
 end
 if k=='escape'  or k=='back' then
  local back={title='title',confirm=self.confirmFrom or 'title',tank='pause',detail='tank',pause='tank',
   settings=self.from or 'title',actions='detail',move='actions',treat='actions',
   shop='pause',research='pause',collection='pause',about=self.from or 'title',
   stats='pause',help='pause'}
  self.screen=back[self.screen] or 'title'
  if self.screen=='tank' then self.selected=nil end
 elseif k=='return' or k=='kpenter' then
  if self.screen=='title' and self.hasSave then self.screen='tank'
  elseif self.screen=='detail' then self.screen='actions' end
 end
end
return Retro
