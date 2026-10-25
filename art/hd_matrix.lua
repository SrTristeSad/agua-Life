-- agua-Life HD 4K: 441 transparent independent 512x256 sprites + 7 specials.
-- One image per fish. The atlas is only for efficient small catalog thumbnails.
-- No cropping from adjacent cells and no scaling-up from low-resolution source.
local M={}
local lg=love.graphics
local unpack=table.unpack or unpack
local Visual=require('art.dna_visual')
local ROOT='assets/fish/hd/'
local META=ROOT..'manifest.json'
local THUMBS=ROOT..'atlas_4k_rgba.png'
local W,H=512,256
local ATLAS_W,ATLAS_H=4096,2304
local magical={{21,17},{15,15},{12,12},{11,10},{6,9},{14,7},{8,8}}
local cache={}
local tick=0
local limit=48
local atlas,atlasFailed,checked=false,false,false
local atlasQuads={}
M.tileSize={W,H}
M.magicPairs=magical
M.source=ROOT
M.CACHE_LIMIT=limit
local function matching(spec)
 if type(spec)~='table' or type(spec.body)~='number' or
    type(spec.fin)~='number' or spec.body%1~=0 or spec.fin%1~=0 or
    spec.body<1 or spec.body>21 or spec.fin<1 or spec.fin>21 then
  return nil
 end
 for i,p in ipairs(magical) do
  if p[1]==spec.body and p[2]==spec.fin then return 441+i,true end
 end
 return (spec.body-1)*21+spec.fin,false
end
M.getIndex=matching
local function filen(id)
 if id>=442 then return string.format('M%d.png',id-442) end
 local n=id-1
 return string.format('C%02d_F%02d.png',math.floor(n/21)+1,(n%21)+1)
end
function M.available()
 if checked then return not atlasFailed end
 checked=true
 atlasFailed=not (love and love.filesystem and
   love.filesystem.getInfo(META,'file') and love.filesystem.getInfo(THUMBS,'file') and
   love.filesystem.getInfo(ROOT..'sprites/C01_F01.png','file'))
 return not atlasFailed
end
function M.pose(t,health)
 t=tonumber(t) or 0
 local ill=health and health.disease and .48 or 1
 local wv=t*(ill<1 and 1.65 or 2.9)
 return {wave=wv,amplitude=ill,
  tail=math.sin(wv)*23*ill,
  dorsal=math.sin(wv+.72)*6*ill,
  ventral=math.sin(wv+1.21)*7*ill,
  body=math.sin(wv)*.013*ill,
  bob=math.sin(wv*.72)*1.75*ill}
end
local function touchCache(entry)
 tick=tick+1;entry.used=tick
end
local function evict()
 local count=0
 for _ in pairs(cache) do count=count+1 end
 if count<limit then return end
 local oldest,lowest=nil,math.huge
 for id,item in pairs(cache) do
  if item.used<lowest then lowest=item.used;oldest=id end
 end
 if oldest then
  local item=cache[oldest]
  if item.mesh then item.mesh:release() end
  if item.image then item.image:release() end
  cache[oldest]=nil
 end
