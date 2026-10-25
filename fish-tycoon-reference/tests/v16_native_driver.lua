-- Teste de renderizacao usando sprites PNG REAIS e uma API grafica estrita.
-- Nao substitui abrir uma janela do LÖVE, mas confere os recortes,
-- recursos, chamadas de desenho, composicao das telas e foco modal.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Assets=require('core.assets')
local View=require('ui.view')
local Atlas=require('core.atlas')
local checks=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('V14 '..name..': '..tostring(err),0) end
 checks=checks+1
 print('OK '..name)
end
local function pngDimensions(path)
 local f=assert(io.open(path,'rb'),'PNG ausente: '..path)
 local header=f:read(24);f:close()
 assert(header and header:sub(1,8)=='\137PNG\r\n\26\n','PNG invalido: '..path)
 local function number(n)
  local a,b,c,d=header:byte(n,n+3)
  return ((a*256+b)*256+c)*256+d
 end
 return number(17),number(21)
end
local currentlyDrawn={}
local function noop(...) end
local font={setFilter=noop}
love={
 graphics={
  newFont=function(size) assert(size>0);return font end,
  getDimensions=function() return 468,858 end,
  newImage=function(path)
   local w,h=pngDimensions(path)
   local img={path=path,w=w,h=h,setFilter=noop}
   function img:getDimensions() return self.w,self.h end
   function img:getWidth() return self.w end
   function img:getHeight() return self.h end
   return img
  end,
  newQuad=function(x,y,w,h,iw,ih)
   assert(x>=0 and y>=0 and w>0 and h>0 and x+w<=iw and y+h<=ih,
     ('recorte fora do atlas %g,%g %gx%g dentro de %gx%g'):format(x,y,w,h,iw,ih))
   return {quad=true,x=x,y=y,w=w,h=h}
  end,
  draw=function(img,...)
   assert(type(img)=='table' and img.path,'Imagem inexistente')
   local args={...}
   if type(args[1])=='table' and args[1].quad then
    local q=table.remove(args,1)
    assert(q.x+q.w<=img.w and q.y+q.h<=img.h)
   end
   for i=1,#args do assert(type(args[i])=='number','Argumento de desenho invalido') end
   currentlyDrawn[img.path]=(currentlyDrawn[img.path] or 0)+1
  end,
  ellipse=function(mode,x,y,rx,ry,segments)
   assert(mode=='fill' or mode=='line')
   assert(rx>0 and ry>0)
   assert(segments==nil or (segments%1==0 and segments>=3), 'Segmentos fracionarios na elipse')
  end,
 }}
for _,key in ipairs({'setColor','rectangle','print','printf','setFont','setLineWidth','line',
 'circle','arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[key]=noop
end

if os.getenv('FISH_NATIVE_SMOKE')~='1' then
 print('SKIP v16_native_driver (usar FISH_NATIVE_SMOKE=1)')
 return
end

-- O driver nativo e exercitado aqui com a mesma API simulada da v14,
-- incluindo callbacks de screenshot, troca de tamanho e cliques reais.
local screenshots={}
local exited=false
local files={}
love.filesystem={createDirectory=function() return true end,
 write=function(path,data) files[path]=data;return true end}
love.window={setMode=function(w,h,opts)
 assert(w==960 and h==600)
 love.graphics.getDimensions=function() return w,h end
 return true
end}
love.timer={getTime=function() return 0 end}
love.event={quit=function(code) assert(code==0);exited=true end}
love.graphics.captureScreenshot=function(callback)
 callback({encode=function(self,format,name)
  assert(format=='png');screenshots[#screenshots+1]=name
 end})
end
-- Executar main.lua como o LÖVE faria; FISH_NATIVE_SMOKE=1 no ambiente.
dofile('main.lua')
love.load()
for i=1,30 do
 if exited then break end
 love.update(.016)
 love.draw()
end
assert(exited,'O driver nao finalizou')
assert(#screenshots==7,'Capturas esperadas: 7, obtidas: '..#screenshots)
assert(files['native-smoke/ok.txt'])
for i,part in ipairs({'aquario','isolamento','vendas','loja','pesquisas','colecao','paisagem'}) do
 assert(screenshots[i]:find(part,1,true),'Tela nao capturada: '..part)
end
love.quit() -- jamais salva uma partida durante o teste nativo
print('V16: sete telas, navegacao e finalizacao do teste nativo aprovados.')
