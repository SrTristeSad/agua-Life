-- agua-Life | Matriz RGBA fornecida pelo usuário: 441 peixes e sete mágicos.
-- O LÖVE recorta a textura em regiões (Quads) e anima juntas em tempo real.
-- Nenhuma releitura procedural da arte: as cores/pixels são os do atlas.
local M={}
local lg=love.graphics
local JSON=require('game.json')
local DNAVisual=require('art.dna_visual')
local ORIGINAL='assets/fish/matrix/atlas_441.png'
local ORIGINAL_META='assets/fish/matrix/atlas_441.json'
local CLEAN='assets/fish/matrix/atlas_original_clean_4k.png'
local CLEAN_META='assets/fish/matrix/atlas_original_clean_4k.json'
local REFINED='assets/fish/matrix/atlas_original_refined_4k.png'
local REFINED_META='assets/fish/matrix/atlas_original_refined_4k.json'
local ATLAS,META=ORIGINAL,ORIGINAL_META
local CW,CH=128,64
local MW,MH=384,136
local AW,AH=2688,1480
local refined=false
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
 local choices={
  -- Extração correta com célula exclusiva para cada corpo e cauda.
  {path=CLEAN,meta=CLEAN_META,aw=4032,ah=2220,cw=192,ch=96,mw=576,mh=204,refined=true},
  -- Compatibilidade para instalações antigas até o atlas limpo estar disponível.
  {path=REFINED,meta=REFINED_META,aw=4032,ah=2220,cw=192,ch=96,mw=576,mh=204,refined=true},
  {path=ORIGINAL,meta=ORIGINAL_META,aw=2688,ah=1480,cw=128,ch=64,mw=384,mh=136,refined=false}
 }
 for _,v in ipairs(choices) do
  if love.filesystem.getInfo(v.path,'file') then
   local ok,image=pcall(lg.newImage,v.path,{mipmaps=false})
   if ok and image then
    if image:getWidth()==v.aw and image:getHeight()==v.ah then
     IMG=image;ATLAS,META=v.path,v.meta
     AW,AH,CW,CH,MW,MH=v.aw,v.ah,v.cw,v.ch,v.mw,v.mh
     refined=v.refined
     M.source=ATLAS
     image:setFilter('linear','linear')
     if love.filesystem.getInfo(META,'file') then
      local raw=love.filesystem.read(META)
      local success,parsed=pcall(JSON.decode,raw)
      if success and type(parsed)=='table' then metadata=parsed end
     end
     return true
    end
    if image.release then image:release() end
   end
  end
 end
 return false
end
function M.isRefined()
 M.available()
 return refined
end
function M.isClean()
 M.available()
 return IMG~=nil and ATLAS==CLEAN
end
function M.resolution()
 M.available()
 return AW,AH,CW,CH
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
 local s=(scale or 1)*(isMagic and .345 or 1)*(isMagic and 384/MW or 128/CW)
 lg.scale((direction or 1)*s,s)
 lg.rotate(math.sin((time or 0)*2.8)*.012)
 lg.draw(IMG,parts.whole,-w*.5,-h*.5)
 lg.pop()
 return true
end
-- Deformação contínua dos grupos anatómicos na malha UV: a cauda e
-- nadadeiras mexem independentemente, mas a pele permanece conectada.
-- É mais fiel para sprites originais achatados que girar retângulos rígidos.
local skeletal={}
local divisionsX,divisionsY=18,10
local function between(v,a,b)
 return math.max(a,math.min(b,v))