end
local XDIV,YDIV=22,12
local function newMesh(image)
 local vertices={}
 local function vertex(x,y)
  vertices[#vertices+1]={x,y,x/W,y/H}
 end
 for row=0,YDIV-1 do
  for col=0,XDIV-1 do
   local x0,y0=col*W/XDIV,row*H/YDIV
   local x1,y1=(col+1)*W/XDIV,(row+1)*H/YDIV
   vertex(x0,y0);vertex(x1,y0);vertex(x1,y1)
   vertex(x0,y0);vertex(x1,y1);vertex(x0,y1)
  end
 end
 local mesh=lg.newMesh(vertices,'triangles','dynamic')
 mesh:setTexture(image)
 return mesh,vertices
end
local function getItem(id)
 local old=cache[id]
 if old then touchCache(old);return old end
 if not M.available() then return nil end
 local filename=ROOT..'sprites/'..filen(id)
 if not love.filesystem.getInfo(filename,'file') then return nil end
 evict()
 local ok,img=pcall(lg.newImage,filename,{mipmaps=false})
 if not ok or not img or img:getWidth()~=W or img:getHeight()~=H then
  if img then img:release() end
  return nil
 end
 img:setFilter('linear','linear')
 local mesh,vertices=newMesh(img)
 local item={image=img,mesh=mesh,base=vertices}
 touchCache(item);cache[id]=item
 return item
end
local function bend(x,y,pose)
 -- Tail silhouette begins at the 184px anatomical joint; all vertices
 -- remain part of ONE contiguous texture mesh. No hard rectangular holes.
 local tail=math.max(0,math.min(1,(202-x)/166))
 local bendY=pose.tail*tail*tail
 local bendX=math.cos(pose.wave)*4*tail
 local finArea=math.max(0,1-math.abs(x-290)/125)
 if y<118 then bendY=bendY+pose.dorsal*finArea*math.max(0,(122-y)/100) end
 if y>149 then bendY=bendY+pose.ventral*finArea*math.max(0,(y-149)/92) end
 return x+bendX,y+bendY
end
function M.draw(spec,x,y,scale,direction,time,health,joints)
 local id=matching(spec)
 if not id then return false end
 local item=getItem(id)
 if not item then return false end
 local pose=M.pose(time,health)
 local positions={}
 for i,v in ipairs(item.base) do
  local px,py=bend(v[1],v[2],pose)
  positions[i]={px,py,v[3],v[4]}
 end
 item.mesh:setVertices(positions)
 local s=(scale or 1)*.24
 lg.push('all')
 lg.setColor(1,1,1,1)
 lg.translate(x,y+pose.bob*s)
 lg.scale((direction or 1)*s,s)
 lg.rotate(pose.body)
 lg.translate(-W*.5,-H*.5)
 local shader=Visual.getShader(spec,0,0,W,H,W,H)
 if shader then lg.setShader(shader) end
 lg.draw(item.mesh)
 if joints then
  lg.setShader()
  lg.setLineWidth(2)
  for _,p in ipairs({{184,128},{285,88},{285,174}}) do
   lg.setColor(1,.89,.31,.96);lg.circle('line',p[1],p[2],5)
  end
 end
 lg.pop()
 return true
end
local function getAtlas()
 if atlas then return atlas end
 if not M.available() or atlasFailed then return nil end
 local ok,img=pcall(lg.newImage,THUMBS,{mipmaps=false})
 if not ok or not img or img:getWidth()~=ATLAS_W or img:getHeight()~=ATLAS_H then
  if img then img:release() end
  atlasFailed=true
  return nil
 end
 img:setFilter('linear','linear')
 atlas=img
 return img
end
function M.drawStatic(spec,x,y,scale,direction,time)
 local id,magic=matching(spec)
 if not id then return false end
 local img=getAtlas()
 if not img then return false end
 local quad=atlasQuads[id]
 local px,py,w,h
 if magic then
  px=720+(id-442)*472;py=2144;w=345;h=125
 else
  local n=id-1
  px=32+(n%21)*192;py=92+math.floor(n/21)*96
  w=192;h=96
 end
 if not quad then
  quad=lg.newQuad(px,py,w,h,ATLAS_W,ATLAS_H)
  atlasQuads[id]=quad
 end
 local s=(scale or 1)*(magic and .26 or .50)
 lg.push('all')
 lg.setColor(1,1,1,1)
 lg.translate(x,y)
 lg.scale((direction or 1)*s,s)
 lg.rotate(math.sin((time or 0)*2)*.008)
 lg.draw(img,quad,-w/2,-h/2)
 lg.pop()
 return true
end
local parts={
 body={185,75,285,119},tail={20,20,185,220},
 dorsal={205,10,192,120},ventral={209,152,190,96},
 eye={363,73,118,88},pectoral={289,126,112,95}}
function M.drawPart(spec,name,x,y,width,height)
 local id=matching(spec)
 local item=id and getItem(id)
 local box=parts[name]
 if not item or not box then return false end
 local bx,by,bw,bh=unpack(box)
 local quad=lg.newQuad(bx,by,bw,bh,W,H)
 local s=math.min((width or 100)/bw,(height or 100)/bh)
 lg.push('all')
 lg.setColor(1,1,1,1)
 lg.translate(x+((width or 100)-bw*s)*.5,y+((height or 100)-bh*s)*.5)
 lg.scale(s,s)
 lg.draw(item.image,quad)
 lg.pop()
 quad:release()
 return true
end
function M.cacheSize()
 local n=0;for _ in pairs(cache) do n=n+1 end;return n
end
function M.clearCache()
 for _,e in pairs(cache) do
  e.mesh:release();e.image:release()
 end
 cache={}
 for _,q in pairs(atlasQuads) do q:release() end
 atlasQuads={}
 if atlas then atlas:release();atlas=nil end
 checked=false;atlasFailed=false
end
return M