-- agua-Life: renderizador de peixe 100% em codigo Lua/LÖVE
-- Curvas e malhas originais; nenhum PNG ou atlas de terceiros.
local C=require('art.catalog')
local A={}
local g=love.graphics
local sin,cos,pi,abs=math.sin,math.cos,math.pi,math.abs
local min,max=math.min,math.max
local unpack=table.unpack or unpack
local meshes={}
local function clamp(v)return max(0,min(1,v))end
local function fromHex(h)
 h=h:gsub('#','')
 return {tonumber(h:sub(1,2),16)/255,tonumber(h:sub(3,4),16)/255,tonumber(h:sub(5,6),16)/255}
end
local function blend(a,b,t)
 t=clamp(t)
 return {a[1]*(1-t)+b[1]*t,a[2]*(1-t)+b[2]*t,a[3]*(1-t)+b[3]*t}
end
local function paint(c,alpha)g.setColor(c[1],c[2],c[3],alpha or 1)end
local function anatomy(b,u)
 local x=(-49+104*u)*b.length
 local s=max(0,sin(pi*u))
 local full=s^.67*(.77+.23*sin(pi*u))
 local h=(15+9*b.height)*full*(1+b.head*(u-.5)*.31)
 local y=b.curvature*13*sin(pi*u)
 return x,y-h-(b.upper-1)*3.7*s,y+h+(b.lower-1)*3.7*s,y,h
