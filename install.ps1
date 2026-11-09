# ============================================================
# TECHFLOW SUITE PRO - INSTALADOR Y EJECUTOR REMOTO (WEB IEX)
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$installDir = "C:\TechFlow_Suite_Pro_v6"
$repoZipUrl = "https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/archive/refs/heads/main.zip"

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              TECHFLOW SUITE PRO - INSTALADOR WEB                 ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Comprobar privilegios de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[!] Elevando permisos de administrador..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/install.ps1 | iex`"" -Verb RunAs
    exit
}

Write-Host "`n[1/4] Configurando exclusión en Windows Defender..." -ForegroundColor Yellow
try {
    Add-MpPreference -ExclusionPath $installDir -ErrorAction SilentlyContinue
    Write-Host "      ✅ Directorio protegido." -ForegroundColor Green
} catch {}

Write-Host "`n[2/4] Descargando última versión desde GitHub..." -ForegroundColor Yellow
$tempZip = "$env:TEMP\TechFlow_Latest.zip"
$tempExt = "$env:TEMP\TechFlow_Extracted"

Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip -UseBasicParsing
if (Test-Path $tempExt) { Remove-Item $tempExt -Recurse -Force }
Expand-Archive -Path $tempZip -DestinationPath $tempExt -Force

Write-Host "`n[3/4] Desplegando en $installDir..." -ForegroundColor Yellow
if (-not (Test-Path $installDir)) { New-Item -Path $installDir -ItemType Directory -Force | Out-Null }

$extractedFolder = Get-ChildItem -Path $tempExt -Directory | Select-Object -First 1
Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $installDir -Recurse -Force

Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $tempExt -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n[4/4] Creando acceso directo en el Escritorio..." -ForegroundColor Yellow
$desktop = [Environment]::GetFolderPath("Desktop")
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut("$desktop\TechFlow Suite Pro.lnk")
$sc.TargetPath = "$installDir\lanzador.bat"
$sc.WorkingDirectory = $installDir
$sc.Description = "TechFlow Suite Pro"
$sc.Save()

Write-Host "`n✅ Instalación remota completada." -ForegroundColor Green
Write-Host "🚀 Iniciando TechFlow Suite Pro..." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Start-Process "$installDir\lanzador.bat"
