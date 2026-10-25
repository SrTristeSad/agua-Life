-- V59 / V60: JAR WELCOME is a five-row centered, text-measured scroll list.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local noop=function()end
love={graphics={
 getDimensions=function()return 480,640 end,
 newFont=function()return {setFilter=noop,getWidth=function(_,s)return #s*6 end}end,
 setFont=noop,setColor=noop,rectangle=noop,draw=noop,clear=noop,
 push=noop,pop=noop,translate=noop,scale=noop,printf=noop,
}}
local function inspect(hasSave)
 local v=Retro.new(Game.new(5900),hasSave)
 v.font=love.graphics.newFont()
 v:draw()
 local entries=v:titleEntries()
 local layout=v:welcomeLayout(entries)
 assert(layout.visible==5,'Original mode 1 shows at most five rows')
 assert(#v.buttons==7,'Five rows plus two softkeys')
 assert(layout.x+math.floor(layout.w/2)==120,'menu horizontally centered')
 assert(layout.y==100,'five rows should be centered around y=160')
 assert(layout.w<178,'must not reuse 178px placeholder buttons')
 for i=1,5 do
  local b=v.buttons[i]
  assert(b.role=='welcome' and b.x==layout.x and b.w==layout.w)
  assert(b.y==layout.y+(i-1)*layout.step and b.h==20)
  assert(b.y+b.h<299 and type(b.fn)=='function')
 end
 assert(v.buttons[6].y==299 and v.buttons[7].y==299)
 return v,layout
end
local with,layout=inspect(true)
local noSave,withoutLayout=inspect(false)
assert(withoutLayout.y==layout.y,'fixed 5-row window does not depend on total entries')
local width=layout.w
with.font={getWidth=function(_,s)return #s*8 end}
assert(with:welcomeLayout(with:titleEntries()).w>=width)
with.font={getWidth=function(_,s)return #s*6 end}
local b=with.buttons[2]
assert(with:press(with.ox+(b.x+10)*with.scale,with.oy+(b.y+8)*with.scale))
assert(with.screen=='confirm' and with.confirmFrom=='title')
local options=noSave.buttons[2]
assert(noSave:press(noSave.ox+(options.x+10)*noSave.scale,
 noSave.oy+(options.y+8)*noSave.scale))
assert(noSave.screen=='settings')
-- Font 0 (first imported face) must be used both for measuring and drawing.
local fontStyles,drawStyles={},{}
local face=Retro.new(Game.new(5905),true)
face.font=love.graphics.newFont()
face.bitmapFont={
 measure=function(_,label,style)fontStyles[#fontStyles+1]=style;return #label*8 end,
 print=function(_,label,x,y,w,align,style)drawStyles[#drawStyles+1]=style end
}
assert(face:welcomeLayout(face:titleEntries()).w>=layout.w)
face:draw()
assert(#fontStyles>=8 and #drawStyles==5,'measure all but draw only five')
for _,style in ipairs(fontStyles) do assert(style==1) end
for _,style in ipairs(drawStyles) do assert(style==1) end
print('OK v59/v60: five visible rows, text sizing, font, touch, softkeys')
