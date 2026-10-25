-- V50: tank backgrounds must not silently use art from another room.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local calls={}
love={graphics={
 setColor=function()end,
 draw=function(img)calls[#calls+1]=img.name end,
 rectangle=function(mode)if mode=='fill' then calls[#calls+1]='fallback' end end,
}}
local view=Retro.new({s={}},true)
local function image(name)return {name=name}end
view.assets.images={tanktop=image('tanktop'),tank1=image('tank1'),tank3=image('tank3')}
view.images.gameMenuTank=image('gameMenuTank')
local function background(room)
 calls={};view:background(room)
 return table.concat(calls,',')
end
local main=background('main')
assert(main:find('tank1',1,true))
local second=background('second')
assert(not second:find('tank1',1,true),'tank 2 reused tank 1 artwork')
assert(second:find('fallback',1,true),'missing tank 2 needs neutral background')
local sale=background('sale')
assert(sale:find('tank3',1,true) and not sale:find('tank1',1,true))
local isolation=background('isolation')
assert(isolation:find('gameMenuTank',1,true) and not isolation:find('tank1',1,true))
print('OK v50: correct tank art and honest fallback')
