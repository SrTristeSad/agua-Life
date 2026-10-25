-- Animacao visual do port Lua. Nao interfere na simulacao ou no RNG
-- reproduzido do JAR; todas as posicoes sao deterministicas.
local Swim={}
local pi=math.pi
local function bound(v,a,b) return math.max(a,math.min(b,v)) end
function Swim.position(f,index,room,t)
  assert(type(f)=='table' and type(f.id)=='number')
  assert(type(index)=='number' and index>=1)
  local col=(index-1)%4
  local row=math.floor((index-1)/4)
  -- Mantem 18 peixes dentro da area util da arte 374x331, incluindo
  -- corpo, barbatana e aro de selecao. A faixa superior contem o HUD.
  local homeX=91+col*79
  local homeY=260+row*45
  local range=15+(f.id%4)*2
  if room=='isolation' then
    homeX=121+(index-1)*174
    homeY=335
    range=23
  end
  local condition=bound((f.health or 100)/100,.3,1)
  local rate=(.61+(f.id%7)*.095)*(.4+.6*condition)
  if (f.age or 20)<6 then rate=rate*1.4
  elseif (f.age or 20)<20 then rate=rate*1.17 end
  if f.disease then rate=rate*.72 end
  local phase=(t or 0)*rate+(f.id*1.763)% (2*pi)
  local x=bound(homeX+math.sin(phase)*range,70,351)
  local y=bound(homeY+math.sin(phase*.73+index*.54)*5,233,453)
  -- Derivada de x: orientacao acompanha a direcao do movimento.
  local face=math.cos(phase)>=0 and 1 or -1
  return x,y,face
end
return Swim
