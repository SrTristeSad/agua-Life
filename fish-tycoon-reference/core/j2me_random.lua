-- Exact 48-bit LCG and nextInt contract recovered from original j.class.
-- j.a(long): (seed XOR 25214903917) AND (2^48-1)
-- j.b(bits): seed=(seed*25214903917+11) AND mask; return seed >>> (48-bits)
-- j.c(bound): java.util.Random.nextInt(bound), including rejection loop.
--
-- All operations use base-2^24 limbs; every intermediate is < 2^53,
-- so this works identically under Lua 5.1/LuaJIT and Lua 5.4 without
-- bitwise extensions or 64-bit integer overflow.
local M={}
M.MOD=281474976710656 -- 2^48, first invalid internal seed value
M.B=16777216        -- 2^24
M.MULT=25214903917
M.ADD=11
M.MULT_LO=M.MULT%M.B
M.MULT_HI=math.floor(M.MULT/M.B)
M.BITS31=2147483648
local function xor24(a,b)
 local r,weight=0,1
 for _=1,24 do
  local aa=a%2
  local bb=b%2
  if aa~=bb then r=r+weight end
  a=math.floor(a/2);b=math.floor(b/2)
  weight=weight*2
 end
 return r
end
function M.seed(raw)
 assert(type(raw)=='number' and raw==raw
   and raw~=math.huge and raw~=-math.huge
   and raw%1==0 and math.abs(raw)<=9007199254740991,
   'J2ME seed invalido')
 local state=raw%M.MOD
 local hi=math.floor(state/M.B)
 local lo=state%M.B
 return xor24(hi,M.MULT_HI)*M.B+xor24(lo,M.MULT_LO)
end
function M.nextBits(state,bits)
 assert(type(state)=='number' and state>=0
   and state<M.MOD and state%1==0,'Estado RNG J2ME invalido')
 assert(type(bits)=='number' and bits%1==0 and bits>=1 and bits<=31,
   'Numero de bits Java invalido')
 local hi=math.floor(state/M.B)
 local lo=state%M.B
 local low=lo*M.MULT_LO+M.ADD
 local carry=math.floor(low/M.B)
 lo=low%M.B
 hi=(hi*M.MULT_LO+math.floor(state%M.B)*M.MULT_HI+carry)%M.B
 local nextState=hi*M.B+lo
 return nextState,math.floor(nextState/2^(48-bits))
end
function M.nextInt(state,bound)
 assert(type(bound)=='number' and bound%1==0
   and bound>=1 and bound<=2147483647,'Limite RNG Java invalido')
 if bound%2==0 then
  local divisor=bound
  while divisor%2==0 do divisor=divisor/2 end
  if divisor==1 then
   local updated,bits=M.nextBits(state,31)
   return updated,math.floor(bound*bits/M.BITS31)
  end
 end
 while true do
  local bits
  state,bits=M.nextBits(state,31)
  local val=bits%bound
  -- Java int overflow in: bits - val + (bound-1) < 0.
  if bits-val+(bound-1)<M.BITS31 then return state,val end
 end
end
return M
