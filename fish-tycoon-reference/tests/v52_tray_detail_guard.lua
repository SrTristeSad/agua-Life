-- V52: tray navigation is available in tank view, not fish details.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local game=Game.new(5200)
local view=Retro.new(game,true)
view.scale=1;view.ox=0;view.oy=0
view.room='isolation';view.screen='detail'
view.selected=game.s.tanks.main[1].id
view.buttons={};view:tray()
assert(#view.buttons==0,'tray incorrectly interactive in details')
assert(not view:press(165,310),'tray accepted input on details')
assert(view.room=='isolation' and view.screen=='detail')
view.screen='tank';view.selected=nil;view.buttons={};view:tray()
assert(#view.buttons==1 and view.buttons[1].role=='tray','tank tray missing')
assert(view:press(165,310),'empty tray touch ignored')
assert(view.room=='main' and view.screen=='tank')
print('OK v52: tray interactive only in normal tank view')
