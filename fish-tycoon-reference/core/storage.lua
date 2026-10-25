local json=require('core.json')
local Game=require('core.game')
local M={filename='fish_tank_save.json',backup='fish_tank_save.backup.json',archive='fish_tank_save_before_new_game.json'}

local function decodeGame(raw)
 if type(raw)~='string' or #raw==0 then return nil,'Arquivo vazio' end
 local ok,data=pcall(json.decode,raw)
 if not ok then return nil,'JSON corrompido' end
 local built,game,err=pcall(Game.fromTable,data)
 if not built then return nil,'Estrutura de salvamento invalida' end
 return game,err
end

function M.save(game)
 if not (love and love.filesystem) then return false,'LOVE nao inicializado' end
 local fs=love.filesystem
 local previousWall=game.s.wall
 local now=os.time()
 -- Relogios atrasados nao reduzem a marca persistida.
 game.s.wall=math.max(tonumber(previousWall) or 0,now)
 local ok,data=pcall(json.encode,game.s)
 if not ok then game.s.wall=previousWall;return false,tostring(data) end
 -- Garantir que o novo arquivo possa ser reaberto ANTES de substituir
 -- o principal e o backup. O encoder sozinho aceita valores finitos
 -- estruturalmente invalidos, como estatisticas negativas e peixes sem ID.
 local checked,why=decodeGame(data)
 if not checked then
  game.s.wall=previousWall
  return false,'Estado nao pode ser salvo: '..tostring(why)
 end
 -- Grava o backup somente se o principal anterior puder ser carregado.
 -- Nunca substitua a unica copia recuperavel por JSON malformado.
 if fs.getInfo(M.filename) then
  local old=fs.read(M.filename)
  if old then
   local oldGame=decodeGame(old)
   if oldGame then
    local backed,backupErr=fs.write(M.backup,old)
    if not backed then
     game.s.wall=previousWall
     return false,'Falha no backup: '..tostring(backupErr)
    end
    local check=fs.read(M.backup)
    if check~=old then
     game.s.wall=previousWall
     return false,'Verificacao do backup falhou'
    end
   end
  end
 end
 local wrote,err=fs.write(M.filename,data)
 if not wrote then game.s.wall=previousWall;return false,tostring(err) end
 -- Uma escrita que retorna sucesso pode estar truncada; o backup
 -- verificado acima continua disponivel no proximo carregamento.
 if fs.read(M.filename)~=data then
  game.s.wall=previousWall
  return false,'Gravacao incompleta; backup anterior preservado'
 end
 return true
end

function M.load()
 if not (love and love.filesystem) then return nil,'LÖVE nao inicializado' end
 local fs=love.filesystem
 if not fs.getInfo(M.filename) and not fs.getInfo(M.backup) then
  return nil,'Sem salvamento anterior'
 end
 local firstError='Salvamento principal indisponivel'
 if fs.getInfo(M.filename) then
  local raw,err=fs.read(M.filename)
  if raw then
   local game,msg=decodeGame(raw)
   if game then return game end
   firstError=tostring(msg)
  else firstError=tostring(err) end
 end
 if fs.getInfo(M.backup) then
  local raw=fs.read(M.backup)
  if raw then
   local game=decodeGame(raw)
   if game then return game,'Backup recuperado: '..firstError end
  end
 end
 return nil,'Save e backup invalidos: '..firstError
end
-- Inicia nova partida somente depois de arquivar um save valido e verificar
-- que o novo arquivo foi gravado. Nao apagar backup anterior nem usar remove().
function M.startNewGame(nextGame)
 local fs=love and love.filesystem
 if not fs then return false,'Armazenamento indisponivel' end
 local previous=M.load()
 if previous then
  local payload=json.encode(previous.s)
  local ok,err=fs.write(M.archive,payload)
  if not ok or fs.read(M.archive)~=payload then
   return false,'Nao foi possivel arquivar a partida anterior: '..tostring(err)
  end
 end
 -- M.save ainda mantem um backup do principal anterior, quando valido.
 local ok,err=M.save(nextGame)
 if not ok then return false,err end
 return true
end
return M
