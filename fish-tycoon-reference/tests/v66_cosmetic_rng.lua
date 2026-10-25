-- V66: Java m.class stores no sex; Lua presentation metadata must not
-- consume the same RNG used for genetics, disease or market visitors.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')

for seed=1,80 do
 local g=Game.new(66000+seed)
 local initialRng=g.s.rng
 local id=g.s.next_id
 local baby=assert(g:addFish('main',1,1,0))
 -- Fish creation spends five RNG draws for Java motion. Cosmetic sex
 -- must not spend a sixth roll (verified against explicit sex below).
 assert(g.s.rng~=initialRng,
  'Java fish constructor failed to advance motion RNG: '..seed)
 assert(baby.sex==(id%2==1 and 'F' or 'M'))
 local save=JSON.encode(g.s)
 local reopened=assert(Game.fromTable(JSON.decode(save)))
 assert(reopened.s.rng==g.s.rng and reopened:find(baby.id).sex==baby.sex)
end

-- The adult quote is allowed to consume RNG, but choosing a cosmetic
-- sex automatically must not change the quote or any later event.
for seed=1,80 do
 local source=Game.new(66600+seed)
 local snapshot=JSON.encode(source.s)
 local automatic=assert(Game.fromTable(JSON.decode(snapshot)))
 local explicit=assert(Game.fromTable(JSON.decode(snapshot)))
 local id=automatic.s.next_id
 local expected=id%2==1 and 'F' or 'M'
 local a=assert(automatic:addFish('main',2,3,20))
 local b=assert(explicit:addFish('main',2,3,20,nil,expected))
 assert(a.sex==expected and b.sex==expected)
 assert(JSON.encode(automatic.s)==JSON.encode(explicit.s),
  'Cosmetic sex unexpectedly perturbed market quote/RNG: '..seed)
 automatic:advance(800)
 explicit:advance(800)
 assert(JSON.encode(automatic.s)==JSON.encode(explicit.s),
  'Cosmetic sex perturbed simulation after growth: '..seed)
end

-- Child IDs determine cosmetic sex. Spawning consumes five Java
-- motion draws per fish, independent of cosmetic metadata.
local births=Game.new(66700)
local before=births.s.rng
local id1=births.s.next_id
local child1=assert(births:addFish('main',3,4,0))
local child2=assert(births:addFish('main',3,4,0))
assert(births.s.rng~=before)
assert(child1.sex==(id1%2==1 and 'F' or 'M'))
assert(child2.sex==((id1+1)%2==1 and 'F' or 'M'))
local valid,why=Game.fromTable(JSON.decode(JSON.encode(births.s)))
assert(valid,why)
-- A passed-in genotype is only an input to create a fish. Every fish
-- owns an independent copy, including when two siblings share input genes.
local siblings=Game.new(66800)
local supplied={body={2,4},tail={6,8}}
local left=assert(siblings:addFish('main',2,6,0,supplied))
local right=assert(siblings:addFish('main',2,6,0,supplied))
supplied.body[1]=21
supplied.tail[2]=21
assert(left.genes.body[1]==2 and right.genes.body[1]==2)
assert(left.genes.tail[2]==8 and right.genes.tail[2]==8)
left.genes.body[2]=11
assert(right.genes.body[2]==4 and supplied.body[2]==4,
 'Fish genotypes unexpectedly share mutable tables')
assert(Game.fromTable(JSON.decode(JSON.encode(siblings.s))))

print('OK v66: 160 RNG scenarios, cosmetic metadata, independent genotypes and saves')
