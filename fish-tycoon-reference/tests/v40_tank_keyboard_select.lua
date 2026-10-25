-- V40: primary J2ME SELECT key must open the fish detail screen.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local game=Game.new(401)
local v=Retro.new(game,true)
local fish=game.s.tanks.main
assert(#fish>0,'fixture requires a fish in the first tank')
for _,key in ipairs({'5','kp5','return','kpenter','space','f'}) do
 v.screen='tank';v.room='main';v.selected=nil;v.browseIndex=1
 v:key(key)
 assert(v.screen=='detail','tank SELECT key '..key..' did not open fish')
 assert(v.selected==fish[1].id,'wrong fish for '..key)
end
v.screen='detail'
v:key('5')
assert(v.screen=='actions','SELECT key in details must open actions')
print('OK v40: six tank selection keys and fish actions')
