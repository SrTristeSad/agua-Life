-- Exercitador opt-in de renderizacao real no LÖVE 11.x.
-- Invocar exclusivamente com FISH_NATIVE_SMOKE=1; nunca salva no slot do jogador.
local Smoke={}
Smoke.__index=Smoke

local function assertPage(view,page)
 assert(view.page==page,('Controle nativo falhou: esperado %s, obtido %s'):format(page,view.page))
end

function Smoke.new(view)
 local self=setmetatable({view=view,index=1,prepared=false,pending=false,done=false},Smoke)
 love.filesystem.createDirectory('native-smoke')
 self.stages={
  {name='01-aquario',prepare=function(s)
    s.view.room='main';s.view.page='tank';assert(#s.view.g.s.tanks.main==18)
   end},
  {name='02-isolamento',prepare=function(s)
    s:mouse(263,139);assert(s.view.room=='isolation')
   end},
  {name='03-vendas',prepare=function(s)
    s:mouse(365,139);assert(s.view.room=='sale')
   end},
  {name='04-loja',prepare=function(s)
    s:mouse(165,755);assertPage(s.view,'shop')
   end},
  {name='05-pesquisas',prepare=function(s)
    s:mouse(262,755);assertPage(s.view,'research')
   end},
  {name='06-colecao',prepare=function(s)
    s:mouse(369,755);assertPage(s.view,'catalog')
   end},
  {name='07-paisagem',prepare=function(s)
    s:mouse(61,755);assertPage(s.view,'tank')
    local ok=love.window.setMode(960,600,{resizable=true,highdpi=false})
    assert(ok,'Nao foi possivel trocar para modo paisagem')
   end},
 }
 return self
end

function Smoke:mouse(x,y)
 local v=self.view
 love.mousepressed(v.ox+x*v.scale,v.oy+y*v.scale,1)
end

function Smoke:afterDraw()
 if self.done or self.pending then return end
 local stage=self.stages[self.index]
 if not stage then
  self.done=true
  local ok=love.filesystem.write('native-smoke/ok.txt',
    'LÖVE nativo: '..(#self.stages)..' telas renderizadas e controles validados\n')
  assert(ok,'Falha ao salvar manifesto do smoke test')
  print('FISH_NATIVE_SMOKE_OK '..#self.stages)
  love.event.quit(0)
  return
 end
 if not self.prepared then
  stage.prepare(self)
  self.prepared=true
  return
 end
 self.pending=true
 local filename='native-smoke/'..stage.name..'.png'
 love.graphics.captureScreenshot(function(imageData)
  local ok,err=pcall(function() imageData:encode('png',filename) end)
  if not ok then
   io.stderr:write('FISH_NATIVE_SMOKE_ERROR '..tostring(err)..'\n')
   love.event.quit(1)
   return
  end
  print('FISH_NATIVE_SCREENSHOT '..filename)
  self.index=self.index+1
  self.prepared=false
  self.pending=false
 end)
end

return Smoke
