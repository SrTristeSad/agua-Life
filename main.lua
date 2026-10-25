-- agua-Life: aquario/vitrine da arte procedural original
local C=require('art.catalog')
local Art=require('art.fish')
local Rig=require('art.rigged_fish')
local DNA=require('genetics.dna')
local Health=require('genetics.health')
local g=love.graphics
local W,H=1180,760
local clock,paused,screen=0,false,'aquarium'
local school,selected={},1
local font,small,heading,logo
local buttons={}
local bubbles={}
local deathReports,examPanel={},false
local cycles=0
local showRigJoints=false
local function rng(id,salt)return ((id*73+salt*211)%997)/997 end
local function rgb(r,gg,b,a)g.setColor(r/255,gg/255,b/255,a or 1)end
local function text(s,x,y,f,r,gg,b)
 g.setFont(f or font);rgb(r or 230,gg or 247,b or 244);g.print(tostring(s),x,y)
end
local function rect(x,y,w,h,rad,r,gg,b,a)
 rgb(r,gg,b,a);g.rectangle('fill',x,y,w,h,rad,rad)
end
-- A arte modular desenha o Azul-Rubi. Os outros peixes conservam
-- o renderizador 21x21; DNA de cor e padrao troca as camadas do Azul-Rubi.
local function drawFish(spec,x,y,scale,dir,t,health)
 if Rig.draw(spec,x,y,(scale or 1)*.65,dir,t,health,showRigJoints) then return end
 Art.draw(spec,x,y,scale,dir,(t or 0)*4)
end
local function viewport()
 local ww,hh=g.getDimensions();local sc=math.min(ww/W,hh/H)
 return sc,(ww-W*sc)*.5,(hh-H*sc)*.5
