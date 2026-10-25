-- V23: tipografia original J2ME com metricas variaveis e reserva no CI.
package.path='./?.lua;./?/init.lua;'..package.path
local Bitmap=require('ui.bitmap_font')
local total=0
local function check(label,fn)
 local ok,err=pcall(fn)
 if not ok then error('V23 '..label..': '..tostring(err),0) end
 total=total+1;print('OK '..label)
end
local actual=pcall(require,'assets.local_font.font_metrics')
local faces={}
local dimensions={{882,20,1},{712,15,1},{504,26,2}}
if actual then
 faces=require('assets.local_font.font_metrics')
else
 -- Fixtures geradas com estrutura real, mas sem incluir PNGs comerciais.
 for k,d in ipairs(dimensions) do
  local offsets={-5}
  for i=2,105 do offsets[i]=math.floor((i-2)*d[1]/104) end
  offsets[106]=d[1]
  faces[k]={file='font_'..(k-1)..'.png',rows=d[3],offsets=offsets,
   gap=(k==3 and 1 or 0)}
 end
end
package.loaded['assets.local_font.font_metrics']=faces
local calls,quads={},{}
love={graphics={
 newImage=function(path)
  local number=tonumber(path:match('font_(%d)'))+1
  local d=dimensions[number]
  local o={setFilter=function()end}
  function o:getDimensions()return d[1],d[2]end
  return o
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and w>0 and x+w<=iw and y+h<=ih)
  quads[#quads+1]={x=x,y=y,w=w,h=h}
  return {x=x,y=y,w=w,h=h}
 end,
 draw=function(img,q,x,y)
  calls[#calls+1]={quad=q,x=x,y=y}
 end,
}}
local font=assert(Bitmap.new())
check('tres fontes e 104 metricas cada',function()
 assert(#font.faces==3)
 for i,face in ipairs(font.faces) do
  assert(#face.glyphs==104)
  assert(face.width==dimensions[i][1] and face.height*face.rows==dimensions[i][2])
 end
end)
check('ASCII J2ME tem glifos proporcionais com codigos corretos',function()
 font:select(3)
 local a=font:measure('A');local i=font:measure('I');local sp=font:measure(' ')
 local aindex=65-27-5+1
 assert(a==faces[3].offsets[aindex+1]-faces[3].offsets[aindex])
 assert(font:measure('AA')==a*2+faces[3].gap)
 assert(font:measure('A A')==a*2+sp+faces[3].gap*2)
 assert(font:measure('')==0 and i>0)
end)
check('alinhamento central e a direita usam medida original',function()
 calls={};font:print('AB',12,29,90,'center')
 assert(#calls==2)
 assert(calls[1].x==12+math.floor((90-font:measure('AB'))/2))
 assert(calls[1].y==29)
 calls={};font:print('AB',12,29,90,'right')
 assert(calls[1].x==12+90-font:measure('AB'))
end)
check('font2 utiliza banda inferior de 13 pixels',function()
 calls={};font:print('A',0,0,40)
 assert(calls[1].quad.y==13 and calls[1].quad.h==13)
end)
check('textos longos sao cortados, sem invadir controles',function()
 local str=font:fit('FISH TYCOON RESEARCH AND ADVERTISING',36)
 assert(font:measure(str)<=36 and str:sub(-2)=='..')
 calls={};font:print(str,20,30,36)
 local last=calls[#calls]
 assert(last.x+last.quad.w<=20+36)
end)
check('quads ficam dentro das texturas e sao cacheados',function()
 local count=#quads
 for i=1,5 do font:print('PRICE $300',2,5,100) end
 assert(#quads==count,'renderizar textos nao deve criar quads novos por frame')
end)
check('modo sem fonte nao falha e permite reserva do LOVE',function()
 local old=package.loaded['assets.local_font.font_metrics']
 package.loaded['assets.local_font.font_metrics']=false
 -- Num .love real, require ainda tentaria carregar os dados em disco,
 -- entao validamos tambem o retorno sem recursos completos.
 local oldImage=love.graphics.newImage
 love.graphics.newImage=function()error('Sem recurso')end
 assert(Bitmap.new()==nil)
 love.graphics.newImage=oldImage
 package.loaded['assets.local_font.font_metrics']=old
end)
print('V23: '..total..' testes tipograficos aprovados; fonte '..(actual and 'do JAR original' or 'sintetica de CI'))
