-- V43: HUD commands take priority when overlapping a swimming fish.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local game=Game.new(4300)
local view=Retro.new(game,true)
local fish=assert(game.s.tanks.main[1])
view.screen='tank';view.room='main'
view.scale=1;view.ox=0;view.oy=0
local taps=0
view.buttons={{x=177,y=299,w=63,h=21,fn=function()taps=taps+1;view.screen='pause' end}}
view.fishHits={{id=fish.id,x=195,y=301,rx=26,ry=16}}
assert(view:press(195,301),'HUD tap not accepted')
assert(taps==1 and view.screen=='pause' and view.selected==nil,'fish intercepted softkey')
view.screen='tank';view.buttons={}
view.fishHits={{id=fish.id,x=110,y=120,rx=26,ry=16}}
assert(view:press(110,120),'fish tap not accepted')
assert(view.screen=='detail' and view.selected==fish.id,'fish selection broken')
assert(not view:press(-1,120),'out-of-bounds tap was accepted')
print('OK v43: HUD priority, fish selection and bounds')
