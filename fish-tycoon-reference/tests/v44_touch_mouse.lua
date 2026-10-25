-- V44: Android touch must trigger one action, not a duplicate mouse action.
package.path='./?.lua;./?/init.lua;'..package.path
for _,name in ipairs({'core.game','core.storage','ui.view','ui.retro','core.audio','core.offline_report'}) do
 package.loaded[name]={}
end
local now=10
love={timer={getTime=function()return now end}}
dofile('main.lua')
local clicks={}
local fake={press=function(_,x,y)clicks[#clicks+1]={x,y} end}
local found=false
for i=1,20 do
 local name=debug.getupvalue(love.mousepressed,i)
 if not name then break end
 if name=='view' then debug.setupvalue(love.mousepressed,i,fake);found=true;break end
end
assert(found,'could not inject view into mouse handler')
love.mousepressed(25,50,1,true)
assert(#clicks==0,'synthetic Android mouse event duplicated touch')
love.mousepressed(25,50,1,false)
assert(#clicks==1,'normal desktop mouse must be accepted')
love.mousepressed(25,50,2,false)
assert(#clicks==1,'right-click must not activate buttons')
love.touchpressed(1,33,44)
assert(#clicks==2 and clicks[2][1]==33 and clicks[2][2]==44,'touch should use pixel positions')
love.mousepressed(33,44,1,true)
assert(#clicks==2,'synthetic mouse after touch must be ignored')
print('OK v44: native pixel touches, synthetic mouse ignored')
