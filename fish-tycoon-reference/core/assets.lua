-- Renderer dos sprites originais (uso local de pesquisa e referencia).
-- o.a(Graphics,int,int,m) usa corpo: largura 50; metade esquerda x=0,
-- metade direita x=50. Barbatana: largura 32; x=0 ou x=32.
-- Barbatanas nas coordenadas x+9, antes do corpo; g[1] seleciona
-- linha corporal e g[2] seleciona linha de barbatana.
local Atlas=require('core.atlas')
local Assets={};Assets.__index=Assets
function Assets.new() return setmetatable({images={},body={},fin={},available=false},Assets) end
local function loadImage(name)
 if not (love and love.graphics and love.graphics.newImage) then return nil end
 local ok,img=pcall(love.graphics.newImage,'assets/original/'..name..'.png')
 if not ok then return nil end
 img:setFilter('nearest','nearest');return img
end
function Assets:init()
 if not love.graphics.newQuad then return false end
 -- Fundos originais sao independentes dos sprites dos peixes:
 -- carregar os cenarios mesmo quando fish.png/fins.png nao estao presentes.
 for _,name in ipairs({'tank1','tank2','tank3','tanktop','isolation_tank','menutank'}) do self.images[name]=loadImage(name) end
 local fish,fin=loadImage('fish'),loadImage('fins')
 if not fish or not fin then return false end
 self.images.fish=fish;self.images.fins=fin
 -- O sprite de alevino e fixo no atlas: m.m()=100, m.l()=296,
 -- dimensoes 21x8. Jovens tem tratamento de faixa etaria separado no JAR.
 self.baby=love.graphics.newQuad(100,296,21,8,fish:getDimensions())
 self.juvenile={}
 for i=1,21 do
  local r=Atlas.juvenile[i]
  self.juvenile[i]={quad=love.graphics.newQuad(r[1],r[2],r[3],r[4],fish:getDimensions()),h=r[4]}
 end
 for i=1,21 do
  local b=Atlas.fish[i]
  local v=Atlas.fins[i]
  if b then self.body[i]={left=love.graphics.newQuad(0,b[2],50,b[4],fish:getDimensions()),right=love.graphics.newQuad(50,b[2],50,b[4],fish:getDimensions()),h=b[4]} end
  if v then self.fin[i]={left=love.graphics.newQuad(0,v[2],32,v[4],fin:getDimensions()),right=love.graphics.newQuad(32,v[2],32,v[4],fin:getDimensions()),h=v[4]} end
 end
 self.available=true
 return true
end
function Assets:drawFish(f,x,y,scale,face)
 if not self.available then return false end
 local b=self.body[f.body]
 if not b then return false end
 if (f.age or 20)<6 then
  local g=love.graphics
  local sc=scale or 1
  g.push();g.translate(x,y);g.scale(sc*((face or 1)>=0 and 1 or -1),sc)
  g.setColor(1,1,1,1)
  g.draw(self.images.fish,self.baby,-10,-4)
  g.pop()
  return true
 end
 if (f.age or 20)<20 then
  local sprite=self.juvenile[f.body]
  local g=love.graphics
  local sc=scale or 1
  g.push();g.translate(x,y);g.scale(sc*((face or 1)>=0 and 1 or -1),sc)
  g.setColor(1,1,1,1)
  g.draw(self.images.fish,sprite.quad,-17.5,-sprite.h/2)
  g.pop()
  return true
 end
 local fin=self.fin[f.tail] -- indice 20 e nulo no atlas original
 local dir=(face or 1)>=0 and 'right' or 'left'
 local g=love.graphics
 local mul=(scale or 1)
 g.push();g.translate(x-25*mul,y);g.scale(mul,mul)
 g.setColor(1,1,1,1)
 if fin and (f.age or 20)>=20 then
  g.draw(self.images.fins,fin[dir],9,-fin.h/2)
 end
 g.draw(self.images.fish,b[dir],0,-b.h/2)
 g.pop()
 return true
end
function Assets:tankBackground(room,x,y,w,h)
 -- A disponibilidade dos fundos nao depende do atlas dos peixes.
 if not (love and love.graphics and love.graphics.draw) then return false end
 local g=love.graphics
 g.setColor(1,1,1,1)
 -- O tanque de isolamento tem uma arte independente de 98x46 pixels
 -- no JAR. Ela representa um recipiente raso, nao um aquario comum.
 -- Mantemos a proporcao original e posicionamos os peixes dentro dele.
 if room=='isolation' then
  local isolated=self.images.isolation_tank
  if not isolated then return false end
  local iw,ih=isolated:getDimensions()
  local targetW=w-16
  local targetH=targetW*ih/iw
  g.draw(isolated,x+8,y+h*.50-targetH*.50,0,targetW/iw,targetH/ih)
  return true
 end
 local source=(room=='second' and 'tank2') or (room=='sale' and 'tank3') or 'tank1'
 local img=self.images[source]
 if not img then return false end
 -- A parte superior recebe o efeito de iluminacao original do tanque.
 local sky=self.images.tanktop
 if sky then g.draw(sky,x,y,0,w/sky:getWidth(),(h*.48)/sky:getHeight()) end
 local bh=h*.72
 g.draw(img,x,y+h-bh,0,w/img:getWidth(),bh/img:getHeight())
 return true
end
return Assets
