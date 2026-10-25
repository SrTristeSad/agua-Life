-- V67: genetics is optional metadata, but must be valid and isolated.
-- Offspring body/tail remain the integer average recovered from m.a(IIIII).
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local Storage=require('core.storage')
local g=Game.new(67001)
local initial=JSON.encode(g.s)
local invalid={
 {body={1,2},tail={2}},
 {body={1,22},tail={2,2}},
 {body={1,2},tail={2,0}},
 {body={1,1.5},tail={2,2}},
 {body={1,2},tail={2,2},mutated='yes'},
 {body={[1]=1,[3]=2},tail={2,2}},
 {body={},tail={2,2}},
 'not genes',
}
for i,genes in ipairs(invalid) do
 local fish,err=g:addFish('main',2,2,0,genes)
 assert(not fish and err=='Genetica do peixe invalida','Invalid alleles accepted '..i)
 assert(JSON.encode(g.s)==initial,
  'Rejected genetic input changed saved state/RNG/ID: '..i)
end

local meta={body={3,5},tail={7,9},mutated=false}
meta.extra=meta -- Cyclic caller metadata is never retained by the fish.
local fish=assert(g:addFish('main',4,8,0,meta))
assert(fish.genes.mutated==false)
assert(fish.genes.body[1]==3 and fish.genes.body[2]==5)
assert(fish.genes.tail[1]==7 and fish.genes.tail[2]==9)
assert(fish.genes.extra==nil)
meta.body[1]=21
assert(fish.genes.body[1]==3,'External allele mutation leaked into fish')
local valid=JSON.encode(g.s)
local loaded,reason=Game.fromTable(JSON.decode(valid))
assert(loaded,reason)
assert(JSON.encode(loaded.s)==valid,'Genes changed through persistence')

-- A v9 save with corrupted genes must be rejected, so storage can
-- recover a healthy backup rather than losing long-term parentage.
local damaged=JSON.decode(valid)
local target=damaged.tanks.main[#damaged.tanks.main]
target.genes.body[1]=99
local malformed=JSON.encode(damaged)
assert(not Game.fromTable(JSON.decode(malformed)))
local files={[Storage.filename]=malformed,[Storage.backup]=valid}
love={filesystem={
 getInfo=function(path) return files[path] and {size=#files[path]} or nil end,
 read=function(path) return files[path] end,
 write=function(path,data) files[path]=data;return true end,
}}
local recovered,note=Storage.load()
assert(recovered and note and note:find('Backup recuperado',1,true))
assert(JSON.encode(recovered.s)==valid)

-- With no special mutation in isolation, the child receives the
-- arithmetic mean of two parents' expressed body and fin indices.
local shape=Game.new(67002)
local p1=assert(shape:addFish('isolation',3,9,20))
local p2=assert(shape:addFish('isolation',8,14,20))
-- Initial fish do not modify the isolation tank's capacity.
assert(shape:breed())
local prev=shape.s.stats.born
local globalBefore=shape.s.rng
shape:_hatch(p1)
local child=shape.s.tanks.main[#shape.s.tanks.main]
assert(shape.s.stats.born==prev+1)
assert(child.body==5 and child.tail==11)
assert(child.genes.body[1]==3 and child.genes.body[2]==8)
assert(child.genes.tail[1]==9 and child.genes.tail[2]==14)
assert(shape.s.rng~=globalBefore,
 'Newborn motion should spend five RNG rolls, even without mutation')
p1.genes.body[1]=17
assert(child.genes.body[1]==3,'Changing a parent affected offspring genes')
local round=JSON.encode(shape.s)
assert(Game.fromTable(JSON.decode(round)))
print('OK v67: invalid alleles atomic, independent genotype, backup, JAR integer mean')
