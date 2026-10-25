-- V58: reconstrucao do menu WELCOME a partir de E/d.class do JAR original.
package.path='./?.lua;./?/init.lua;'..package.path
local Retro=require('ui.retro')
local Game=require('core.game')

local function labels(entries)
 local out={}
 for _,entry in ipairs(entries) do out[#out+1]=entry[1] end
 return table.concat(out,'|')
end
local withSave=Retro.new(Game.new(5801),true)
local menu=withSave:titleEntries()
assert(labels(menu)=='RESUME|START NEW GAME|OPTIONS|TROPHY|STATS|HELP|ABOUT|EXIT',
 'The WELCOME options differ from English E file (indices 1..9)')
assert(not labels(menu):find('MORE GAMES',1,true),
 'MORE GAMES must not appear when the edition does not expose it')

local without=Retro.new(Game.new(5802),false)
assert(labels(without:titleEntries())==
 'START NEW GAME|OPTIONS|TROPHY|STATS|HELP|ABOUT|EXIT',
 'RESUME may only appear with a saved game')
without.onNewGame=function()return true,nil,Game.new(5803) end
without:titleEntries()[1][2]()
assert(without.screen=='tank' and without.hasSave,
 'NEW GAME must start playable tank')

-- A saved game must request confirmation before overwriting.
menu[2][2]()
assert(withSave.screen=='confirm' and withSave.confirmFrom=='title')
withSave.screen='title'
menu[3][2]()
assert(withSave.screen=='settings' and withSave.from=='title')
withSave.screen='title'
menu[4][2]()
assert(withSave.screen=='collection')
withSave.screen='title'
menu[5][2]()
assert(withSave.screen=='stats')
withSave.screen='title'
menu[6][2]()
assert(withSave.screen=='help')
withSave.screen='title'
menu[7][2]()
assert(withSave.screen=='about' and withSave.from=='title')

local saves,exits=0,0
withSave.onSave=function()saves=saves+1;return false,'disk full' end
withSave.onExit=function()exits=exits+1 end
menu[#menu][2]()
assert(saves==1 and exits==0,'EXIT must never discard a failed save')
withSave.onSave=function()saves=saves+1;return true end
menu[#menu][2]()
assert(saves==2 and exits==1,'EXIT should save then close')
local extra=Retro.new(Game.new(5804),true)
extra.onMoreGames=function()end
assert(labels(extra:titleEntries()):find('ABOUT|MORE GAMES|EXIT',1,true),
 'Optional MORE GAMES should follow ABOUT, before EXIT')

print('OK v58: WELCOME list, conditional RESUME, navigation and safe exit')
