package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Storage=require('core.storage')
local JSON=require('core.json')
local count=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('ERRO '..name..': '..tostring(err)) end
 count=count+1;print('OK '..name)
end
local files={}
love={filesystem={
 getInfo=function(path) return files[path] and {size=#files[path]} or nil end,
 read=function(path) return files[path] end,
 write=function(path,data) files[path]=data;return #data end,
}}
local function backupMalform(change)
 local good=Game.new(4321)
 good.s.cash=777
 files[Storage.backup]=JSON.encode(good.s)
 local bad=JSON.decode(JSON.encode(good.s))
 change(bad)
 files[Storage.filename]=JSON.encode(bad)
 local loaded,msg=Storage.load()
 assert(loaded and msg and msg:find('Backup recuperado',1,true),tostring(msg))
 assert(loaded.s.cash==777)
 return loaded
end
test('salva backup para peixe com idade invalida',function()
 backupMalform(function(bad) bad.tanks.main[1].age='muito' end)
end)
test('recupera backup diante de estatisticas nao numericas',function()
 backupMalform(function(bad) bad.stats.sold='zero' end)
end)
test('recupera backup com research_job inconsistente',function()
 backupMalform(function(bad) bad.research_job={id='nao-existe',at=50} end)
end)
test('recupera backup se material de pesquisa e invalido',function()
 backupMalform(function(bad) bad.research='quebrada' end)
end)
test('recupera backup se id dos peixes esta repetido',function()
 backupMalform(function(bad) bad.tanks.main[2].id=bad.tanks.main[1].id end)
end)
test('recupera backup se lista de ovos nao e valida',function()
 backupMalform(function(bad) bad.eggs={{at='agora',body=2,tail=2}} end)
end)
test('save valido mantem estado e aceita a mesma versao',function()
 local g=Game.new(4330)
 g.s.cash=432
 files[Storage.filename]=JSON.encode(g.s)
 files[Storage.backup]=nil
 local loaded,msg=Storage.load()
 assert(loaded and msg==nil)
 assert(loaded.s.cash==432 and loaded.s.version==9)
end)
print('V12: '..count..' testes de recuperacao passaram.')
