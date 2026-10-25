-- agua-Life: base jogavel Lua + LOVE2D. Nenhuma dependencia de browser.
local C=require('art.catalog')
local Art=require('art.fish')
local Matrix=require('art.matrix')
local Rig=require('art.rigged_fish')
local DNA=require('genetics.dna')
local Health=require('genetics.health')
local Play=require('game.play')
local Storage=require('game.storage')
local g=love.graphics
local W,H=1180,760
local font,small,titleFont,logo,fontTiny
local world,saved,loadError
local screen='title'
local room='main'
local selectedId=nil
local breedParent=nil
local modal=nil
local paused=false
local clock=0
local autosave=0
local message='Selecione um peixe para começar.'
local messageTime=0
local joints=false
local buttons={}
local uiError=false
local bubbles={}
local function rng(i,k)return ((i*73+k*211)%997)/997 end
local function setColor(r,gg,b,a)g.setColor(r/255,gg/255,b/255,a or 1)end
local function rect(x,y,w,h,r,gg,b,rad,opacity)
 setColor(r,gg,b,opacity)
 g.rectangle('fill',x,y,w,h,rad or 0,rad or 0)
end
local function line(x1,y1,x2,y2,r,gg,b,alpha,thickness)
 setColor(r,gg,b,alpha);g.setLineWidth(thickness or 1);g.line(x1,y1,x2,y2)
end
local function text(s,x,y,style,r,gg,b)
 g.setFont(style or font);setColor(r or 231,gg or 246,b or 245)
 g.print(tostring(s),x,y)
end
local function center(s,x,y,w,style,r,gg,b)
 g.setFont(style or font);setColor(r or 231,gg or 246,b or 245)
 g.printf(tostring(s),x,y,w,'center')
