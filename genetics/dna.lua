-- Agua Life: genes reais do jogo, sem usar o RNG do desenho.
local Catalog=require('art.catalog')
local DNA={}
local function clamp(v,max) return math.max(1,math.min(max,math.floor(v))) end
local function pair(a,b,max)
 return {clamp(a,max),clamp(b,max)}
end
function DNA.founder(spec)
 assert(Catalog.valid(spec),"especie visual invalida")
 return {body=pair(spec.body,spec.body,#Catalog.bodies),
  fin=pair(spec.fin,spec.fin,#Catalog.fins),
  palette=pair(spec.palette,spec.palette,#Catalog.palettes),
  pattern=pair(spec.pattern,spec.pattern,6),generation=1,parents={}}
end
function DNA.valid(g)
 if type(g)~='table' then return false end
 for _,part in ipairs({'body','fin','palette','pattern'}) do
  local pairValues=g[part]
  local max=part=='body' and #Catalog.bodies or
    part=='fin' and #Catalog.fins or part=='palette' and #Catalog.palettes or 6
  if type(pairValues)~='table' or #pairValues~=2 then return false end
  for _,v in ipairs(pairValues) do
   if type(v)~='number' or v%1~=0 or v<1 or v>max then return false end
  end
 end
 return true
end
function DNA.express(g)
 assert(DNA.valid(g),"DNA invalido")
 -- Primeiro alelo dominante em cada locus; preservamos recessivos.
 return Catalog.get(g.body[1],g.fin[1],g.palette[1],g.pattern[1])
end
function DNA.child(a,b,random)
 assert(DNA.valid(a) and DNA.valid(b),"Pais invalidos")
 local draw=random or math.random
 local child={generation=math.max(a.generation or 1,b.generation or 1)+1,
  parents={a.id or 0,b.id or 0}}
 for _,part in ipairs({'body','fin','palette','pattern'}) do
  child[part]={a[part][draw(1,2)],b[part][draw(1,2)]}
 end
 return child
end
function DNA.profile(f)
 assert(type(f)=='table' and DNA.valid(f.genome),"Peixe sem DNA")
 local g=f.genome
 local score=(g.body[1]*11+g.body[2]*7+g.fin[1]*5+g.fin[2]*3)%41+40
 local sensitivity=((g.body[1]+g.fin[2])%2==0) and 'ick' or 'fungus'
 return {id=f.id or 0,generation=g.generation or 1,
  name=Catalog.bodies[f.spec.body].name..' / '..Catalog.fins[f.spec.fin].name,
  resistance=score,predisposition=sensitivity,
  heterozygous=g.body[1]~=g.body[2] or g.fin[1]~=g.fin[2] or
    g.palette[1]~=g.palette[2] or g.pattern[1]~=g.pattern[2]}
end
function DNA.lines(f)
 local p=DNA.profile(f);local g=f.genome
 return {'DNA DO PEIXE #'..p.id,'Variedade: '..p.name,
  'Geracao: '..p.generation,'Corpo: '..table.concat(g.body,' / '),
  'Cauda: '..table.concat(g.fin,' / '),
  'Paleta: '..table.concat(g.palette,' / '),
  'Estampa: '..table.concat(g.pattern,' / '),
  'Resistencia genetica: '..p.resistance..'/100',
  'Predisposicao: '..p.predisposition,
  'Genes recessivos: '..(p.heterozygous and 'presentes' or 'nao detectados'),
  'Saude: '..(f.health and f.health.hp or 100)..'/100',
  'Doenca: '..(f.health and f.health.disease or 'nenhuma')}
end
return DNA
