package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Report=require('core.offline_report')
local count=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('ERRO '..name..': '..tostring(err)) end
 count=count+1;print('OK '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end

test('relatorio contabiliza diferencas reais e mantem motor intocado',function()
 local g=Game.new(22)
 local before=Report.snapshot(g)
 local rng=g.s.rng
 local cash=g.s.cash
 g.s.cash=cash+40
 g.s.stats.sold=g.s.stats.sold+2
 g.s.stats.born=g.s.stats.born+3
 g.s.market.visits=g.s.market.visits+8
 g.s.research.food=1
 local r=Report.build(before,g,3600)
 eq(r.seconds,3600)
 eq(r.lines[1],'Dinheiro: +40')
 assert(table.concat(r.lines,';'):find('Peixes vendidos: +2',1,true))
 assert(table.concat(r.lines,';'):find('Pesquisa Alimentacao: +1',1,true))
 eq(g.s.rng,rng)
end)
test('relatorio vazio nao inventa alteracoes',function()
 local g=Game.new(23)
 local a=Report.snapshot(g)
 local r=Report.build(a,g,65)
 eq(#r.lines,1)
 eq(r.lines[1],'Nenhuma mudanca registrada.')
 assert(Report.build(a,g,0)==nil)
end)
test('progressao offline produz resumo de mercado e tempo',function()
 local g=Game.new(24)
 g.s.sale_open=true
 local before=Report.snapshot(g)
 g.s.wall=1000000
 local seconds=g:offline(1000600)
 eq(seconds,600)
 local r=Report.build(before,g,seconds)
 assert(table.concat(r.lines,';'):find('Visitas a loja: +120',1,true))
end)
test('a interface abre o relatorio e bloqueia botoes de fundo',function()
 local nop=function() end
 love={graphics={newFont=function() return {setFilter=nop} end,
     getDimensions=function() return 420,800 end}}
 for _,name in ipairs({'setColor','rectangle','print','printf','setFont','setLineWidth','line',
  'ellipse','circle','arc','polygon','push','pop','translate','scale','clear'}) do
   love.graphics[name]=nop
 end
 local View=require('ui.view')
 local g=Game.new(25)
 local v=View.new(g);v:init()
 local snap=Report.snapshot(g)
 g.s.cash=g.s.cash+20
 local report=Report.build(snap,g,180)
 v:showOfflineReport(report)
 eq(v.modal,'offline')
 v:draw()
 eq(#v.buttons,1)
 local cash=g.s.cash
 assert(not v:press(50,105))
 eq(g.s.cash,cash)
 -- Fecha dialogo e reabre pelo aquario, sem apagar o resumo.
 assert(v:press(360,207));eq(v.modal,nil)
 v:draw()
 assert(v:press(300,660));eq(v.modal,'offline')
end)
print('V12: '..count..' testes offline passaram.')
