@echo off
title TechFlow Suite Pro - Centro de Control Dev (Go)
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DevTools\DevHub.ps1"
