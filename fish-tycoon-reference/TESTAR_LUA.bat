@echo off
setlocal
cd /d "%~dp0"
where texlua >nul 2>&1
if errorlevel 1 (
 echo Para testes automatizados instale Lua ou TeX Live / texlua.
 pause
 exit /b 1
)
set "failed=0"
rem Executa todas as suites presentes, inclusive regressões adicionadas apos a v38.
for %%F in (tests\*.lua) do (
 echo Verificando %%F...
 texlua "%%F" || set "failed=1"
)
if "%failed%"=="1" (
 echo Verificacoes com falha.
 exit /b 1
)
echo Todos os testes Lua foram executados.
exit /b 0
