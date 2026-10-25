-- Os indices de forma/calda 1..21 e os sete peixes especiais vêm do
-- bytecode n/j do JAR. Nomes das variacoes sao identificadores neutros.
local Jar=require('core.jar_data')
local M={}
M.species={}
local palette={{.85,.59,.32},{.68,.82,.87},{.95,.70,.34},{.44,.78,.60},{.87,.49,.66},{.90,.80,.33}}
for i=1,21 do
 M.species[i]={id=i,name=string.format('Forma %02d',i-1),price=Jar.bodyValues[i],color=palette[(i-1)%#palette+1]}
end
M.magic={}
local effects={'fertility','sustain','cure','growth','vitality','mutation','wealth'}
for i,magic in ipairs(Jar.magic) do
 M.magic[i]={body=magic.body,tail=magic.fin,name=string.format('Peixe magico %d',i),
   effect=effects[i],note='Combinacao confirmada no JAR; bonus experimental'}
end
M.supplies = {
  {id='food', title='Racao especial', desc='5 porcoes para alimentar os peixes', price=20},
  {id='ick', title='Tratamento para Ick', desc='3 doses, 40% de cura por aplicacao', price=45},
  {id='fungus', title='Antifungico', desc='3 doses, 40% de cura por aplicacao', price=45},
  {id='vitamin', title='Vitaminas', desc='3 doses; recupera 6 a 15 de saude', price=35},
  {id='hormone', title='Horm. crescimento', desc='3 doses; idade +2 a +6 (ate 40)', price=65},
  {id='mutagen', title='Quimico desconhecido', desc='1 dose; 26% chance de mutacao (experimental)', price=150},
  {id='eggs', title='Ovos da lagoa', desc='2 ovos para incubar no tanque 1', price=55},
  {id='aerator', title='Aerador', desc='41% de chance de +1 saude por ciclo', price=130},
  {id='heater', title='Termorregulador', desc='41% de chance de +1 saude por ciclo', price=170},
  {id='snail', title='Caracol zelador', desc='Pode reduzir o risco de doenca pela metade', price=115},
  {id='plant', title='Planta de nutricao', desc='Pode recuperar 5 de alimento ao passar fome', price=95},
  {id='curing_plant', title='Planta de cura', desc='Reduz risco de doenca pela metade', price=160},
  {id='fertility_plant', title='Planta de fertilidade', desc='Permite 1 nascimento extra por gestacao', price=195},
  {id='decor', title='Ornamentos', desc='Atrai compradores para a loja', price=100},
  {id='second', title='Tanque adicional', desc='Abre o aquario 2', price=260},
}
M.research = {
  {id='environment', title='Ambiente', desc='Diminui doencas e fragilidade'},
  {id='food', title='Alimentacao', desc='Reduz a necessidade de racao'},
  {id='advertising', title='Publicidade', desc='Aumenta as chances de vendas'},
}
function M.magicFor(body, tail)
 for i,m in ipairs(M.magic) do
  if body==m.body and tail==m.tail then return i,m end
 end
 return nil,nil
end
-- Ordens textuais 51..71 (corpos) e 72..92 (barbatanas) da tabela
-- inglesa do JAR 1.0.1. O indice Lua corresponde ao indice Java+1.
M.bodyNames={'SHARK','CATFISH','ARROWFISH','SNOUT','FATFISH',
 'SNOOPER','GOLDSHARK','FIRE-ARROW','FRUITFISH','FLASHFISH','GOLDBULB',
 'COMET','STICKFISH','GROUPER','LEAFFISH','CARP','BETA','PIGMY',
 'BANANAFISH','QUICKSILVER','SPOTANUS'}
M.finNames={'SILKY','TIGER','HORNET','FANNED','PINK','SNUBBED',
 'WASP','CANARY','ORANGE','ORIENTAL','GOLDEN','CRIMSON','SPINED',
 'STUBBY','SPECKLED','RAZORBACK','GREENFIN','GREAT-SAIL',
 'FLAGGED','FINLESS','TWIN-FIN'}
function M.nameFor(body,tail)
 return (M.finNames[tail] or ('FIN '..tostring(tail)))..' '..
        (M.bodyNames[body] or ('FISH '..tostring(body)))
end
function M.basePrice(body,tail)
 return Jar.basePrice(body,tail)
end
return M