-- V41: SELECT on fish details must behave consistently on J2ME and desktop keys.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local game=Game.new(411)
local view=Retro.new(game,true)
local first=assert(game.s.tanks.main[1])
for _,key in ipairs({'5','kp5','return','kpenter','space'}) do
 view.screen='detail';view.room='main';view.selected=first.id
 view:key(key)
 assert(view.screen=='actions','SELECT from fish details failed: '..key)
 assert(view.selected==first.id,'SELECT unexpectedly changed fish: '..key)
end
for _,key in ipairs({'escape','back'}) do
 view.screen='actions';view.selected=first.id
 view:key(key)
 assert(view.screen=='detail','actions BACK failed: '..key)
 assert(view.selected==first.id,'actions BACK lost selected fish: '..key)
end
print('OK v41: detail SELECT and return controls')
