local Game=require('core.game')
local Storage=require('core.storage')
local LegacyView=require('ui.view')
local Retro=require('ui.retro')
local Audio=require('core.audio')
local OfflineReport=require('core.offline_report')
local game,view,music,nativeSmoke
local autosave=0
local suppressMouseUntil=0
local focused=true

local function save()
 return Storage.save(game)
end

function love.load()
 if os.getenv('FISH_RETRO_SMOKE')=='1' then
  game=Game.new(1900)
  view=Retro.new(game,true);view:init()
  nativeSmoke=require('core.retro_smoke').new(view)
  return
 end
 if os.getenv('FISH_NATIVE_SMOKE')=='1' then
  -- Teste isolado: nao le nem grava a partida do jogador.
  game=Game.new(1600)
  for i=5,18 do
   assert(game:addFish('main',((i-1)%21)+1,((i*3-1)%21)+1,20))
  end
  view=LegacyView.new(game);view:init()
  nativeSmoke=require('core.native_smoke').new(view)
  return
 end
 local loaded,err=Storage.load()
 game=loaded or Game.new()
 local before=loaded and OfflineReport.snapshot(game) or nil
 local passed=loaded and game:offline(os.time()) or 0
 local report=OfflineReport.build(before,game,passed)
 view=Retro.new(game,loaded~=nil);view:init()
 view.onSave=save
 view.onNewGame=function()
  local nextGame=Game.new()
  nextGame.s.sound_enabled=music and music.enabled~=false
  local ok,msg=Storage.startNewGame(nextGame)
  if not ok then return false,msg end
  game=nextGame;autosave=0
  return true,nil,nextGame
 end
 music=Audio.new();music:init()
 if game.s.sound_enabled==false then music:toggle() end
 view.soundEnabled=music.enabled
 view.onSound=function()
  local enabled=music:toggle()
  game.s.sound_enabled=enabled
  if view.hasSave then save() end
  return enabled
 end
 if passed>=60 then view.offlineReport=report end
 if err and loaded then view:notify(err)
 elseif err and err~='Sem salvamento anterior' then view:notify(err) end
 -- Somente o arranque normal exibe as telas originais.
 -- Capturas e testes nativos continuam com estado inicial controlado.
 view:beginIntro()
end

function love.update(dt)
 if nativeSmoke then view:update(math.min(dt,1));return end
 if not focused then return end
 dt=math.min(dt,1)
 if view.isPlaying==nil or view:isPlaying() then
  game:advance(dt*game.s.game_speed)
 end
 view:update(dt)
 if music then
  music:update((view.screen=='tank' or view.screen=='detail') and 'tank' or 'menu',view.room)
 end
 if view.isPlaying==nil or view:isPlaying() then autosave=autosave+dt end
 if autosave>=12 then
  autosave=0
  save()
 end
end

function love.draw()
 view:draw()
 if nativeSmoke then nativeSmoke:afterDraw() end
end
function love.mousepressed(x,y,button,istouch)
 if button~=1 then return end
 -- LÖVE 11.x can generate a mouse event from the same touch.
 -- Ignore that synthetic mouse press, even if it arrives after the timer guard.
 if istouch then return end
 if love.timer.getTime()<suppressMouseUntil then return end
 view:press(x,y)
end
function love.touchpressed(id,x,y)
 suppressMouseUntil=love.timer.getTime()+.5
 view:press(x,y)
end
function love.keypressed(key) view:key(key) end
function love.focus(f)
 focused=f
 if not f then if music then music:pause() end;if view.hasSave==nil or view.hasSave then save() end
 else
  local before=OfflineReport.snapshot(game)
  local passed=game:offline(os.time())
  if passed>=60 then
   local report=OfflineReport.build(before,game,passed)
   if view.showOfflineReport then view:showOfflineReport(report) else view.offlineReport=report;view:notify('OFFLINE PROGRESS SAVED') end
  end
 end
end
function love.quit()
 if not nativeSmoke and (view.hasSave==nil or view.hasSave) then save() end
end
