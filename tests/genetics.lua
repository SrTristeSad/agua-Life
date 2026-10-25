package.path='./?.lua;./?/init.lua;'..package.path
local C=require('art.catalog')
local D=require('genetics.dna')
local H=require('genetics.health')
local mom={id=1,spec=C.get(2,3,4,5)}
mom.genome=D.founder(mom.spec);mom.health=H.new()
local dad={id=2,spec=C.get(7,8,9,3)}
dad.genome=D.founder(dad.spec);dad.health=H.new()
assert(D.valid(mom.genome))
local kid=D.child(mom.genome,dad.genome,function(a,b)return a end)
local spec=D.express(kid)
assert(spec.body==2 and spec.fin==3 and spec.palette==4 and spec.pattern==5)
assert(kid.body[2]==7 and kid.fin[2]==8)
local f={id=3,spec=spec,genome=kid,health=H.new()}
assert(D.profile(f).heterozygous)
for i=1,20 do assert(H.cycle(f,function()return 1 end)) end
assert(f.health.disease==false)
f.health.disease='fungus';f.health.hp=2
assert(not H.cycle(f,function()return 1 end))
local report=H.autopsy(f)
assert(report.cause=='Complicacoes por fungus')
assert(H.deathLines(report)[1]:find('NECROPSIA'))
f.health.disease=false
assert(not H.treat(f))
assert(H.feed(f)>0)
print('OK agua-Life: DNA recessivo, cruzamento, doencas, alimentacao e necropsia')
