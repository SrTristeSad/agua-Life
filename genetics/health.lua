-- Simulacao de saude; doenca ativa nao equivale a predisposicao genetica.
local DNA=require('genetics.dna')
local Health={}
local function clamp(v) return math.max(0,math.min(100,v)) end
function Health.new() return {hp=100,fed=100,age=0,disease=false,sickCycles=0} end
function Health.examine(f)
 local h=assert(f.health,'Peixe sem saude')
 local p=DNA.profile(f)
 return {id=f.id,hp=h.hp,fed=h.fed,age=h.age,disease=h.disease or 'nenhuma',
  predisposition=p.predisposition,resistance=p.resistance,
  status=h.hp<=25 and 'critico' or (h.disease and 'doente' or 'estavel')}
end
-- Cada ciclo representa uma unidade biologica; 'roll' injetavel facilita testes.
function Health.cycle(f,roll)
 local h=assert(f.health);local p=DNA.profile(f)
 local chance=roll or math.random
 h.age=h.age+1
 h.fed=clamp(h.fed-1)
 if not h.disease and h.age>=20 then
  local risk=(102-p.resistance)/24000
  if chance()<risk then h.disease=chance()<.5 and 'ick' or 'fungus' end
 end
 if h.disease then h.sickCycles=h.sickCycles+1;h.hp=clamp(h.hp-2)
 elseif h.hp<100 and h.fed>=30 then h.hp=clamp(h.hp+1) end
 if h.fed<15 then h.hp=clamp(h.hp-2) end
 if h.age>650 then h.hp=clamp(h.hp-1) end
 return h.hp>0
end
function Health.feed(f)
 local h=assert(f.health);h.fed=clamp(h.fed+35)
 return h.fed
end
function Health.treat(f,roll)
 local h=assert(f.health)
 if not h.disease then return false,'Nenhuma doenca ativa' end
 if (roll or math.random)()<.60 then
  h.disease=false;h.sickCycles=0;return true,'Tratamento eficaz'
 end
 return false,'Tratamento nao resolveu'
end
function Health.autopsy(f)
 local e=Health.examine(f)
 local cause,certainty='Indeterminada','baixa'
 if e.fed<15 then cause='Desnutricao';certainty='alta'
 elseif e.disease~='nenhuma' then
  cause='Complicacoes por '..e.disease;certainty='moderada'
 elseif e.age>650 then cause='Envelhecimento';certainty='moderada' end
 return {id=f.id,age=e.age,body=f.spec.body,fin=f.spec.fin,disease=e.disease,
  cause=cause,certainty=certainty,fed=e.fed,predisposition=e.predisposition}
end
function Health.deathLines(r)
 if not r then return {'Nenhuma morte registrada ainda.'} end
 return {'NECROPSIA - PEIXE #'..r.id,'Idade: '..r.age,
  'Corpo / cauda: '..r.body..' / '..r.fin,
  'Doenca encontrada: '..r.disease,
  'Alimentacao: '..r.fed..'/100',
  'Causa provavel: '..r.cause,
  'Confianca: '..r.certainty,
  'Predisposicao: '..r.predisposition}
end
return Health
