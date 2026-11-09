@echo off
title TechFlow Suite Pro Launcher
cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: Usar start /wait desacopla la captura de interrupci¢n del archivo por lotes
start "" /wait powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TechFlow.ps1"
exit /b
