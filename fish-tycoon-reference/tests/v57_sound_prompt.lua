-- V57: prompt de som do estado 34 do JAR antes do splash.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local noop=function()end
love={graphics={
 getDimensions=function()return 480,640 end,
 clear=noop,push=noop,pop=noop,translate=noop,scale=noop,
 setFont=noop,setColor=noop,rectangle=noop,printf=noop,draw=noop,
}}
local function fresh(sound)
 local v=Retro.new({s={}},true)
 v.font={};v.soundEnabled=sound
 v.images.oberon={name='oberon'}
 v.images.splash={name='splash'}
 v:beginIntro()
 assert(not v:isPlaying())
 v:update(3.1)
 assert(v.screen=='intro_sound' and not v:isPlaying())
 v:draw()
 assert(v.softkeys.left.label=='YES' and v.softkeys.right.label=='NO')
 return v
end

-- YES preserves already enabled sound; no unnecessary toggle or save.
local yes=fresh(true)
local toggles=0
yes.onSound=function()
 toggles=toggles+1;yes.soundEnabled=not yes.soundEnabled
 return yes.soundEnabled
end
yes:key('f1')
assert(yes.screen=='intro_splash' and yes.soundEnabled and toggles==0)
yes:update(3)
assert(yes.screen=='title' and not yes:isPlaying())

-- NO updates the actual sound adapter once, before Splash.
local no=fresh(true)
local changes=0
no.onSound=function()
 changes=changes+1;no.soundEnabled=not no.soundEnabled
 return no.soundEnabled
end
no:key('f2')
assert(no.screen=='intro_splash' and not no.soundEnabled and changes==1)
assert(not no:chooseIntroSound(true),'sound prompt cannot be answered twice')
assert(changes==1)

-- ESC follows the Java right softkey (NO), not a shortcut to menu.
local back=fresh(true)
back:key('escape')
assert(back.screen=='intro_splash' and back.soundEnabled==false)

-- Sound already muted can be enabled using YES.
local enable=fresh(false)
enable.onSound=function() enable.soundEnabled=true;return true end
enable:press(enable.ox+30*enable.scale,enable.oy+309*enable.scale) -- bottom-left softkey
assert(enable.screen=='intro_splash' and enable.soundEnabled)

-- Missing Splash goes straight to title after the prompt.
local partial=Retro.new({s={}},false)
partial.images.oberon={name='oberon'};partial.font={}
partial:beginIntro();partial:update(3)
assert(partial.screen=='intro_sound')
partial:chooseIntroSound(false)
assert(partial.screen=='title')

print('OK v57: JAR sound question, YES/NO/ESC and sound adapter')
