@echo off
setlocal
cd /d "%~dp0"
where love >nul 2>&1
if not errorlevel 1 (
  love .
  exit /b %errorlevel%
)
if exist "C:\Program Files\LOVE\love.exe" (
  "C:\Program Files\LOVE\love.exe" .
  exit /b %errorlevel%
)
echo Instale LÖVE 2D (11.4+) em https://love2d.org/
echo Depois arraste esta pasta para love.exe ou execute: love .
pause
exit /b 1
