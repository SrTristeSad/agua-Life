-- V51: fish inside isolation tray must win over tray navigation.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local game=Game.new(5100)
local fish=assert(game.s.tanks.main[1])
local view=Retro.new(game,true)
view.scale=1;view.ox=0;view.oy=0;view.room='isolation';view.screen='tank'
local tray=0
view.buttons={}
view:hit(69,272,102,47,function() tray=tray+1;view.room='main' end,'tray')
view.fishHits={{id=fish.id,x=96,y=284,rx=15,ry=8}}
-- This fixture exercises the hit-order independent of the game move rules.
-- The selected fish must exist in the active room.
assert(game:move(fish.id,'isolation'))
assert(view:press(96,284),'tap on isolated fish was ignored')
assert(view.screen=='detail' and view.room=='isolation' and view.selected==fish.id)
assert(tray==0,'tray swallowed a fish tap')
view.screen='tank';view.selected=nil
assert(view:press(165,310),'empty tray press ignored')
assert(tray==1 and view.room=='main','empty tray did not navigate')
-- HUD still precedes both fish and tray.
view.screen='tank';view.room='isolation';tray=0
view.buttons={}
view:hit(69,272,102,47,function()tray=tray+1 end,'tray')
local hud=0
view:hit(85,274,25,20,function()hud=hud+1 end)
assert(view:press(96,284))
assert(hud==1 and tray==0 and view.selected==nil,'HUD lost priority')
print('OK v51: HUD > fish > tray; isolation fish accessible')
