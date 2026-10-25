local Catalog=require('core.catalog')
local Config=require('core.config')
local Assets=require('core.assets')
local Swim=require('ui.swim')
local View={};View.__index=View
local W,H=420,800
local function color(hex,a)
 local n=tonumber(hex:gsub('#',''),16)
 return ((math.floor(n/65536)%256)/255),((math.floor(n/256)%256)/255),((n%256)/255),a or 1
end
local function rgba(hex,a) love.graphics.setColor(color(hex,a)) end
local function rect(x,y,w,h,r,fill)
 if fill then rgba(fill);love.graphics.rectangle('fill',x,y,w,h,r or 0,r or 0) end
end
local function text(s,x,y,size,hex,align,w)
 local font=View.fonts[size] or View.fonts[14]
 love.graphics.setFont(font);rgba(hex or '#e3f4f7')
 if w then love.graphics.printf(tostring(s),x,y,w,align or 'left')
 else love.graphics.print(tostring(s),x,y) end
end
local function line(x1,y1,x2,y2,hex,width)
 rgba(hex);love.graphics.setLineWidth(width or 1);love.graphics.line(x1,y1,x2,y2)
end
function View.new(game)
 return setmetatable({g=game,assets=Assets.new(),page='tank',room='main',selected=nil,modal=nil,
    shopPage=1,catalogPage=1,catalogBody=1,buttons={},fishHits={},toast='',toast_time=0,
    pulse=0,autosave=0,scale=1,ox=0,oy=0,
    saleFlash=0,lastSaleCount=game.s.stats.sold or 0},View)
end
function View:init()
 View.fonts={}
 for _,size in ipairs({11,12,13,14,16,18,20,23,27,32}) do
   View.fonts[size]=love.graphics.newFont(size)
 end
 View.fonts[11]:setFilter('linear','linear')
 self.assets:init()
end
function View:showOfflineReport(report)
 if not report then return end
 self.offlineReport=report
 self.offlinePage=1
 self.modal='offline'
 self:notify('Relatorio de progresso offline disponivel')
end
function View:notify(msg)
 self.toast=tostring(msg)
 self.toast_time=3.5
end
function View:update(dt)
 self.pulse=self.pulse+dt
 self.toast_time=math.max(0,self.toast_time-dt)
 self.saleFlash=math.max(0,self.saleFlash-dt)
 local sold=self.g.s.stats.sold or 0
 if sold>self.lastSaleCount then self.saleFlash=2.5 end
 self.lastSaleCount=sold
end
function View:hit(x,y,w,h,fn)
 table.insert(self.buttons,{x=x,y=y,w=w,h=h,fn=fn})
end
function View:button(title,x,y,w,h,fn,opts)
 opts=opts or {}
 rect(x,y,w,h,9,opts.secondary and '#193d55' or '#23758d')
 if not opts.disabled then
  rgba(opts.secondary and '#4e91a3' or '#54d3d4',.30)
  love.graphics.setLineWidth(1.2)
  love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,9,9)
 end
 text(title,x+5,y+(h-18)/2,opts.size or 14,opts.disabled and '#7695a2' or '#effdff','center',w-10)
 if not opts.disabled and fn then self:hit(x,y,w,h,fn) end
end
function View:panel(x,y,w,h)
 rect(x,y,w,h,14,'#0e3046')
 rgba('#477c92',.55);love.graphics.setLineWidth(1)
 love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,14,14)
end
function View:backdrop()
 rect(0,0,W,H,0,'#071c30')
 for i=0,15 do
  rect(0,i*50,W,50,0, i%2==0 and '#0a273e' or '#0b2a40')
 end
 for i=1,15 do
  local x=((i*63)%450)-12
  local y=((i*97+self.pulse*11)%850)
  rgba('#67bbd1',.10);love.graphics.circle('fill',x,y,2+(i%4))
 end
