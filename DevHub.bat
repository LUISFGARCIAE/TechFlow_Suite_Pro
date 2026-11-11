@echo off
title TechFlow Suite Pro - Centro de Control Dev (Go)
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Solicitando elevacion de privilegios de Administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
if exist "%~dp0DevTools\DevHub.ps1" (
    cd /d "%~dp0"
    set "SCRIPT_PATH=%~dp0DevTools\DevHub.ps1"
) else if exist "%~dp0DevHub.ps1" (
    cd /d "%~dp0\.."
    set "SCRIPT_PATH=%~dp0DevHub.ps1"
) else (
    set "SCRIPT_PATH=C:\TechFlow_Go\DevTools\DevHub.ps1"
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '%SCRIPT_PATH%'"