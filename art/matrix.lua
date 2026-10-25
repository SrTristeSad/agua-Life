-- Matriz original enviada pelo usuario: 21 corpos x 21 conjuntos de nadadeiras.
-- Atlas RGBA gerado uma vez por scripts/extract_matrix.py.
-- O LOVE corta corpo/cauda/dorsal/ventral em memoria para anima-los de verdade.
-- As artes do Fish Tycoon de estudo NAO sao utilizadas aqui.
local Matrix={}
local g=love.graphics
local atlas=nil
local pixels=nil
local attempted=false
local sourcePath='assets/fish/matrix/atlas_441.png'
local COLS,ROWS=21,21
local CW,CH=128,64
local MW,MH=384,136
local AW,AH=COLS*CW,ROWS*CH+MH
local quads={}
local fragments={}
local cached={}
local cacheOrder={}
local MAX_PART_CACHE=44
local magic={{21,17},{15,15},{12,12},{11,10},{6,9},{14,7},{8,8}}
Matrix.magicPairs=magic
Matrix.source=sourcePath
Matrix.tileSize={CW,CH}
Matrix.magicTileSize={MW,MH}
local function spriteIndex(spec)
 if type(spec)~='table' or type(spec.body)~='number' or type(spec.fin)~='number'
  or spec.body%1~=0 or spec.fin%1~=0 or spec.body<1 or spec.body>21
  or spec.fin<1 or spec.fin>21 then return nil end
 for i,m in ipairs(magic) do
  if spec.body==m[1] and spec.fin==m[2] then return 441+i,true end
 end
 return (spec.body-1)*COLS+spec.fin,false
end
function Matrix.getIndex(spec)return spriteIndex(spec)end
function Matrix.available()
 if atlas then return true end
 if attempted then return false end
 attempted=true
 if not love.filesystem.getInfo(sourcePath,'file') then return false end
 local ok,img=pcall(g.newImage,sourcePath,{mipmaps=false})
 if not ok then return false end
 if img:getWidth()~=AW or img:getHeight()~=AH then
  img:release();return false
 end
 img:setFilter('linear','linear')
 atlas=img
 return true
end
local function position(index,isMagic)
 if isMagic then
  return (index-442)*MW,ROWS*CH,MW,MH
 end
 local n=index-1
 return (n%21)*CW,math.floor(n/21)*CH,CW,CH
end
local function quad(index,mag)
 local q=quads[index]
 if q then return q end
 local x,y,w,h=position(index,mag)
 q=g.newQuad(x,y,w,h,AW,AH)
 quads[index]=q
 return q
end
local function drawTile(image,q,w,h,x,y,scale,dir,time,tint)
 g.push('all')
 g.setColor(1,1,1,1)
 g.translate(x,y)
 g.scale((dir or 1)*(scale or 1),(scale or 1))
 g.rotate(math.sin((time or 0)*2.8)*.012)
 g.draw(image,q,-w*.5,-h*.5)
 g.pop()
end
function Matrix.drawStatic(spec,x,y,scale,dir,time)
 local idx,magicFlag=spriteIndex(spec)
 if not idx or not Matrix.available() then return false end
 local w,h=magicFlag and MW or CW,magicFlag and MH or CH
 local normalization=magicFlag and .345 or 1
 drawTile(atlas,quad(idx,magicFlag),w,h,x,y,(scale or 1)*normalization,dir,time)
 return true
