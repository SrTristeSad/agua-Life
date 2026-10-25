-- Testa o NOVO front-end 240x320 no binario real do LOVE.
local Smoke={};Smoke.__index=Smoke
function Smoke.new(view)
 love.filesystem.createDirectory('retro-smoke')
 local actions={
  {'01-menu',function(v) assert(v.screen=='title') end},
  {'02-tanque',function(v)
   v:press(v.ox+120*v.scale,v.oy+110*v.scale); assert(v.screen=='tank') end},
  {'03-peixe',function(v)
   -- Fixture da captura 240x320 enviada pelo usuario:
   -- GREENFIN FRUITFISH, idade 21. So existe no save descartavel do CI.
   local fish=v.g.s.tanks.main[1]
   assert(fish)
   fish.body=9;fish.tail=17;fish.age=21
   local hit=v.fishHits[1];assert(hit and hit.id==fish.id)
   v:press(v.ox+hit.x*v.scale,v.oy+hit.y*v.scale)
   assert(v.screen=='detail' and v.selected==fish.id) end},
  {'04-acoes',function(v) v:press(v.ox+31*v.scale,v.oy+307*v.scale);assert(v.screen=='actions') end},
  {'05-menu-pausa',function(v)
   v:key('escape');v:key('escape');v:key('escape');assert(v.screen=='pause') end},
  {'06-suprimentos',function(v) v:press(v.ox+181*v.scale,v.oy+12*v.scale);assert(v.screen=='shop') end},
  {'07-suprimentos-pagina2',function(v)
   v:press(v.ox+165*v.scale,v.oy+289*v.scale)
   assert(v.screen=='shop' and v.shopPage==2) end},
  {'08-pesquisas',function(v)
   v:key('escape');v:draw()
   v:press(v.ox+203*v.scale,v.oy+12*v.scale)
   assert(v.screen=='research') end},
  {'09-configuracoes',function(v)
   v:key('escape');v:draw()
   v:press(v.ox+114*v.scale,v.oy+126*v.scale)
   assert(v.screen=='settings') end},
  {'10-vendas',function(v)
   v:key('escape');v:key('escape');v:draw()
   v:press(v.ox+45*v.scale,v.oy+12*v.scale)
   assert(v.screen=='tank' and v.room=='sale')
   assert(v.g:addFish('sale',3,4,20)) end},
  {'11-vendas-peixe',function(v)
   local hit=v.fishHits[1]
   assert(hit and v.g:find(hit.id))
   v:press(v.ox+hit.x*v.scale,v.oy+hit.y*v.scale)
   assert(v.screen=='detail' and v.room=='sale') end},
  {'12-menu-original',function(v)
   v:key('escape');v:key('escape');assert(v.screen=='pause') end},
  {'13-estatisticas',function(v)
   v:press(v.ox+114*v.scale,v.oy+180*v.scale)
   assert(v.screen=='stats') end},
  {'14-ajuda',function(v)
   v:key('escape');v:draw()
   v:press(v.ox+114*v.scale,v.oy+208*v.scale)
   assert(v.screen=='help') end},
  {'15-trofeu',function(v)
   v:key('escape');v:draw()
   v:press(v.ox+114*v.scale,v.oy+155*v.scale)
   assert(v.screen=='collection') end},
  {'16-acoes-peixe',function(v)
   v:key('escape');v:key('escape');v:draw()
   v:press(v.ox+9*v.scale,v.oy+12*v.scale)
   assert(v.room=='main' and v.screen=='tank')
   v:draw();local h=v.fishHits[1];assert(h)
   v:press(v.ox+h.x*v.scale,v.oy+h.y*v.scale)
   assert(v.screen=='detail');v:key('5');assert(v.screen=='actions') end},
  {'17-transferir-peixe',function(v)
   v:press(v.ox+112*v.scale,v.oy+165*v.scale)
   assert(v.screen=='move') end},
  {'18-tratar-peixe',function(v)
   v:key('escape');assert(v.screen=='actions')
   v:draw();v:press(v.ox+112*v.scale,v.oy+134*v.scale)
   assert(v.screen=='treat') end},
  {'19-selecao-superior',function(v)
   v:key('escape');assert(v.screen=='actions')
   v:key('escape');assert(v.screen=='detail')
   assert(v:browseFish(1))
   assert(v.screen=='detail' and v.selected) end},
  {'20-nado-livre',function(v)
   v:key('escape');assert(v.screen=='tank')
   v.room='main';v.selected=nil
   local tank=v.g.s.tanks.main
   for i=#tank+1,18 do assert(v.g:addFish('main',(i%21)+1,((i+6)%21)+1,20)) end
   v.time=8;v:draw()
   local xs,ys={},{}
   for _,hit in ipairs(v.fishHits) do
    xs[math.floor(hit.x+.5)]=true;ys[math.floor(hit.y+.5)]=true
   end
   local nx,ny=0,0
   for _ in pairs(xs) do nx=nx+1 end
   for _ in pairs(ys) do ny=ny+1 end
   assert(#v.fishHits==18 and nx>=13 and ny>=13,'Nado ainda parece grade') end},
  {'21-isolamento-dois',function(v)
   local fish=v.g.s.tanks.main
   fish[#fish].body=12;fish[#fish].tail=21
   assert(v.g:move(fish[#fish].id,'isolation'))
   assert(v.g:move(fish[#fish].id,'isolation'))
   v.room='isolation';v.selected=nil;v.screen='tank';v:draw()
   assert(#v.fishHits==2)
   for _,hit in ipairs(v.fishHits) do
    assert(hit.x-hit.rx>=70 and hit.x+hit.rx<=168)
    assert(hit.y-hit.ry>=274 and hit.y+hit.ry<=298)
   end
  end},
  {'22-isolamento-selecao',function(v)
   local h=v.fishHits[1];assert(h)
   v:press(v.ox+h.x*v.scale,v.oy+h.y*v.scale)
   assert(v.screen=='detail' and v.room=='isolation')
   v:draw()
   assert(v.fishHits[#v.fishHits].x==91)
   assert(v.fishHits[#v.fishHits].y==53)
  end},
  {'23-referencia-vendas',function(v)
   -- Mesma sala e exemplar da imagem fornecida pelo usuario, nao
   -- tanque principal com plantas diferentes (comparacao v34).
   v.room='sale';v.screen='detail';v.selected=nil
   local tank=v.g.s.tanks.sale
   while #tank<5 do
    assert(v.g:addFish('sale',3+(#tank%7),4+(#tank%9),21))
   end
   local fish=tank[1]
   fish.body=9;fish.tail=17;fish.age=21;fish.fed=100;fish.health=100
   v.selected=fish.id;v.time=1.5
   assert(v.g:find(fish.id)==fish)
   v:draw()
   assert(v.room=='sale' and v.screen=='detail')
   assert(v.fishHits[#v.fishHits].id==fish.id)
  end},
  {'24-selecao-barbatana-alta',function(v)
   -- Com 39px, a barbatana tipo 21 ultrapassaria a moldura de 37px
   -- sem recorte de desenho. Somente fixture descartavel do CI.
   local fish=v.g.s.tanks.sale[1];assert(fish)
   fish.body=9;fish.tail=21;fish.age=21
   v.selected=fish.id;v.room='sale';v.screen='detail';v.time=1.5
   v:draw();assert(v.fishHits[#v.fishHits].id==fish.id)
  end},
  {'25-trofeus',function(v)
   -- Apenas estado descartavel do smoke; nao toca no salvamento do jogador.
   v.g.s.magic['1']=true
   v.screen='collection';v.trophyIndex=1;v:draw()
   assert(v.screen=='collection' and v.g:countMagic()>=1)
  end},
  {'26-suprimentos-indisponiveis',function(v)
   -- O CI nao grava esta partida: estados criados para captura visual.
   v.g.s.cash=0;v.g.s.gear.aerator=true
   v.screen='shop';v.shopPage=2;v.selectedShopIndex=8;v:draw()
   assert(v.screen=='shop')
  end},
  {'27-pesquisa-custos',function(v)
   v.g.s.cash=120;v.g.s.research_job=false
   v.screen='research';v:draw()
   assert(v.screen=='research')
  end},
  {'28-titulo-com-save',function(v)
   v.screen='title';v.selected=nil;v:draw()
   assert(v.hasSave and v.screen=='title')
  end},
  {'29-confirmar-novo-jogo',function(v)
   v:press(v.ox+120*v.scale,v.oy+135*v.scale)
   assert(v.screen=='confirm' and v.confirmFrom=='title')
  end},
  {'30-opcoes-do-titulo',function(v)
   v:key('escape');assert(v.screen=='title')
   v:draw()
   v:press(v.ox+120*v.scale,v.oy+160*v.scale)
   assert(v.screen=='settings' and v.from=='title')
  end},
  {'31-voltar-ao-titulo',function(v)
   v:key('escape')
   assert(v.screen=='title')
  end}
 }
 return setmetatable({v=view,steps=actions,n=1,ready=false,pending=false,done=false},Smoke)
end
function Smoke:afterDraw()
 if self.done or self.pending then return end
 local stage=self.steps[self.n]
 if not stage then
  assert(love.filesystem.write('retro-smoke/ok.txt',tostring(#self.steps)..' J2ME-style screens rendered\n'))
  self.done=true;print('FISH_RETRO_SMOKE_OK '..#self.steps);love.event.quit(0);return
 end
 if not self.ready then
  local ok,err=pcall(stage[2],self.v)
  if not ok then print('FISH_RETRO_SMOKE_FAIL: '..tostring(err));self.done=true;love.event.quit(1);return end
  self.ready=true
  return
 end
 self.pending=true
 local path='retro-smoke/'..stage[1]..'.png'
 love.graphics.captureScreenshot(function(data)
  local ok,err=pcall(function() data:encode('png',path) end)
  if not ok then print('FISH_RETRO_ERROR '..tostring(err));love.event.quit(1);return end
  print('FISH_RETRO_PNG '..path)
  self.n=self.n+1;self.ready=false;self.pending=false
 end)
end
return Smoke
