-- V38: visibilidade dos custos, estoques e indisponibilidade antes do clique.
-- As formulas monetarias permanecem exatamente as de core/game.lua.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local Catalog=require('core.catalog')
local Config=require('core.config')
local noop=function()end
local labels={}
love={graphics={
 newFont=function()return {setFilter=noop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local h=f:read(24);f:close()
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local img={w=n(17),h=n(21),setFilter=noop}
  function img:getDimensions()return self.w,self.h end
  function img:getWidth()return self.w end
  function img:getHeight()return self.h end
  return img
 end,
 newQuad=function(x,y,w,h,iw,ih)
  assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih)
  return {x=x,y=y,w=w,h=h}
 end,
 printf=function(s)labels[#labels+1]=tostring(s)end,
}}
for _,name in ipairs({'setColor','rectangle','line','draw','push','pop','translate','scale','setFont','clear'}) do
 love.graphics[name]=noop
end
local g=Game.new(3800)
local v=Retro.new(g,true);v:init();v.bitmapFont=nil
local tests=0
local function assertTest(name,fn)
 local ok,err=pcall(fn)
 assert(ok,'V38 '..name..': '..tostring(err))
 tests=tests+1;print('OK '..name)
end
local function render(screen)
 if screen then v.screen=screen end
 labels={};v:draw()
 return table.concat(labels,';')
end
local function tap(x,y)
 v:draw();return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
local function contains(text,substring)
 assert(text:find(substring,1,true),substring..' nao encontrado em '..text)
end
assertTest('loja mostra saldo real e estoque de consumiveis',function()
 g.s.cash=500;g.s.supplies.ick=3
 v.shopPage=1;v.selectedShopIndex=1
 local text=render('shop')
 contains(text,'CASH $500')
 contains(text,'$45  x3')
end)
assertTest('saldo insuficiente desativa BUY sem alterar dinheiro',function()
 g.s.cash=0;v.shopPage=1;v.selectedShopIndex=1
 local text=render('shop');contains(text,'NO $')
 assert(not tap(190,107))
 assert(g.s.cash==0)
end)
assertTest('comprado mostra OWN sem acionar compra duplicada',function()
 g.s.cash=1000;g.s.gear.aerator=true;v.shopPage=2;v.selectedShopIndex=8
 local text=render('shop');contains(text,'OWN')
 assert(not tap(192,234))
 assert(g.s.cash==1000)
end)
assertTest('ovos sem espaco deixam botao FULL inativo',function()
 local count=#g.s.tanks.main
 local target=Config.CAPACITY.main-1
 for i=count+1,target do
  assert(g:addFish('main',1,1,20))
 end
 g.s.cash=1000;v.shopPage=2;v.selectedShopIndex=7
 local text=render('shop');contains(text,'FULL')
 assert(not tap(191,191)) -- ovos: indice 7, terceira linha da pagina 2
 assert(g.s.cash==1000)
end)
assertTest('pesquisa apresenta custos e duracoes configurados no motor',function()
 g.s.cash=500;g.s.research_job=false
 local text=render('research')
 contains(text,'CASH $500')
 for _,entry in ipairs(Catalog.research) do
  local cost=Config.RESEARCH_COSTS[entry.id][1]
  local duration=math.ceil(Config.RESEARCH_SECONDS[1]/60)
  contains(text,'$'..cost..' / '..duration..' MIN')
 end
end)
assertTest('pesquisa sem saldo bloqueia START antes de tocar',function()
 g.s.cash=0;g.s.research_job=false
 local text=render('research');contains(text,'NO $')
 assert(not tap(180,124))
 assert(g.s.research_job==false and g.s.cash==0)
end)
assertTest('pesquisa ativa aparece BUSY e bloqueia novas',function()
 g.s.cash=500;g.s.research_job=false
 render('research')
 assert(tap(180,124))
 assert(g.s.research_job)
 local text=render('research');contains(text,'BUSY')
 assert(not tap(180,188))
end)
assertTest('pesquisa concluida aparece MAX e permanece bloqueada',function()
 g.s.research_job=false;g.s.research.environment=Config.RESEARCH_MAX
 local text=render('research');contains(text,'MAX LEVEL')
 assert(not tap(180,124))
 assert(g.s.research.environment==Config.RESEARCH_MAX)
end)
assertTest('nao houve mudanca no esquema de salvamento',function()
 assert(g.s.version==9)
end)
print('V38: '..tests..' cenarios de compras/pesquisas aprovados.')
