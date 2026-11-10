# ============================================================
# TECHFLOW SUITE PRO (GO EDITION) - INSTALADOR WEB DESATENDIDO
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$installDir = "C:\TechFlow"
$repoZipUrl = "https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases/latest/download/TechFlow_Suite_Pro_v7.0_Portable.zip"

Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        TECHFLOW SUITE PRO (GO) - INSTALADOR DESATENDIDO          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# 1. Comprobar permisos de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[!] Elevando permisos de administrador requeridos..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/install.ps1 | iex`"" -Verb RunAs
    exit
}

# 2. Configurar exclusión en Windows Defender
Write-Host "`n[1/4] Configurando exclusión en Windows Defender..." -ForegroundColor Yellow
try {
    Add-MpPreference -ExclusionPath $installDir -ErrorAction SilentlyContinue
    Write-Host "      ✅ Directorio protegido ($installDir)." -ForegroundColor Green
} catch {}

# 3. Descarga de la versión portátil
Write-Host "`n[2/4] Descargando TechFlow Suite Pro v7.0 Portable..." -ForegroundColor Yellow
$tempZip = "$env:TEMP\TechFlow_Go_Release.zip"

try {
    Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip -UseBasicParsing
} catch {
    Write-Host "      [!] Falló descarga desde Releases. Descargando snapshot de repositorio..." -ForegroundColor Yellow
    $fallbackUrl = "https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/archive/refs/heads/main.zip"
    Invoke-WebRequest -Uri $fallbackUrl -OutFile $tempZip -UseBasicParsing
}

# 4. Despliegue en C:\TechFlow
Write-Host "`n[3/4] Instalando archivos en $installDir..." -ForegroundColor Yellow
if (-not (Test-Path $installDir)) { New-Item -Path $installDir -ItemType Directory -Force | Out-Null }
Expand-Archive -Path $tempZip -DestinationPath $installDir -Force
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue

# 5. Crear acceso directo en el Escritorio
Write-Host "`n[4/4] Creando accesos directos..." -ForegroundColor Yellow
$desktop = [Environment]::GetFolderPath("Desktop")
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut("$desktop\TechFlow Suite Pro.lnk")
$sc.TargetPath = "$installDir\Iniciar_TechFlow.bat"
$sc.WorkingDirectory = $installDir
$sc.Description = "TechFlow Suite Pro (Native Go Edition)"
if (Test-Path "$installDir\cmd\techflow\app.ico") {
    $sc.IconLocation = "$installDir\cmd\techflow\app.ico,0"
}
$sc.Save()

Write-Host "`n✅ Instalación completada exitosamente." -ForegroundColor Green
Write-Host "🚀 Iniciando TechFlow Suite Pro..." -ForegroundColor Cyan
Start-Process "$installDir\Iniciar_TechFlow.bat"
