-- Exact RNG call order in Fish Tycoon J2ME m.a(IIIII).
-- The Java fish constructor spends four j.c(n) draws before calling
-- m.a(IIII...J), which spends one j.b(16) draw. These affect the SAME
-- gameplay RNG used by other game mechanics; even j.c(1) advances it.
-- Values are cosmetic (spawn position/direction/velocity), but their RNG
-- consumption changes all later market, biology and mutation outcomes.
--
-- New games use the exact Java j.class LCG. Old saves continue the
-- previous Lua PRNG and retain the legacy five-call behavior.
local M={}
function M.roll(game)
 local x=game:int(0,189) -- j.c(190): sprite initial x
 local y=214-game:int(0,38) -- j.c(39): sprite initial y
 local dx=game:int(0,0)==0 and -1 or 1 -- j.c(1): always 0, still a call
 local dy=game:int(0,0)==0 and -1 or 1 -- second j.c(1) call
 -- j.b(16) returns the upper sixteen bits of ONE 48-bit LCG step.
 -- It is NOT j.c(65536): that method consumes next(31) instead.
 local drift=game.nextBits and game:nextBits(16)
   or game:int(0,65535) -- legacy Park-Miller compatibility
 return {x=x,y=y,dx=dx,dy=dy,drift=drift}
end
return M