end
local function loadParts(index,isMagic)
 local entry=fragments[index]
 if entry then return entry end
 if not Matrix.available() then return nil end
 if not pixels then
  -- Decode PNG apenas quando o primeiro peixe precisar nadar.
  local ok,bitmap=pcall(love.image.newImageData,sourcePath)
  if not ok then return nil end
  pixels=bitmap
 end
 local sx,sy,w,h=position(index,isMagic)
 local base=love.image.newImageData(w,h)
 base:paste(pixels,0,0,sx,sy,w,h)
 local loX,loY,hiX,hiY=w,h,0,0
 for yy=0,h-1 do
  for xx=0,w-1 do
   local _,_,_,a=base:getPixel(xx,yy)
   if a>.22 then
    loX=math.min(loX,xx);loY=math.min(loY,yy)
    hiX=math.max(hiX,xx);hiY=math.max(hiY,yy)
   end
  end
 end
 if loX>hiX then return nil end
 local spanX=hiX-loX+1
 local spanY=hiY-loY+1
 local middleY=(loY+hiY)*.5
 local cutX=loX+spanX*.38
 local dorsalPivot={loX+spanX*.58,loY+spanY*.36}
 local ventralPivot={loX+spanX*.62,loY+spanY*.67}
 local tailPivot={cutX,middleY}
 local names={'tail','dorsal','ventral','body'}
 local bitmaps={}
 for _,n in ipairs(names) do bitmaps[n]=love.image.newImageData(w,h) end
 for yy=0,h-1 do
  for xx=0,w-1 do
   local r,gg,b,a=base:getPixel(xx,yy)
   if a>0 then
    local component='body'
    local tailRatio=math.min(1,math.max(0,(cutX+2.5-xx)/5))
    local region=(xx>loX+spanX*.33 and xx<loX+spanX*.84)
    if region and yy<loY+spanY*.31 then component='dorsal'
    elseif region and yy>loY+spanY*.76 then component='ventral'
    end
    if tailRatio>=.999 then
     bitmaps.tail:setPixel(xx,yy,r,gg,b,a)
    elseif tailRatio>.001 then
     -- Peso repartido entre corpo e cauda para não criar rasgo no encaixe.
     bitmaps.tail:setPixel(xx,yy,r,gg,b,a*tailRatio)
     bitmaps.body:setPixel(xx,yy,r,gg,b,a*(1-tailRatio))
    else
     bitmaps[component]:setPixel(xx,yy,r,gg,b,a)
    end
   end
  end
 end
 local layers={}
 for _,n in ipairs(names) do
  layers[n]=g.newImage(bitmaps[n],{mipmaps=false})
  layers[n]:setFilter('linear','linear')
  bitmaps[n]:release()
 end
 base:release()
 entry={images=layers,tailPivot=tailPivot,dorsalPivot=dorsalPivot,
  ventralPivot=ventralPivot,w=w,h=h,magic=isMagic}
 fragments[index]=entry
 cacheOrder[#cacheOrder+1]=index
 if #cacheOrder>MAX_PART_CACHE then
  local oldest=table.remove(cacheOrder,1)
  local replaced=fragments[oldest]
  if replaced then
   for _,v in pairs(replaced.images) do v:release() end
   fragments[oldest]=nil
  end
 end
 return entry
end
local function jointDraw(layer,pivot,angle)
 g.push()
 g.translate(pivot[1],pivot[2]);g.rotate(angle)
 g.draw(layer,-pivot[1],-pivot[2])
 g.pop()
end
function Matrix.draw(spec,x,y,scale,face,time,health,joints)
 local index,isMagic=spriteIndex(spec)
 if not index or not Matrix.available() then return false end
 local entry=loadParts(index,isMagic)
 if not entry then return Matrix.drawStatic(spec,x,y,scale,face,time) end
 local t=time or 0
 local ill=health and health.disease and 0.42 or 1
 local speed=health and health.disease and 1.5 or 2.7
 local wave=t*speed
 local k=(scale or 1)*(isMagic and .345 or 1)
 g.push('all')
 g.setColor(1,1,1,1)
 g.translate(x,y+math.sin(wave*.7)*1.4*k*ill)
 g.scale((face or 1)*k,k)
 g.rotate(math.sin(wave)*.012*ill)
 g.translate(-entry.w*.5,-entry.h*.5)
 jointDraw(entry.images.tail,entry.tailPivot,math.sin(wave)*.20*ill)
 jointDraw(entry.images.dorsal,entry.dorsalPivot,math.sin(wave+.75)*.065*ill)
 jointDraw(entry.images.ventral,entry.ventralPivot,math.sin(wave+1.5)*.085*ill)
 g.draw(entry.images.body)
 if joints then
  g.setLineWidth(1.2)
  for _,pt in ipairs({entry.tailPivot,entry.dorsalPivot,entry.ventralPivot}) do
   g.setColor(1,.87,.32,1);g.circle('line',pt[1],pt[2],4)
  end
 end
 g.pop()
 return true
end
function Matrix.drawPart(spec,part,x,y,w,h)
 local index,isMagic=spriteIndex(spec)
 if not index or not Matrix.available() then return false end
 local entry=loadParts(index,isMagic)
 if not entry or not entry.images[part] then return false end
 local image=entry.images[part]
 g.push('all')
 g.setColor(1,1,1,1)
 local scale=math.min((w or 80)/entry.w,(h or 55)/entry.h)
 g.draw(image,x+((w or 80)-entry.w*scale)/2,
   y+((h or 55)-entry.h*scale)/2,0,scale,scale)
 g.pop()
 return true
end
function Matrix.clearCache()
 for _,p in pairs(fragments) do for _,img in pairs(p.images) do img:release() end end
 fragments={};cacheOrder={}
 if pixels then pixels:release();pixels=nil end
end
return Matrix