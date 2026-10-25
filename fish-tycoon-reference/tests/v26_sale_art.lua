-- Valida que a sinalizacao For Sale pertence a arte do JAR, nao aos peixes.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')
local noop=function() end
local drawn,printed={},{ }
love={graphics={
 newFont=function()return {setFilter=noop} end,
 getDimensions=function()return 480,640 end,
 newImage=function(path)
  local h=assert(io.open(path,'rb')):read(24)
  assert(h:sub(1,8)=='\137PNG\r\n\26\n')
  local function n(k)local a,b,c,d=h:byte(k,k+3);return ((a*256+b)*256+c)*256+d end
  local img={w=n(17),h=n(21),path=path,setFilter=noop}
  function img:getDimensions()return self.w,self.h end
  function img:getWidth()return self.w end
  function img:getHeight()return self.h end
  return img
 end,
 newQuad=function(x,y,w,h,iw,ih) assert(x+w<=iw and y+h<=ih);return {x=x,y=y,w=w,h=h} end,
 draw=function(img) if img.path then drawn[#drawn+1]=img.path end end,
 printf=function(s)printed[#printed+1]=tostring(s) end,
}}
for _,op in ipairs({'setColor','rectangle','setFont','line','push','pop','translate','scale','clear'}) do love.graphics[op]=noop end
local g=Game.new(2600)
local v=Retro.new(g,true);v:init()
local f=assert(g:addFish('sale',3,4,20))
v.room='sale';v.selected=f.id;v.screen='detail';v.bitmapFont=nil
v:draw()
local bg=false
for _,path in ipairs(drawn) do if path:match('tank3%.png$') then bg=true end end
assert(bg,'Tanque de vendas precisa do fundo nativo tank3.png')
for _,text in ipairs(printed) do assert(text~='For Sale!', 'Nao duplicar placa sobre peixe') end
assert(#v.fishHits>=1,'Peixe adulto permanece desenhado e selecionavel')
-- O foco v30 usa ponto fixo nos detalhes; ao voltar ao aquario,
-- o alvo correto volta a ser a posicao normal de nado.
v.screen='tank';v:draw()
local h
for _,hit in ipairs(v.fishHits) do if hit.id==f.id then h=hit;break end end
assert(h)
assert(v:press(v.ox+h.x*v.scale,v.oy+h.y*v.scale))
assert(v.screen=='detail' and v.selected==f.id)
assert(g.s.version==9)
print('V26: placas de venda originais fixas, selecao e save preservados')
