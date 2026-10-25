package.path='./?.lua;./?/init.lua;'..package.path
local Swim=require('ui.swim')
local Game=require('core.game')
local g=Game.new(123)
local startingRng=g.s.rng
local tests=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('ERRO '..name..': '..tostring(err)) end
 tests=tests+1
 print('OK '..name)
end
local fish={id=3,age=25,health=90}
test('movimento deterministico, sem modificar o RNG do jogo',function()
 for n=0,20 do
  local a,b,c=Swim.position(fish,2,'main',n*.47)
  local x,y,face=Swim.position(fish,2,'main',n*.47)
  assert(a==x and b==y and c==face)
 end
 assert(g.s.rng==startingRng)
end)
test('18 peixes cabem no tanque durante as trajetorias',function()
 for i=1,18 do
  for t=0,150,.25 do
   local f={id=i,age=(i%3==0 and 2 or (i%3==1 and 15 or 30)),health=40+(i%6)*10}
   local x,y,face=Swim.position(f,i,'main',t)
   assert(x>=50 and x<=371,'fora horizontal '..i..' '..x)
   assert(y>=222 and y<=468,'fora vertical '..i..' '..y)
   assert(face==1 or face==-1)
  end
 end
end)
test('isolamento mantem dois peixes na area visivel',function()
 for i=1,2 do
  for t=0,70,.4 do
   local x,y=Swim.position({id=i,age=30,health=100},i,'isolation',t)
   assert(x>=70 and x<=350 and y>=320 and y<=350)
  end
 end
end)
test('direcao acompanha o deslocamento horizontal',function()
 for n=1,500 do
  local t=n*.17
  local x,_,face=Swim.position(fish,3,'main',t)
  local nx=Swim.position(fish,3,'main',t+.0002)
  if math.abs(nx-x)>1e-6 then
   assert((nx>x and face==1) or (nx<x and face==-1))
  end
 end
end)
test('crescimento e doenca modificam a velocidade de nado',function()
 local baby={id=7,age=2,health=100}
 local adult={id=7,age=30,health=100}
 local sick={id=7,age=30,health=20,disease='ick'}
 local function span(f)
  local x1=Swim.position(f,1,'main',0)
  local x2=Swim.position(f,1,'main',.5)
  return math.abs(x2-x1)
 end
 assert(span(baby)>span(adult) and span(adult)>span(sick))
end)
print('V10: '..tests..' testes de comportamento visual passaram.')
