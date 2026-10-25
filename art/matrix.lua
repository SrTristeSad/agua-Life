-- agua-Life | Matriz RGBA fornecida pelo usuário: 441 peixes e sete mágicos.
-- O LÖVE recorta a textura em regiões (Quads) e anima juntas em tempo real.
-- Nenhuma releitura procedural da arte: as cores/pixels são os do atlas.
local M={}
local lg=love.graphics
local JSON=require('game.json')
local ATLAS='assets/fish/matrix/atlas_441.png'
local META='assets/fish/matrix/atlas_441.json'
local CW,CH=128,64
local MW,MH=384,136
local AW,AH=2688,1480
local IMG=nil
local attempted=false
local metadata=nil
local cache={}
local order={'tail','dorsal','ventral','body','headTop','headBottom'}
local magic={{21,17},{15,15},{12,12},{11,10},{6,9},{14,7},{8,8}}
M.magicPairs=magic
M.source=ATLAS
M.tileSize={CW,CH}
M.magicTileSize={MW,MH}

local function index(spec)
 if type(spec)~='table' or type(spec.body)~='number' or type(spec.fin)~='number'
    or spec.body%1~=0 or spec.fin%1~=0 or spec.body<1 or spec.body>21
    or spec.fin<1 or spec.fin>21 then return nil end
 for i,p in ipairs(magic) do
  if spec.body==p[1] and spec.fin==p[2] then return 441+i,true end
 end
 return (spec.body-1)*21+spec.fin,false
end
M.getIndex=index
function M.available()
 if IMG then return true end
 if attempted then return false end
 attempted=true
 if not love.filesystem.getInfo(ATLAS,'file') then return false end
 local ok,ret=pcall(lg.newImage,ATLAS,{mipmaps=false})
 if not ok then return false end
 if ret:getWidth()~=AW or ret:getHeight()~=AH then ret:release();return false end
 ret:setFilter('linear','linear')
 IMG=ret
 if love.filesystem.getInfo(META,'file') then
  local data=love.filesystem.read(META)
  local success,parsed=pcall(JSON.decode,data)
  if success and type(parsed)=='table' then metadata=parsed end
 end
 return true
end
local function tile(indexValue,magicFlag)
 if magicFlag then return (indexValue-442)*MW,21*CH,MW,MH end
 local num=indexValue-1
 return (num%21)*CW,math.floor(num/21)*CH,CW,CH
end
local function measure(indexValue,mag,w,h)
 if metadata then
  local b
  if mag then b=metadata.magic_bounds and metadata.magic_bounds[indexValue-441]
  else
   local row=math.floor((indexValue-1)/21)+1
   local col=(indexValue-1)%21+1
   b=metadata.bounds and metadata.bounds[row] and metadata.bounds[row][col]
  end
  if type(b)=='table' and #b==4 then return b end
 end
 return {w*.24,h*.15,w*.75,h*.86}
end
local function rectangleQuad(tileX,tileY,box)
 local x,y,ex,ey=box[1],box[2],box[3],box[4]
 x=math.floor(math.max(0,x));y=math.floor(math.max(0,y))
 ex=math.ceil(math.max(x+1,ex));ey=math.ceil(math.max(y+1,ey))
 return {q=lg.newQuad(tileX+x,tileY+y,ex-x,ey-y,AW,AH),x=x,y=y}
end
local function fragments(indexValue,isMagic)
 local existing=cache[indexValue]
 if existing then return existing end
 local tx,ty,w,h=tile(indexValue,isMagic)
 local b=measure(indexValue,isMagic,w,h)
 local minX,minY,maxX,maxY=b[1],b[2],b[3],b[4]
 local spanX=maxX-minX;local spanY=maxY-minY
 local cutX=math.floor(minX+spanX*.38)
 local headX=math.floor(minX+spanX*.77)
 local top=math.floor(minY+spanY*.32)
 local bottom=math.floor(minY+spanY*.74)
 local boxes={
  tail={0,0,cutX+2,h},
  dorsal={cutX-1,0,headX+1,top+2},
  ventral={cutX-1,bottom-2,headX+1,h},
  body={cutX-1,top,w,bottom},
  headTop={headX,0,w,top+2},
  headBottom={headX,bottom-2,w,h}
 }
 local regions={}
 for key,rect in pairs(boxes) do regions[key]=rectangleQuad(tx,ty,rect) end
 local centers={tail={cutX,(minY+maxY)/2},
  dorsal={minX+spanX*.58,top},
  ventral={minX+spanX*.58,bottom}}
 existing={w=w,h=h,magic=isMagic,regions=regions,pivots=centers}
 cache[indexValue]=existing
 return existing
