-- Relatorio de sessao: nao altera a simulacao nem o salvamento.
-- Mede apenas a diferenca entre estados, evitando inferir eventos que
-- nao constam dos contadores do motor.
local R={}
local COUNTERS={
 {key='born',label='Filhotes nascidos'},
 {key='sold',label='Peixes vendidos'},
 {key='lost',label='Peixes perdidos'},
 {key='healed',label='Tratamentos bem-sucedidos'},
 {key='infections',label='Novas doencas'},
}
local ORDER={'main','second','isolation','sale'}
local function countFish(g)
 local n=0
 for _,room in ipairs(ORDER) do n=n+#(g.s.tanks[room] or {}) end
 return n
end
function R.snapshot(g)
 local s=g.s
 local stats=s.stats or {}
 local counters={}
 for _,item in ipairs(COUNTERS) do counters[item.key]=stats[item.key] or 0 end
 return {cash=s.cash,fish=countFish(g),visits=(s.market and s.market.visits) or 0,
  research={environment=s.research.environment or 0,food=s.research.food or 0,
    advertising=s.research.advertising or 0},counters=counters,
  magic=g:countMagic()}
end
function R.build(before,g,seconds)
 if not before or not seconds or seconds<=0 then return nil end
 local after=R.snapshot(g)
 local result={seconds=seconds,lines={},before=before,after=after}
 local function add(label,delta)
  if delta~=0 then
   local sign=(delta>0 and '+' or '')
   result.lines[#result.lines+1]=label..': '..sign..tostring(delta)
  end
 end
 add('Dinheiro',after.cash-before.cash)
 add('Peixes no total',after.fish-before.fish)
 for _,item in ipairs(COUNTERS) do
  add(item.label,after.counters[item.key]-before.counters[item.key])
 end
 add('Visitas a loja',after.visits-before.visits)
 add('Especiais descobertos',after.magic-before.magic)
 for _,info in ipairs({{'food','Alimentacao'},{'environment','Ambiente'},{'advertising','Publicidade'}}) do
  local key,label=info[1],info[2]
  add('Pesquisa '..label,after.research[key]-before.research[key])
 end
 if #result.lines==0 then result.lines[1]='Nenhuma mudanca registrada.' end
 return result
end
return R
