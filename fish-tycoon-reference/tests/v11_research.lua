package.path='./?.lua;./?/init.lua;'..package.path
local Game=require('core.game')
local P=require('core.research_preview')
local Market=require('core.market')
local Care=require('core.care')
local g=Game.new(7)
local food=P.preview(g,'food')
assert(food.current=='100% dos ciclos consomem reserva')
assert(food.next=='61% dos ciclos consomem reserva')
for level=0,3 do
 g.s.research.food=level
 local p=g:researchProjection('food')
 assert(p.current:find(tostring(Care.foodDrainChance(level)),1,true))
 if level==3 then assert(p.max and not p.next) end
end
g.s.research.environment=0
local env=P.preview(g,'environment')
assert(env.current:find('Delta biologico medio',1,true))
assert(env.next~=env.current)
g.s.research.advertising=0
local ads=P.preview(g,'advertising')
assert(ads.current=='Indice de publico '..Market.traffic(0,g.s.gear.decor,#g.s.tanks.sale))
assert(ads.next=='Indice de publico '..Market.traffic(1,g.s.gear.decor,#g.s.tanks.sale))
assert(P.preview(g,'does-not-exist')==nil)
print('V11: 8 verificacoes de pesquisa passaram.')
