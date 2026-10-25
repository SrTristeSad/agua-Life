-- Movimento visual para o front-end J2ME (nao altera simulacao/salvamento).
-- Evidencia: m.n() escolhe origem em [0,190) x [0,214) e h.a()/h.c()
-- usam posicao e velocidade em inteiros 16.16, revertendo direcao nas bordas.
-- No JAR, a velocidade adulta inicial e aprox. 20000/65536 e 6380/65536
-- pixels por atualizacao. A cadencia de 60 quadros/segundo e uma adaptacao
-- do port: a taxa real do MIDlet depende de seu loop e ainda nao foi aferida.
-- Para tornar o desenho estavel, a semente vem do ID do peixe, NAO do RNG
-- biologico e NAO do indice de posicao no vetor do tanque.
local Motion={}
local modulus=2147483647
local function unit(id,salt)
 local x=(math.floor(id)%modulus+salt*9187+19)%modulus
 for _=1,3 do x=(x*48271)%modulus end
 return x/modulus
end
local function reflected(start,step,low,high)
 local width=high-low
 local p=(start+step-low)%(2*width)
 if p<=width then return low+p,1 end
 return high-(p-width),-1
end
local roomSalt={main=1,second=2,sale=3}
function Motion.position(f,index,room,time)
 assert(type(f)=='table' and type(f.id)=='number' and f.id>=0)
 assert(type(time)=='number' or time==nil)
 local salt=roomSalt[room] or 1
 local id=f.id
 local young=(f.age or 20)<6
 -- Peixes jovens recem-nascidos aparecem inicialmente perto do solo,
 -- como na ramificacao de m.n() para movimento lento.
 local x0=27+unit(id,salt*13+1)*186
 local y0=young and (232+unit(id,salt*13+2)*16)
                or (40+unit(id,salt*13+2)*208)
 local xSpeed=(young and 1500 or (20000+math.floor(unit(id,salt*13+3)*16)))/65536*60
 local ySpeed=(young and 800 or (6380+math.floor(unit(id,salt*13+4)*16)))/65536*60
 local xDir=unit(id,salt*13+5)>.5 and 1 or -1
 local yDir=unit(id,salt*13+6)>.5 and 1 or -1
 local t=math.max(0,time or 0)
 -- A margem tem 25px para corpo adulto 50px. A fase juvenil e menor,
 -- mas mantemos a area ampla para nao cortar sprites ao crescer.
 local minY,maxY=young and 229 or 41, young and 253 or 253
 local x,flip=reflected(x0,xDir*xSpeed*t,27,213)
 local y=reflected(y0,yDir*ySpeed*t,minY,maxY)
 return x,y,flip*xDir
end
return Motion
