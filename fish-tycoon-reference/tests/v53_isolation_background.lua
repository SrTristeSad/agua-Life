-- V53: never substitute main-tank art for missing isolation background.
package.path='./?.lua;./?/init.lua;'..package.path
local Assets=require('core.assets')
local draws={}
love={graphics={
 setColor=function()end,
 draw=function(img)draws[#draws+1]=img.name end,
}}
local assets=Assets.new()
local function img(name)
 return {name=name,getDimensions=function()return 98,46 end,
         getWidth=function()return 98 end,getHeight=function()return 46 end}
end
assets.images={tank1=img('tank1'),tanktop=img('tanktop')}
assert(not assets:tankBackground('isolation',0,0,240,320),
 'isolation must not use tank1 as substitute')
assert(#draws==0,'missing isolation sprite unexpectedly drew a background')
assert(assets:tankBackground('main',0,0,240,320))
assert(draws[1]=='tanktop' and draws[2]=='tank1','main tank rendering changed')
draws={}
assets.images.isolation_tank=img('isolation_tank')
assert(assets:tankBackground('isolation',0,0,240,320))
assert(#draws==1 and draws[1]=='isolation_tank',
 'isolation background should use its own resource only')
print('OK v53: isolated tank has no cross-room artwork fallback')
