@echo off
setlocal
cd /d "%~dp0"
where love.exe >nul 2>&1
if %errorlevel%==0 (
  start "" love.exe "%~dp0"
  exit /b 0
)
if exist "%ProgramFiles%\LOVE\love.exe" (
  start "" "%ProgramFiles%\LOVE\love.exe" "%~dp0"
  exit /b 0
)
if exist "%ProgramFiles(x86)%\LOVE\love.exe" (
  start "" "%ProgramFiles(x86)%\LOVE\love.exe" "%~dp0"
  exit /b 0
)
echo O LOVE 11.x nao foi encontrado.
echo Instale em https://love2d.org e abra este arquivo novamente.
pause
exit /b 1
