-- V32: faixa etaria, tamanho nativo do JAR, alvo e limites do painel.
package.path='./?.lua;./?/init.lua;'..package.path
local Geometry=require('ui.fish_geometry')
local Atlas=require('core.atlas')
local Game=require('core.game')
local Retro=require('ui.retro')
local noop=function() end
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'))
  local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local o={w=n(17),h=n(21),setFilter=noop}
  function o:getDimensions()return self.w,self.h end
  function o:getWidth()return self.w end
  function o:getHeight()return self.h end
  return o
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
}}
for _,op in ipairs({'setColor','rectangle','line','push','pop','translate','scale','setFont','clear','printf','draw'}) do love.graphics[op]=noop end
local g=Game.new(3200)
local v=Retro.new(g,true);v:init()
local renders={}
local original=v.assets.drawFish
v.assets.drawFish=function(self,f,x,y,scale,face)
 renders[#renders+1]={id=f.id,x=x,y=y,scale=scale,age=f.age}
 return original(self,f,x,y,scale,face)
end
local count=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V32 '..name..': '..tostring(err))
 count=count+1;print('OK '..name)
end
check('m.a() corresponde a 21, 35, 50 pixels nos limites 5/6 e 19/20',function()
 for _,case in ipairs({{0,21},{5.99,21},{6,35},{19.99,35},{20,50},{100,50}}) do
  local w=Geometry.size({age=case[1],body=1,tail=1})
  assert(w==case[2])
 end
end)
check('largura juvenil e altura original de todas as 21 variantes',function()
 for b=1,21 do
  local w,h=Geometry.size({age=12,body=b,tail=1})
  assert(w==35 and h==Atlas.juvenile[b][4])
 end
end)
check('adultos incluem as barbatanas na altura de desenho',function()
 for b=1,21 do for t=1,21 do
  local w,h=Geometry.size({age=21,body=b,tail=t})
  local fin=Atlas.fins[t]
  assert(w==50)
  assert(h==math.max(Atlas.fish[b][4],fin and fin[4] or 0))
 end end
end)
check('sprites usam escala 1 sem reduzir as artes originais',function()
 g.s.tanks.main={g.s.tanks.main[1],g.s.tanks.main[2],g.s.tanks.main[3]}
 local ages={2,12,25}
 for i,f in ipairs(g.s.tanks.main) do f.age=ages[i] end
 v.screen='tank';v.room='main';v.time=2
 renders={};v:draw()
 assert(#renders==3)
 for _,r in ipairs(renders) do assert(r.scale==1) end
 assert(v.fishHits[1].rx==10.5 and v.fishHits[2].rx==17.5 and v.fishHits[3].rx==25)
end)
check('todos os sprites cabem na agua sem invadir HUD ou bandeja',function()
 for t=0,55,2.35 do
  renders={};v.time=t;v:draw()
  for i,f in ipairs(g.s.tanks.main) do
   local hit=v.fishHits[i]
   local w,h=Geometry.size(f)
   assert(hit.x-w/2>=2-1e-6 and hit.x+w/2<=238+1e-6)
   assert(hit.y-h/2>=35-1e-6 and hit.y+h/2<=270+1e-6)
  end
 end
end)
check('selecionado continua na ancora original e navega normalmente',function()
 v.screen='detail';v.selected=g.s.tanks.main[3].id
 renders={};v:draw()
 local r=renders[#renders]
 assert(r.id==v.selected and r.x==91 and r.y==53 and r.scale==1)
 assert(v.g.s.version==9)
 v:key('escape'); assert(v.screen=='tank')
end)
print('V32: '..count..' testes de tamanho e interface passaram.')