end
local function drawRegion(region)
 lg.draw(IMG,region.q,region.x,region.y)
end
local function rotatePart(region,pivot,radians)
 lg.push()
 lg.translate(pivot[1],pivot[2]);lg.rotate(radians)
 lg.translate(-pivot[1],-pivot[2])
 drawRegion(region)
 lg.pop()
end
function M.drawStatic(spec,x,y,scale,direction,time)
 local id,isMagic=index(spec)
 if not id or not M.available() then return false end
 local tileX,tileY,w,h=tile(id,isMagic)
 local parts=fragments(id,isMagic)
 if not parts.whole then parts.whole=lg.newQuad(tileX,tileY,w,h,AW,AH) end
 lg.push('all')
 lg.setColor(1,1,1,1)
 lg.translate(x,y)
 local s=(scale or 1)*(isMagic and .345 or 1)
 lg.scale((direction or 1)*s,s)
 lg.rotate(math.sin((time or 0)*2.8)*.012)
 lg.draw(IMG,parts.whole,-w*.5,-h*.5)
 lg.pop()
 return true
end
function M.draw(spec,x,y,scale,direction,time,health,joints)
 local id,isMagic=index(spec)
 if not id or not M.available() then return false end
 local parts=fragments(id,isMagic)
 local t=time or 0
 local ill=health and health.disease and .44 or 1
 local rate=health and health.disease and 1.5 or 2.7
 local wv=t*rate
 local s=(scale or 1)*(isMagic and .345 or 1)
 lg.push('all')
 lg.setColor(1,1,1,1)
 lg.translate(x,y+math.sin(wv*.8)*1.5*s*ill)
 lg.scale((direction or 1)*s,s)
 lg.rotate(math.sin(wv)*.013*ill)
 lg.translate(-parts.w*.5,-parts.h*.5)
 rotatePart(parts.regions.tail,parts.pivots.tail,math.sin(wv)*.17*ill)
 rotatePart(parts.regions.dorsal,parts.pivots.dorsal,math.sin(wv+.7)*.045*ill)
 rotatePart(parts.regions.ventral,parts.pivots.ventral,math.sin(wv+1.3)*.072*ill)
 drawRegion(parts.regions.body)
 drawRegion(parts.regions.headTop)
 drawRegion(parts.regions.headBottom)
 if joints then
  lg.setLineWidth(1.2)
  for _,p in pairs(parts.pivots) do
   lg.setColor(1,.86,.28,.95)
   lg.circle('line',p[1],p[2],3.2)
  end
 end
 lg.pop()
 return true
end
function M.drawPart(spec,part,x,y,width,height)
 local id,isMagic=index(spec)
 if not id or not M.available() then return false end
 local p=fragments(id,isMagic)
 local name=part
 if part=='body' then name='body' end
 if not p.regions[name] then return false end
 lg.push('all')
 lg.setColor(1,1,1,1)
 local s=math.min((width or 80)/p.w,(height or 80)/p.h)
 lg.translate(x+((width or 80)-p.w*s)*.5,y+((height or 80)-p.h*s)*.5)
 lg.scale(s,s)
 if part=='body' then
  drawRegion(p.regions.body)
  drawRegion(p.regions.headTop)
  drawRegion(p.regions.headBottom)
 else
  drawRegion(p.regions[name])
 end
 lg.pop()
 return true
end
function M.clearCache()
 for _,entry in pairs(cache) do
  if entry.whole then entry.whole:release() end
  for _,part in pairs(entry.regions) do part.q:release() end
 end
 cache={}
end
return M