end
local function makeMesh(indexValue,isMagic)
 local tx,ty,w,h=tile(indexValue,isMagic)
 local b=measure(indexValue,isMagic,w,h)
 local vertices={}
 local function append(x,y)
  vertices[#vertices+1]={x,y,(tx+x)/AW,(ty+y)/AH}
 end
 for iy=0,divisionsY-1 do
  local y0=iy*h/divisionsY
  local y1=(iy+1)*h/divisionsY
  for ix=0,divisionsX-1 do
   local x0=ix*w/divisionsX
   local x1=(ix+1)*w/divisionsX
   append(x0,y0);append(x1,y0);append(x1,y1)
   append(x0,y0);append(x1,y1);append(x0,y1)
  end
 end
 local m=lg.newMesh(vertices,'triangles','dynamic')
 m:setTexture(IMG)
 local item={mesh=m,base=vertices,bounds=b,w=w,h=h,
  tx=tx,ty=ty,count=#vertices}
 skeletal[indexValue]=item
 return item
end
function M.pose(t,health)
 t=tonumber(t) or 0
 local ill=health and health.disease and .45 or 1
 local rate=health and health.disease and 1.5 or 2.7
 local wv=t*rate
 return {wave=wv,
  tail=math.sin(wv)*.17*ill,
  dorsal=math.sin(wv+.7)*.045*ill,
  ventral=math.sin(wv+1.3)*.072*ill,
  body=math.sin(wv)*.013*ill,
  bob=math.sin(wv*.8)*1.5*ill,
  amplitude=ill}
end
local function moveVertex(x,y,b,pose)
 local minX,minY,maxX,maxY=b[1],b[2],b[3],b[4]
 local sx=math.max(1,maxX-minX)
 local sy=math.max(1,maxY-minY)
 local nx=(x-minX)/sx
 local ny=(y-minY)/sy
 -- Cauda: flexão progressiva que zera na base, sem cortes e sem buracos.
 local tail=between((.45-nx)/.65,0,1)
 local displacementY=pose.tail*sy*.82*tail*tail
 local displacementX=math.cos(pose.wave)*sx*.018*tail
 -- Dorsal e ventral só deformam as regiões superiores/inferiores.
 local mid=between((nx-.18)/.18,0,1)*between((.92-nx)/.20,0,1)
 local dorsal=between((.34-ny)/.34,0,1)*mid
 local ventral=between((ny-.69)/.31,0,1)*mid
 displacementY=displacementY+pose.dorsal*sy*.57*dorsal
 displacementY=displacementY+pose.ventral*sy*.50*ventral
 return x+displacementX,y+displacementY
end
function M.draw(spec,x,y,scale,direction,time,health,joints)
 local id,isMagic=index(spec)
 if not id or not M.available() then return false end
 local entry=skeletal[id] or makeMesh(id,isMagic)
 local pose=M.pose(time,health)
 local b=entry.bounds
 local verts={}
 for i,orig in ipairs(entry.base) do
  local vx,vy=moveVertex(orig[1],orig[2],b,pose)
  verts[i]={vx,vy,orig[3],orig[4]}
 end
 entry.mesh:setVertices(verts)
 local s=(scale or 1)*(isMagic and .345 or 1)*(isMagic and 384/MW or 128/CW)
 lg.push('all')
 lg.setColor(1,1,1,1)
 -- O catálogo estático mantém os pixels canônicos; nos peixes vivos,
 -- alelos de paleta/estampa alteram apenas o fenótipo visual.
 local shader=DNAVisual.getShader(spec,entry.tx,entry.ty,entry.w,entry.h,AW,AH)
 if shader then lg.setShader(shader) end
 lg.translate(x,y+pose.bob*s)
 lg.scale((direction or 1)*s,s)
 lg.rotate(pose.body)
 lg.translate(-entry.w*.5,-entry.h*.5)
 lg.draw(entry.mesh)
 if joints then
  local pivots=fragments(id,isMagic).pivots
  for _,p in pairs(pivots) do
   lg.setColor(1,.86,.28,.95)
   lg.setLineWidth(1.2)
   lg.circle('line',p[1],p[2],3.2)
  end
 end
 lg.pop()
 return true
end
-- Os mesmos recortes RGBA permanecem disponíveis no Ateliê para
-- visualizar as peças separadas, sem convertê-las em sprites fictícios.
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
function M.visualParameters(spec)
 return DNAVisual.parameters(spec)
end
-- Qualidade de exibição: o arquivo RGBA permanece intocado.
function M.setSharpness(value)
 return DNAVisual.setSharpness(value)
end
function M.isSharp()
 return DNAVisual.isSharp()
end
function M.clearCache()
 for _,entry in pairs(skeletal) do
  if entry.mesh then entry.mesh:release() end
 end
 skeletal={}
 for _,entry in pairs(cache) do
  if entry.whole then entry.whole:release() end
  for _,part in pairs(entry.regions) do part.q:release() end
 end
 cache={}
end
return M