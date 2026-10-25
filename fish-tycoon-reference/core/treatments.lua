-- Rotinas de cuidados do MIDlet J2ME 1.0.1 reconstruidas via javap.
-- n.a(o,int): comida; n.a(o,int,int): tratamento para manchas/fungos;
-- n.b(o,int,int): vitaminas, hormonio e quimico desconhecido.
-- No JAR os efeitos percorrem os peixes do tanque; neste port os
-- consumiveis sao aplicados ao peixe selecionado (adaptacao de interface).
local M={}
local function clamp(x) return math.max(0,math.min(100,x)) end

-- Quando a comida excede 100, o original retira 2 pontos de saude.
function M.feed(f)
 local before=f.fed or 0
 if before>=100 then return false,'Peixe ja alimentado' end
 f.fed=clamp(before+50)
 if before+50>100 then f.health=clamp((f.health or 100)-2) end
 return true,'Peixe alimentado'
end

-- n.a(o,int,int): 40 de 100 valores (0..39) curam a doenca correspondente.
function M.cure(game,f,kind)
 if f.disease~=kind then return false,'Tratamento nao corresponde a doenca' end
 if game:int(0,99)<40 then
  f.disease=false
  return true,'Tratamento funcionou: peixe curado'
 end
 return false,'Tratamento aplicado, mas nao fez efeito (40% de chance por dose)'
end

function M.vitamin(game,f)
 local amount=6+game:int(0,9)
 f.health=clamp((f.health or 100)+amount)
 return amount
end

function M.hormone(game,f)
 if f.age>40 then return false,'Hormonio so funciona ate 40 unidades de idade' end
 local amount=2+game:int(0,4)
 f.age=f.age+amount
 return true,amount
end

-- Chance de alteracao: j.c(100) <=25 (26%). A parte escolhida
-- muda um indice entre 0..20 em +/-1, sem sair dos limites.
function M.mutagen(game,f)
 if game:int(0,99)>25 then return false,nil end
 local part=game:int(0,99)<50 and 'body' or 'tail'
 local original=f[part]
 if original==21 then f[part]=20
 elseif original==1 then f[part]=2
 elseif game:int(0,99)<50 then f[part]=original+1
 else f[part]=original-1 end
 return true,part
end
return M
