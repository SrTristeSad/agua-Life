-- V63: [] (lista) e {} (objeto) nunca podem ser confundidos no save.
package.path='./?.lua;./?/init.lua;'..package.path
local JSON=require('core.json')
local Game=require('core.game')
local Storage=require('core.storage')

local function kind(source, expected, serialized)
 local decoded=JSON.decode(source)
 assert(JSON.kind(decoded)==expected, 'Parser lost original JSON container type')
 assert(JSON.encode(decoded)==serialized,'JSON roundtrip changed container type')
end
kind('[]','array','[]')
kind('{}','object','{}')
kind('{"history":[], "meta":{}}','object','{"history":[],"meta":{}}')
local nested=JSON.decode('{"history":[], "meta":{}}')
assert(JSON.kind(nested.history)=='array')
assert(JSON.kind(nested.meta)=='object')
assert(JSON.kind(JSON.decode('{"arr":[{},[]]}').arr[1])=='object')
assert(JSON.kind(JSON.decode('{"arr":[{},[]]}').arr[2])=='array')

local fresh=Game.new(6301)
fresh.s.unlocked.second=true
assert(fresh:addFish('second',2,2,20))
local complete=JSON.encode(fresh.s)
local parsed=JSON.decode(complete)
assert(JSON.kind(parsed.tanks.second)=='array')
assert(JSON.kind(parsed.eggs)=='array')
assert(JSON.kind(parsed.market.history)=='array')
assert(Game.fromTable(JSON.decode(complete)))

local function corrupt(field,replacement)
 local source,n=complete:gsub(field,replacement,1)
 assert(n==1,'Fixture missing '..field)
 local broken=JSON.decode(source)
 local loaded,reason=Game.fromTable(broken)
 assert(not loaded and type(reason)=='string','Corrupt empty object accepted: '..field)
 return source
end
-- An empty object in a field intended to be an array previously passed
-- validation, allowing a genuinely lost list of fish to appear legitimate.
local malformedSale=corrupt('"second":%b[]','"second":{}')
corrupt('"eggs":%[%]','"eggs":{}')
corrupt('"history":%[%]','"history":{}')
local events=complete:gsub('"events":%b[]','"events":{}',1)
assert(events~=complete,'Could not replace events list')
local badEvents,reason=Game.fromTable(JSON.decode(events))
assert(not badEvents and reason)

-- The save must fall back to an intact backup without overwriting either file.
local writes=0
local files={[Storage.filename]=malformedSale,[Storage.backup]=complete}
love={filesystem={
 getInfo=function(path)return files[path] and {size=#files[path]} or nil end,
 read=function(path)return files[path] end,
 write=function(path,data)writes=writes+1;files[path]=data;return true end,
}}
local recovered,message=Storage.load()
assert(recovered and recovered:countFish()==fresh:countFish())
assert(message and message:find('Backup recuperado',1,true))
assert(writes==0,'Fallback unexpectedly modified user data')
assert(files[Storage.filename]==malformedSale)
assert(files[Storage.backup]==complete)

-- A legitimate save with empty collections must keep working, and its
-- containers must remain arrays after repeated save/load cycles.
local saved,err=Storage.save(recovered)
assert(saved,err)
local roundtrip=JSON.decode(files[Storage.filename])
assert(JSON.kind(roundtrip.tanks.second)=='array')
assert(JSON.kind(roundtrip.eggs)=='array')
assert(JSON.kind(roundtrip.market.history)=='array')
assert(Game.fromTable(roundtrip))
print('OK v63: JSON array/object identity, reject {} in tank/egg/history, backup recovery')
