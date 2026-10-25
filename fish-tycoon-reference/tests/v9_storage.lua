package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local Storage=require('core.storage')
local count=0
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then io.stderr:write('FALHOU '..name..': '..tostring(err)..'\n');os.exit(1) end
 count=count+1;print('OK '..name)
end
local files={}
local fail={}
love={filesystem={
 getInfo=function(path) return files[path] and {size=#files[path]} or nil end,
 read=function(path) if files[path] then return files[path] end;return nil,'Ausente' end,
 write=function(path,data)
  if fail[path] then return nil,'Disco cheio' end
  files[path]=data;return #data
 end,
}}
local function reset() files={};fail={} end
local main=Storage.filename
local backup=Storage.backup

test('primeira gravacao sem save anterior',function()
 reset();local g=Game.new(3)
 assert(Storage.save(g))
 assert(files[main] and not files[backup])
end)
test('salvamento seguinte preserva copia anterior valida',function()
 reset();local g=Game.new(4)
 g.s.cash=100;assert(Storage.save(g))
 g.s.cash=500;assert(Storage.save(g))
 eq(JSON.decode(files[backup]).cash,100)
 eq(JSON.decode(files[main]).cash,500)
end)
test('arquivo principal corrompido recupera backup valido',function()
 reset();local g=Game.new(5)
 g.s.cash=775;assert(Storage.save(g))
 g.s.cash=250;assert(Storage.save(g))
 files[main]='{broken'
 local restored,reason=Storage.load()
 assert(restored and reason:find('Backup recuperado',1,true))
 eq(restored.s.cash,775)
end)
test('save nao troca backup valido por principal corrompido',function()
 reset();local g=Game.new(6)
 g.s.cash=670;assert(Storage.save(g))
 g.s.cash=680;assert(Storage.save(g))
 files[main]='{broken'
 g.s.cash=690;assert(Storage.save(g))
 eq(JSON.decode(files[backup]).cash,670)
 eq(JSON.decode(files[main]).cash,690)
end)
test('falha de escrita do backup conserva ultimo save',function()
 reset();local g=Game.new(7)
 assert(Storage.save(g));local orig=files[main]
 fail[backup]=true
 local ok,msg=Storage.save(g)
 assert(not ok and msg:find('backup',1,true))
 eq(files[main],orig)
end)
test('falha de escrita principal devolve erro',function()
 reset();local g=Game.new(8)
 fail[main]=true
 local ok,msg=Storage.save(g)
 assert(not ok);eq(msg,'Disco cheio')
end)
test('ambos invalidos nao criam novo jogo silenciosamente',function()
 reset();files[main]='broken';files[backup]='broken'
 local restored,err=Storage.load()
 assert(not restored and err:find('invalidos',1,true))
end)
test('save anterior schema 8 tambem serve como backup',function()
 reset();local g=Game.new(9)
 local old=JSON.decode(JSON.encode(g.s));old.version=8
 files[main]=JSON.encode(old)
 g.s.cash=333;assert(Storage.save(g))
 eq(JSON.decode(files[backup]).version,8)
 files[main]='broken'
 local recovered=assert(Storage.load())
 eq(recovered.s.version,9)
end)
print('\nSalvamento v9: '..count..' testes passaram.')
