@echo off
title TechFlow Suite Pro (Native Go Edition)
cd /d "%~dp0"

:: Verificar permisos de Administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Solicitando permisos de Administrador...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if exist "%~dp0TechFlow_Pro.exe" (
    start "" "%~dp0TechFlow_Pro.exe"
) else (
    echo [X] No se encontro TechFlow_Pro.exe en este directorio.
    echo     Asegurate de descomprimir la suite por completo.
    pause
)
