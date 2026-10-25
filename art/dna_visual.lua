-- DNA visual aplicado sobre os pixels originais do atlas da matriz C x F.
-- Sem novas imagens por combinacao: cor e estampa mudam no shader GPU.
-- Configuracao pura para testes sem LÖVE.
local DNAVisual={}
local shader=nil
local failed=false

function DNAVisual.parameters(spec)
 if type(spec)~='table' or type(spec.body)~='number' or
    type(spec.palette)~='number' or type(spec.pattern)~='number' then
  return nil,'Especificacao genetica invalida'
 end
 local nativePalette=((spec.body-1)%12)+1
 local delta=(spec.palette-nativePalette+6)%12-6
 local nativePattern=((spec.body-1)%6)+1
 return {
  hueShift=delta*.026,
  pattern=spec.pattern,
  patternStrength=spec.pattern==nativePattern and 0 or .24,
  nativePalette=nativePalette,
  nativePattern=nativePattern
 }
end

local source=[[
extern number hueShift;
extern number patternType;
extern number patternStrength;
extern vec2 atlasOrigin;
extern vec2 atlasSize;
vec3 rgb2hsv(vec3 c) {
 vec4 K=vec4(0.,-.3333333,.6666667,-1.);
 vec4 p=mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g));
 vec4 q=mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));
 number d=q.x-min(q.w,q.y),e=.000001;
 return vec3(abs(q.z+(q.w-q.y)/(6.*d+e)),d/(q.x+e),q.x);
}
vec3 hsv2rgb(vec3 c) {
 vec3 p=abs(fract(c.xxx+vec3(0.,.6666667,.3333333))*6.-3.);
 return c.z*mix(vec3(1.),clamp(p-1.,0.,1.),c.y);
}
number marks(vec2 uv) {
 number p=patternType;
 if(p<1.5) {
  return pow(max(0.,sin(uv.x*117.)*sin(uv.y*132.)),6.);
 }
 if(p<2.5) {
  return pow(max(0.,sin(uv.x*77.+uv.y*19.)),8.);
 }
 if(p<3.5) {
  return pow(max(0.,sin(uv.y*103.)),9.);
 }
 if(p<4.5) {
  return pow(max(0.,sin((uv.x+uv.y*.45)*127.)*sin((uv.x-uv.y*.6)*94.)),5.);
 }
 if(p<5.5) {
  return pow(max(0.,cos(uv.x*47.)*cos(uv.y*67.)),6.);
 }
 return pow(max(0.,sin(uv.x*64.+uv.y*103.)),9.);
}
vec4 effect(vec4 color,Image tex,vec2 textureCoords,vec2 screenCoords) {
 vec4 px=Texel(tex,textureCoords);
 if(px.a<=.001) return px*color;
 vec3 hsv=rgb2hsv(px.rgb);
 hsv.x=fract(hsv.x+hueShift);
 vec3 rgb=hsv2rgb(hsv);
 vec2 uv=(textureCoords-atlasOrigin)/atlasSize;
 vec2 centered=(uv-vec2(.54,.50))/vec2(.17,.24);
 number coreMask=1.-smoothstep(.48,1.1,length(centered));
 number mark=patternStrength*coreMask*marks(uv);
 rgb=mix(rgb,vec3(.93,.96,1.),mark);
 return vec4(rgb,px.a)*color;
}
]]
function DNAVisual.getShader(spec,x,y,w,h,atlasWidth,atlasHeight)
 if failed then return nil end
 if not (love and love.graphics and love.graphics.newShader) then return nil end
 if not shader then
  local ok,obj=pcall(love.graphics.newShader,source)
  if not ok then failed=true;return nil end
  shader=obj
 end
 local params=DNAVisual.parameters(spec)
 if not params then return nil end
 shader:send('hueShift',params.hueShift)
 shader:send('patternType',params.pattern)
 shader:send('patternStrength',params.patternStrength)
 atlasWidth=atlasWidth or 2688
 atlasHeight=atlasHeight or 1480
 shader:send('atlasOrigin',{x/atlasWidth,y/atlasHeight})
 shader:send('atlasSize',{w/atlasWidth,h/atlasHeight})
 return shader
end
return DNAVisual
