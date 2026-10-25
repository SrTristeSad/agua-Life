package.path='./?.lua;./?/init.lua;'..package.path
local images,quads,draws=0,0,0
local mockimg={}
function mockimg:setFilter() end
function mockimg:getDimensions() return 170,532 end
function mockimg:getWidth() return 240 end
function mockimg:getHeight() return 154 end
love={graphics={},audio={}}
function love.graphics.newImage(path)
 assert(path:match('^assets/original/'))
 local f=assert(io.open(path,'rb'))
 local head=f:read(8);f:close()
 assert(head=='\137PNG\r\n\26\n',path)
 images=images+1
 return mockimg
end
function love.graphics.newQuad(x,y,w,h,sw,sh)
 assert(x>=0 and y>=0 and w>0 and h>0 and sw>=w and sh>=h)
 quads=quads+1
 return {x=x,y=y,w=w,h=h}
end
for _,k in ipairs({'setColor','push','pop','translate','scale'}) do love.graphics[k]=function() end end
love.graphics.draw=function() draws=draws+1 end
local function track() return {setLooping=function() end,setVolume=function() end,play=function() end,stop=function() end} end
love.audio.newSource=function(path,kind)
 assert(path:match('^assets/audio/') and kind=='stream')
 local f=assert(io.open(path,'rb'))
 local head=f:read(4);f:close()
 assert(head=='OggS',path)
 return track()
end
local Assets=require('core.assets')
local view=Assets.new();assert(view:init())
assert(images==8,images) -- fish/fins/tank1/tank2/tank3/tanktop/isolation/menutank
assert(quads==104,quads) -- 21 corpos * 2 + 20 barbatanas * 2 + 1 filhote + 21 jovens
for body=1,21 do
 for fin=1,21 do
  assert(view:drawFish({body=body,tail=fin,age=20},100,100,1,body%2==0 and 1 or -1))
 end
end
assert(draws>=441)
for body=1,21 do
 assert(view:drawFish({body=body,tail=1,age=0},100,100,1,1))
 assert(view:drawFish({body=body,tail=1,age=10},100,100,1,1))
end
assert(view:drawFish({body=20,tail=20,age=20},100,100,1,1))
assert(view:tankBackground('second',1,1,374,331))
assert(view:tankBackground('sale',1,1,374,331))
local Audio=require('core.audio')
local a=Audio.new();a:init();a:update('tank','main');assert(a.current=='tankTune1')
a:update('tank','sale');assert(a.current=='sale')
assert(not a:toggle());a:update('shop','main');assert(a.current==nil)
assert(a:toggle());a:update('shop','main');assert(a.current=='menu')
print('Recursos OK: 8 imagens, 104 quads, 441 combinacoes, 5 OGG, troca de faixas.')
