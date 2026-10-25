-- Mercado J2ME do Fish Tycoon: reconstrucao do metodo n.a(int,o,int).
-- Os limiares 30/10/4/1 sobre 900 e uma venda por visita sao do bytecode.
-- O numero de visitantes (decoracao, publicidade, quantidade de peixes)
-- e o intervalo aproximado sao adaptacoes; ver docs/FASE_8.md.
local Catalog=require('core.catalog')
local Clock=require('core.sim_clock')
local M={VISIT_SECONDS=5,HISTORY_LIMIT=12}
function M.key(body,fin) return body..'-'..fin end
function M.ensure(game,body,fin)
 local s=game.s
 s.market=s.market or {quotes={},visits=0,rejected=0,last_sale=false,elapsed=0}
 s.market.quotes=s.market.quotes or {}
 local key=M.key(body,fin)
 local price=s.market.quotes[key]
 if price~=nil then return price end
 local base=assert(Catalog.basePrice(body,fin),'Variedade invalida')
 local span=math.floor(base/5)
 local diff=(span>0) and game:int(0,span-1) or 0
 if game:int(0,99)<=49 then diff=-diff end
 price=math.max(1,base+diff)
 s.market.quotes[key]=price
 return price
end
function M.peek(game,body,fin)
 local s=game.s
 return s.market and s.market.quotes and s.market.quotes[M.key(body,fin)] or nil
end
-- O argumento 'traffic' do Java (l.x) combina anuncios, equipamentos,
-- peixes adultos e uma pequena parcela aleatoria. Esta funcao preserva
-- a estrutura da pontuacao, mas usa um indice de publico do port Lua.
function M.traffic(advertising,decor,fishCount)
 local audience=4+2*math.max(0,advertising or 0)
 if decor then audience=audience+1 end
 audience=audience+math.floor(math.max(0,fishCount or 0)/3)
 return math.max(1,math.floor((audience+2)/2))
end
function M.chancePerVisit(f,quote,base,advertising,decor,fishCount)
 local ask=math.max(1,math.floor(f.price or base))
 local demand
 if ask<quote then
  demand=(quote-ask>=math.floor(quote/2)) and 30 or 10
 elseif ask<2*base then
  demand=(ask-quote<=math.floor(base/2)) and 4 or 1
 else
  demand=0
 end
 local threshold=demand*M.traffic(advertising,decor,fishCount)
 -- Java: j.c(900) <= limiar. 0..899, entao chance=(limiar+1)/900.
 return demand==0 and 0 or math.min(1,(threshold+1)/900),demand,threshold
end
-- Historico e estados de cliente: instrumentacao do port Lua para mostrar
-- resultados sem mudar os limiares de procura recuperados do JAR.
-- Somente as 12 visitas mais recentes permanecem no salvamento.
local function record(s,entry)
 local history=s.market.history
 if type(history)~='table' then history={};s.market.history=history end
 history[#history+1]=entry
 if #history>M.HISTORY_LIMIT then table.remove(history,1) end
 s.market.last_visit=entry
end
-- Uma visita percorre os adultos na ordem do tanque. No maximo um peixe
-- vendido por cliente (n.a(int,o,int) retorna true assim que vende).
function M.step(game)
 local s=game.s
 if not s.sale_open then return false end
 s.market.visits=(s.market.visits or 0)+1
 local sale=s.tanks.sale
 local visit=s.market.visits
 local offered=0
 for i=1,#sale do
  local f=sale[i]
  if f.age>=20 then
   offered=offered+1
   local quote=M.ensure(game,f.body,f.tail)
   local base=Catalog.basePrice(f.body,f.tail)
   local chance,demand,threshold=M.chancePerVisit(f,quote,base,
     s.research.advertising,s.gear.decor,#sale)
   -- Mesmo que a probabilidade seja zero, evita gastar um sorteio do RNG.
   if demand>0 and game:int(0,899)<=threshold then
    local ok=game:sell(f.id,true)
    if ok then
     record(s,{visit=visit,time=s.time,status='sold',id=f.id,
       body=f.body,fin=f.tail,asked=f.price,quote=quote,amount=s.market.last_sale.amount})
     return true
    end
   end
  end
 end
 s.market.rejected=(s.market.rejected or 0)+1
 record(s,{visit=visit,time=s.time,status=offered>0 and 'passed' or 'empty',offered=offered})
 return false
end
-- A loja e atualizada em segundos de simulacao, nao em unidades de idade.
-- Acumulador persistido para que advance(a+b)==advance(a);advance(b).
function M.advance(game,seconds)
 local s=game.s
 if not s.sale_open then
  s.market.elapsed=0
  return 0
 end
 local interval=M.VISIT_SECONDS
 local elapsed=Clock.snap((s.market.elapsed or 0)+math.max(0,seconds or 0))
 local visits=math.floor((elapsed+0.0000001)/interval)
 s.market.elapsed=elapsed-visits*interval
 if s.market.elapsed<0 then s.market.elapsed=0 end
 for _=1,visits do
  M.step(game)
 end
 return visits
end
return M
