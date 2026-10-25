-- Saves do agua-Life separados dos da reconstrução 1:1.
local Json=require('game.json')
local Play=require('game.play')
local Storage={}
Storage.filename='agua_life_playable_1.json'
Storage.backup='agua_life_playable_1.backup.json'
Storage.archive='agua_life_playable_previous.json'
local function decode(raw)
 if type(raw)~='string' or #raw==0 then return nil,'Arquivo vazio.' end
 local ok,data=pcall(Json.decode,raw)
 if not ok then return nil,'JSON corrompido.' end
 return Play.fromTable(data)
end
function Storage.encode(world)
 return Json.encode(world.s)
end
function Storage.decode(raw)
 return decode(raw)
end
function Storage.save(world)
 if not (love and love.filesystem) then return false,'LÖVE indisponível.' end
 local fs=love.filesystem
 local ok,raw=pcall(Storage.encode,world)
 if not ok then return false,'Falha ao serializar: '..tostring(raw) end
 local validated,why=decode(raw)
 if not validated then return false,'Save inválido: '..tostring(why) end
 if fs.getInfo(Storage.filename) then
  local previous=fs.read(Storage.filename)
  if previous and decode(previous) then
   local wrote,err=fs.write(Storage.backup,previous)
   if not wrote then return false,'Falha no backup: '..tostring(err) end
  end
 end
 local wrote,err=fs.write(Storage.filename,raw)
 if not wrote then return false,tostring(err) end
 if fs.read(Storage.filename)~=raw then return false,'Arquivo salvo incompleto.' end
 return true
end
function Storage.load()
 local fs=love and love.filesystem
 if not fs then return nil,'LÖVE indisponível.' end
 for _,name in ipairs({Storage.filename,Storage.backup}) do
  if fs.getInfo(name) then
   local raw=fs.read(name)
   local game,err=decode(raw)
   if game then
    return game,name==Storage.backup and 'Backup recuperado.' or nil
   end
  end
 end
 return nil,'Nenhuma partida válida.'
end
function Storage.newGame(seed)
 local fs=love and love.filesystem
 if not fs then return nil,'LÖVE indisponível.' end
 local old=Storage.load()
 if old then
  local ok,err=fs.write(Storage.archive,Storage.encode(old))
  if not ok then return nil,'Falha ao arquivar partida: '..tostring(err) end
 end
 local world=Play.new(seed)
 local ok,err=Storage.save(world)
 if not ok then return nil,err end
 return world
end
return Storage
