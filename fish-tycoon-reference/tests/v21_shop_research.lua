-- V21: interface de loja e pesquisa (teste com API LÖVE simulada).
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local Catalog=require('core.catalog')
local Config=require('core.config')
local nop=function()end
local labels={}
love={graphics={
 newFont=function()return {setFilter=nop}end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local f=assert(io.open(path,'rb'));local bytes=f:read(24);f:close()
  assert(bytes:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(pos)
   local a,b,c,d=bytes:byte(pos,pos+3)
   return ((a*256+b)*256+c)*256+d
  end
  local img={w=n(17),h=n(21),setFilter=nop}
  function img:getDimensions()return self.w,self.h end
  function img:getWidth()return self.w end
  function img:getHeight()return self.h end
  return img
 end,
 newQuad=function(x,y,w,h,iw,ih)assert(x>=0 and y>=0 and x+w<=iw and y+h<=ih);return {}end,
 printf=function(s)labels[#labels+1]=tostring(s)end
}}
for _,name in ipairs({'setColor','rectangle','line','draw','push','pop','translate',
 'scale','setFont','clear'}) do love.graphics[name]=nop end
local g=Game.new(2100)
local v=Retro.new(g,true);v:init()
-- Teste historico de rotulos via printf, sem tipografia privada opcional.
v.bitmapFont=nil
local count=0
local function check(name,fn)
 local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));count=count+1
 print('OK '..name)
end
local function tap(x,y)
 v:draw();return v:press(v.ox+x*v.scale,v.oy+y*v.scale)
end
check('recortes do atlas store validos para os suprimentos',function()
 assert(v.images.store)
 for _,item in ipairs(Catalog.supplies) do assert(v.storeQuads[item.id],item.id) end
end)
check('selecao nao compra, botao BUY compra',function()
 v.screen='shop';v.shopPage=1;v.selectedShopIndex=1
 local cash=g.s.cash
 assert(tap(75,131) and v.selectedShopIndex==2 and g.s.cash==cash)
 assert(tap(191,147) and g.s.cash==cash-Catalog.supplies[2].price)
end)
check('pagina avanca e retorna',function()
 assert(tap(164,291) and v.shopPage==2 and v.selectedShopIndex==5)
 assert(tap(75,131) and v.selectedShopIndex==6)
 assert(tap(75,291) and v.shopPage==1 and v.selectedShopIndex==1)
end)
check('ultima pagina nao desenha botoes fora da tela',function()
 v.shopPage=math.ceil(#Catalog.supplies/4);v.selectedShopIndex=999;v:draw()
 for _,b in ipairs(v.buttons) do
  assert(b.x>=0 and b.y>=0 and b.x+b.w<=240.1 and b.y+b.h<=320.1)
 end
end)
check('pesquisas exibem tres categorias',function()
 v.screen='research';labels={};v:draw()
 local all=table.concat(labels,';')
 for _,e in ipairs(Catalog.research) do assert(all:find(e.title:upper(),1,true)) end
end)
check('uma pesquisa ativa bloqueia nova',function()
 assert(tap(179,123))
 assert(g.s.research_job and g.s.research_job~=false)
 assert(not tap(179,188))
end)
check('nivel maximo impede nova pesquisa',function()
 g.s.research_job=false;g.s.research.environment=Config.RESEARCH_MAX
 v.screen='research';labels={};v:draw()
 assert(table.concat(labels,';'):find('LEVEL 3/3',1,true))
 assert(not tap(179,123))
end)
check('controle BACK e fallback sem sprite continuam',function()
 v.screen='shop';v.room='sale';v.shopPage=1;v.selectedShopIndex=1
 v.images.store=nil;v:draw()
 assert(tap(75,131) and v.selectedShopIndex==2)
 assert(tap(200,308) and v.screen=='pause' and v.room=='sale')
end)
print('V21: '..count..' testes de interface aprovados.')
