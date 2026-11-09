@echo off
title Visor y Gestor de Documentacion IA - TechFlow Suite Pro
setlocal enabledelayedexpansion

:MENU
cls
color 0B
echo.
echo  ==================================================================
echo            TECHFLOW SUITE PRO - VISOR DE ARCHIVOS IA
echo                 Panel de Control de Desarrollo
echo  ==================================================================
echo.
echo   LECTURA DE DOCUMENTACION:
echo   [1] Ver AI_PROMPT_MASTER.md       (Directivas y reglas para la IA)
echo   [2] Ver VERSION.json              (Version activa y changelog)
echo   [3] Ver AI_CONTEXT_DUMP.txt       (Volcado tecnico generado)
echo.
echo   ------------------------------------------------------------------
echo   ACCIONES Y HERRAMIENTAS IA:
echo   [4] Ejecutar Escaner IA           (Actualizar contexto y portapapeles)
echo   [5] Comprobar Sintaxis AST        (Validar scripts .ps1 sin errores)
echo   [6] Subir Version Semantica       (Incrementar patch/minor/major)
echo   ------------------------------------------------------------------
echo   [X] Volver / Salir
echo.

set /p "opt= > SELECCIONE UNA OPCION: "

if /i "%opt%"=="1" goto VER_MASTER
if /i "%opt%"=="2" goto VER_VERSION
if /i "%opt%"=="3" goto VER_DUMP
if /i "%opt%"=="4" goto CORRER_SCANNER
if /i "%opt%"=="5" goto CORRER_TEST
if /i "%opt%"=="6" goto CORRER_BUMP
if /i "%opt%"=="X" goto SALIR

echo.
echo  [!] Opcion no valida. Intente de nuevo.
timeout /t 1 >nul
goto MENU

:VER_MASTER
cls
color 0A
if exist "%~dp0AI_PROMPT_MASTER.md" (
    echo  ==================== AI_PROMPT_MASTER.md ====================
    type "%~dp0AI_PROMPT_MASTER.md"
    echo.
    echo  =============================================================
) else (
    echo.
    echo  [!] El archivo AI_PROMPT_MASTER.md no se encuentra en DevTools.
)
echo.
pause
goto MENU

:VER_VERSION
cls
color 0E
if exist "%~dp0VERSION.json" (
    echo  ======================= VERSION.json =======================
    type "%~dp0VERSION.json"
    echo.
    echo  =============================================================
) else (
    echo.
    echo  [!] El archivo VERSION.json no se encuentra en DevTools.
)
echo.
pause
goto MENU

:VER_DUMP
cls
color 0F
if exist "%~dp0AI_CONTEXT_DUMP.txt" (
    echo  Abriendo AI_CONTEXT_DUMP.txt (Espacio avanza, Q sale)...
    timeout /t 1 >nul
    more "%~dp0AI_CONTEXT_DUMP.txt"
) else (
    echo.
    echo  [!] El archivo AI_CONTEXT_DUMP.txt aun no ha sido generado.
    echo      Ejecute la opcion [4] para crearlo.
    pause
)
goto MENU

:CORRER_SCANNER
cls
if exist "%~dp0AI_SCANNER.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0AI_SCANNER.ps1"
) else (
    echo [!] No se encontro AI_SCANNER.ps1 en %~dp0
    pause
)
goto MENU

:CORRER_TEST
cls
if exist "%~dp0TEST_MODULES.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TEST_MODULES.ps1"
) else (
    echo [!] No se encontro TEST_MODULES.ps1 en %~dp0
    pause
)
goto MENU

:CORRER_BUMP
cls
if exist "%~dp0BUMP_VERSION.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUMP_VERSION.ps1"
) else (
    echo [!] No se encontro BUMP_VERSION.ps1 en %~dp0
    pause
)
goto MENU

:SALIR
exit /b
