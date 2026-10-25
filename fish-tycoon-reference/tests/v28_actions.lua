-- V28: ações, transferências e tratamentos com disponibilidade explícita.
-- API gráfica LÖVE simulada; smoke nativo separado no GitHub Actions.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Retro=require('ui.retro')
local noop=function() end
local text={}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local im={w=n(17),h=n(21),setFilter=noop}
  function im:getDimensions()return self.w,self.h end
  function im:getWidth()return self.w end
  function im:getHeight()return self.h end
  return im
 end,
 newQuad=function(x,y,w,h,iw,ih) assert(x+w<=iw and y+h<=ih);return {x=x,y=y,w=w,h=h}end,
 printf=function(s)text[#text+1]=tostring(s)end,
}}
for _,name in ipairs({'setColor','rectangle','line','draw','push','pop','translate','scale','setFont','clear'})do love.graphics[name]=noop end
local checks=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V28 '..name..': '..tostring(err))
 checks=checks+1;print('OK '..name)
end
local game=Game.new(2802)
local ui=Retro.new(game,true);ui:init();ui.bitmapFont=nil
local f=game.s.tanks.main[1];f.age=20;f.fed=50;f.health=80
local function show(screen)
 ui.screen=screen;ui.selected=f.id;ui.room=select(2,game:find(f.id)) or 'main'
 text={};ui:draw();return table.concat(text,' | ')
end
local function tap(x,y)
 return ui:press(ui.ox+x*ui.scale,ui.oy+y*ui.scale)
end
check('ações compactas exibem dados do peixe e seis controles',function()
 local txt=show('actions')
 assert(txt:find('AGE ',1,true))
 assert(txt:find('TREAT FISH',1,true))
 assert(txt:find('MOVE FISH',1,true))
 assert(#ui.buttons>=14) -- toolbar + FEED,TREAT,MOVE + volta
 assert(ui.buttons[12].x==23 and ui.buttons[12].y==97)
 assert(ui.buttons[13].y==127 and ui.buttons[14].y==157)
end)
check('preço e venda desabilitados fora do tanque de vendas',function()
 show('actions')
 local before=game.s.cash
 assert(not tap(100,248))
 assert(game.s.cash==before and game:find(f.id)==f)
end)
check('transferência mostra origem e tanque 2 bloqueados',function()
 local txt=show('move')
 assert(txt:find('CURRENT',1,true))
 assert(txt:find('LOCKED',1,true))
 local before=select(2,game:find(f.id))
 assert(not tap(100,112) and not tap(100,148))
 assert(select(2,game:find(f.id))==before)
end)
check('transferir adulto ao isolamento funciona e respeita BACK',function()
 show('move')
 assert(tap(100,186))
 assert(ui.screen=='tank' and ui.room=='isolation')
 assert(select(2,game:find(f.id))=='isolation')
 show('move')
 ui:key('f2');assert(ui.screen=='actions')
end)
check('peixe gestante nao sai do isolamento',function()
 f.eggs_at=999
 local txt=show('move')
 assert(txt:find('EGGS',1,true))
 assert(not tap(100,112))
 assert(select(2,game:find(f.id))=='isolation')
 f.eggs_at=nil
end)
check('filhotes não podem ser colocados no tanque de vendas',function()
 f.age=7
 show('move')
 local txt=show('move')
 assert(txt:find('ADULT ONLY',1,true))
 assert(not tap(100,219))
 f.age=20
end)
check('medicamentos sem estoque ou contra doença errada ficam indisponíveis',function()
 f.disease='fungus'
 game.s.supplies.ick=4;game.s.supplies.fungus=0
 local txt=show('treat')
 assert(txt:find('CONDITION: FUNGUS',1,true))
 assert(txt:find('ICK',1,true))
 local before=game.s.supplies.ick
 assert(not tap(113,126))
 assert(not tap(113,160))
 assert(game.s.supplies.ick==before and ui.screen=='treat')
end)
check('tratamento compatível consome estoque e volta às ações',function()
 game.s.supplies.fungus=2
 show('treat')
 local count=game.s.supplies.fungus
 assert(tap(113,160))
 assert(ui.screen=='actions' and game.s.supplies.fungus==count-1)
end)
check('hormônio não pode ser usado depois de 40 unidades',function()
 f.age=41
 local before=game.s.supplies.hormone or 0
 game.s.supplies.hormone=3
 show('treat')
 assert(not tap(110,224))
 assert(game.s.supplies.hormone==3)
 game.s.supplies.hormone=before
end)
check('preço e venda disponíveis apenas para adultos no tanque de venda',function()
 local sale=assert(game:addFish('sale',1,1,21))
 ui.selected=sale.id;ui.room='sale';ui.screen='actions';ui:draw()
 local oldPrice=sale.price
 assert(tap(100,229)) -- PRICE +5
 assert(sale.price>oldPrice)
 ui:draw()
 local oldCash=game.s.cash
 assert(tap(100,252)) -- SELL NOW
 assert(ui.screen=='tank' and game:find(sale.id)==nil and game.s.cash>oldCash)
 ui.selected=f.id
end)
check('tanque cheio é bloqueado no menu sem alterar contagem',function()
 while #game.s.tanks.sale < game:capacity('sale') do
  assert(game:addFish('sale',1,1,20))
 end
 local before=#game.s.tanks.sale
 local txt=show('move')
 assert(txt:find('(FULL)',1,true))
 assert(not tap(110,218))
 assert(#game.s.tanks.sale==before)
end)
check('economia, genes e formato de salvamento permanecem',function()
 assert(game.s.version==9)
 assert(game:find(f.id)==f)
 assert(f.body>=1 and f.body<=21 and f.tail>=1 and f.tail<=21)
end)
print('V28: '..checks..' cenários de ações e controle passaram')
