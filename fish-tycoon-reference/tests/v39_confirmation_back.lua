-- Regression: BACK/Esc must cancel a new-game confirmation to its origin.
-- No LÖVE graphics or external assets required.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local view=Retro.new({s={}},true)
for _,origin in ipairs({'title','pause'}) do
 view.screen='confirm'
 view.confirmFrom=origin
 view:key('escape')
 assert(view.screen==origin,'Esc from confirmation must return to '..origin)
 view.screen='confirm'
 view.confirmFrom=origin
 view:key('back')
 assert(view.screen==origin,'Back from confirmation must return to '..origin)
end
-- Canceling a confirmation must never replace the active game.
assert(view.hasSave and view.g and view.g.s)
print('OK v39: confirm Esc/Back return to origin, game preserved')
