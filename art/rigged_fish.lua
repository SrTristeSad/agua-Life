-- agua-Life: arte modular original Azul-Rubi, 320x180, pecas transparentes.
-- Os PNGs sao gerados por scripts/generate_azul_rubi.py
local Rig={}
local pi=math.pi
local ROOT='assets/fish/azul_rubi/'
local WIDTH,HEIGHT,SCALE=320,180,2
local pivots={tail={110,94},dorsal={187,64},pelvic={176,121},
 pectoral={245,104},eye={273,85}}
local bounds={tail={6,12,114,164},dorsal={145,8,230,75},
 pelvic={135,115,204,177},body={94,54,299,137},
 pectoral={187,98,262,150},eye={261,73,287,99}}
local order={'tail','dorsal','pelvic','body','pattern','pectoral','eye'}
local images,quads,attempted={},{},{}
local shader=nil
Rig.pivots=pivots
Rig.bounds=bounds
Rig.order=order
Rig.name='Azul-Rubi'
function Rig.supports(spec)
 return type(spec)=='table' and spec.body==1 and spec.fin==1
  and type(spec.palette)=='number' and spec.palette>=1 and spec.palette<=12
  and type(spec.pattern)=='number' and spec.pattern>=1 and spec.pattern<=6
end
function Rig.pose(t,diseased)
 t=tonumber(t) or 0
 local speed=diseased and .56 or 1
 local wave=t*2.7*speed
 local amp=diseased and .45 or 1
 return {tail=math.sin(wave)*.22*amp,
  dorsal=math.sin(wave+.4)*.068*amp,
  pelvic=math.sin(wave+1.4)*.105*amp,
  pectoral=math.sin(wave*1.6+.7)*.28*amp,
  body=math.sin(wave)*.013*amp,
  bob=math.sin(wave*.8)*1.8*amp,
  blink=(t%7.3)>7.12 and .12 or 1}
end
local function layerName(part,pattern)
 return part=='pattern' and ('pattern_'..tostring(pattern)) or part
end
local function loadImage(name)
 if images[name] then return images[name] end
 if attempted[name] then return nil end
 local path=ROOT..name..'.png'
 if not (love and love.filesystem and love.filesystem.getInfo(path)) then return nil end
 attempted[name]=true
 local ok,ret=pcall(love.graphics.newImage,path,{mipmaps=false})
 if not ok then return nil end
 ret:setFilter('linear','linear');images[name]=ret
 return ret
end
local shaderCode=[[
extern number hueAngle;
vec3 rgb2hsv(vec3 c) {
 vec4 K=vec4(0.0,-0.3333333,0.6666667,-1.0);
 vec4 p=mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g));
 vec4 q=mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));
 number d=q.x-min(q.w,q.y);number e=0.000001;
 return vec3(abs(q.z+(q.w-q.y)/(6.0*d+e)),d/(q.x+e),q.x);
}
vec3 hsv2rgb(vec3 c) {
 vec3 p=abs(fract(c.xxx+vec3(0.,0.6666667,0.3333333))*6.-3.);
 return c.z*mix(vec3(1.),clamp(p-1.,0.,1.),c.y);
}
vec4 effect(vec4 color,Image tex,vec2 textureCoords,vec2 screenCoords) {
 vec4 px=Texel(tex,textureCoords);
 vec3 hsv=rgb2hsv(px.rgb);hsv.x=fract(hsv.x+hueAngle);
 return vec4(hsv2rgb(hsv),px.a)*color;
}
]]
local function getShader(spec)
 local lg=love.graphics
 if shader==false then return nil end
 if not shader then
  local ok,ret=pcall(lg.newShader,shaderCode)
  shader=ok and ret or false
 end
 if shader and shader~=false then
  shader:send('hueAngle',((spec.palette-3)/12)%1)
  return shader
 end
end
function Rig.assetsReady(spec)
 if not Rig.supports(spec) then return false end
 for _,part in ipairs(order) do
  if not loadImage(layerName(part,spec.pattern)) then return false end
 end
 return true
end
local function partDraw(img,joint,angle,blink)
 local lg=love.graphics;lg.push()
 if joint then
  lg.translate(joint[1],joint[2]);lg.rotate(angle or 0)
  if blink and blink~=1 then lg.scale(1,blink) end
  lg.draw(img,-joint[1],-joint[2],0,1/SCALE,1/SCALE)
 else lg.draw(img,0,0,0,1/SCALE,1/SCALE) end
 lg.pop()
end
-- Retorna false quando o DNA pede outro corpo/cauda; renderizador antigo assume.
function Rig.draw(spec,x,y,scale,direction,t,health,showJoints)
 if not Rig.assetsReady(spec) then return false end
 local lg=love.graphics
 local pose=Rig.pose(t,health and health.disease)
 lg.push('all')
 lg.translate(x,y+pose.bob*(scale or 1))
 lg.scale((direction or 1)*(scale or 1),scale or 1)
 lg.rotate(pose.body);lg.translate(-WIDTH/2,-HEIGHT/2)
 local previous=lg.getShader()
 lg.setShader(getShader(spec))
 for _,part in ipairs(order) do
  partDraw(images[layerName(part,spec.pattern)],pivots[part],
   pose[part] or 0,part=='eye' and pose.blink or nil)
 end
 lg.setShader(previous)
 if showJoints then
  for _,xy in pairs(pivots) do
   lg.setColor(1,.9,.38,.85);lg.circle('line',xy[1],xy[2],3)
  end
 end
 lg.pop()
 return true
end
function Rig.drawPart(name,x,y,w,h)
 local img=loadImage(name);local b=bounds[name]
 if not img or not b then return false end
 local lg=love.graphics
 if not quads[name] then
  quads[name]=lg.newQuad(b[1]*SCALE,b[2]*SCALE,
   (b[3]-b[1])*SCALE,(b[4]-b[2])*SCALE,
   WIDTH*SCALE,HEIGHT*SCALE)
 end
 local pw,ph=(b[3]-b[1])*SCALE,(b[4]-b[2])*SCALE
 local ratio=math.min(w/pw,h/ph)
 lg.push('all')
 lg.setColor(1,1,1,1)
 lg.draw(img,quads[name],x+(w-pw*ratio)/2,y+(h-ph*ratio)/2,0,ratio,ratio)
 lg.pop()
 return true
end
return Rig
