-- Renderizador das fontes originais codificadas em 1.dat (classe i do J2ME).
-- Requer importar assets/local_font via scripts/import_j2me_fonts.py.
-- Sem esses recursos privados, a interface usa a fonte LÖVE existente.
local Font={}
Font.__index=Font
local prefix='assets/local_font/'
local function glyphIndex(byte)
 -- i.a(String): ASCII <97 vira byte-27; com String.toUpperCase().
 -- O desenho i.a(Graphics,byte[],...) usa indice code-5 na tabela.
 if byte==32 then return 1 end  -- espaco: codigo 5
 if byte==124 or byte==10 then return nil end
 if byte>=97 and byte<=122 then byte=byte-32 end
 if byte>=32 and byte<97 then
  local index=byte-27-5+1
  if index>=1 and index<=104 then return index end
 end
 -- Substituicao por '?' para simbolos ainda sem mapeamento.
 return 63-27-5+1
end
local function glyphHeight(image,rows)
 local _,h=image:getDimensions()
 return h/rows
end
function Font.new()
 local ok,metadata=pcall(require,'assets.local_font.font_metrics')
 if not ok or type(metadata)~='table' then return nil end
 local self=setmetatable({faces={},selected=3},Font)
 for i,entry in ipairs(metadata) do
  local success,img=pcall(love.graphics.newImage,prefix..entry.file)
  if not success or not img then return nil end
  img:setFilter('nearest','nearest')
  local w,h=img:getDimensions()
  local rows=entry.rows
  if not rows or rows<=0 or h%rows~=0 or #entry.offsets~=106 then return nil end
  local offset=entry.offsets
  if offset[106]~=w then return nil end
  local face={image=img,height=glyphHeight(img,rows),width=w,
   rows=rows,offsets=offset,gap=entry.gap or 0,glyphs={}}
  for idx=1,104 do
   local x=offset[idx];local right=offset[idx+1]
   local advance=right-x
   if idx>1 and (x<0 or right>w or advance<0) then return nil end
   local glyph={x=x,width=advance,quads={}}
   if x>=0 and advance>0 then
    for row=0,rows-1 do
     glyph.quads[row+1]=love.graphics.newQuad(x,row*face.height,advance,face.height,w,h)
    end
   end
   face.glyphs[idx]=glyph
  end
  self.faces[i]=face
 end
 return self
end
function Font:select(index)
 if self.faces[index] then self.selected=index;return true end
 return false
end
function Font:measure(text,style)
 local face=self.faces[style or self.selected]
 if not face then return 0 end
 text=tostring(text or ''):upper()
 local advance=0
 for i=1,#text do
  local idx=glyphIndex(text:byte(i))
  if idx then
   local glyph=face.glyphs[idx]
   advance=advance+glyph.width+face.gap
  end
 end
 if advance>0 then advance=advance-face.gap end
 return advance
end
function Font:fit(text,width,style)
 -- Uma unica linha, como nos rotulos do jogo original.
 text=tostring(text or ''):upper():gsub('[\r\n]',' ')
 if self:measure(text,style)<=width then return text end
 local ellipsis='..'
 if self:measure(ellipsis,style)>width then return '' end
 while #text>0 and self:measure(text..ellipsis,style)>width do
  text=text:sub(1,-2)
 end
 return text..ellipsis
end
function Font:print(text,x,y,maxWidth,align,style)
 local face=self.faces[style or self.selected]
 if not face then return end
 maxWidth=maxWidth or 220
 local fitted=self:fit(text,maxWidth,style)
 local width=self:measure(fitted,style)
 if align=='center' then x=x+math.floor((maxWidth-width)/2)
 elseif align=='right' then x=x+maxWidth-width end
 local cursor=math.floor(x)
 -- Fonte 2 possui duas linhas: a linha 2 (indice 1) e clara,
 -- propria para multiplicar pelas cores usadas no jogo Lua.
 local row=(style or self.selected)==3 and 1 or 0
 for i=1,#fitted do
  local idx=glyphIndex(fitted:byte(i))
  if idx then
   local glyph=face.glyphs[idx]
   local advance=glyph.width
   if glyph.x>=0 and advance>0 then
    love.graphics.draw(face.image,glyph.quads[row+1],cursor,y)
   end
   cursor=cursor+advance+face.gap
  end
 end
end
return Font
