-- V31: trajetorias livres e reversao de direcao inspiradas no bytecode J2ME.
package.path='./?.lua;./?/init.lua;'..package.path
local Motion=require('ui.j2me_motion')
local Game=require('core.game')
local Retro=require('ui.retro')
local calls=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V31 '..name..': '..tostring(err))
 calls=calls+1;print('OK '..name)
end
local sample={id=3101,age=21,health=100,body=1,tail=2}
check('a trajetoria independe da ordem no tanque e do RNG da simulacao',function()
 local a,b,c=Motion.position(sample,1,'main',7.25)
 local x,y,d=Motion.position(sample,18,'main',7.25)
 assert(a==x and b==y and c==d)
 local g=Game.new(3110)
 local before=g.s.rng
 for i=1,150 do Motion.position(sample,i,'second',i/5) end
 assert(g.s.rng==before)
end)
check('coordenadas, orientacoes e limites mantidos por horas',function()
 for id=1,50 do
  local fish={id=id,age=id%6==0 and 3 or 25}
  for _,room in ipairs({'main','second','sale'}) do
   for t=0,5400,37 do
    local x,y,face=Motion.position(fish,id%18+1,room,t)
    assert(x>=27 and x<=213,('x fora do tanque: '..x))
    assert(y>=40 and y<=253,('y fora do tanque: '..y))
    assert(face==1 or face==-1)
   end
  end
 end
end)
check('composicao inicial nao depende de grade de quatro colunas',function()
 local xs,ys={},{}
 local minx,maxx,miny,maxy=999,-999,999,-999
 for id=1,18 do
  local x,y=Motion.position({id=id,age=21},id,'main',0)
  xs[math.floor(x+.5)]=true;ys[math.floor(y+.5)]=true
  minx=math.min(minx,x);maxx=math.max(maxx,x)
  miny=math.min(miny,y);maxy=math.max(maxy,y)
 end
 local nx,ny=0,0
 for _ in pairs(xs) do nx=nx+1 end
 for _ in pairs(ys) do ny=ny+1 end
 assert(nx>=13 and ny>=13,('distribuicao repetida %d,%d'):format(nx,ny))
 assert(maxx-minx>=105 and maxy-miny>=115,'Aquario nao foi ocupado em area ampla')
end)
check('velocidade adulta baseada em 16.16 e alevino mais lento',function()
 local id=300
 local adult={id=id,age=25}
 local fry={id=id,age=2}
 local ax,ay=Motion.position(adult,1,'main',0)
 local ax1,ay1=Motion.position(adult,1,'main',.05)
 local bx,by=Motion.position(fry,1,'main',0)
 local bx1,by1=Motion.position(fry,1,'main',.05)
 assert(math.abs(ax1-ax)>.8 and math.abs(ax1-ax)<1.0)
 assert(math.abs(ay1-ay)>.2 and math.abs(ay1-ay)<.4)
 assert(math.abs(bx1-bx)<.1 and math.abs(by1-by)<.1)
 assert(by>=229 and by<=253)
end)
check('reflexao troca o sentido depois de atingir os limites',function()
 local fish={id=1,age=25}
 local previous
 local turns=0
 for t=0,100,0.1 do
  local x,y,dir=Motion.position(fish,1,'main',t)
  if previous and dir~=previous then turns=turns+1 end
  previous=dir
 end
 assert(turns>=6,'Peixe nao inverteu direcao')
end)
check('motor, ids e saves nao mudam so por desenhar movimento',function()
 local g=Game.new(3120)
 local before=g.s.rng
 local initial={}
 for _,f in ipairs(g.s.tanks.main) do
  initial[#initial+1]={id=f.id,body=f.body,tail=f.tail,age=f.age}
  for t=0,10,.05 do Motion.position(f,1,'main',t) end
 end
 assert(g.s.version==9 and g.s.rng==before)
 for i,f in ipairs(g.s.tanks.main) do
  local orig=initial[i]
  assert(f.id==orig.id and f.body==orig.body and f.tail==orig.tail and f.age==orig.age)
 end
end)
print('V31: '..calls..' verificacoes do nado inspiradas no JAR aprovadas')