end
local function mesh(b,p)
 local key=b.id..':'..p.name
 if meshes[key] then return meshes[key] end
 local back,base,belly,highlight=fromHex(p.back),fromHex(p.base),fromHex(p.belly),fromHex(p.light)
 local verts={}
 local function vertex(u,v)
  local x,top,bottom=anatomy(b,u)
  local shade
  if v<.37 then shade=blend(back,base,v/.37)
  elseif v<.69 then shade=blend(base,belly,((v-.37)/.32)*.75)
  else shade=blend(belly,back,((v-.69)/.31)*.51) end
  local glow=.20*math.exp(-((v-.25)/.12)^2)*sin(pi*u)
  shade=blend(shade,highlight,glow)
  return {x,top+(bottom-top)*v,0,0,shade[1],shade[2],shade[3],1}
 end
 for x=0,27 do
  for y=0,9 do
   local v1=vertex(x/28,y/10)
   local v2=vertex((x+1)/28,y/10)
   local v3=vertex((x+1)/28,(y+1)/10)
   local v4=vertex(x/28,(y+1)/10)
   verts[#verts+1]=v1;verts[#verts+1]=v2;verts[#verts+1]=v3
   verts[#verts+1]=v1;verts[#verts+1]=v3;verts[#verts+1]=v4
  end
 end
 local m=g.newMesh(verts,'triangles','static');meshes[key]=m;return m
end
local function triangularFan(coords)
 -- Tira a concavidade do problema: todos os triangulos nascem na raiz.
 for i=3,#coords-3,2 do
  g.polygon('fill',coords[1],coords[2],coords[i],coords[i+1],coords[i+2],coords[i+3])
 end
end
local function tail(b,f,p,t)
 local x=-47*b.length
 local length=24+17*f.length
 local spread=13+18*f.spread
 local px=x-length
 local wave=sin(t)*5
 local points={x,-5}
 if f.kind=='fan' or f.kind=='round' then
  for i=0,18 do
   local v=i/18;local theta=(-.5+v)*pi
   points[#points+1]=px+wave-((f.kind=='round') and 7*cos(theta)^2 or 4*abs(sin(v*pi*3)))
   points[#points+1]=spread*sin(theta)
  end
 elseif f.kind=='fork' then
  local P={{px-9,-spread},{px+1,-spread*.42},{px+length*.25,0},{px+1,spread*.42},{px-9,spread}}
  for _,v in ipairs(P) do points[#points+1]=v[1]+wave;points[#points+1]=v[2] end
 elseif f.kind=='veil' then
  local P={{px-4,-spread*1.24},{px-9,-spread*.7},{px+4,0},{px-10,spread*.83},{px-2,spread*1.34}}
  for _,v in ipairs(P) do points[#points+1]=v[1]+wave;points[#points+1]=v[2] end
 elseif f.kind=='spear' then
  local P={{px,-spread*.38},{px-15,0},{px,spread*.38},{px+length*.1,0}}
  for _,v in ipairs(P) do points[#points+1]=v[1]+wave;points[#points+1]=v[2] end
 elseif f.kind=='double' then
  local P={{px-11,-spread},{px+3,-spread*.35},{px+11,-spread*.08},{px+11,spread*.08},{px+3,spread*.35},{px-11,spread}}
  for _,v in ipairs(P) do points[#points+1]=v[1]+wave;points[#points+1]=v[2] end
 else
  local P={{px+8,-spread*.42},{px-6,-spread},{px-12,0},{px-6,spread},{px+8,spread*.42}}
  for _,v in ipairs(P) do points[#points+1]=v[1]+wave;points[#points+1]=v[2] end
 end
 points[#points+1]=x;points[#points+1]=5
 paint(fromHex(p.fin),.94);triangularFan(points)
 paint(fromHex(p.accent),.54);g.setLineWidth(1)
 for i=0,13 do
  local v=(i/13)*2-1
  g.line(x-2,0,px+5+wave,spread*v*.82)
 end
end
local function fins(b,p,t)
 local x=-24*b.length;local sway=sin(t)*2
 paint(fromHex(p.fin),.85)
 g.polygon('fill',x,-8,x+4,-23*b.height,x+17+sway,-38*b.height,17*b.length-11,-21*b.height,17*b.length,-7)
 paint(fromHex(p.light),.40);g.setLineWidth(.8)
 for i=1,6 do
  g.line(x+i*6,-11,x+15+i+sway,-34*b.height+i*2)
 end
 paint(fromHex(p.fin),.77)
 g.polygon('fill',-21*b.length,10,0,17*b.height,8+sin(t)*2,33*b.height,22*b.length,11)
end
local function details(b,p,pattern)
 local accent,light,back=fromHex(p.accent),fromHex(p.light),fromHex(p.back)
 if pattern==1 or pattern==6 then
  for i=1,24 do
   local u=.14+((i*37)%71)/100
   local x,top,bottom,y,h=anatomy(b,u)
   local v=(((i*19)%11)-5)/10
   paint(i%4==0 and accent or light,i%3==0 and .44 or .25)
   g.ellipse('fill',x,y+v*h*.7,.6+(i%4)*.3,.62+(i%3)*.13)
  end
 elseif pattern==2 then
  for i=1,5 do
   local u=.2+i*.11;local x,top,bottom=anatomy(b,u)
   local h=(bottom-top)*.33
   paint(i%2==0 and light or back,.27)
   g.polygon('fill',x-3,top+h*.24,x+2,top+h*.42,x+3,bottom-h*.17,x-2,bottom-h*.42)
  end
 elseif pattern==3 then
  local line={}
  for i=0,18 do
   local u=.11+i/18*.77;local x,top,bottom,y=anatomy(b,u)
   line[#line+1]=x;line[#line+1]=y+(top-y)*.13
  end
  paint(accent,.55);g.setLineWidth(2.6);g.line(line)
  paint(light,.53);g.setLineWidth(.8);g.line(line)
 elseif pattern==4 then
  paint(light,.19);g.setLineWidth(.8)
  for j=1,3 do for i=1,11 do
   local u=.18+i*.057+(j%2)*.021
   local x,top,bottom,y,h=anatomy(b,u)
   g.arc('line','open',x,y+(j-2)*h*.28,3,pi*.1,pi*.9)
  end end
 elseif pattern==5 then
  paint(accent,.57)
  for i=1,11 do
   local u=.17+i*.061;local x,top,bottom,y,h=anatomy(b,u)
   g.circle('fill',x,y+(i%3-1)*h*.33,.65+(i%3)*.29)
  end
 end
end
function A.draw(spec,x,y,scale,direction,time)
 assert(C.valid(spec),'genoma visual invalido')
 local b=C.bodies[spec.body];local f=C.fins[spec.fin];local p=C.palettes[spec.palette]
 local t=time or 0
 g.push('all');g.translate(x,y)
 g.scale((direction or 1)*(scale or 1),scale or 1)
 g.rotate(sin(t)*.026)
 tail(b,f,p,t);fins(b,p,t)
 paint({1,1,1});g.draw(mesh(b,p))
 details(b,p,spec.pattern)
 local outline=blend(fromHex(p.back),{0,.09,.16},.38)
 local top,bottom={},{}
 for i=0,44 do
  local xx,yt,yb=anatomy(b,i/44)
  top[#top+1]=xx;top[#top+1]=yt
  bottom[#bottom+1]=xx;bottom[#bottom+1]=yb
 end
 paint(outline,.66);g.setLineWidth(1.15);g.line(top);g.line(bottom)
 local sx,yt,yb,ym=anatomy(b,.63)
 paint(fromHex(p.fin),.80)
 g.polygon('fill',sx-5,ym+3,sx-16-sin(t*1.3)*3,ym+18,sx+7,ym+11)
 paint(fromHex(p.light),.49);g.line(sx-4,ym+5,sx-11-sin(t)*3,ym+16)
 local gx,_,__,gy,h=anatomy(b,.76)
 paint(fromHex(p.back),.39);g.setLineWidth(.9)
 g.arc('line','open',gx-1,gy,h*.65,-pi*.37,pi*.37)
 local ex,_,__,ey=anatomy(b,.83)
 local er=4+1.5*b.height
 paint(fromHex(p.back),.7);g.circle('fill',ex,ey-3,er+1)
 paint(fromHex(p.light));g.circle('fill',ex,ey-3,er)
 paint(fromHex(p.accent));g.circle('fill',ex+1,ey-3,er*.67)
 paint({.025,.085,.14});g.circle('fill',ex+1.4,ey-3,er*.43)
 paint({1,1,1},.96);g.circle('fill',ex+.1,ey-5,er*.23)
 local mx,_,__,my=anatomy(b,.97)
 paint(outline,.70);g.line(mx-1,my+3,mx+3,my+2)
 local glint={}
 for i=0,18 do
  local u=.31+i/18*.41;local xx,top,bot,mid,hh=anatomy(b,u)
  glint[#glint+1]=xx;glint[#glint+1]=top+hh*.43
 end
 paint(fromHex(p.light),.24);g.setLineWidth(1.2);g.line(glint)
 g.pop()
end
function A.cacheSize()local n=0;for _ in pairs(meshes)do n=n+1 end;return n end
return A
