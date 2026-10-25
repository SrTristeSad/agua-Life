-- V70: golden vectors generated independently with OpenJDK java.util.Random
-- (the same 48-bit multiplier, state update and nextInt as JAR j.class).
package.path='./?.lua;./?/init.lua;'..package.path
local R=require('core.j2me_random')
local Game=require('core.game')
local JSON=require('core.json')
local Storage=require('core.storage')

local samples={
 {0,      {120,31,0,0,41773,53,2,1,1283218719,1},{47904,1785505948,15763}},
 {1,      {25,13,0,0,13612,4,2,1,2078239978,1}, {47898,215764588,26875}},
 {42,     {140,33,0,0,20232,25,2,3,1429255519,0},{47681,117392763,44775}},
 {123456789,{165,15,0,0,25592,54,0,1,1609843297,0},{43518,1639209600,29946}},
}
local bounds={190,39,1,1,65536,100,3,7,2147483647,2}
for _,v in ipairs(samples) do
 local state=R.seed(v[1])
 assert(state>=0 and state<R.MOD and state%1==0)
 for i,n in ipairs(bounds) do
  local result
  state,result=R.nextInt(state,n)
  assert(result==v[2][i],
   ('OpenJDK mismatch: seed=%d bound=%d index=%d got=%d expected=%d')
     :format(v[1],n,i,result,v[2][i]))
 end
 state=R.seed(v[1])
 local bits
 state,bits=R.nextBits(state,16);assert(bits==v[3][1])
 state,bits=R.nextBits(state,31);assert(bits==v[3][2])
 state,bits=R.nextBits(state,16);assert(bits==v[3][3])
end
local neg=R.seed(-1)
local x
neg,x=R.nextBits(neg,16)
assert(x==17625,'Signed Java long seeding differed')

-- New games use Java 48-bit. Reopened games must continue from the
-- exact 48-bit state, including zero and values above signed int31.
local g=Game.new(42)
assert(g.s.rng_kind=='j2me48' and g.s.rng>=0 and g.s.rng<R.MOD)
local save=JSON.encode(g.s)
local loaded,reason=Game.fromTable(JSON.decode(save))
assert(loaded,reason)
local function compare(game,copy)
 for i=1,150 do
  local n=({1,2,3,39,190,100,65536})[(i-1)%7+1]
  assert(game:int(0,n-1)==copy:int(0,n-1),'RNG diverged after save '..i)
  assert(game.s.rng==copy.s.rng)
 end
end
compare(g,loaded)
assert(Game.fromTable(JSON.decode(JSON.encode(g.s))))

-- Pre-v70 saves did not contain rng_kind, and must not be reseeded or
-- silently converted to Java. Their next Park-Miller output is fixed.
local old=JSON.decode(save)
old.rng_kind=nil;old.rng=12345
local legacy,reason=Game.fromTable(old)
assert(legacy,reason)
assert(legacy.s.rng_kind==nil and legacy.s.rng==12345)
local v=legacy:random()
assert(legacy.s.rng==((12345*48271)%2147483647))
assert(v==legacy.s.rng/2147483647)
local legacySave=JSON.encode(legacy.s)
local restored,err=Game.fromTable(JSON.decode(legacySave))
assert(restored,err)
assert(restored.s.rng_kind==nil and restored.s.rng==legacy.s.rng)
compare(legacy,restored)
local damaged=JSON.decode(save)
damaged.rng_kind='invalid-kind'
assert(not Game.fromTable(damaged),'Unknown RNG algorithm accepted')
damaged.rng_kind='j2me48';damaged.rng=R.MOD
assert(not Game.fromTable(damaged),'Invalid 48-bit state accepted')
damaged.rng_kind=nil;damaged.rng=R.MOD-1
assert(not Game.fromTable(damaged),'Legacy save accepted Java state')

-- The actual last draw of m.a(IIIIIJ) is nextBits(16), not nextInt(65536).
local fresh=Game.new(70)
local a,b=Game.fromTable(JSON.decode(JSON.encode(fresh.s))),
 Game.fromTable(JSON.decode(JSON.encode(fresh.s)))
local bits=a:nextBits(16)
local expectedState,expectedBits=R.nextBits(b.s.rng,16)
assert(bits==expectedBits and a.s.rng==expectedState)

print('OK v70: Java LCG golden vectors, next(16), save/load and Park-Miller legacy')
