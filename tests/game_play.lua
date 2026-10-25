package.path='./?.lua;./?/init.lua;'..package.path
local Play=require('game.play')
local Health=require('genetics.health')
local Json=require('game.json')
local Storage=require('game.storage')
local w=Play.new(427)
assert(#w.s.fish==4 and w.s.cash==280 and w.s.food==12)
assert(w.s.nextId==5 and w.s.days==0)
assert(not w:breed(1,1))
assert(w:breed(1,2))
assert(w.s.cash==268 and #w.s.jobs==1)
assert(not w:breed(1,3),'pais ocupados nao podem repetir cruzamento')
for i=1,3 do w:advance(Play.INTERVAL) end
assert(#w.s.fish==4 and #w.s.jobs==1)
w:advance(Play.INTERVAL)
assert(#w.s.fish==5 and #w.s.jobs==0 and w.s.stats.born==1)
local baby=w.s.fish[#w.s.fish]
assert(baby.id==5 and baby.health.age==0 and baby.genome.generation==2)
assert(baby.genome.parents[1]==1 and baby.genome.parents[2]==2)
local profile=require('genetics.dna').profile(baby)
assert(profile.generation==2)
local first=w:find(1)
first.health.fed=30
local food=w.s.food
assert(w:feed(1) and w.s.food==food-1 and first.health.fed==65)
assert(not w:feed(99))
local cashBefore=w.s.cash
local price=w:price(first)
assert(w:sell(1) and w.s.cash==cashBefore+price and not w:find(1))
assert(not w:sell(baby.id),'filhotes nao podem ser vendidos')
assert(w:buy('egg') and #w.s.fish==5)
assert(w:buy('nursery') and w.s.upgrades.nursery)
local fish=w:find(2)
assert(w:transfer(fish.id) and fish.room=='nursery')
assert(not w:buy('care'),'uma pesquisa sem dinheiro deve ser bloqueada')
-- Credito apenas da fixture de teste para exercitar upgrades caros.
w.s.cash=700
assert(w:buy('care') and w.s.upgrades.care==1)
assert(w:buy('food') and w:buy('medicine'))
local victim=w:find(3)
victim.health.hp=2;victim.health.disease='fungus';victim.health.fed=80
w:advance(Play.INTERVAL)
assert(not w:find(3) and w.s.stats.lost==1 and #w.s.deaths==1)
assert(w.s.deaths[1].cause:find('fungus'))
local raw=Json.encode(w.s)
local reload=assert(Storage.decode(raw))
assert(#reload.s.fish==#w.s.fish and #reload.s.deaths==1 and reload.s.cash==w.s.cash)
local bad=Json.decode(raw)
bad.fish[1].spec.body=21
assert(not Play.fromTable(bad),'save com DNA adulterado precisa ser recusado')
bad=Json.decode(raw);bad.fish[1].health.hp=-5
assert(not Play.fromTable(bad))
bad=Json.decode(raw);bad.fish[1].id=bad.fish[2].id
assert(not Play.fromTable(bad),'IDs duplicados')
local timeout=Play.new(42)
assert(timeout:advance(999999)==5,'o tempo offline deve ser limitado')
assert(timeout.s.days==5)
for _,magic in ipairs(Play.MAGIC) do
 assert(magic.body>=1 and magic.body<=21 and magic.fin>=1 and magic.fin<=21)
end
print('OK playable: crossing, birth, prices, markets, supplies, tank unlock, lifecycle, death and save validation')
