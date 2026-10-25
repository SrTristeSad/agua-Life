-- V64: reproduzir perda de filhotes no mesmo ciclo da morte da mae.
-- Bytecode original n.a(o): nascimento a(m,o,int) antecede condicao.
package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local JSON=require('core.json')
local C=require('core.config')

local function pregnant(seed)
 local game=Game.new(seed)
 -- O peixe 2/2 perde condicao quando a pesquisa de ambiente e zero.
 local mother=game.s.tanks.main[2]
 local father=game.s.tanks.main[1]
 assert(game:move(mother.id,'isolation'))
 assert(game:move(father.id,'isolation'))
 assert(game:breed())
 game:advance(3*600)
 local carrier=assert(game:find(mother.id))
 assert(carrier.eggs_at and carrier.gestation_end_age)
 assert(carrier.age==carrier.gestation_end_age)
 assert(game.s.stats.born==0)
 return game,carrier
end

local game,mother=pregnant(64001)
local id=mother.id
local count=game:countFish()
mother.health=1 -- a mae morrera ao cumprir o quarto ciclo de gestacao
local pre=JSON.encode(game.s)
local fork=assert(Game.fromTable(JSON.decode(pre)))
game:advance(600)
for i=1,600 do fork:advance(1) end
assert(JSON.encode(game.s)==JSON.encode(fork.s),
 'Avanco continuo e fracionado geraram nascimentos diferentes')
assert(game.s.stats.born==1,
 'Parto desapareceu por ter sido processado depois da morte')
assert(game.s.stats.lost==1 and not game:find(id))
assert(game:countFish()==count,'Deveria nascer um filhote e morrer a mae')
assert(Game.fromTable(JSON.decode(JSON.encode(game.s))),
 'Nascimento e morte deixaram o save inconsistente')

-- O Java mantem capacidade 18 e nao gera filhotes alem desse limite.
local full,fullMother=pregnant(64002)
while #full.s.tanks.main<C.CAPACITY.main do
 assert(full:addFish('main',1,1,20))
end
local born=full.s.stats.born
local oldCount=full:countFish()
fullMother.health=1
full:advance(600)
assert(full.s.stats.born==born and full.s.stats.lost==1)
assert(full:countFish()==oldCount-1)
assert(#full.s.tanks.main==C.CAPACITY.main)
assert(Game.fromTable(JSON.decode(JSON.encode(full.s))))

-- Os ovos comprados nao desaparecem com o tanque cheio; aguardam vaga.
local purchased=Game.new(64003)
while #purchased.s.tanks.main<C.CAPACITY.main do
 assert(purchased:addFish('main',1,1,20))
end
purchased.s.eggs[#purchased.s.eggs+1]={body=2,tail=2,at=purchased.s.time}
purchased:advance(1)
assert(#purchased.s.eggs==1 and purchased.s.eggs[1].waiting)
local removed=purchased.s.tanks.main[1].id
assert(purchased:move(removed,'isolation'))
purchased:advance(1)
assert(#purchased.s.eggs==0 and #purchased.s.tanks.main==C.CAPACITY.main)
assert(purchased.s.stats.born==1)
assert(Game.fromTable(JSON.decode(JSON.encode(purchased.s))))
print('OK v64: parto antecede morte, lotacao preservada, ovos aguardam vaga')
