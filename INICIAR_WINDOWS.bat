@echo off
setlocal EnableExtensions
rem %~dp0 termina com barra invertida; acrescente ponto para nao
rem deixar a ultima barra imediatamente antes das aspas do argumento.
set "GAME_PATH=%~dp0."
set "GAME_FILE=%~dp0agua-Life-playable.love"
if exist "%GAME_FILE%" set "GAME_PATH=%GAME_FILE%"
if not exist "%~dp0main.lua" if not exist "%GAME_FILE%" (
  echo [ERRO] O jogo nao foi encontrado ao lado deste iniciador.
  echo Extraia o ZIP inteiro ou coloque este BAT na pasta com main.lua.
  pause
  exit /b 1
)

rem AGUA_LOVE_EXECUTABLE: permite testar o BAT sem instalar LOVE.
if defined AGUA_LOVE_EXECUTABLE (
  set "LOVE_EXE=%AGUA_LOVE_EXECUTABLE%"
) else (
  set "LOVE_EXE="
  where love.exe >nul 2>&1
  if not errorlevel 1 set "LOVE_EXE=love.exe"
  if not defined LOVE_EXE if exist "%ProgramFiles%\LOVE\love.exe" set "LOVE_EXE=%ProgramFiles%\LOVE\love.exe"
  if not defined LOVE_EXE if exist "%ProgramFiles(x86)%\LOVE\love.exe" set "LOVE_EXE=%ProgramFiles(x86)%\LOVE\love.exe"
)
if not defined LOVE_EXE (
  echo [ERRO] LOVE 11.x nao encontrado.
  echo Instale em https://love2d.org
  pause
  exit /b 1
)
echo Iniciando agua-Life...
call "%LOVE_EXE%" "%GAME_PATH%"
if errorlevel 1 (
  echo.
  echo [ERRO] O jogo encerrou com erro.
  pause
  exit /b 1
)
endlocal
exit /b 0
