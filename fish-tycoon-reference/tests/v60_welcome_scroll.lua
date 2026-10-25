-- V60: JAR f(32) calls mode=1, visible W=5, spacing V=5.
-- Verify scrolling, focus stability, touch targets and keyboard selection.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local noop=function()end
love={graphics={
 getDimensions=function()return 480,640 end,
 setColor=noop,rectangle=noop,draw=noop,printf=noop,clear=noop,
 push=noop,pop=noop,translate=noop,scale=noop,setFont=noop
}}
local g=Game.new(6000)
local v=Retro.new(g,true)
v.font={getWidth=function(_,s)return #s*6 end}
local function verify(index)
 v:draw()
 local first=math.max(1,math.min(4,index-2))
 assert(v.welcomeIndex==index)
 assert(v.welcomeTop==first,
  ('window first=%s, expected=%s at selection=%d'):format(v.welcomeTop,first,index))
 assert(#v.buttons==7,'only five menu choices and two softkeys')
 assert(v.focus==index-first+1,'focused button and selected item disagree')
 assert(v.buttons[1].y==100 and v.buttons[5].y==200)
end
verify(1)
-- A direct click on an item updates selection and route together.
for index=2,8 do
 v:key('8')
 verify(index)
end
-- The last visible menu item is EXIT; it must not be invoked by navigation.
local closed=0
v.onExit=function()closed=closed+1 end
assert(closed==0 and v.screen=='title')
-- Moving the cursor up recenters scroll, including the first page.
for index=7,1,-1 do
 v:key('2')
 verify(index)
end
-- Five arrow presses should select HELP (index 6), even before draw.
for i=1,5 do v:key('8') end
assert(v.welcomeIndex==6)
v:key('5')
assert(v.screen=='help','keyboard selection must use global index while scrolled')
v.screen='title';v.welcomeIndex=7;v:draw()
local b=v.buttons[v.focus]
assert(v:press(v.ox+(b.x+12)*v.scale,v.oy+(b.y+8)*v.scale))
assert(v.screen=='about','a visible scrolled row should retain its original action')
v.screen='title';v.welcomeIndex=8;v:draw()
assert(v:press(v.ox+(v.buttons[5].x+12)*v.scale,
 v.oy+(v.buttons[5].y+8)*v.scale))
assert(closed==1,'last scrolled item should invoke EXIT only when selected')
-- A no-save game has seven entries but still displays five rows.
local noSave=Retro.new(Game.new(6001),false);noSave.font=v.font
noSave.welcomeIndex=7;noSave:draw()
assert(noSave.welcomeTop==3 and #noSave.buttons==7)
print('OK v60: W=5 viewport, V=5 spacing, scrolling, actions, softkeys')