end
local function addButton(label,x,y,w,h,action,selected,disabled,inModal)
 local bg=disabled and {27,46,53} or selected and {36,115,126} or {26,72,88}
 rect(x,y,w,h,bg[1],bg[2],bg[3],8)
 if not disabled then
  setColor(84,175,190,.55);g.rectangle('line',x+.5,y+.5,w-1,h-1,8,8)
 end
 center(label,x,y+(h-(small:getHeight()))/2,w,small,
   disabled and 108 or 228,disabled and 131 or 247,disabled and 135 or 245)
 buttons[#buttons+1]={x=x,y=y,w=w,h=h,action=action,disabled=disabled,modal=inModal}
end
local function viewport()
 local w,h=g.getDimensions()
 local s=math.min(w/W,h/H)
 return s,(w-W*s)/2,(h-H*s)/2
end
local function announce(msg)
 message=tostring(msg or '');messageTime=5
end
local function activeFish()
 return world and selectedId and world:find(selectedId) or nil
end
local function firstFish()
 if not world then return nil end
 for _,f in ipairs(world.s.fish) do if f.room==room then return f end end
end
local function findSelection()
 local f=activeFish()
 if f and f.room==room then return f end
 local one=firstFish()
 selectedId=one and one.id or nil
 return one
end
local function save()
 if not world then return end
 local ok,err=Storage.save(world)
 if not ok then announce('Falha ao salvar: '..tostring(err))
 else saved=world end
 return ok
end
local function action(ok,msg)
 if msg then announce(msg)
 elseif ok and world then announce(world.s.events[#world.s.events] and world.s.events[#world.s.events].text or 'Pronto.') end
 if ok then save() end
 return ok
end
local function setRoom(which)
 room=which;screen='aquarium';selectedId=nil;findSelection()
 if which=='nursery' and world and not world.s.upgrades.nursery then
  announce('Aquário 2 bloqueado. Compre na loja.')
 end
end
local function beginNew()
 local nextGame,err=Storage.newGame(os.time())
 if not nextGame then announce(err);return false end
 world=nextGame;saved=nextGame
 selectedId=nil;breedParent=nil
 modal=nil;screen='aquarium';room='main';paused=false;clock=0
 findSelection()
 announce('Nova partida criada e salva.')
 return true
end
local function resume()
 if not saved then announce('Sem partida salva. Inicie uma nova.');return end
 world=saved;room='main';selectedId=nil;screen='aquarium';modal=nil
 paused=false;findSelection()
 announce('Partida recuperada.')
end
local function drawFish(spec,x,y,scale,face,t,health,showJoints)
 local k=scale or 1
 if Matrix.draw(spec,x,y,k*1.62,face,t,health,showJoints) then return end
 if Rig.supports(spec) and Rig.draw(spec,x,y,k*.60,face,t,health,showJoints) then return end
 Art.draw(spec,x,y,k,face,t*3.1)
end
local function bar(x,y,w,value,r,gg,b)
 rect(x,y,w,10,22,58,74,5)
 rect(x+1,y+1,math.max(0,(w-2)*math.max(0,math.min(100,value))/100),8,r,gg,b,4)
end
local function tabs()
 rect(0,0,W,116,8,30,45)
 text('agua-Life',25,15,logo,230,250,244)
 text('AQUARIO GENETICO',28,64,fontTiny,140,197,208)
 text('Moedas  $'..world.s.cash,259,20,small,255,226,150)
 text('Dia '..world.s.days,397,20,small,207,237,239)
 text('Racao '..world.s.food,494,20,small,150,229,207)
 text('Remedios '..world.s.medicine,603,20,small,207,190,246)
 text('Peixes '..#world.s.fish,764,20,small,194,226,236)
 local items={
  {'1 Aquario',function()setRoom('main')end,screen=='aquarium' and room=='main',111},
  {'2 Viveiro',function()setRoom('nursery')end,screen=='aquarium' and room=='nursery',111},
  {'3 Loja',function()screen='store'end,screen=='store',104},
  {'4 DNA',function()screen='lab'end,screen=='lab',90},
  {'5 Colecao',function()screen='collection'end,screen=='collection',119},
  {'6 Atelie',function()screen='atelier'end,screen=='atelier',108},
  {'Menu',function()save();screen='title'end,false,85}
 }
 local x=261
 for _,it in ipairs(items) do
  addButton(it[1],x,69,it[4],33,it[2],it[3])
  x=x+it[4]+7
 end
end
local function aquariumBackdrop()
 rect(27,135,801,564,10,58,80,15)
 for i=0,58 do
  local t=i/58
  rect(28,137+i*9.1,798,10,
    math.floor(10+t*7),math.floor(79-t*47),math.floor(109-t*52))
 end
 g.setBlendMode('add')
 for j=1,6 do
  local x=55+j*112+math.sin(clock*.17+j)*20
  setColor(60,114,145,.03)
  g.polygon('fill',x,138,x+32,138,x+100,670,x-48,670)
 end
 g.setBlendMode('alpha')
 setColor(17,51,62)
 g.polygon('fill',28,663,151,640,292,673,432,641,568,671,707,641,827,657,827,698,28,698)
 for i=1,12 do
  local root=65+i*60
  local len=44+rng(i,2)*86
  local bend=math.sin(clock*.75+i)*6
  for k=1,2 do
   setColor(33+rng(i,k)*17,130+rng(i,3)*43,113+rng(i,1)*20,.60)
   g.setLineWidth(2+rng(i,k)*2)
   g.line(root,666,root-8+bend*.3,666-len*.4,root-19+bend,666-len)
  end
 end
 for i,p in ipairs(bubbles) do
  local py=650-(p.y+clock*p.speed)%520
  setColor(153,226,242,.2+rng(i,3)*.25)
  g.setLineWidth(1);g.circle('line',p.x+math.sin(clock+i)*5,py,p.r)
 end
 setColor(127,202,223,.48)
 g.setLineWidth(2);g.rectangle('line',27,135,801,564,15,15)
end
local function activeCount()
 return world:roomCount(room)
end
local function aquarium()
 aquariumBackdrop()
 text(room=='main' and 'AQUARIO PRINCIPAL' or 'VIVEIRO',49,148,titleFont,220,249,248)
 local max=Play.CAPACITY[room]
 text(activeCount()..'/'..max..' peixes',673,155,small,193,221,221)
 if room=='nursery' and not world.s.upgrades.nursery then
  rect(215,300,410,161,12,21,54,71,.94)
  center('AQUARIO 2 BLOQUEADO',215,320,410,titleFont)
  center('Desbloqueie na Loja para separar seus peixes.',215,374,410,small)
  addButton('Ir para a Loja',327,412,184,34,function()screen='store'end)
  return
 end
 for _,f in ipairs(world.s.fish) do
  if f.room==room then
   local stage=f.health.age<20 and (.53+f.health.age*.007) or .72
   if f.id==selectedId then
    setColor(255,213,119,.35);g.setLineWidth(2)
    g.ellipse('line',f.x,f.y,stage*77,stage*49)
   end
   drawFish(f.spec,f.x,f.y,stage,f.direction,clock+f.phase,f.health)
   if f.health.disease then
    setColor(255,154,152,.9);g.circle('fill',f.x+15,f.y-34,3)
   end
  end
 end
 if breedParent then
  rect(62,627,733,33,9,26,86,105,.92)
  text('Cruzar: escolha outro peixe adulto no aquario. [ESC cancela]',78,633,small,250,244,196)
 end
end
local function sellSelected()
 local f=activeFish()
 if not f then return announce('Selecione um peixe.') end
 modal='sell'
end
local function breedSelected()
 local f=activeFish()
 if not f then return announce('Selecione um peixe.') end
 if f.health.age<20 then return announce('O peixe precisa ser adulto (20 ciclos).') end
 if breedParent==f.id then breedParent=nil;announce('Cruzamento cancelado.');return end
 breedParent=f.id
 screen='aquarium';room=f.room
 announce('Selecione o outro peixe adulto do mesmo aquario.')
end
local function clickFish(f)
 if breedParent then
  if not world:find(breedParent) then breedParent=nil;announce('O primeiro peixe saiu do aquario.');return end
  local parent=breedParent;breedParent=nil
  local ok,msg=world:breed(parent,f.id)
  action(ok,msg or (ok and 'Cruzamento iniciado.'))
  selectedId=f.id
 else
  selectedId=f.id
  announce('Peixe #'..f.id..' selecionado.')
 end
end
local function sidebar()
 rect(849,135,304,564,14,40,56,16)
 local f=findSelection()
 if not f then
  text('Meus peixes',871,158,titleFont)
  center('Nenhum peixe aqui.',862,274,276,font)
  center('Use a Loja para comprar ovos.',862,302,276,small,176,208,208)
  addButton('Ir para a Loja',871,392,262,39,function()screen='store'end)
  return
 end
 text('PEIXE  #'..f.id,868,149,titleFont)
 text('Geração '..f.genome.generation,1032,156,small,160,220,215)
 rect(865,192,273,142,12,23,72,91)
 drawFish(f.spec,1000,265,1.18,1,clock+f.phase,f.health,joints)
 local name=C.bodies[f.spec.body].name..' / '..C.fins[f.spec.fin].name
 text(name,871,344,small)
 text('Idade '..f.health.age..'  |  '..(f.health.age>=20 and 'Adulto' or 'Jovem'),871,370,small,179,223,230)
 text('Saude',871,397,small,196,231,233)
 bar(947,398,180,f.health.hp,58,200,147)
 text('Fome',871,421,small,196,231,233)
 bar(947,421,180,f.health.fed,214,184,81)
 text(f.health.disease and ('Doente: '..f.health.disease) or 'Sem doenca ativa',871,451,small,
  f.health.disease and 255 or 149,f.health.disease and 142 or 226,f.health.disease and 135 or 191)
 text('Valor de venda: $'..world:price(f),871,477,small,253,214,143)
 addButton('Alimentar [F]',868,512,129,39,function()
  local ok,msg=world:feed(f.id);action(ok,msg)
 end,false,world.s.food<=0)
 addButton('Tratar [H]',1004,512,129,39,function()
  local ok,msg=world:treat(f.id);action(ok,msg)
 end,false,not f.health.disease or world.s.medicine<=0)
 addButton(breedParent and 'Cancelar cruzamento' or 'Cruzar [B]',868,560,265,38,breedSelected,false,f.health.age<20)
 addButton('Vender',868,610,129,38,sellSelected,false,f.health.age<20)
 addButton('Mover',1004,610,129,38,function()
  local ok,msg=world:transfer(f.id)
  if ok then selectedId=nil end
  action(ok,msg)
 end,false,not world:canAdd(f.room=='main' and 'nursery' or 'main'))
 addButton('Ver DNA [F8]',868,655,265,31,function()modal='dna'end)
end
local function storeCard(x,y,w,h,title,description,cost,button,fn,disabled)
 rect(x,y,w,h,16,57,74,13)
 text(title,x+18,y+15,titleFont)
 text(description,x+18,y+55,small,171,210,216)
 text('Preco: $'..cost,x+18,y+86,font,252,219,143)
 addButton(button,x+w-157,y+h-52,140,35,fn,false,disabled)
end
local function store()
 rect(27,135,801,564,12,43,60,14)
 text('LOJA DE AQUARISMO',53,156,titleFont)
 text('Cuide da sua colecao, compre ovos e melhore os tanques.',53,190,small,172,213,220)
 local goods={
  {'Racao','+6 porcoes de alimento',Play.PRICES.food,'COMPRAR', 'food'},
  {'Remedios','+3 tratamentos para infeccoes',Play.PRICES.medicine,'COMPRAR','medicine'},
  {'Ovos especiais','1 filhote aleatorio no aquario',Play.PRICES.egg,'CHOCAR','egg'},
  {'Aquario 2','Novo espaco para 14 peixes',Play.PRICES.nursery,'DESBLOQUEAR','nursery'},
  {'Pesquisa de cuidado','Melhora recuperacao de saude',Play.PRICES.care*(world.s.upgrades.care+1),'PESQUISAR','care'}
 }
 for i,it in ipairs(goods) do
  local row=math.floor((i-1)/2);local col=(i-1)%2
  local x=52+col*382;local y=220+row*149
  local kind=it[5]
  local bought=kind=='nursery' and world.s.upgrades.nursery or kind=='care' and world.s.upgrades.care>=3
  local label=bought and 'CONCLUIDO' or it[4]
  storeCard(x,y,366,135,it[1],it[2],it[3],label,function()
   local ok,result=world:buy(kind)
   if ok and kind=='egg' then selectedId=result.id end
   action(ok,type(result)=='string' and result or nil)
  end,bought or world.s.cash<it[3])
 end
 local y=220+2*149
 rect(434,y,369,135,16,75,91,13)
 text('Suas pesquisas',452,y+14,titleFont)
 text('Cuidados: '..world.s.upgrades.care..'/3',452,y+52,small,194,229,228)
 text('Aquario 2: '..(world.s.upgrades.nursery and 'aberto' or 'bloqueado'),452,y+79,small,194,229,228)
end
local function lab()
 rect(27,135,801,564,13,43,60,13)
 text('LABORATORIO DE DNA',53,158,titleFont)
 text('Corpo + cauda + paleta + padrao = descendente unico.',53,188,small,170,212,217)
 local f=activeFish() or firstFish()
 if not f then
  text('Sem peixes para examinar.',65,286)
  return
 end
 local p=DNA.profile(f)
 drawFish(f.spec,185,342,1.42,1,clock,f.health)
 rect(333,229,455,323,12,22,73,93)
 local gnome=f.genome
 text('PEIXE #'..f.id..'   GERACAO '..gnome.generation,355,246,titleFont)
 local rows={
  {'Corpo',gnome.body[1],gnome.body[2]},
  {'Cauda',gnome.fin[1],gnome.fin[2]},
  {'Cor',gnome.palette[1],gnome.palette[2]},
  {'Estampa',gnome.pattern[1],gnome.pattern[2]}}
 for i,entry in ipairs(rows) do
  local y=300+(i-1)*46
  text(entry[1],355,y,small)
  rect(480,y-2,66,28,16,108,131,8)
  rect(559,y-2,66,28,64,112,126,8)
  center(tostring(entry[2]),480,y,66,small)
  center(tostring(entry[3]),559,y,66,small)
 end
 text('Resistencia '..p.resistance..'/100',637,299,small)
 text('Predisp.: '..p.predisposition,637,329,small)
 text('Valor: $'..world:price(f),637,359,small,244,212,154)
 text(p.heterozygous and 'Carrega genes recessivos' or 'Pares identicos',637,405,small,153,230,232)
 addButton('Iniciar cruzamento',368,502,380,39,breedSelected,false,f.health.age<20)
 rect(57,579,731,82,12,18,78,85)
 text('Como cruzar: no aquario, selecione um adulto e clique em Cruzar.',73,594,small)
 text('Depois clique em outro adulto. O nascimento leva quatro ciclos (~24 s).',73,620,small,186,221,220)
end
local function collection()
 rect(27,135,801,564,12,24,65,86)
 text('CATALOGO GENETICO  -  21 CORPOS x 21 CAUDAS',46,148,titleFont,219,243,242)
 local count=0;for _,seen in pairs(world.s.discovered) do if seen then count=count+1 end end
 text('Descobertos: '..count..'/441',585,155,small,254,222,159)
 local x0=76;local y0=204;local dx=35.0;local dy=21.1
 for tail=1,21 do
  center('F'..tail,x0+(tail-1)*dx-16,180,34,fontTiny,177,219,228)
 end
 for body=1,21 do
  text('C'..body,36,y0+(body-1)*dy-6,fontTiny,174,219,226)
  for tail=1,21 do
   local x=x0+(tail-1)*dx;local y=y0+(body-1)*dy
   local key=body..'-'..tail
   local discovered=world.s.discovered[key]
   if discovered then rect(x-17,y-9,34,19,21,106,110,2,.38) end
   local spec=C.get(body,tail,(body-1)%12+1,(body-1)%6+1)
   -- Uma grade 21x21 real, composta a partir dos indices geneticos.
   if not Matrix.drawStatic(spec,x,y,.33,1,clock*.24+body*.15) then
    Art.draw(spec,x,y,.185,1,clock*2+body*.15)
   end
  end
 end
 rect(51,658,749,28,8,14,80,99)
 text('Corpo (C) vem das linhas. Barbatanas (F) vêm das colunas. Destaques = encontrados.',60,665,fontTiny)
end
local function atelier()
 rect(27,135,801,564,12,20,61,78)
 text('ATELIE DE ANIMACAO  |  MATRIZ C x F',52,154,titleFont)
 text('Recortes da imagem: corpo, cauda, dorsal e ventral animados.',52,189,small,184,225,224)
 rect(57,223,739,267,12,21,80,94)
 local f=activeFish()
 local spec=f and f.spec or C.get(1,1,3,1)
 if not Matrix.draw(spec,410,355,2.4,1,clock,f and f.health or nil,joints) then
  drawFish(spec,410,355,2,1,clock,f and f.health)
  text('Coloque atlas_441.png em assets/fish/matrix para ativar os sprites.',75,476,small)
 end
 local labels={{'CORPO','body'},{'CAUDA','tail'},
  {'DORSAL','dorsal'},{'VENTRAL','ventral'}}
 for i,item in ipairs(labels) do
  local x=72+(i-1)*177
  rect(x,519,162,150,10,61,80,10)
  Matrix.drawPart(spec,item[2],x+7,529,148,109)
  center(item[1],x,646,162,fontTiny)
 end
 addButton(joints and 'Ocultar juntas [J]' or 'Ver juntas [J]',538,171,241,31,function()joints=not joints end)
end
local function frame()
 tabs()
 if screen=='aquarium' then aquarium()
 elseif screen=='store' then store()
 elseif screen=='lab' then lab()
 elseif screen=='collection' then collection()
 elseif screen=='atelier' then atelier()
 end
 sidebar()
 rect(0,709,W,51,7,28,42)
 local events=world.s.events
 local last=events[#events]
 local msg=messageTime>0 and message or (last and last.text or 'Escolha um peixe para cuidar.')
 text(msg:sub(1,99),25,727,small,194,222,223)
 addButton(paused and 'RETOMAR [P]' or 'PAUSAR [P]',912,719,119,31,function()
  paused=not paused;announce(paused and 'Simulacao pausada.' or 'Simulacao retomada.')
 end,paused)
 addButton('SALVAR',1039,719,112,31,function()
  if save() then announce('Partida salva com sucesso.') end
 end)
end
local function drawHome()
 rect(0,0,W,H,8,28,45)
 text('agua-Life',74,70,logo,220,250,245)
 text('AQUARIO VIVO  |  SIMULACAO GENETICA',78,135,titleFont,159,211,216)
 rect(50,210,755,448,13,57,76,17)
 drawFish(C.get(1,1,3,1),257,390,2.1,1,clock)
 drawFish(C.get(4,7,2,2),597,344,1.55,-1,clock+2.5)
 drawFish(C.get(8,8,6,3),529,521,1.06,1,clock+1.3)
 rect(850,210,284,448,12,46,66,15)
 text('INICIAR JOGO',866,247,titleFont,237,250,242)
 text('Cuide, cruze e descubra',866,286,small,184,215,218)
 text('novas variedades de peixes.',866,309,small,184,215,218)
 addButton('CONTINUAR',866,370,252,47,resume,false,not saved)
 addButton('NOVA PARTIDA',866,430,252,47,function()
  if saved then modal='new' else beginNew() end
 end)
 addButton('COMO JOGAR',866,490,252,42,function()modal='help'end)
 addButton('SAIR',866,542,252,42,function()love.event.quit(0)end)
 text(saved and 'Salvamento encontrado.' or 'Nenhuma partida salva.',866,617,fontTiny,160,204,211)
 text('Base jogavel - Lua + LOVE2D',74,708,small,157,207,209)
end
local function modalButton(label,x,y,w,cb)
 addButton(label,x,y,w,38,cb,false,false,true)
end
local function overlay()
 if not modal then return end
 rect(0,0,W,H,2,12,21,0,.76)
 rect(263,146,655,460,17,55,73,17,.99)
 if modal=='dna' then
  local f=activeFish()
  text('EXAME DE DNA',290,169,titleFont)
  local rows=f and DNA.lines(f) or {'Nenhum peixe selecionado.'}
  for i,r in ipairs(rows) do
   if i<=12 then text(r,292,218+(i-1)*29,small) end
  end
 elseif modal=='death' then
  text('REGISTRO DE NECROPSIAS',290,169,titleFont)
  local r=world and world.s.deaths[#world.s.deaths] or nil
  local rows=Health.deathLines(r)
  for i,lineText in ipairs(rows) do
   text(lineText,294,230+(i-1)*36,small)
  end
 elseif modal=='sell' then
  local f=activeFish()
  text('CONFIRMAR VENDA',289,176,titleFont)
  text(f and ('Vender peixe #'..f.id..' por $'..world:price(f)..'?') or 'Peixe ausente.',294,249)
  text('A venda é irreversível.',294,285,small,246,184,149)
  modalButton('CANCELAR',314,520,220,function()modal=nil end)
  modalButton('VENDER PEIXE',614,520,239,function()
   local fish=activeFish();modal=nil
   if fish then
    local ok,msg=world:sell(fish.id)
    action(ok,ok and ('Vendido por $'..msg) or msg)
    selectedId=nil;findSelection()
   end
  end)
  return
 elseif modal=='new' then
  text('INICIAR NOVA PARTIDA?',291,184,titleFont)
  text('O salvamento atual será arquivado antes de começar.',292,268,small)
  modalButton('CANCELAR',317,520,219,function()modal=nil end)
  modalButton('CRIAR PARTIDA',612,520,241,beginNew)
  return
 elseif modal=='help' then
  text('COMO JOGAR',288,175,titleFont)
  local rows={
   '1) Selecione um peixe no aquário.',
   '2) Alimente-o usando F ou o botão Alimentar.',
   '3) Compre ração e remédios na Loja.',
   '4) Cruze dois adultos para produzir um filhote.',
   '5) Descubra novos corpos e caudas no catálogo.',
   '6) Venda adultos para ganhar moedas.',
   '7) Pesquise cuidados e desbloqueie o segundo tanque.',
   'F8: DNA  |  F9: Necropsia  |  P: Pausar',
   'O jogo salva automaticamente e ao sair.'
  }
  for i,row in ipairs(rows) do text(row,291,215+(i-1)*35,small) end
 end
 modalButton('FECHAR [ESC]',410,552,356,function()modal=nil end)
end
function love.load()
 love.window.setMode(W,H,{resizable=true,minwidth=820,minheight=580,msaa=4})
 love.window.setTitle('agua-Life | Aquario genetico')
 g.setDefaultFilter('linear','linear')
 font=g.newFont(17);small=g.newFont(14)
 titleFont=g.newFont(22);logo=g.newFont(44);fontTiny=g.newFont(12)
 for i=1,86 do
  bubbles[i]={x=48+rng(i,7)*761,y=rng(i,8)*520,r=1+rng(i,9)*3,speed=10+rng(i,10)*34}
 end
 saved,loadError=Storage.load()
 if os.getenv('AGUA_PLAY_SMOKE')=='aquarium' or os.getenv('AGUA_PLAY_SMOKE')=='collection' then
  world=Play.new(2026);screen=os.getenv('AGUA_PLAY_SMOKE')
  room='main';findSelection()
 elseif os.getenv('AGUA_RIG_SMOKE')=='1' then
  world=Play.new(2008);screen='atelier'
 else screen='title' end
end
function love.update(dt)
 dt=math.max(0,math.min(dt or 0,.12));clock=clock+dt
 if messageTime>0 then messageTime=math.max(0,messageTime-dt) end
 if not world or paused or screen=='title' or modal then return end
 local steps=world:advance(dt)
 if steps>0 and selectedId and not world:find(selectedId) then
  selectedId=nil;breedParent=nil;findSelection()
 end
 for _,f in ipairs(world.s.fish) do
  f.x=f.x+f.speed*f.direction*dt
  if f.x>=755 then f.x=755;f.direction=-1 end
  if f.x<=120 then f.x=120;f.direction=1 end
  f.y=math.max(235,math.min(619,f.y+math.sin(clock*.6+f.phase)*2*dt))
 end
 autosave=autosave+dt
 if autosave>=12 then autosave=0;save() end
end
function love.draw()
 -- Testa o atlas inteiro e as peças cortadas com a GPU real, sem ficar
 -- parado no menu de título durante os testes automatizados.
 if os.getenv('AGUA_MATRIX_SMOKE')=='1' then
  assert(Matrix.available(),'O atlas de 441 peixes não foi encontrado')
  assert(Matrix.draw(C.get(1,1,3,1),300,300,2,1,clock))
  assert(Matrix.draw(C.get(21,17,3,1),580,300,2,1,clock))
  assert(Matrix.drawPart(C.get(1,1,3,1),'tail',730,320,180,120))
  print('OK graphics: 441 matrix + 7 magic fish + tail animation')
  love.event.quit(0)
  return
 end
 -- Ambos exercitam a renderização nativa, não apenas o parser Lua.
 if os.getenv('AGUA_RIG_SMOKE')=='1' then
  assert(Rig.assetsReady(C.get(1,1,3,1)))
  assert(Matrix.available(),'Atlas da matriz ausente no smoke visual')
  assert(Matrix.draw(C.get(2,17,3,1),650,340,2,1,clock))
  g.clear(.04,.13,.17)
  assert(Rig.draw(C.get(1,1,3,1),380,300,1.3,1,clock,nil,true))
  for i,name in ipairs({'body','tail','dorsal','pelvic','pectoral','eye'}) do
   assert(Rig.drawPart(name,40+(i-1)*122,490,105,100))
  end
  print('OK graphics: rig and sprites');love.event.quit(0);return
 end
 g.clear(.02,.08,.11)
 local scale,ox,oy=viewport()
 g.push('all');g.translate(ox,oy);g.scale(scale,scale)
 buttons={}
 if screen=='title' or not world then drawHome() else frame() end
 if modal then overlay() end
 g.pop()
 if os.getenv('AGUA_PLAY_SMOKE') then
  print('OK graphics: playable '..screen)
  love.event.quit(0)
 end
end
function love.mousepressed(px,py,button,istouch)
 if button~=1 or istouch then return end
 local scale,ox,oy=viewport()
 local x=(px-ox)/scale;local y=(py-oy)/scale
 if x<0 or y<0 or x>W or y>H then return end
 for i=#buttons,1,-1 do
  local b=buttons[i]
  if (not modal or b.modal) and (modal or not b.modal) and
   x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
   if not b.disabled then b.action() end
   return
  end
 end
 if modal or not world or screen~='aquarium' or
  (room=='nursery' and not world.s.upgrades.nursery) then return end
 local chosen,dist=nil,math.huge
 for _,f in ipairs(world.s.fish) do
  if f.room==room then
   local dx=(x-f.x)/70;local dy=(y-f.y)/40
   local d=dx*dx+dy*dy
   if d<1 and d<dist then chosen,dist=f,d end
  end
 end
 if chosen then clickFish(chosen) end
end
function love.touchpressed(id,x,y)
 love.mousepressed(x,y,1,false)
end
function love.keypressed(k)
 if modal then
  if k=='escape' then modal=nil end
  return
 end
 if screen=='title' then
  if k=='return' and saved then resume() end
  return
 end
 if not world then return end
 if k=='escape' then breedParent=nil;save();screen='title'
 elseif k=='1' then setRoom('main')
 elseif k=='2' then setRoom('nursery')
 elseif k=='3' then screen='store'
 elseif k=='4' then screen='lab'
 elseif k=='5' then screen='collection'
 elseif k=='6' then screen='atelier'
 elseif k=='f8' then modal='dna'
 elseif k=='f9' then modal='death'
 elseif k=='p' or k=='space' then paused=not paused
 elseif k=='j' then joints=not joints
 elseif k=='f' and activeFish() then
  local ok,msg=world:feed(selectedId);action(ok,msg)
 elseif k=='h' and activeFish() then
  local ok,msg=world:treat(selectedId);action(ok,msg)
 elseif k=='b' then breedSelected()
 elseif k=='s' then if save() then announce('Salvamento atualizado.') end end
end
function love.focus(focused)
 if not focused then save() end
end
function love.quit()
 if world then save() end
end