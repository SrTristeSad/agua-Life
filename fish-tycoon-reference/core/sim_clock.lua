-- Avoid floating error at integer-second simulation boundaries.
-- With repeated dt=0.1 or 1/60, a timestamp may land at
-- 179.999999999 instead of 180, deferring eggs/research until after a
-- market visitor and changing RNG outcomes. Only snap values very close
-- to whole seconds: do not round every frame or accumulate artificial
-- drift from repeated 1/60-second updates.
local Clock={}
local EPS=0.0000001
function Clock.snap(value)
 local nearest=math.floor(value+0.5)
 if math.abs(value-nearest)<=EPS then return nearest end
 return value
end
return Clock
