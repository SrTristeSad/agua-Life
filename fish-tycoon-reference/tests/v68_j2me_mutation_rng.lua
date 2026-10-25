-- V68: bytecode n.a(m,o,int), offsets 7..169 in original Fish Tycoon JAR.
-- Verify which j.c(100) calls are made and whether selected allele changes.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')

local function reproduce(label,rolls,expected,params,magicEnabled)
 local g=Game.new(68000)
 local original=g.s.rng
 local calls={}
 g.hasMagic=function(_,effect,room)
  if effect=='mutation' and room=='isolation' then return magicEnabled~=false end
  return false
 end
 g.int=function(_,min,max)
  calls[#calls+1]={min,max}
  local index=#calls
  assert(index<=#rolls,label..': extra RNG call '..index)
  assert(min==0 and max==99,label..': original JAR always requests j.c(100)')
  return rolls[index]
 end
 local genes,body,tail=g:combineParents(
  params[1],params[2],params[3],params[4])
 assert(#calls==#rolls,label..': missing RNG calls ('..#calls..' ~= '..#rolls..')')
 assert(body==expected[1] and tail==expected[2],label..': wrong phenotype')
 assert(genes.body[1]==params[1] and genes.body[2]==expected[3],
  label..': wrong body partner allele')
 assert(genes.tail[1]==params[2] and genes.tail[2]==expected[4],
  label..': wrong fin partner allele')
 assert(genes.mutated==(magicEnabled~=false and rolls[1]<=15),
  label..': mutation flag incorrect')
 assert(g.s.rng==original,label..': mocked RNG unexpectedly changed state')
end

-- Without the sixth magic fish, there are no mutation RNG calls at all.
reproduce('no special',{}, {10,10,10,10},{11,11,10,10},false)
-- Java uses <=15 on 0..99 (16%).
reproduce('roll 16 no mutation',{16},{10,10,10,10},{11,11,10,10})
reproduce('roll 15 triggers mutation',{15,49,49},{10,11,10,11},{11,11,10,10})
-- 49 selects partner fin; 50 selects partner body.
reproduce('fin increases',{0,49,0},{10,11,10,11},{11,11,10,10})
reproduce('fin decreases',{0,49,50},{10,10,10,9},{11,11,10,10})
reproduce('body increases',{0,50,49},{11,10,11,10},{11,11,10,10})
reproduce('body decreases',{0,50,50},{10,10,9,10},{11,11,10,10})
-- Lower boundary (Java 0; Lua 1) consumes a third RNG roll,
-- even though the direction is forcibly +1.
reproduce('low fin boundary',{0,49,99},{1,1,1,2},{2,1,1,1})
reproduce('low body boundary',{0,50,99},{1,1,2,1},{1,2,1,1})
-- Upper boundary (Java 20; Lua 21) does NOT consume a direction roll.
reproduce('high fin boundary',{0,49},{21,20,21,20},{21,21,21,21})
reproduce('high body boundary',{0,50},{20,21,20,21},{21,21,21,21})

-- A single mutated partner-allele selection must be reused for each
-- sibling. No extra mutation RNG calls even with a fertility plant.
local g=Game.new(68001)
g.s.gear.fertility_plant=true
local mom=assert(g:addFish('isolation',11,11,20))
local dad=assert(g:addFish('isolation',10,10,20))
assert(g:breed())
g.hasMagic=function(_,effect,room)
 return effect=='mutation' and room=='isolation'
end
local sequence={0,49,49}
local consumed=0
local spawns={{0,189},{0,38},{0,0},{0,0},{0,65535}}
g.int=function(_,a,b)
 consumed=consumed+1
 if consumed<=#sequence then
  assert(a==0 and b==99,'Mutation rolls must come before spawning')
  return sequence[consumed]
 end
 local spawnIndex=(consumed-#sequence-1)%4+1
 local spec=spawns[spawnIndex]
 assert(spec and a==spec[1] and b==spec[2],
  'Unexpected child motion draw at '..consumed)
 return a
end
local born=g.s.stats.born
g:_hatch(mom)
assert(consumed==11 and g.s.stats.born==born+2,
 'Mutation uses 3 nextInt calls; each fish uses 4 nextInt + 1 nextBits(16)')
local babies=g.s.tanks.main
local left,right=babies[#babies-1],babies[#babies]
assert(left.genes.mutated and right.genes.mutated)
assert(JSON.encode(left.genes)==JSON.encode(right.genes))
assert(left.body==right.body and left.tail==right.tail)
assert(not mom.eggs_at and not mom.mate)
assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))
print('OK v68: exact mutation rolls and boundaries; one mutation shared by siblings')
