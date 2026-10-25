-- V62: ninguem perde um save por validacao atrasada ou JSON ambíguo.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local Storage=require('core.storage')
local JSON=require('core.json')

local seed=Game.new(6200)
local original=JSON.encode(seed.s)
local function rejectJson(raw)
 local ok=pcall(JSON.decode,raw)
 assert(not ok,'JSON ambiguo/corrompido foi aceito')
end
rejectJson('{"cash":200,"cash":0}')
rejectJson('{"tanks":{"main":[1],"main":[]}}')
rejectJson('{"stats":{"lost":null,"lost":0}}')
assert(JSON.decode('{"first":1,"second":2}').second==2)

local function invalidState(edit)
 local s=JSON.decode(original);edit(s)
 local game,msg=Game.fromTable(s)
 assert(game==nil and type(msg)=='string','Estado corrompido foi aceito')
end
for _,key in ipairs({'treatments','failed_treatments','mutations','infections'}) do
 invalidState(function(s)s.stats[key]='corrupt' end)
 invalidState(function(s)s.stats[key]=-4 end)
end
invalidState(function(s)s.supplies.mutagen='corrupt' end)
invalidState(function(s)s.supplies.mutagen=-7 end)
invalidState(function(s)s.market.history[1]={visit='corrupt',time=1,status='sold'} end)
invalidState(function(s)s.market.last_visit='corrupt' end)
invalidState(function(s)s.market.last_sale='corrupt' end)
invalidState(function(s)s.market.history[1]={visit=1,time=0,status='invalid'} end)

local files={[Storage.filename]=original,[Storage.backup]=original}
local writes=0
love={filesystem={
 getInfo=function(path)return files[path] and {size=#files[path]} or nil end,
 read=function(path)return files[path] end,
 write=function(path,data)writes=writes+1;files[path]=data;return true end,
}}

-- O save validado ANTES de qualquer write evita sobrescrever a unica
-- partida recuperavel por um arquivo valido JSON mas invalido no jogo.
local corrupt=Game.new(6201)
corrupt.s.stats.treatments=-1
local previousWall=corrupt.s.wall
local ok,err=Storage.save(corrupt)
assert(not ok and tostring(err):find('Estado nao pode ser salvo',1,true))
assert(writes==0,'Salvamento invalido chegou a alterar disco')
assert(corrupt.s.wall==previousWall,'Erro nao restaurou timestamp original')
assert(files[Storage.filename]==original and files[Storage.backup]==original)

-- O principal pode conter um JSON correto mas um historico mutilado.
local damaged=JSON.decode(original)
damaged.market.history[1]={visit='bad',time=1,status='sold'}
files[Storage.filename]=JSON.encode(damaged)
local recovered,msg=Storage.load()
assert(recovered and recovered:countFish()==seed:countFish())
assert(type(msg)=='string' and msg:find('Backup recuperado',1,true))
assert(writes==0,'Load de backup nunca deve substituir automaticamente o principal')

local valid=Game.new(6202)
valid.s.cash=valid.s.cash+11
local saved,reason=Storage.save(valid)
assert(saved,reason)
assert(writes==1,'Principal invalido nao deve destruir o backup')
assert(files[Storage.backup]==original)
assert(JSON.decode(files[Storage.filename]).cash==valid.s.cash)
assert(Game.fromTable(JSON.decode(files[Storage.filename])))

-- Em um save com principal integro, backup se torna a copia anterior.
files[Storage.filename]=original
writes=0
local newer=Game.new(6203)
newer.s.cash=newer.s.cash+25
assert(Storage.save(newer))
assert(writes==2 and files[Storage.backup]==original)
assert(Game.fromTable(JSON.decode(files[Storage.filename])))

print('OK v62: no silent normalisation, duplicate JSON keys, pre-save validation, backup')
