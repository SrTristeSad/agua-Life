-- V42: numeric keypad fish browsing must match classic J2ME 2/8 controls.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local game=Game.new(420)
local view=Retro.new(game,true)
local fish=game.s.tanks.main
assert(#fish>=3,'expected multiple fish in initial tank')
local start=2
for _,key in ipairs({'2','kp2','up','4','kp4','left'}) do
 view.screen='detail';view.room='main';view.selected=fish[start].id;view.browseIndex=start
 view:key(key)
 assert(view.selected==fish[start-1].id,'previous fish failed for '..key)
end
for _,key in ipairs({'8','kp8','down','6','kp6','right'}) do
 view.screen='detail';view.room='main';view.selected=fish[start].id;view.browseIndex=start
 view:key(key)
 assert(view.selected==fish[start+1].id,'next fish failed for '..key)
end
view.screen='detail';view.room='main';view.selected=fish[1].id;view.browseIndex=1
view:key('kp2')
assert(view.selected==fish[#fish].id,'previous fish should wrap around')
view.selected=fish[#fish].id;view.browseIndex=#fish
view:key('kp8')
assert(view.selected==fish[1].id,'next fish should wrap around')
print('OK v42: keypad navigation parity and wraparound')
