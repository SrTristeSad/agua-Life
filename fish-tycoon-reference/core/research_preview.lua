-- Resumo NUMERICO do sistema de pesquisas do port Lua.
-- Niveis, custos e bonus adicionais nao foram autenticados no JAR.
-- Os numeros aqui derivam do motor atual, nao de uma segunda simulacao.
local Care=require('core.care')
local Market=require('core.market')
local Config=require('core.config')
local R={}

local function meanDelta(level)
 local total=0
 for body=1,21 do
  for tail=1,21 do
   local delta=Care.environmentDelta(body,tail,level+1)
   if level>=3 then delta=delta+2 end -- regra extra do port Lua
   total=total+delta
  end
 end
 return total/441
end
function R.preview(game,id)
 local level=game.s.research[id]
 if level==nil then return nil end
 level=math.max(0,math.min(Config.RESEARCH_MAX,level))
 local function describe(lvl)
  if id=='food' then
   return string.format('%d%% dos ciclos consomem reserva',Care.foodDrainChance(lvl))
  elseif id=='environment' then
   return string.format('Delta biologico medio %+.1f/ciclo',meanDelta(lvl))
  elseif id=='advertising' then
   local traffic=Market.traffic(lvl,game.s.gear.decor,#game.s.tanks.sale)
   return 'Indice de publico '..traffic
  end
 end
 return {level=level,max=level>=Config.RESEARCH_MAX,
  current=describe(level),next=(level<Config.RESEARCH_MAX and describe(level+1) or nil),
  -- Keeps the interface honest about what is original and what is not.
  source=(id=='advertising' and 'Publicidade experimental do port Lua'
    or 'Biologia JAR: niveis 1-3; nivel 4 e custos experimentais')}
end
return R
