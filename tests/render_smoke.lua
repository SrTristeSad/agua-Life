-- Smoke test do desenho sem necessidade de GPU/SDL
package.path='./?.lua;./?/init.lua;'..package.path
local function validate(...)
 for i=1,select('#',...) do
  local v=select(i,...)
  if type(v)=='table' then
   for _,n in ipairs(v) do assert(type(n)=='number' and n==n) end
  elseif type(v)=='number' then
   assert(v==v and v>-1e8 and v<1e8)
  end
 end
end
local g={}
for _,name in ipairs({'setColor','setLineWidth','push','pop','translate','scale','rotate','draw','polygon','line','ellipse','circle','arc'}) do
 g[name]=function(...) validate(...) end
end
local count=0
function g.newMesh(verts,mode,usage)
 assert(mode=='triangles' and usage=='static')
 assert(#verts>0 and #verts%3==0)
 for _,v in ipairs(verts) do
  assert(#v==8)
  for _,n in ipairs(v) do assert(type(n)=='number' and n==n) end
 end
 count=count+1
 return {}
end
love={graphics=g}
local C=require('art.catalog')
local A=require('art.fish')
for b=1,21 do
 for f=1,21 do
  local spec=C.get(b,f,(b+f)%12+1,(b+f)%6+1)
  A.draw(spec,300,200,.7,1,(b+f)*.17)
  A.draw(spec,300,200,.7,-1,(b+f)*.31)
 end
end
assert(count>0)
print('OK: 441 especies visuais renderizadas em 2 direcoes; malhas=',count)
