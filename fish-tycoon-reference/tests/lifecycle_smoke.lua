package.path='./?.lua;./?/init.lua;'..package.path
local noop=function() end
local files={}
love={
 graphics={newFont=function() return {setFilter=noop} end,getDimensions=function() return 480,640 end},
 timer={getTime=function() return 100 end},
 filesystem={
  getInfo=function(key) return files[key] and {size=#files[key]} or nil end,
  read=function(key) return files[key] end,
  write=function(key,val) files[key]=val;return #val end,
 }
}
for _,key in ipairs({'setColor','rectangle','print','printf','setFont','setLineWidth','line','ellipse','circle',
 'arc','polygon','push','pop','translate','scale','clear'}) do
 love.graphics[key]=noop
end
assert(loadfile('main.lua'))()
love.load();love.update(1);love.draw()
-- v19: o menu inicial exige NOVO JOGO antes de existir save.
-- Menu WELCOME sem save: START NEW GAME em y=66..89, viewport escala 2.
love.mousepressed(240,216,1);love.draw()
assert(files['fish_tank_save.json'])
love.keypressed('2');love.draw()
love.touchpressed(1,100,250);love.draw()
love.focus(false);love.focus(true)
love.quit()
assert(files['fish_tank_save.json'] and #files['fish_tank_save.json']>100)
local save=files['fish_tank_save.json']
love.load();love.draw();love.quit()
assert(files['fish_tank_save.json'] and #files['fish_tank_save.json']>100)
print('Ciclo OK: iniciar, navegar, toque, perder/recuperar foco, salvar e recarregar JSON ('..#save..' bytes)')
