-- V69: The Java m.a(IIIII) constructor spends four j.c(n) draws
-- followed by one j.b(16) before its fish is committed.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local Spawn=require('core.j2me_spawn_rng')
local calls={}
local dummy={int=function(_,a,b)
 calls[#calls+1]={a,b}
 return a
end}
local appearance=Spawn.roll(dummy)
local expected={{0,189},{0,38},{0,0},{0,0},{0,65535}}
assert(#calls==5)
for i,item in ipairs(expected) do
 assert(calls[i][1]==item[1] and calls[i][2]==item[2],
  'Wrong call/order/range '..i)
end
assert(appearance.x==0 and appearance.y==214 and appearance.dx==-1
 and appearance.dy==-1 and appearance.drift==0)
-- Even though j.c(1) always returns zero, it MUST advance the RNG.
local game=Game.new(69001)
local rng=game.s.rng
local observed={}
local oldInt=game.int
game.int=function(self,a,b)
 observed[#observed+1]={a,b}
 return oldInt(self,a,b)
end
local juvenile=assert(game:addFish('main',1,1,0))
assert(#observed==4,'Juvenile spawn uses four nextInt draws plus nextBits(16)')
assert(game.s.rng~=rng)
for i=1,4 do
 local entry=expected[i]
 assert(observed[i][1]==entry[1] and observed[i][2]==entry[2])
end
local afterJuvenile=game.s.rng
local adult=assert(game:addFish('main',2,3,20))
assert(#observed>8,'Adults must roll spawn movement before market quote')
for i=1,4 do
 local entry=expected[i]
 assert(observed[4+i][1]==entry[1] and observed[4+i][2]==entry[2],
  'Adult quote occurred before fish movement roll')
end
assert(game.s.rng~=afterJuvenile)
local snapshot=JSON.encode(game.s)
local again,why=Game.fromTable(JSON.decode(snapshot))
assert(again,why)
assert(JSON.encode(again.s)==snapshot and again:find(adult.id))
-- A rejected insertion must not spend RNG or increment the next ID.
local oldRng=game.s.rng
local id=game.s.next_id
local bad=game:addFish('main',0,1,0)
assert(not bad and game.s.rng==oldRng and game.s.next_id==id)
local badGenes=game:addFish('main',1,1,0,{body={1},tail={1,1}})
assert(not badGenes and game.s.rng==oldRng and game.s.next_id==id)
-- An unopened tank also must not trigger fish creation rolls.
assert(not game:addFish('second',1,1,0))
assert(game.s.rng==oldRng and game.s.next_id==id)
-- Determinism and save/load across child spawning.
local g1=Game.new(69002)
local g2=Game.new(69002)
for n=1,8 do
 assert(g1:addFish('main',n,n,0))
 assert(g2:addFish('main',n,n,0))
 assert(JSON.encode(g1.s)==JSON.encode(g2.s),
  'Spawn sequence is not deterministic on birth '..n)
end
assert(Game.fromTable(JSON.decode(JSON.encode(g1.s))))
print('OK v69: Java constructor call order, validation, adult quotes, RNG and persistence')