end
function View:header()
 rect(0,0,W,80,0,'#103850')
 text('AQUARIO DE ISOLA',18,12,23,'#f5d597')
 text('Um pequeno mundo vivo, em tempo real',19,44,12,'#9ac6ce')
 rect(286,15,115,47,11,'#17495b')
 text('CAIXA',291,18,11,'#a9c8d0')
 text('$ '..self.g.s.cash,292,32,20,'#e5d98c')
 self:button('Rapido '..self.g.s.game_speed..'x',18,82,110,30,function()
  local sp=self.g.s.game_speed
  self.g.s.game_speed=sp==1 and 5 or (sp==5 and 20 or 1)
  self:notify('Velocidade: '..self.g.s.game_speed..'x')
 end,{secondary=true,size=12})
 self:button('Idade '..self.g.s.growth_minutes..'min',131,82,99,30,function()
  local m=self.g.s.growth_minutes
  self.g:setGrowthMinutes(m==5 and 10 or (m==10 and 15 or 5))
  self:notify('Crescimento: 1 unidade a cada '..self.g.s.growth_minutes..' min')
 end,{secondary=true,size=12})
 self:button(self.soundEnabled==false and 'Som OFF' or 'Som ON',235,82,96,30,function()
  if self.onSound then self.soundEnabled=self.onSound();self:notify(self.soundEnabled and 'Musica ligada' or 'Musica desligada') end
 end,{secondary=true,size=12})
 self:button('Salvar',338,82,64,30,function()
  if self.onSave then local ok,err=self.onSave();self:notify(ok and 'Progresso salvo!' or tostring(err)) end
 end,{secondary=true,size=12})
end
function View:tabs()
 local labels={{'main','Tanque 1'},{'second','Tanque 2'},{'isolation','Isolar'},{'sale','Vendas'}}
 for i,t in ipairs(labels) do
  local x=18+(i-1)*99
  local chosen=self.room==t[1]
  rect(x,121,94,34,8,chosen and '#3189a0' or '#123c52')
  text(t[2],x,129,13,chosen and '#ffffff' or '#9bbfc8','center',94)
  self:hit(x,121,94,34,function()
   if t[1]=='second' and not self.g.s.unlocked.second then
    self:notify('Compre o tanque 2 na loja de suprimentos.')
   else self.room=t[1];self.selected=nil end
  end)
 end
end
function View:drawFish(f,x,y,scale,face)
 if self.assets:drawFish(f,x,y,scale,face) then return end
 local s=scale or 1
 local base=Catalog.species[f.body].color
 local tail=Catalog.species[f.tail].color
 love.graphics.push()
 love.graphics.translate(x,y)
 love.graphics.scale(s*(face or 1),s)
 local glow=(f.health<35) and .6 or 1
 rgba('#000c1d',.32);love.graphics.ellipse('fill',1,15,29,7)
 love.graphics.setColor(tail[1]*glow,tail[2]*glow,tail[3]*glow)
 love.graphics.polygon('fill',-22,0,-43,-15,-38,0,-43,15)
 love.graphics.polygon('fill',-4,-8,0,-24,14,-9)
 love.graphics.setColor(base[1]*glow,base[2]*glow,base[3]*glow)
 love.graphics.ellipse('fill',0,0,30,17)
 love.graphics.setColor(1,1,1,.25)
 love.graphics.ellipse('fill',-2,-6,23,7)
 love.graphics.setColor(1,.97,.83,.85)
 love.graphics.ellipse('fill',12,-2,6,7)
 rgba('#112e43');love.graphics.circle('fill',15,-2,3.2)
 rgba('#fafafa',.8);love.graphics.circle('fill',16,-3,1)
 rgba('#26465a',.52);love.graphics.arc('line','open',19,5,.9,0,math.pi)
 if f.disease then
  rgba(f.disease=='ick' and '#f2f5f0' or '#72bf82')
  love.graphics.circle('fill',-8,-4,3)
  love.graphics.circle('fill',4,5,2.5)
  love.graphics.circle('fill',-14,5,1.5)
 end
 if f.eggs_at then
  rgba('#f4e3a1')
  love.graphics.circle('fill',-2,2,3)
 end
 love.graphics.pop()
