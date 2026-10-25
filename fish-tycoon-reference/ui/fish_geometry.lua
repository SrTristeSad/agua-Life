-- Medidas originais do JAR para m.a() / m.b() / m.c() e atlas do peixe.
-- O Lua nao deve reduzir o sprite importado: 21px (0..5), 35px (6..19),
-- 50px (20+). O efeito de zoom fica a cargo do viewport 240x320.
local Atlas = require('core.atlas')
local Geometry = {}

function Geometry.size(f)
 local age = f.age or 20
 if age < 6 then return 21,8 end
 if age < 20 then
  local juvenile = Atlas.juvenile[f.body]
  return 35, juvenile and juvenile[4] or 14
 end
 local body = Atlas.fish[f.body]
 local fin = Atlas.fins[f.tail]
 return 50, math.max(body and body[4] or 20, fin and fin[4] or 0)
end

return Geometry