end
local function btn(title,x,y,w,h,fn,active)
 rect(x,y,w,h,9,active and 45 or 25,active and 112 or 64,active and 131 or 87)
 rgb(113,212,220,.21);g.rectangle('line',x+.5,y+.5,w-1,h-1,9,9)
 g.setFont(small);rgb(239,253,250);g.printf(title,x,y+(h-14)*.5,w,'center')
 buttons[#buttons+1]={x=x,y=y,w=w,h=h,fn=fn}
end
local function choice(kind,step)
 if not school[selected] then return end
 local f=school[selected].spec
 if kind=='body' then f.body=C.wrap(f.body+step,#C.bodies)
 elseif kind=='fin' then f.fin=C.wrap(f.fin+step,#C.fins)
 elseif kind=='palette' then f.palette=C.wrap(f.palette+step,#C.palettes)
 else f.pattern=((f.pattern-1+step)%6)+1 end
 school[selected].genome=DNA.founder(f)
end
local function reset()
 school={}
 for i=1,17 do
  school[i]={
   spec=i==1 and C.get(1,1,3,1) or C.get(i,1+(i*5)%21,1+(i*3)%12,(i%6)+1),
   x=120+rng(i,1)*580,y=222+rng(i,2)*379,
   scale=.59+rng(i,3)*.35,face=(i%2==0) and -1 or 1,
   speed=15+rng(i,4)*23,phase=i*.73,
   id=i,genome=DNA.founder(i==1 and C.get(1,1,3,1) or C.get(i,1+(i*5)%21,1+(i*3)%12,(i%6)+1)),
   health=Health.new()}
 end
 selected=1;deathReports={};examPanel=false;cycles=0
end
function love.load()
 love.window.setMode(W,H,{resizable=true,minwidth=760,minheight=520,msaa=4})
 love.window.setTitle('agua-Life | Peixes originais em Lua')
 g.setDefaultFilter('linear','linear')
 font=g.newFont(17);small=g.newFont(13)
 heading=g.newFont(23);logo=g.newFont(35)
 reset()
 for i=1,72 do
  bubbles[i]={x=57+rng(i,7)*739,y=rng(i,8)*540,r=1+rng(i,9)*3,velocity=11+rng(i,10)*26}
 end
end
local function water()
 for i=0,45 do
  local t=i/45;rgb(11+t*3,62-t*21,89-t*28)
  g.rectangle('fill',40,131+i*12,792,13)
 end
 g.setBlendMode('add')
 for k=1,8 do
  local x=55+k*100+math.sin(clock*.18+k)*25
  rgb(24,63,79,.045);g.polygon('fill',x,133,x+37,133,x+114,690,x-48,690)
 end
 g.setBlendMode('alpha')
 rgb(15,47,64)
 g.polygon('fill',40,640,150,619,241,647,354,627,495,651,618,620,730,650,832,622,832,694,40,694)
 rgb(23,63,71)
 g.polygon('fill',40,663,143,649,245,669,352,650,487,670,610,647,733,666,832,650,832,696,40,696)
 for i=1,44 do
  local x=50+rng(i,11)*770;local y=654+rng(i,12)*28
  rgb(96+rng(i,13)*30,115+rng(i,4)*31,106+rng(i,5)*28,.6)
  g.ellipse('fill',x,y,3+rng(i,6)*9,2+rng(i,8)*4)
 end
 for j=1,13 do
  local rootX=60+j*57+rng(j,1)*18
  local rootY=651+rng(j,2)*20
  local height=36+rng(j,5)*77
  for branch=1,3 do
   local bend=math.sin(clock*.66+j+branch)*6
   rgb(32+rng(j,branch)*30,130+rng(j,1)*43,115+rng(j,4)*32,.63)
   g.setLineWidth(2+rng(j,branch+2)*2)
   local line={}
   for z=0,9 do
    local t=z/9
    line[#line+1]=rootX+math.sin(t*2+j+branch)*14*t+bend*t
    line[#line+1]=rootY-height*t*(.65+branch*.11)
   end
   g.line(line)
  end
 end
 for i,b in ipairs(bubbles) do
  local y=633-(b.y+clock*b.velocity)%510
  rgb(175,239,247,.2+rng(i,3)*.17)
  g.setLineWidth(.9);g.circle('line',b.x+math.sin(clock*.5+i)*7,y,b.r)
 end
 rgb(133,215,219,.5);g.setLineWidth(2);g.rectangle('line',39,130,794,565,15,15)
 rgb(207,243,239,.13);g.line(47,162,47,670)
end
local function header()
 rect(0,0,W,108,0,7,28,42)
 text('agua-Life',40,22,logo,230,249,241)
 text('ATELIE DE PEIXES PROCEDURAIS',43,73,small,112,190,190)
 btn('1 Aquario',408,36,132,35,function()screen='aquarium'end,screen=='aquarium')
 btn('2 Galeria',548,36,113,35,function()screen='gallery'end,screen=='gallery')
 btn('3 Atelie',669,36,113,35,function()screen='atelier'end,screen=='atelier')
 btn('DNA',790,36,70,35,function()examPanel=examPanel=='dna' and false or 'dna'end,examPanel=='dna')
 btn('Mortes',868,36,90,35,function()examPanel=examPanel=='death' and false or 'death'end,examPanel=='death')
 rect(969,41,180,29,15,20,64,82)
 text('LUA + LOVE2D',1000,48,small,176,231,232)
end
local function side()
 rect(853,130,287,565,17,13,42,59)
 local a=school[selected];if not a then
  text('Aquario vazio. Pressione R para reiniciar.',878,160,small)
  return
 end
 local f=a.spec
 text('Laboratorio',878,152,heading)
 text('Configure seu peixe original',878,185,small,136,187,193)
 rect(872,211,246,143,15,22,72,92)
 drawFish(f,998,285,1.10,1,clock,a.health)
 local function row(label,value,y,key)
  text(label,878,y,small,145,198,204)
  text(value,878,y+18,font)
  btn('<',1060,y+10,26,32,function()choice(key,-1)end)
  btn('>',1091,y+10,26,32,function()choice(key,1)end)
 end
 row('CORPO  '..f.body..'/21',C.bodies[f.body].name,372,'body')
 row('CAUDA  '..f.fin..'/21',C.fins[f.fin].name,433,'fin')
 row('PALETA  '..f.palette..'/12',C.palettes[f.palette].name,494,'palette')
 row('PADRAO  '..f.pattern..'/6','Ornamento '..f.pattern,555,'pattern')
 rect(875,623,240,50,10,22,73,86)
 text('441 combinacoes anatomicas',890,631,small,228,248,244)
 text('21 corpos x 21 caudas',890,650,small,140,204,213)
end
local function aquarium()
 water()
 for i,a in ipairs(school) do
  if i==selected then
   rgb(227,210,141,.2);g.ellipse('line',a.x,a.y,64*a.scale,45*a.scale)
  end
  drawFish(a.spec,a.x,a.y,a.scale,a.face,clock+a.phase,a.health)
 end
 text('AQUARIO CRIATIVO',65,151,small,187,219,217)
 text('Clique no peixe para personalizar',65,174,small,152,196,198)
end
local function gallery()
 rect(39,130,794,565,15,10,52,73)
 text('21 corpos originais',63,151,heading)
 text('Cada desenho aceita qualquer cauda e paleta.',64,189,small,147,197,202)
 local current=school[selected] and school[selected].spec or C.get(1,1,1,1)
 for i=1,21 do
  local col=(i-1)%3;local row=math.floor((i-1)/3)
  local x=63+col*254;local y=224+row*64
  local active=i==current.body
  rect(x,y,239,56,8,active and 39 or 22,active and 98 or 75,active and 112 or 90)
  drawFish(C.get(i,current.fin,current.palette,(i%6)+1),x+75,y+28,.56,1,clock+i)
  text(C.bodies[i].name,x+129,y+18,small)
  buttons[#buttons+1]={x=x,y=y,w=239,h=56,fn=function()choice('body',i-current.body);screen='aquarium'end}
 end
end
-- Atelie: o proprio sprite de jogo e exibido e as pecas originais sao
-- listadas independentemente. Sem mockup e sem sprites duplicados.
local function atelier()
 rect(39,130,794,565,15,10,52,73)
 text('Azul-Rubi | Peixe em camadas',62,149,heading)
 text('Articulacoes reais: cauda, dorsal, ventral, peitoral e olho',62,182,small,142,209,217)
 text('J: mostrar as articulacoes de movimento',62,204,small,142,209,217)
 rect(63,233,747,273,14,15,64,83)
 local exemplar=school[selected]
 local spec=Rig.supports(exemplar and exemplar.spec) and exemplar.spec or C.get(1,1,3,1)
 if not Rig.draw(spec,415,368,1.42,1,clock,
     Rig.supports(exemplar and exemplar.spec) and exemplar.health or nil,showRigJoints) then
  text('Sprites PNG ainda nao encontrados; confira assets/fish/azul_rubi/',78,355,small)
 end
 local cards={{'CORPO','body'},{'CAUDA','tail'},{'DORSAL','dorsal'},
  {'VENTRAL','pelvic'},{'PEITORAL','pectoral'},{'OLHO','eye'}}
 for i,item in ipairs(cards) do
  local x=51+(i-1)*129
  rect(x,529,119,141,10,19,71,91)
  Rig.drawPart(item[2],x+5,545,109,95)
  text(item[1],x+10,647,small,229,241,242)
 end
end
function love.update(dt)
 if paused then return end
 dt=math.min(dt,.1);clock=clock+dt
 cycles=cycles+dt
 if cycles>=5 then
  cycles=cycles-5
  for i=#school,1,-1 do
   local f=school[i]
   if not Health.cycle(f) then
    deathReports[#deathReports+1]=Health.autopsy(f)
    while #deathReports>30 do table.remove(deathReports,1) end
    table.remove(school,i)
    if selected>#school then selected=#school end
   end
  end
 end
 if screen~='aquarium' then return end
 for _,a in ipairs(school) do
  a.x=a.x+a.face*a.speed*dt
  if a.x>770 then a.x=770;a.face=-1 elseif a.x<112 then a.x=112;a.face=1 end
  a.y=math.max(229,math.min(603,a.y+math.sin(clock*.7+a.phase)*dt*3))
 end
end
function love.draw()
 -- Teste nativo opcional no CI: valida que PNGs e articulacoes realmente
 -- renderizam na GPU (ao contrario de testar apenas sintaxe Lua).
 if os.getenv('AGUA_RIG_SMOKE')=='1' then
  local sample=C.get(1,1,3,1)
  assert(Rig.assetsReady(sample),'PNG modular ausente')
  g.clear(.02,.12,.17)
  assert(Rig.draw(sample,360,300,1.3,1,clock,nil,true),'Desenho modular falhou')
  for i,name in ipairs({'body','tail','dorsal','pelvic','pectoral','eye'}) do
   assert(Rig.drawPart(name,50+(i-1)*125,490,105,105),'Parte nao carregou: '..name)
  end
  print('OK LÖVE: rig Azul-Rubi com camadas reais')
  love.event.quit(0)
  return
 end
 local sc,ox,oy=viewport()
 g.clear(.024,.09,.13)
 g.push('all');g.translate(ox,oy);g.scale(sc,sc)
 buttons={}
 header()
 if screen=='aquarium' then aquarium()
 elseif screen=='gallery' then gallery()
 else atelier() end
 side()
 if examPanel then
  local lines
  if examPanel=='dna' then
   lines=school[selected] and DNA.lines(school[selected]) or {'Nenhum peixe selecionado.'}
  else lines=Health.deathLines(deathReports[#deathReports]) end
  rect(240,190,530,430,17,11,38,54,.98)
  for i,line in ipairs(lines) do
   text(line,265,208+(i-1)*30,i==1 and heading or font)
  end
  btn('FECHAR',639,569,105,33,function()examPanel=false end)
 end
 rect(0,707,W,53,0,8,29,42)
 text('1 Aquario  2 Galeria  3 Atelie  |  J articulacoes  |  N cruzar  |  F alimentar  H tratar  |  R reiniciar',40,726,small,175,215,212)
 text(paused and 'PAUSADO' or ('Peixes: '..#school),1049,726,small)
 g.pop()
end
function love.mousepressed(x,y,button)
 if button~=1 then return end
 local sc,ox,oy=viewport();x=(x-ox)/sc;y=(y-oy)/sc
 for i=#buttons,1,-1 do
  local b=buttons[i]
  if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then b.fn();return end
 end
 if screen~='aquarium' then return end
 local best,distance
 for i,a in ipairs(school) do
  local dx,dy=(x-a.x)/(55*a.scale),(y-a.y)/(27*a.scale)
  local d=dx*dx+dy*dy
  if d<1.1 and (not distance or d<distance) then best=i;distance=d end
 end
 if best then selected=best end
end
function love.keypressed(k)
 if k=='space' then paused=not paused
 elseif k=='1' then screen='aquarium'
 elseif k=='2' then screen='gallery'
 elseif k=='3' then screen='atelier'
 elseif k=='j' then showRigJoints=not showRigJoints
 elseif k=='right' then choice('body',1)
 elseif k=='left' then choice('body',-1)
 elseif k=='up' then choice('fin',1)
 elseif k=='down' then choice('fin',-1)
 elseif k=='c' then choice('palette',1)
 elseif k=='x' then choice('pattern',1)
 elseif k=='r' then reset()
 elseif k=='f8' then examPanel=examPanel=='dna' and false or 'dna'
 elseif k=='f9' then examPanel=examPanel=='death' and false or 'death'
 elseif k=='escape' then examPanel=false
 elseif k=='f' and school[selected] then Health.feed(school[selected])
 elseif k=='h' and school[selected] then Health.treat(school[selected])
 elseif k=='n' and #school>1 and #school<30 then
  local a=school[selected];local b=school[selected==#school and 1 or selected+1]
  local child=DNA.child(a.genome,b.genome)
  local spec=DNA.express(child)
  school[#school+1]={id=#school+1,genome=child,spec=spec,health=Health.new(),
   x=240+rng(#school,1)*380,y=300+rng(#school,2)*260,
   scale=.55,face=1,speed=20,phase=clock}
 elseif k=='f12' then g.captureScreenshot(os.date('agua-life-%Y%m%d-%H%M%S.png')) end
end
