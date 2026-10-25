package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Storage=require('core.storage')
local JSON=require('core.json')
local Report=require('core.offline_report')
local passed=0
local function test(label,fn)
 local ok,err=pcall(fn)
 if not ok then error('V13 falhou: '..label..': '..tostring(err),0) end
 passed=passed+1
 print('OK '..label)
end
local files={}
local brokenPath=nil
love={filesystem={
 getInfo=function(path) return files[path] and {size=#files[path]} or nil end,
 read=function(path) return files[path] end,
 write=function(path,value)
  if path==brokenPath then
   files[path]=value:sub(1,math.floor(#value/2))
   return #value -- falha simulada: driver informa sucesso, mas trunca os dados
  end
  files[path]=value
  return #value
 end,
}}
local function restoreFixture()
 for key in pairs(files) do files[key]=nil end
 brokenPath=nil
 local g=Game.new(610)
 g.s.cash=321
 assert(Storage.save(g))
 return g
end
local function invalidState(change)
 local good=restoreFixture()
 local safe=files[Storage.filename]
 local bad=JSON.decode(JSON.encode(good.s))
 change(bad)
 files[Storage.filename]=JSON.encode(bad)
 files[Storage.backup]=safe
 local loaded,info=Storage.load()
 assert(loaded and info and info:find('Backup recuperado',1,true),tostring(info))
 assert(loaded.s.cash==321)
end

test('rejeita proximo ID menor ou igual ao maior peixe',function()
 invalidState(function(s) s.next_id=s.tanks.main[4].id end)
end)
test('rejeita parceiro de gestacao com indice fora de 1..21',function()
 invalidState(function(s) s.tanks.main[1].mate={body_index=999,tail_index=1} end)
end)
test('rejeita pesquisas ativas de tipo invalido',function()
 invalidState(function(s) s.research_job='quebrada' end)
end)
test('rejeita ovo com valor negativo de tempo',function()
 invalidState(function(s) s.eggs={{body=1,tail=1,at=-5}} end)
end)
test('rejeita estado da loja como texto',function()
 invalidState(function(s) s.sale_open='true' end)
end)
test('aceita contador ausente em salvamento legado',function()
 local g=Game.new(611)
 local s=JSON.decode(JSON.encode(g.s))
 s.stats.failed_treatments=nil
 s.stats.mutations=nil
 -- Contadores ausentes sao normais em saves LEGADOS; na v9 indicam dano.
 s.version=8
 local loaded,err=Game.fromTable(s)
 assert(loaded,err)
 assert(loaded.s.stats.failed_treatments==0 and loaded.s.stats.mutations==0)
end)
test('se gravacao principal for truncada, identifica erro e preserva backup',function()
 local g=restoreFixture()
 g.s.cash=999
 g.s.wall=1
 brokenPath=Storage.filename
 local ok,msg=Storage.save(g)
 assert(not ok and msg:find('incompleta',1,true))
 assert(g.s.wall==1, 'nao deve modificar marca de tempo em falha de escrita')
 brokenPath=nil
 local loaded,info=Storage.load()
 assert(loaded and info:find('Backup recuperado',1,true))
 assert(loaded.s.cash==321)
end)
test('se backup truncar, nao altera principal',function()
 local g=restoreFixture()
 local orig=files[Storage.filename]
 g.s.cash=555
 brokenPath=Storage.backup
 local ok,msg=Storage.save(g)
 assert(not ok and msg:find('backup',1,true))
 assert(files[Storage.filename]==orig)
 brokenPath=nil
 local loaded=Storage.load()
 assert(loaded and loaded.s.cash==321)
end)
test('relogio retrocedeu: nao duplica tempo offline',function()
 local g=Game.new(612)
 g.s.wall=2000
 assert(g:offline(1500)==0)
 assert(g.s.wall==2000 and g.s.time==0)
 assert(g:offline(2150)==150)
 assert(g.s.wall==2150 and g.s.time==150)
 assert(g:offline(2110)==0)
 assert(g.s.wall==2150 and g.s.time==150)
 assert(g:offline(2200)==50)
 assert(g.s.time==200)
end)
test('relatorio longo mostra pagina seguinte sem acionar fundo',function()
 local nop=function() end
 love.graphics={newFont=function() return {setFilter=nop} end,
  getDimensions=function() return 420,800 end}
 for _,name in ipairs({'setColor','rectangle','print','printf','setFont','setLineWidth',
 'line','ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do love.graphics[name]=nop end
 local View=require('ui.view')
 local g=Game.new(613)
 local before=Report.snapshot(g)
 g.s.cash=300;g.s.stats.born=1;g.s.stats.sold=1;g.s.stats.lost=1
 g.s.stats.healed=1;g.s.stats.infections=1;g.s.market.visits=25
 g.s.magic['1']=true;g.s.research.food=1;g.s.research.environment=1
 local report=Report.build(before,g,7200)
 assert(#report.lines>7)
 local v=View.new(g);v:init();v:showOfflineReport(report);v:draw()
 assert(v.offlinePage==1)
 assert(v:press(345,565));assert(v.offlinePage==2)
 v:draw()
 assert(not v:press(180,755),'modal nao pode liberar controles do rodape')
 assert(v:press(70,565));assert(v.offlinePage==1)
 v:draw()
 assert(v:press(360,205));assert(v.modal==nil)
end)
print('V13: '..passed..' novos testes passaram.')