end
function View:tank()
 self:tabs()
 self:panel(17,164,386,343)
 rect(23,170,374,331,12,'#0b4c67')
 local hasOriginal=self.assets:tankBackground(self.room,23,170,374,331)
 self:hit(23,170,374,331,function() self.selected=nil end) -- toque no fundo
 for i=0,9 do
  local a=i/9
  rgba('#226e88',.08+.05*a)
  love.graphics.rectangle('fill',24,173+i*30,370,29)
 end
 local room=self.g.s.tanks[self.room]
 if self.room=='second' and not self.g.s.unlocked.second then
  text('TANQUE 2 BLOQUEADO',42,270,23,'#f5d597','center',336)
  text('Encontre-o na loja de suprimentos.',42,310,14,'#d1e8e5','center',336)
 else
  if not hasOriginal then for i=1,11 do
   local x=23+i*33
   local high=(i%3)*16+20
   local v=math.sin(self.pulse*1.1+i)*4
   line(x,495,x+v,495-high,'#1ba58f',3)
   rgba('#23997d',.8)
   love.graphics.ellipse('fill',x+v,495-high,5,9,16)
  end
  for i=1,8 do
   local x=22+i*47
   rgba('#65b5c9',.25)
   love.graphics.circle('line',x,475-(self.pulse*28+i*50)%273,2+i%3)
  end
  rect(24,493,372,7,0,'#bdab7b') end
  for i,f in ipairs(room) do
   local x,y,face=Swim.position(f,i,self.room,self.pulse)
   local scale=self.g:fishStage(f)=='Filhote' and 1.25 or (self.g:fishStage(f)=='Jovem' and 1.1 or 1.10)
   if self.selected==f.id then
    rgba('#ffdfa1',.5);love.graphics.circle('line',x,y,35*scale+10)
   end
   self:drawFish(f,x,y,scale,face)
   -- Sinais visuais de urgencia, sem esconder o sprite original.
   if f.disease then
    rgba('#f0787d',.94);love.graphics.circle('fill',x+27,y-21,9)
    text('!',x+23,y-29,14,'#ffffff')
   elseif (f.fed or 100)<=15 then
    rgba('#f2cb6e',.94);love.graphics.circle('fill',x+27,y-21,8)
    text('!',x+23,y-29,13,'#2b3540')
   end
   if f.eggs_at then
    rgba('#ffedac',.95);love.graphics.circle('fill',x-23,y-19,5)
   end
   self.fishHits[#self.fishHits+1]={x=x,y=y,id=f.id}
  end
  if #room==0 then
   text('Nenhum peixe neste tanque',38,312,18,'#c7e4e6','center',344)
  end
 end
 if self.room=='sale' and self.saleFlash>0 then
  local last=self.g.s.market.last_sale
  if type(last)=='table' then
   rect(75,218,270,37,9,'#15596a')
   text('VENDA  +$'..last.amount,80,225,20,'#ffe3a0','center',260)
  end
 end
 text(({main='Tanque principal',second='Tanque secundario',isolation='Tanque de isolamento',sale='Tanque de vendas'})[self.room],28,177,13,'#e1f2e8')
 text(#room..'/'..Config.CAPACITY[self.room]..' peixes',271,177,13,'#d0e4d8','right',117)
 local report=self.g:tankReport(self.room)
 if report and report.count>0 then
  local status='Saude '..report.health..'%  |  Alimento '..report.food..'%  |  Doentes '..report.sick
  rect(30,193,360,17,4,'#10394b')
  text(status,37,195,11,report.urgent>0 and '#ffe7a2' or '#d9efe4','left',350)
 end
 self:fishInfo()
end
function View:fishInfo()
 self:panel(17,517,386,189)
 local f,room
 if self.selected then f,room=self.g:find(self.selected) end
 if room~=self.room then self.selected=nil;f=nil end
 if not f then
  if self.room=='sale' then
   local m=self.g.s.market
   text('CONTROLE DE VENDAS',34,536,20,'#f3d28e')
   text('Clientes: '..(m.visits or 0)..' | Sem compra: '..(m.rejected or 0),34,566,12,'#b0d2df')
   local last=m.last_visit
   local status='Ainda nao houve visitas'
   if type(last)=='table' then
    if last.status=='sold' then status='Cliente comprou por $'..(last.amount or '?')
    elseif last.status=='empty' then status='Cliente saiu: nenhuma oferta adulta'
    else status='Cliente avaliou os precos e nao comprou' end
   end
   text(status,34,587,12,'#e0ecce')
   text(self.g.s.sale_open and ('Proxima visita em '..math.ceil(5-(m.elapsed or 0))..'s (simulados)')
      or 'Loja fechada: sem visitantes',34,609,12,'#f5d597')
  else
   text('SELECIONE UM PEIXE',34,536,20,'#f3d28e')
   text('Toque em um peixe para ver seus dados e acoes.',34,567,13,'#c4d9e5')
   text('Cruzamento: transfira 2 adultos para Isolar.',34,594,13,'#c4d9e5')
  end
  if self.room=='sale' then
   self:button(self.g.s.sale_open and 'Fechar loja' or 'Abrir loja',37,635,165,42,function()
    self.g.s.sale_open=not self.g.s.sale_open
    self:notify(self.g.s.sale_open and 'Vendas automaticas ativadas' or 'Loja fechada')
   end)
   self:button('Historico',214,635,168,42,function() self.modal='history' end,{secondary=true})
  elseif self.room=='main' or self.room=='second' then
   if self.offlineReport then
    self:button('Resumo offline',259,640,124,41,function() self.modal='offline' end,{secondary=true,size=12})
   end
   self:button('Alimentar tanque ('..(self.g.s.supplies.food or 0)..')',35,640,216,41,function()
    local ok,value=self.g:feedTank(self.room)
    self:notify(ok and (value..' peixe(s) alimentado(s)') or value)
   end)
  elseif self.room=='isolation' then
   self:button('Cruzar os 2 adultos',35,640,207,41,function()
    local ok,msg=self.g:breed();self:notify(msg or (ok and 'Reproducao iniciada' or 'Erro'))
   end)
  end
  return
 end
 local nm=Catalog.nameFor(f.body,f.tail)
 text(nm,32,530,16,'#f8db91')
 text('Idade '..f.age..' | '..self.g:fishStage(f)..' | Preco $'..(f.price or self.g:fishPrice(f)),32,551,13,'#cbdde4')
 text((self.g:isAdult(f) and 'Valor de mercado $' or 'Preco base $')..self.g:marketQuote(f),32,569,12,'#b6dbca')
 self:meter('Saude',f.health,33,599,164,'#7cdd9e')
 self:meter('Alimento',f.fed,218,599,166,'#ffce82')
 local incubation=self.g:incubationInfo(f.id)
 text(f.disease and ('DOENTE: '..(f.disease=='ick' and 'Ick' or 'Fungo'))
        or (incubation and ('OVOS: '..incubation.remaining..' ciclos para eclosao') or 'Estado: saudavel'),33,623,12,
        f.disease and '#ff9a9a' or '#b3e4ca')
 local delta=self.g:fishEnvironmentDelta(f.id) or 0
 text('Resistencia '..(delta>0 and '+' or '')..delta,235,623,11,delta<0 and '#ffd09f' or '#a4e2c1','right',146)
 if self.room=='sale' then
  self:button('- $5',32,650,58,40,function() self.g:changePrice(f.id,-5) end,{size=12})
  self:button('+ $5',95,650,58,40,function() self.g:changePrice(f.id,5) end,{size=12})
  self:button('Justo',158,650,68,40,function()
   local ok,value=self.g:matchMarketPrice(f.id)
   self:notify(ok and ('Preco definido: $'..value) or value)
  end,{size=12})
  self:button('Vender',231,650,75,40,function()
   local ok,msg=self.g:sell(f.id);self:notify(ok and 'Venda direta concluida!' or msg);if ok then self.selected=nil end
  end,{size=12})
  self:button('Mover',311,650,70,40,function() self.modal='move' end,{size=12})
 else
  self:button('Alimentar',32,650,102,40,function()
   local ok,msg=self.g:feed(f.id);self:notify(msg)
  end,{size=13})
  self:button('Tratar',141,650,99,40,function() self.modal='medicine' end)
  self:button('Mover',248,650,132,40,function() self.modal='move' end)
 end
end
function View:meter(name,value,x,y,w,hex)
 text(name..' '..value..'%',x,y-15,11,'#dbeaf0')
 rect(x,y,w,9,4,'#17435a')
 rect(x,y,math.max(0,w*value/100),9,4,hex)
end
function View:shop()
 self:panel(17,122,386,579)
 text('SUPRIMENTOS',33,139,23,'#f5d597')
 text('Tudo para cultivar um aquario saudavel',33,172,13,'#b7d6e0')
 local start=(self.shopPage-1)*6+1
 for r=1,6 do
  local item=Catalog.supplies[start+r-1]
  if item then
   local y=202+(r-1)*72
   rect(28,y,364,64,10,r%2==0 and '#144056' or '#10374c')
   text(item.title,37,y+7,16,'#d9f5ea')
   text(item.desc,37,y+30,11,'#98bbc8')
   local owned=(item.id=='second' and self.g.s.unlocked.second) or self.g.s.gear[item.id]
   self:button(owned and 'OK' or ('$'..item.price),308,y+10,73,43,function()
    local ok,msg=self.g:purchase(item.id)
    self:notify(ok and (item.title..' comprado') or msg)
   end,{size=13,disabled=owned})
  end
 end
 self:button('< Anterior',34,644,128,42,function() self.shopPage=math.max(1,self.shopPage-1) end,{secondary=true,disabled=self.shopPage==1})
 text(self.shopPage..' / '..math.ceil(#Catalog.supplies/6),177,655,16,'#d6ecf2','center',64)
 self:button('Proxima >',263,644,120,42,function() self.shopPage=math.min(math.ceil(#Catalog.supplies/6),self.shopPage+1) end,{secondary=true,disabled=self.shopPage==math.ceil(#Catalog.supplies/6)})
end
function View:research()
 self:panel(17,122,386,579)
 text('CENTRO DE PESQUISA',32,138,21,'#f5d597')
 text('Avance de nivel e melhore seu ecossistema.',32,175,13,'#add2da')
 for i,item in ipairs(Catalog.research) do
  local y=208+(i-1)*131
  rect(28,y,364,119,11,'#123c51')
  local level=self.g.s.research[item.id] or 0
  text(item.title,40,y+11,18,'#d9f2e8')
  text('Nivel '..level..' / 3',300,y+14,13,'#e9d293')
  local details=item.desc
  if item.id=='food' then
   details=({'Reserva diminui em 100% dos ciclos','Reserva diminui em 61% dos ciclos',
             'Reserva diminui em 31% dos ciclos','Reserva diminui em 20% (extra Lua)'})[math.min(level+1,4)]
  elseif item.id=='environment' then
   details=({'Resistencia biologica: nivel 1','Resistencia biologica: nivel 2',
             'Resistencia biologica: nivel 3','Protecao +2 por ciclo (extra Lua)'})[math.min(level+1,4)]
  elseif item.id=='advertising' then
   details='Promove os peixes anunciados na loja (adaptacao)'
  end
  text(details,40,y+36,12,'#a4cdd5')
  local preview=self.g:researchProjection(item.id)
  if preview then
   local line=preview.next and ('Prox.: '..preview.next) or ('Atual: '..preview.current)
   text(line,40,y+53,11,'#f2dfaa')
  end
  local active=self.g.s.research_job
  local busy=active and active.id==item.id
  local max=level>=Config.RESEARCH_MAX
  local cost=not max and Config.RESEARCH_COSTS[item.id][level+1]
  local label=max and 'Concluida' or (busy and 'Em andamento' or ('$'..cost..' | Pesquisar'))
  self:button(label,41,y+69,336,37,function()
   local ok,msg=self.g:startResearch(item.id)
   self:notify(ok and 'Pesquisa iniciada!' or msg)
  end,{disabled=max or active~=false,size=13})
 end
 local job=self.g:researchInfo()
 if job then
  text('Trabalho em andamento: '..math.ceil(job.remaining/60)..' min simulados',40,624,13,'#f5d597')
  self:meter('Progresso',math.floor(job.progress*100),40,662,340,'#f1cd77')
 else
  text('Nenhuma pesquisa em andamento',40,624,13,'#a6cad2')
 end
end
function View:catalog()
 self:panel(17,122,386,579)
 text('DESCOBERTAS',33,139,22,'#f5d597')
 text(self.g:countMagic()..' / 7 peixes especiais descobertos',33,175,14,'#bedcdf')
 if self.catalogPage==1 then
  for i,m in ipairs(Catalog.magic) do
   local y=209+(i-1)*59
   rect(28,y,362,53,9,i%2==0 and '#143e53' or '#10364c')
   local found=self.g.s.magic[tostring(i)]
   text(found and m.name or ('??? - Descoberta '..i),38,y+7,15,found and '#f7d391' or '#8cacbc')
   text(found and m.note or 'Cruze linhagens para revelar',38,y+31,11,'#c2dae0')
  end
 elseif self.catalogPage==2 then
  local st=self.g.s.stats
  local rows={
   {'Dinheiro ganho','$'..st.earned},{'Dinheiro gasto','$'..st.spent},
   {'Peixes vendidos',st.sold},{'Peixes nascidos',st.born},
   {'Peixes mortos',st.lost},{'Curados',st.healed},
   {'Racoes usadas',st.food_given},{'Especies descobertas',self:seenCount()},
   {'Maior venda','$'..st.high_price},{'Peixes atuais',self.g:countFish()},
  }
  for i,r in ipairs(rows) do
   local y=214+(i-1)*40
   text(r[1],39,y,14,'#afcfda')
   text(r[2],280,y,14,'#f5d597','right',100)
   if i<10 then line(38,y+30,382,y+30,'#29536a',1) end
  end
 else
  local body=self.catalogBody
  local discovered=0
  for tail=1,21 do
   if self.g.s.seen[body..'-'..tail] then discovered=discovered+1 end
  end
  text('FORMA '..string.format('%02d',body-1)..'  |  '..discovered..' de 21 barbatanas',35,176,14,'#bfe3df')
  for tail=1,21 do
   local col=(tail-1)%3
   local row=math.floor((tail-1)/3)
   local x=29+col*122
   local y=214+row*57
   local found=self.g.s.seen[body..'-'..tail] == true
   local magicId=found and Catalog.magicFor(body,tail)
   rect(x,y,115,48,8,found and '#1b5d60' or '#143449')
   text(found and ('BARB. '..string.format('%02d',tail-1)) or ('#'..string.format('%02d',tail-1)..'  ???'),x+7,y+7,12,
    found and '#f6e6ac' or '#7295a9')
   text(found and (magicId and 'ESPECIAL' or 'Descoberto') or 'Nao visto',x+7,y+27,11,
    found and (magicId and '#ffcb91' or '#b3e9d9') or '#829bac')
  end
  self:button('< Corpo',34,621,146,30,function()
   self.catalogBody=(self.catalogBody-2)%21+1
  end,{secondary=true,size=12})
  self:button('Corpo >',241,621,146,30,function()
   self.catalogBody=self.catalogBody%21+1
  end,{secondary=true,size=12})
 end
 local nextPage=({'Ver estatisticas','Ver variedades','Ver descobertas'})[self.catalogPage]
 self:button(nextPage,77,661,268,32,function()
  self.catalogPage=self.catalogPage%3+1
 end,{secondary=true,size=13})
end
function View:seenCount() local n=0;for _ in pairs(self.g.s.seen) do n=n+1 end;return n end
function View:footer()
 rect(0,716,W,84,0,'#103448')
 local tabs={{'tank','AQUARIOS'},{'shop','LOJA'},{'research','PESQUISA'},{'catalog','COLECAO'}}
 for i,p in ipairs(tabs) do
  local x=14+(i-1)*103
  local selected=self.page==p[1]
  if selected then rect(x,729,98,52,11,'#2b788c') end
  text(p[2],x+3,745,12,selected and '#ffffff' or '#afcbd2','center',92)
  self:hit(x,727,98,57,function()
   self.page=p[1];self.selected=nil;self.modal=nil
  end)
 end
end
function View:modalDraw()
 if not self.modal then return end
 rect(0,0,W,H,0,'#071725')
 rgba('#d5f2e9',.06);love.graphics.rectangle('fill',0,0,W,H)
 self.buttons={} -- bloqueia cliques nas telas atras do dialogo
 self:panel(24,184,372,432)
 local modal=self.modal
 self:button('X',348,193,34,32,function() self.modal=nil end,{secondary=true})
 local f=self.selected and self.g:find(self.selected)
 if modal=='offline' then
  local report=self.offlineReport
  text('PROGRESSO OFFLINE',40,211,20,'#f8d696')
  if report then
   local mins=math.floor(report.seconds/60)
   local hours=math.floor(mins/60)
   local label=(hours>0 and (hours..' h '..(mins%60)..' min') or (mins..' min'))
   text('Tempo simulado: '..label,40,247,13,'#b9d8dd')
   local pageSize=7
   local pages=math.max(1,math.ceil(#report.lines/pageSize))
   self.offlinePage=math.min(math.max(1,self.offlinePage or 1),pages)
   local first=(self.offlinePage-1)*pageSize+1
   for i=first,math.min(#report.lines,first+pageSize-1) do
    text(report.lines[i],40,280+(i-first)*33,13,'#e1ead5')
   end
   if pages>1 then
    self:button('<',43,550,60,36,function()
     self.offlinePage=math.max(1,self.offlinePage-1)
    end,{secondary=true,disabled=self.offlinePage==1})
    text('Pagina '..self.offlinePage..' / '..pages,110,560,13,'#f2dea4','center',199)
    self:button('>',318,550,60,36,function()
     self.offlinePage=math.min(pages,self.offlinePage+1)
    end,{secondary=true,disabled=self.offlinePage==pages})
   end
  else
   text('Nao ha relatorio para esta sessao.',40,280,14,'#b9d8dd')
  end
 elseif modal=='move' then
  text('TRANSFERIR PEIXE',40,211,20,'#f8d696')
  text('Escolha o aquario de destino:',40,254,14,'#b9d8dd')
  local dest={{'main','Tanque 1'},{'second','Tanque 2'},{'isolation','Isolamento'},{'sale','Area de vendas'}}
  for i,t in ipairs(dest) do
   self:button(t[2],43,286+(i-1)*62,335,47,function()
    local ok,msg=self.g:move(self.selected,t[1])
    self:notify(msg or (ok and 'Transferido!' or 'Nao foi possivel mover'))
    if ok then self.selected=nil;self.room=t[1];self.modal=nil end
   end,{secondary=true})
  end
 elseif modal=='history' then
  text('HISTORICO DA LOJA',40,207,19,'#f7d696')
  text('Ultimas 7 visitas (registro de ate 12)',40,243,12,'#b9d8dd')
  local history=self.g.s.market.history or {}
  if #history==0 then
   text('Nenhum cliente passou por aqui ainda.',40,300,14,'#cfdee0')
  else
   for pos=1,math.min(7,#history) do
    local entry=history[#history-pos+1]
    local y=277+(pos-1)*43
    rect(39,y,339,37,7,pos%2==0 and '#163f52' or '#10384a')
    local desc
    if entry.status=='sold' then
     desc='VENDA  Forma '..(entry.body or '?')..' / Barbatana '..(entry.fin or '?')..'  +$'..(entry.amount or '?')
    elseif entry.status=='empty' then desc='Sem peixes adultos para venda'
    else desc='Cliente saiu sem comprar' end
    text('#'..entry.visit,49,y+10,12,'#e9d29b')
    text(desc,91,y+10,12,entry.status=='sold' and '#afeec9' or '#c9d8db')
   end
  end
 elseif modal=='medicine' then
  text('CUIDADOS DO PEIXE',40,207,19,'#f7d696')
  text(f and ('Saude: '..f.health..'% | Idade: '..f.age) or 'Peixe indisponivel',40,239,13,'#b9d8dd')
  text('Cura 40% por dose; quimico muta em 26%',40,260,12,'#f2ce93')
  local items={{'ick','Tratar Ick'},{'fungus','Tratar fungos'},{'vitamin','Aplicar vitaminas'},{'hormone','Horm. de crescimento'},{'mutagen','Quimico desconhecido'}}
  for i,t in ipairs(items) do
   self:button(t[2]..'  ('..(self.g.s.supplies[t[1]] or 0)..')',43,285+(i-1)*57,335,46,function()
    local ok,msg=self.g:medicine(self.selected,t[1])
    self:notify(msg)
    if ok then self.modal=nil end
   end,{secondary=true})
  end
 end
end
function View:draw()
 local sw,sh=love.graphics.getDimensions()
 self.scale=math.min(sw/W,sh/H)
 self.ox=(sw-W*self.scale)/2;self.oy=(sh-H*self.scale)/2
 love.graphics.clear(color('#061b2c'))
 self.buttons={}
 self.fishHits={}
 love.graphics.push()
 love.graphics.translate(self.ox,self.oy)
 love.graphics.scale(self.scale,self.scale)
 self:backdrop();self:header()
 if self.page=='tank' then self:tank()
 elseif self.page=='shop' then self:shop()
 elseif self.page=='research' then self:research()
 elseif self.page=='catalog' then self:catalog() end
 self:footer()
 self:modalDraw()
 if self.toast_time>0 then
  rect(23,676,374,42,11,'#314b58')
  text(self.toast,34,689,12,'#fff0bf','center',352)
 end
 love.graphics.pop()
end
function View:press(px,py)
 local x=(px-self.ox)/self.scale
 local y=(py-self.oy)/self.scale
 -- Peixes vizinhos podem ter alvos de toque sobrepostos. Selecionamos
 -- o mais proximo em vez de favorecer a ultima figura desenhada.
 if self.page=='tank' and not self.modal then
  local best,bestDistance=nil,math.huge
  for _,hit in ipairs(self.fishHits) do
   local dx,dy=x-hit.x,y-hit.y
   if math.abs(dx)<=33 and math.abs(dy)<=23 then
    local distance=dx*dx+dy*dy
    if distance<bestDistance then best,bestDistance=hit,distance end
   end
  end
  if best then
   if self.selected==best.id then self.selected=nil else self.selected=best.id end
   return true
  end
 end
 for i=#self.buttons,1,-1 do
  local a=self.buttons[i]
  if x>=a.x and x<=a.x+a.w and y>=a.y and y<=a.y+a.h then
   a.fn();return true
  end
 end
 return false
end
function View:key(key)
 -- A janela modal captura as teclas: nao trocar pagina nem acelerar
 -- a simulacao por baixo de um relatorio ou tratamento aberto.
 if self.modal then
  if key=='escape' or key=='back' then self.modal=nil end
  return
 end
 if key=='escape' or key=='back' then
  self.page='tank';self.selected=nil
 elseif key=='1' or key=='2' or key=='3' or key=='4' then
  local pages={['1']='tank',['2']='shop',['3']='research',['4']='catalog'}
  self.page=pages[key];self.selected=nil
 elseif key=='space' then
  self.g.s.game_speed=self.g.s.game_speed==1 and 5 or (self.g.s.game_speed==5 and 20 or 1)
 end
end
return View
