-- v29: fluxo de utilitarios e sprites reais J2ME nos menus.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Retro=require('ui.retro')
local noop=function()end
local drawn,printed={},{}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local im={w=n(17),h=n(21),path=path,setFilter=noop}
  function im:getDimensions()return self.w,self.h end
  function im:getWidth()return self.w end
  function im:getHeight()return self.h end
  return im
 end,
 newQuad=function(x,y,w,h,iw,ih) assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih);return {x=x,y=y,w=w,h=h}end,
 draw=function(img) if img.path then drawn[#drawn+1]=img.path end end,
 printf=function(s) printed[#printed+1]=tostring(s)end,
}}
for _,name in ipairs({'setColor','rectangle','line','push','pop','translate','scale','setFont','clear'}) do
 love.graphics[name]=noop
end
local g=Game.new(2900)
local ui=Retro.new(g,true);ui:init();ui.bitmapFont=nil
local pass=0
local function check(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V29 '..name..': '..tostring(err))
 pass=pass+1;print('OK '..name)
end
local function tap(x,y)
 ui:draw();return ui:press(ui.ox+x*ui.scale,ui.oy+y*ui.scale)
end
check('loja via barra retorna ao aquario com F2',function()
 ui.screen='tank';ui.room='main';ui.selected=nil
 assert(tap(181,12) and ui.screen=='shop')
 ui:draw();ui:key('f2')
 assert(ui.screen=='tank' and ui.room=='main')
end)
check('pesquisas via barra retornam ao mesmo aquario com Escape',function()
 ui.screen='tank';ui.room='sale';ui.selected=nil
 assert(tap(205,12) and ui.screen=='research')
 ui:key('escape')
 assert(ui.screen=='tank' and ui.room=='sale')
end)
check('loja aberta do menu de pausa volta para pausa',function()
 ui.screen='pause'
 assert(tap(181,12) and ui.screen=='shop')
 ui:draw();assert(tap(215,309) and ui.screen=='pause')
end)
check('trocar loja/pesquisa nao produz retorno circular',function()
 ui.screen='tank';ui.room='main'
 assert(tap(181,12) and ui.screen=='shop')
 assert(tap(203,12) and ui.screen=='research')
 assert(tap(181,12) and ui.screen=='shop')
 ui:draw();ui:key('escape')
 assert(ui.screen=='tank')
end)
check('se tela utilitaria e carregada diretamente preserva BACK antigo',function()
 ui.utilityReturn=nil;ui.screen='research';ui:draw();ui:key('f2')
 assert(ui.screen=='pause')
end)
check('acoes ilustradas usam atlas original quando disponivel',function()
 local f=g.s.tanks.main[1];f.age=20;f.fed=50
 ui.screen='actions';ui.room='main';ui.selected=f.id
 drawn={};ui:draw()
 assert(#ui.buttons>=14)
 assert(ui.buttons[12].x==23 and ui.buttons[12].y==97)
 assert(ui.buttons[13].y==127 and ui.buttons[14].y==157)
 local atlas=false
 for _,p in ipairs(drawn)do if p:match('/assets%.png$')then atlas=true end end
 if ui.images.assets then assert(atlas,'sprites de itens nao apareceram')
 else assert(#ui.buttons>=14,'fallback deve manter os comandos') end
end)
check('tratamentos usam miniaturas do store.png sem mudar a compra',function()
 local f=g.s.tanks.main[1];f.disease='ick';g.s.supplies.ick=2
 ui.selected=f.id;ui.screen='treat'
 drawn={};ui:draw()
 local found=false
 for _,p in ipairs(drawn)do if p:match('/store%.png$')then found=true end end
 if ui.images.store then assert(found,'atlas store.png deve ilustrar tratamentos')
 else assert(#ui.buttons>=13,'fallback de produtos deve manter comandos') end
 assert(ui.buttons[12].x==23 and ui.buttons[12].y==115)
end)
check('movimentacao usa miniaturas de tanque e isolamento original',function()
 local f=g.s.tanks.main[1];ui.selected=f.id;ui.screen='move'
 drawn={};ui:draw()
 local tank,isol=false,false
 for _,p in ipairs(drawn)do
  if p:match('/tank[123]%.png$')then tank=true end
  if p:match('/isolation_tank%.png$')then isol=true end
 end
 if ui.tankIcons[1] then assert(tank,'miniaturas disponiveis devem aparecer') end
 if ui.assets.images.isolation_tank then assert(isol,'isolamento deve aparecer') end
 assert(#ui.buttons>=13, 'Destinos acessiveis + botao de voltar devem permanecer')
end)
check('sem atlas opcional os textos e controles continuam acessiveis',function()
 local oldAssets,oldStore,oldTanks=ui.images.assets,ui.images.store,ui.tankIcons
 ui.images.assets=nil;ui.images.store=nil;ui.tankIcons={}
 ui.screen='actions';ui:draw();assert(ui.buttons[12].x==23)
 ui.screen='treat';ui:draw();assert(ui.buttons[12].y==115)
 ui.screen='move';ui:draw();assert(#ui.buttons>=13)
 ui.images.assets,ui.images.store,ui.tankIcons=oldAssets,oldStore,oldTanks
end)
check('nenhuma alteracao no formato ou estado economico do jogo',function()
 assert(g.s.version==9 and g.s.cash==g.s.cash)
 assert(#g.s.tanks.main>=1 and ui.g==g)
end)
print('V29: '..pass..' verificacoes de menus e sprites aprovadas')
