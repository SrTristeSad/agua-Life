-- V61: perdas silenciosas no JSON, recuperacao de backup e deltas infinitos.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local Storage=require('core.storage')
local function rejectDecode(source)
 local ok=pcall(JSON.decode,source)
 assert(not ok,'JSON com null em lista foi aceito e compactaria peixes')
end

rejectDecode('[1,null,2]')
rejectDecode('[null]')
rejectDecode('[null,null]')
assert(JSON.decode('{"optional":null,"normal":3}').normal==3)
assert(JSON.decode('{"optional":null}').optional==nil)
assert(JSON.decode('[1,2,3]')[3]==3)

local g=Game.new(61001)
local base=JSON.encode(g.s)
local restored=assert(Game.fromTable(JSON.decode(base)))
assert(#restored.s.tanks.main==4)

-- Falha real anterior: [fish,null,fish] era reduzido a [fish,fish].
local damaged,n=base:gsub('"main":%[','"main":[null,',1)
assert(n==1,'fixture nao encontrou tanque principal')
rejectDecode(damaged)

local files={
 [Storage.filename]=damaged,
 [Storage.backup]=base
}
love={filesystem={
 getInfo=function(key)return files[key] and {size=#files[key]} or nil end,
 read=function(key)return files[key] end,
 write=function(key,data)files[key]=data;return true end,
}}
local loaded,note=Storage.load()
assert(loaded and #loaded.s.tanks.main==4)
assert(note and note:find('Backup recuperado',1,true),
 'Salvamento danificado nao recuperou backup')
assert(files[Storage.filename]==damaged,'load deve manter evidencia do principal corrompido')
local ok,err=Storage.save(loaded)
assert(ok,err)
assert(JSON.decode(files[Storage.filename]).version==9)
assert(JSON.decode(files[Storage.backup]).version==9)

-- Atual v9: nao "consertar" campos fundamentais danificados em silencio.
local function rejectState(mutator)
 local s=JSON.decode(base)
 mutator(s)
 local current,msg=Game.fromTable(s)
 assert(current==nil and type(msg)=='string', 'Save corrompido foi carregado')
end
rejectState(function(s)s.growth_elapsed=-60 end)
rejectState(function(s)s.growth_elapsed=600 end)
rejectState(function(s)s.growth_minutes=42 end)
rejectState(function(s)s.year_tick=-10 end)
rejectState(function(s)s.game_speed=123 end)
rejectState(function(s)s.market.elapsed=-1 end)
rejectState(function(s)s.market.elapsed=5 end)
rejectState(function(s)s.market.visits=-1 end)
rejectState(function(s)s.market.rejected=1.5 end)
-- JSON lists must not silently become Lua maps with string-number keys.
rejectState(function(s)s.tanks.main={['1']=s.tanks.main[1]} end)
rejectState(function(s)s.tanks.second={['1']=s.tanks.main[1]} end)
rejectState(function(s)s.eggs={['1']={body=1,tail=1,at=60}} end)
rejectState(function(s)s.events={['1']={text='hello',time=1}} end)
rejectState(function(s)s.market.history={['1']={visit=1,time=1,status='sold'}} end)

-- Recover a structurally malformed primary from the untouched backup.
local objectSave=JSON.decode(base)
objectSave.tanks.main={['1']=objectSave.tanks.main[1]}
files[Storage.filename]=JSON.encode(objectSave)
files[Storage.backup]=base
local recovered,recoveryNote=Storage.load()
assert(recovered and #recovered.s.tanks.main==4)
assert(recoveryNote and recoveryNote:find('Backup recuperado',1,true))

-- A versao 60 convertia +infinito em 24h: todos os peixes morriam.
local stable=Game.new(61002)
local snapshot=JSON.encode(stable.s)
stable:advance(math.huge)
stable:advance(-math.huge)
stable:advance(0/0)
assert(JSON.encode(stable.s)==snapshot,'Tempo invalido afetou o aquario')
stable:advance(10)
assert(stable.s.time==10 and stable:countFish()==4,
 'Delta finito valido deixou de ser processado')

-- Invalid API inputs must never poison a previously valid save.
local safe=Game.new(61003)
local previous=JSON.encode(safe.s)
local fish,errorMessage=safe:addFish('main',2,2,math.huge)
assert(not fish and errorMessage)
fish,errorMessage=safe:addFish('main',2,2,-1)
assert(not fish and errorMessage)
fish,errorMessage=safe:addFish('main',2,2,0/0)
assert(not fish and errorMessage)
fish,errorMessage=safe:addFish('main',math.huge,2,10)
assert(not fish and errorMessage)
local id=safe.s.tanks.main[1].id
for _,invalid in ipairs({math.huge,-math.huge,0/0}) do
 local allowed,reason=safe:changePrice(id,invalid)
 assert(not allowed and reason=='Ajuste de preco invalido')
end
assert(JSON.encode(safe.s)==previous,'Invalid command mutated game state')
assert(safe:addFish('main',2,2,2),'Valid fish insertion was rejected')
assert(safe:changePrice(id,1),'Valid price change was rejected')
assert(JSON.encode(safe.s),'Valid commands must remain serializable')

print('OK v61: corrupt backup fallback, non-finite time, age and price guard')
