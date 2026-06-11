if ($Host.Name -ne "ConsoleHost") { Clear-Host } else { [System.Console]::Clear() }
$ErrorActionPreference = "SilentlyContinue"

# 🎨 Definición de Estilo Visual
$LINEA = " ═══════════════════════════════════════════════════════════════════"

# ============================================================
# 🛡️ AUTO-ELEVACIÓN SIMPLE Y EFECTIVA
# ============================================================

# Configurar UTF-8 para emojis
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Verificar si somos admin
$currentUser = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Detectar si se ejecutó desde irm | iex (sin archivo)
    $ejecucionRemota = (-not $PSCommandPath -or -not $MyInvocation.MyCommand.Path -or $PSCommandPath -eq "")
    
    if ($ejecucionRemota) {
        Write-Host "`n⚠️ TechFlow se ejecuta en MODO REMOTO (irm | iex)" -ForegroundColor Yellow
        Write-Host "   Para ejecutar correctamente, abre PowerShell COMO ADMINISTRADOR" -ForegroundColor Yellow
        Write-Host "   y vuelve a pegar el comando." -ForegroundColor Yellow
        Write-Host "`n   Presiona ENTER para salir..."
        Read-Host
        exit
    } else {
        $scriptPath = $PSCommandPath
        if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Path }
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    }
}

# Limpiar pantalla al iniciar como admin
Clear-Host
Write-Host "✅ EJECUTANDO CON PERMISOS DE ADMINISTRADOR" -ForegroundColor Green
Start-Sleep -Seconds 1
Clear-Host

# ============================================================
# 🔍 DIAGNÓSTICO DE ELEVACIÓN
# ============================================================
function Test-AdminAndContinue {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "`n ⚠️ ERROR: No se pudo elevar a Administrador automáticamente." -ForegroundColor Red
        Write-Host ""
        Write-Host " 📌 SOLUCIÓN MANUAL:" -ForegroundColor Yellow
        Write-Host "    1. Cierra esta ventana" -ForegroundColor Gray
        Write-Host "    2. Haz clic DERECHO en el archivo" -ForegroundColor Gray
        Write-Host "    3. Selecciona 'Ejecutar como administrador'" -ForegroundColor Gray
        Write-Host ""
        Write-Host " Presiona ENTER para salir..."
        Read-Host
        exit
    }
    
    Write-Host "`n ✅ EJECUTANDO CON PERMISOS DE ADMINISTRADOR" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

# Llamar a la función después de la auto-elevación
Test-AdminAndContinue

# ============================================================
# 🔧 DETECCIÓN DE EJECUCIÓN REMOTA (para que $PSScriptRoot no falle)
# ============================================================
$esScriptRemoto = $false
if (-not $PSScriptRoot -or $PSScriptRoot -eq "") {
    $esScriptRemoto = $true
    $carpetaTemp = "$env:TEMP\TechFlow_Suite_$(Get-Random)"
    if (-not (Test-Path $carpetaTemp)) {
        New-Item -ItemType Directory -Path $carpetaTemp -Force | Out-Null
    }
    $PSScriptRoot = $carpetaTemp
    Write-Host "   🌐 Modo remoto detectado. Usando carpeta: $carpetaTemp" -ForegroundColor DarkGray
}

# ============================================================
# 🛠️ [AUTO-REPARADOR] - WINGET & CHOCOLATEY
# ============================================================

function Repair-Winget {
    $wingetOk = $false
    try {
        $test = winget --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $test -match "\d+\.\d+") {
            $wingetOk = $true
        } else {
            throw "Winget no responde"
        }
    } catch {
        Write-Host "   🔧 Reparando motor WINGET 🧊..." -ForegroundColor Yellow
        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $wingetBundle = "$env:TEMP\winget_latest.msixbundle"
        try {
            Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetBundle -UseBasicParsing -ErrorAction Stop
            Add-AppxPackage -Path $wingetBundle -ErrorAction Stop
            Remove-Item $wingetBundle -Force -ErrorAction SilentlyContinue
            $wingetOk = $true
        } catch {
            Write-Host "   ❌ ERROR: No se pudo reparar Winget automáticamente" -ForegroundColor Red
        }
    }
    return $wingetOk
}

function Repair-Chocolatey {
    $chocoOk = $false
    try {
        $test = choco --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $test -match "\d+\.\d+\.\d+") {
            $chocoOk = $true
        } else {
            throw "Choco no responde"
        }
    } catch {
        Write-Host "   🔧 Instalando CHOCOLATEY 🍫..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            $installScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
            Invoke-Expression $installScript
            refreshenv 2>&1 | Out-Null
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $chocoOk = $true
        } catch {
            Write-Host "   ❌ ERROR: No se pudo instalar Chocolatey automáticamente" -ForegroundColor Red
        }
    }
    return $chocoOk
}

# ============================================================
# 🔍 [EJECUCIÓN] - VALIDACIÓN DE REPOSITORIOS
# ============================================================

Write-Host ""
Write-Host " 📦 ESTADO DE REPOSITORIOS DE SOFTWARE" -ForegroundColor Cyan
Write-Host $LINEA -ForegroundColor Gray

# Winget
$wingetWorking = Repair-Winget
if ($wingetWorking) {
    Write-Host "   ✅ WINGET      : DISPONIBLE 🧊" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ WINGET      : NO DISPONIBLE (Uso de URLs manuales)" -ForegroundColor Yellow
}

# Chocolatey
$chocoWorking = Repair-Chocolatey
if ($chocoWorking) {
    Write-Host "   ✅ CHOCOLATEY  : DISPONIBLE 🍫" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ CHOCOLATEY  : NO DISPONIBLE" -ForegroundColor Yellow
}

Write-Host $LINEA -ForegroundColor Gray
Write-Host "   💡 RECOMENDACIÓN: Los repositorios permiten instalaciones silenciosas." -ForegroundColor Gray

# Pequeña pausa para que el usuario lea
Start-Sleep -Seconds 1

# ============================================================
# 🔄 VERIFICACIÓN DE ACTUALIZACIONES
# ============================================================

Write-Host "`n 🔍 [1/3] VERIFICANDO ACTUALIZACIONES..." -ForegroundColor Gray

$scriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
if (-not $scriptPath) { $scriptPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName }

$carpetaDelScript = Split-Path $scriptPath -Parent
$nombreDelExe = [System.IO.Path]::GetFileName($scriptPath)
$exeActual = "$carpetaDelScript\$nombreDelExe"

try {
    $apiUrl = "https://api.github.com/repos/LUISFGARCIAE/TechFlow_Suite_Pro/releases/latest"
    $latestRelease = Invoke-RestMethod -Uri $apiUrl -ErrorAction SilentlyContinue
    $latestVersion = $latestRelease.tag_name -replace 'v', ''
    
    if ($latestVersion -and ($latestVersion -ne "5.9")) {
        Write-Host " $LINEA" -ForegroundColor Yellow
        Write-Host "   🚀 ¡NUEVA VERSIÓN DISPONIBLE!" -ForegroundColor Yellow
        Write-Host "   📦 Actual: v5.9  ➜  Nueva: v$latestVersion" -ForegroundColor Cyan
        Write-Host " $LINEA" -ForegroundColor Yellow
        
        $update = Read-Host "`n   ❓ ¿Deseas actualizar ahora? (S/N)"
        
        if ($update -eq "S" -or $update -eq "s") {
            $asset = $latestRelease.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
            
            if (-not $asset) {
                Write-Host "   ❌ ERROR: No se encontró archivo ejecutable en el servidor." -ForegroundColor Red
                Read-Host "   Presiona ENTER para continuar..."
            } else {
                Write-Host "   ⏳ Descargando nueva versión..." -ForegroundColor Yellow
                $nuevaVersion = "$carpetaDelScript\TechFlow_NUEVO.exe"
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $nuevaVersion -UseBasicParsing
                
                if (Test-Path $nuevaVersion) {
                    Write-Host "   ✅ Descarga completada con éxito." -ForegroundColor Green
                    
                    $batFile = "$carpetaDelScript\actualizar.bat"
                    $batContent = @"
@echo off
cd /d "$carpetaDelScript"
timeout /t 2 /nobreak > nul
taskkill /f /im "$nombreDelExe" > nul 2>&1
timeout /t 2 /nobreak > nul
del /f /q "$nombreDelExe" > nul 2>&1
timeout /t 1 /nobreak > nul
copy /y "TechFlow_NUEVO.exe" "$nombreDelExe" > nul
timeout /t 1 /nobreak > nul
start "" "$nombreDelExe"
del /f /q "TechFlow_NUEVO.exe" > nul 2>&1
del /f /q "%~f0" > nul 2>&1
exit
"@
                    $batContent | Out-File -FilePath $batFile -Encoding ascii -Force
                    Write-Host "   🔄 Aplicando parche de actualización..." -ForegroundColor Yellow
                    Start-Process -FilePath $batFile -WindowStyle Hidden
                    Start-Sleep -Seconds 3
                    exit
                } else {
                    Write-Host "   ❌ ERROR: Falló la descarga del archivo." -ForegroundColor Red
                    Read-Host "   Presiona ENTER para continuar..."
                }
            }
        }
    } else {
        Write-Host "   ✅ Versión al día (v5.9)." -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️ No se pudo conectar con el servidor de actualizaciones." -ForegroundColor Yellow
}

# ============================================================
# 🛡️ [AUTO-EXCLUSIÓN] - SEGURIDAD DEFENDER
# ============================================================
Write-Host " 🔍 [2/3] OPTIMIZANDO PROTECCIÓN DEFENDER..." -ForegroundColor Gray
$exePath = $MyInvocation.MyCommand.Path
$exeName = [System.IO.Path]::GetFileName($exePath)
$exeFolder = Split-Path $exePath -Parent

$currentExclusions = Get-MpPreference -ErrorAction SilentlyContinue
$isPathExcluded = $currentExclusions.ExclusionPath -contains $exeFolder
$isProcessExcluded = $currentExclusions.ExclusionProcess -contains $exeName

if (-not ($isPathExcluded -and $isProcessExcluded)) {
    try {
        Add-MpPreference -ExclusionPath $exeFolder -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess $exeName -ErrorAction SilentlyContinue
        Write-Host "   ✅ TechFlow añadido a exclusiones de seguridad." -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ Ejecuta como Admin para habilitar auto-exclusión." -ForegroundColor Yellow
    }
} else {
    Write-Host "   🛡️ El script ya cuenta con protección total." -ForegroundColor Green
}

# ============================================================
# 🧹 LIMPIEZA DE RESIDUOS
# ============================================================
Write-Host " 🔍 [3/3] LIMPIANDO TEMPORALES DE INICIO..." -ForegroundColor Gray
$basura1 = "$carpetaDelScript\TechFlow_NUEVO.exe"
$basura2 = "$carpetaDelScript\actualizar.bat"
if (Test-Path $basura1) { Remove-Item $basura1 -Force -ErrorAction SilentlyContinue }
if (Test-Path $basura2) { Remove-Item $basura2 -Force -ErrorAction SilentlyContinue }
Get-ChildItem -Path $carpetaDelScript -Include "TechFlow_Backup*.exe","TechFlow_Nueva*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "   ✨ Entorno de ejecución limpio." -ForegroundColor Green
Start-Sleep -Seconds 0


# ============================================================
# ⚙️ CONFIGURACIÓN INICIAL Y LOGS
# ============================================================
$LOG_FILE = Join-Path $PSScriptRoot ("techflowlog_" + (Get-Date).ToString("yyyyMMdd") + ".log")
$PREFS_FILE = Join-Path $PSScriptRoot "suite_prefs.json"
$CONFIG_FILE = "$PSScriptRoot\suite_config.dat"
$COLOR_PRIMARY = "Green"; $COLOR_ALERT = "Yellow"; $COLOR_DANGER = "Red"; $COLOR_MENU = "Cyan"; $COLOR_PROCESO = "Cyan"; $COLOR_WARNING = "Yellow"
$Global:MenuHorizontal = $true

function Rotate-Log {
    param([string]$LogPath = $LOG_FILE)
    if (-not $LogPath) { return }
    try {
        if (Test-Path $LogPath) {
            $fileInfo = Get-Item $LogPath -ErrorAction SilentlyContinue
            if ($fileInfo.Length -gt 10MB) {
                $oldLog = $LogPath -replace '\.log$', '_old.log'
                if (Test-Path $oldLog) { Remove-Item $oldLog -Force -ErrorAction SilentlyContinue }
                Move-Item $LogPath $oldLog -Force -ErrorAction Stop
                Write-Log "INFO" "Log rotado por tamaño excesivo (>10MB)."
            }
        }
    } catch {}
}

Rotate-Log

# ============================================================
# 📂 DEFINICIÓN DE ESTRUCTURA
# ============================================================
$USER_FOLDER_NAMES = @("Desktop", "Documents", "Pictures", "Videos", "Music", "Downloads", "Favorites", "Contacts")
$USER_FOLDERS = $USER_FOLDER_NAMES
$DEFAULT_BACKOP_BASE = "$env:SystemDrive\BACKOPs"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message,
        [switch]$NoConsole
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "$ts [$Level] $Message"
    Add-Content -Path $LOG_FILE -Value $logEntry -Encoding utf8 -ErrorAction SilentlyContinue
    
    if (-not $NoConsole) {
        $color = switch ($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } "SUCCESS" { "Green" } default { "Gray" } }
        $ico = switch ($Level) { "ERROR" { "❌" } "WARN" { "⚠️" } "SUCCESS" { "✅" } default { "ℹ️" } }
        Write-Host "   $ico $logEntry" -ForegroundColor $color
    }
}

function Get-LogStats {
    if (Test-Path $LOG_FILE) {
        $lines = Get-Content $LOG_FILE -ErrorAction SilentlyContinue
        $errorCount = ($lines | Select-String "\[ERROR\]").Count
        $warnCount = ($lines | Select-String "\[WARN\]").Count
        $size = (Get-Item $LOG_FILE).Length
        Write-Host "`n 📊 ESTADÍSTICAS DEL SISTEMA (LOGS):" -ForegroundColor Cyan
        Write-Host "   📄 Archivo: $LOG_FILE"
        Write-Host "   📦 Tamaño: $([math]::Round($size/1KB,2)) KB"
        Write-Host "   📝 Líneas totales: $($lines.Count)"
        Write-Host "   🔴 Errores: $errorCount"
        Write-Host "   🟡 Advertencias: $warnCount"
    }
}

function Clear-PendingDeletes {
    $pendingDir = "$env:TEMP\_pending_delete_"
    if (Test-Path $pendingDir) {
        Write-Host " 🧹 ELIMINANDO ARCHIVOS PENDIENTES..." -ForegroundColor Gray
        Start-Process -NoNewWindow -Wait cmd -ArgumentList "/c rmdir /s /q `"$pendingDir`"" -WindowStyle Hidden
    }
}
Clear-PendingDeletes

# ============================================================
# 🖥️ BANNER PRINCIPAL
# ============================================================
$Banner = @"
 ╔═══════════════════════════════════════════════════════════════════════════════╗
 ║                                                                               ║
 ║    ████████╗███████╗ ██████╗██╗  ██╗    ███████╗██╗      ██████╗ ██╗    ██╗   ║
 ║    ╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██║     ██╔═══██╗██║    ██║   ║
 ║       ██║   █████╗  ██║     ███████║    █████╗  ██║     ██║   ██║██║ █╗ ██║   ║
 ║       ██║   ██╔══╝  ██║     ██╔══██║    ██╔══╝  ██║     ██║   ██║██║███╗██║   ║
 ║       ██║   ███████╗╚██████╗██║  ██║    ██║     ███████╗╚██████╔╝╚███╔███╔╝   ║
 ║       ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝    ║
 ║                                                                               ║
 ║                                PRO EDITION v5.9                               ║
 ║                                                                               ║
 ║                    SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                ║
 ║                                                                               ║
 ╚═══════════════════════════════════════════════════════════════════════════════╝
"@
Write-Host $Banner -ForegroundColor Cyan

# ============================================================
# 🧹 LIMPIEZA AUTOMÁTICA DE BASURA DE ACTUALIZACIONES
# ============================================================
function Start-CleanupScheduler {
    # Programar limpieza de archivos temporales viejos al cerrar el script
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        $tempPatterns = @(
            "$env:TEMP\TechFlow_*.exe",
            "$env:TEMP\update_script*.ps1",
            "$env:TEMP\*TechFlow*.tmp"
        )
        foreach ($pattern in $tempPatterns) {
            Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | 
                Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-1) } |
                ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }
        }
        
        # Limpiar carpetas _pending_delete_ viejas
        $pendingDir = "$env:TEMP\_pending_delete_"
        if (Test-Path $pendingDir) {
            Remove-Item $pendingDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } | Out-Null
}

# Ejecutar el limpiador automático
Start-CleanupScheduler

# ============================================================
# 🔄 AUTO-ACTUALIZACIÓN - SIMPLE Y DIRECTA
# ============================================================
$currentVersion = "5.9"
$repoOwner = "LUISFGARCIAE"
$repoName = "TechFlow_Suite_Pro"

Write-Host "`n 🔍 [🔄] Verificando actualizaciones..." -ForegroundColor DarkGray

# Obtener la carpeta DONDE ESTÁ EL SCRIPT
$scriptPath = $MyInvocation.MyCommand.Path
if (-not $scriptPath) {
    $scriptPath = $PSCommandPath
}
if (-not $scriptPath) {
    $scriptPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
}

$carpetaDelScript = Split-Path $scriptPath -Parent
$nombreDelExe = [System.IO.Path]::GetFileName($scriptPath)
$exeActual = "$carpetaDelScript\$nombreDelExe"

Write-Host "   📂 [DEBUG] Carpeta: $carpetaDelScript" -ForegroundColor DarkGray
Write-Host "   🎯 [DEBUG] EXE actual: $exeActual" -ForegroundColor DarkGray

try {
    $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
    $latestRelease = Invoke-RestMethod -Uri $apiUrl -ErrorAction SilentlyContinue
    $latestVersion = $latestRelease.tag_name -replace 'v', ''
    
    if ($latestVersion -and ($latestVersion -ne $currentVersion)) {
        Write-Host " ════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "   🚀 [!] ¡NUEVA VERSIÓN DISPONIBLE!" -ForegroundColor Yellow
        Write-Host "   📦 Actual: v$currentVersion -> Nueva: v$latestVersion" -ForegroundColor Cyan
        Write-Host " ════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        
        $update = Read-Host "`n   ❓ ¿Deseas actualizar ahora? (S/N)"
        
        if ($update -eq "S") {
            $asset = $latestRelease.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
            
            if (-not $asset) {
                Write-Host "   ❌ [ERROR] No se encontró archivo .exe" -ForegroundColor Red
                Read-Host "   Presiona ENTER"
            } else {
                Write-Host "   ⏳ [+] Descargando nueva versión..." -ForegroundColor Yellow
                
                # La nueva versión se guarda en la MISMA CARPETA
                $nuevaVersion = "$carpetaDelScript\TechFlow_NUEVO.exe"
                
                # Descargar
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $nuevaVersion -UseBasicParsing
                
                if (Test-Path $nuevaVersion) {
                    Write-Host "   ✅ [✔] Descarga completada en: $carpetaDelScript" -ForegroundColor Green
                    
                    # Crear un script BAT simple en la misma carpeta
                    $batFile = "$carpetaDelScript\actualizar.bat"
                    $batContent = @"
@echo off
cd /d "$carpetaDelScript"
echo Actualizando...
timeout /t 2 /nobreak > nul
taskkill /f /im "$nombreDelExe" > nul 2>&1
timeout /t 2 /nobreak > nul
del /f /q "$nombreDelExe" > nul 2>&1
timeout /t 1 /nobreak > nul
copy /y "TechFlow_NUEVO.exe" "$nombreDelExe" > nul
timeout /t 1 /nobreak > nul
start "" "$nombreDelExe"
del /f /q "TechFlow_NUEVO.exe" > nul 2>&1
del /f /q "%~f0" > nul 2>&1
exit
"@
                    
                    # Guardar el BAT
                    $batContent | Out-File -FilePath $batFile -Encoding ascii -Force
                    
                    Write-Host "`n   🔄 [+] Aplicando actualización..." -ForegroundColor Yellow
                    Write-Host "   💡 La ventana se cerrará sola en 3 segundos..." -ForegroundColor Gray
                    
                    # Ejecutar el BAT
                    Start-Process -FilePath $batFile -WindowStyle Hidden
                    
                    # Cerrar esta ventana
                    Start-Sleep -Seconds 3
                    exit
                    
                } else {
                    Write-Host "   ❌ [ERROR] No se pudo descargar la nueva versión" -ForegroundColor Red
                    Read-Host "   Presiona ENTER"
                }
            }
        }
    } else {
        Write-Host "   ✅ [✔] Versión actualizada (v$currentVersion)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "   ⚠️ [!] No se pudo verificar actualizaciones" -ForegroundColor DarkGray
}

# ============================================================
# 🛡️ [AUTO-EXCLUSIÓN] - Silenciosa para Defender
# ============================================================
$exePath = $MyInvocation.MyCommand.Path
$exeName = [System.IO.Path]::GetFileName($exePath)
$exeFolder = Split-Path $exePath -Parent

# Verificar si ya está excluido
$currentExclusions = Get-MpPreference -ErrorAction SilentlyContinue
$isPathExcluded = $currentExclusions.ExclusionPath -contains $exeFolder
$isProcessExcluded = $currentExclusions.ExclusionProcess -contains $exeName

# Solo intentar si falta alguna exclusión
if (-not ($isPathExcluded -and $isProcessExcluded)) {
    Write-Host "`n   🔧 [🔧] Configurando exclusión en Defender..." -ForegroundColor DarkGray
    try {
        Add-MpPreference -ExclusionPath $exeFolder -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionProcess $exeName -ErrorAction SilentlyContinue
        Write-Host "   ✅ [✅] TechFlow protegido - Defender no lo molestará" -ForegroundColor DarkGray
    } catch {
        Write-Host "   ⚠️ [⚠️] No se pudo auto-excluir (ejecuta como Admin para protección total)" -ForegroundColor DarkGray
    }
}

Write-Host "`n   🚀 [+] Cargando menú principal..." -ForegroundColor Green

# ============================================================
# 🧹 LIMPIEZA - Borrar cualquier archivo temporal que haya quedado
# ============================================================
$basura1 = "$carpetaDelScript\TechFlow_NUEVO.exe"
$basura2 = "$carpetaDelScript\actualizar.bat"
$basura3 = "$carpetaDelScript\TechFlow_Backup*.exe"
$basura4 = "$carpetaDelScript\TechFlow_Nueva*.exe"

if (Test-Path $basura1) { Remove-Item $basura1 -Force -ErrorAction SilentlyContinue }
if (Test-Path $basura2) { Remove-Item $basura2 -Force -ErrorAction SilentlyContinue }
Get-ChildItem -Path $carpetaDelScript -Include "TechFlow_Backup*.exe","TechFlow_Nueva*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "`n   🚀 [+] Cargando menú principal..." -ForegroundColor Green

# ============================================================
# ⚙️ LECTURA DE CONFIGURACION PERSISTENTE
# ============================================================
function Get-Prefs {
    if(Test-Path $PREFS_FILE){
        try { 
            $prefs = Get-Content $PREFS_FILE -Raw | ConvertFrom-Json
            # Asegurar que la propiedad lastKitOption exista
            if (-not ($prefs.PSObject.Properties['lastKitOption'])) {
                $prefs | Add-Member -NotePropertyName 'lastKitOption' -NotePropertyValue $null
            }
            return $prefs
        } catch { 
            return [pscustomobject]@{ lastKitOption = $null }
        }
    }
    # Si no existe el archivo, devolvemos un objeto con la propiedad
    return [pscustomobject]@{ lastKitOption = $null }
}

# ============================================================
# 💾 GUARDADO DE CONFIGURACION PERSISTENTE
# ============================================================
function Save-Prefs($prefs){
    try {
        ($prefs | ConvertTo-Json -Depth 5) | Out-File -FilePath $PREFS_FILE -Encoding utf8 -Force
        Write-Log "INFO" "Prefs saved to $PREFS_FILE"
    } catch {
        Write-Log "WARN" ("Prefs save failed: " + $_.Exception.Message)
    }
}

# ============================================================
# ⏸️ PAUSA ESTANDAR CON MENSAJE
# ============================================================
function Pause-Enter {
    param([string]$Message = "   ⌨️ PRESIONE ENTER PARA VOLVER")
    Read-Host $Message | Out-Null
}

# ============================================================
# ⌨️ LECTOR DE OPCIONES DE MENU ROBUSTO
# ============================================================
function Read-MenuOption {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string[]]$Valid = @(),
        [switch]$AllowEmpty
    )
    while ($true) {
        # Verificar Ctrl+C - sale del script completamente
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.ControlKeyChar -eq 3) {
                Write-Host "`n`n   🛑 [!] Ctrl+C detectado. Saliendo..." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                exit
            }
        }
        
        $raw = Read-Host $Prompt
        if (-not $raw -or -not $raw.Trim()) {
            if ($AllowEmpty) { return "" }
            Write-Host "   ⚠️ Entrada requerida" -ForegroundColor Yellow
            continue
        }
        $opt = $raw.Trim().ToUpper()
        if ($Valid.Count -eq 0 -or $Valid -contains $opt) { return $opt }
        Write-Host "`n   ❌ [!] OPCIÓN NO VÁLIDA: $opt" -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 1
    }
}

# ============================================================
# 🛡️ DETECTOR DE PERMISOS ADMINISTRADOR (VERIFICA TOKEN DE SEGURIDAD)
# ============================================================
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

# ============================================================
# 👤 IDENTIFICADOR DE USUARIO ADMIN LOCALIZADO (DETECTA ESPAÑOL/INGLES)
# ============================================================
function Get-AdminUsername {
    $locale = (Get-WinSystemLocale).Name
    if ($locale -like "*es*") {
        return "administrador"
    } else {
        return "administrator"
    }
}

# ============================================================
# 🔑 VALIDADOR Y SOLICITADOR DE ADMIN (VERIFICA Y ADVIERTE SI NO ES ADMIN)
# ============================================================
function Require-Admin {
    param([string]$ActionName = "esta operación")
    if (-not (Test-IsAdmin)) {
        Write-Host "`n   🛑 [!] Requiere permisos de ADMIN para $ActionName." -ForegroundColor $COLOR_DANGER
        Write-Host "      Cierra y ejecuta PowerShell como Administrador." -ForegroundColor $COLOR_ALERT
        Write-Log "WARN" "Admin required for: $ActionName"
        Pause-Enter "   ⌨️ ENTER"
        return $false
    }
    return $true
}

# ============================================================
# 🌐 DETECTOR DE CONEXION A INTERNET (PING A 1.1.1.1)
# ============================================================
function Test-HasInternet {
    try {
        return Test-Connection -ComputerName "1.1.1.1" -Count 1 -Quiet -ErrorAction SilentlyContinue
    } catch {
        return $false
    }
}

# ============================================================
# ⚠️ CONFIRMACION DE OPERACIONES CRITICAS (PIN + KEYWORD)
# ============================================================
function Confirm-Critical {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Keyword
    )
    Show-MainTitle
    Write-Host "`n   🔥 OPERACIÓN CRÍTICA: $Title" -ForegroundColor $COLOR_DANGER
    $pin = Get-Random -Min 1000 -Max 9999
    Write-Host "`n   🔐 PIN DE SEGURIDAD $pin" -BackgroundColor Red -ForegroundColor White
    $p = Read-Host "   ⌨️ INGRESE PIN PARA CONFIRMAR"
    if ($p -ne $pin.ToString()) {
        Write-Host "`n   ❌ [!] PIN INCORRECTO." -ForegroundColor $COLOR_DANGER
        Write-Log "WARN" "Critical confirm failed (PIN): $Title"
        Start-Sleep -Seconds 1
        return $false
    }
    $k = (Read-Host "   ⌨️ ESCRIBA '$Keyword' PARA CONTINUAR").Trim().ToUpper()
    if ($k -ne $Keyword.Trim().ToUpper()) {
        Write-Host "`n   ❌ [!] PALABRA DE CONFIRMACIÓN INCORRECTA." -ForegroundColor $COLOR_DANGER
        Write-Log "WARN" "Critical confirm failed (keyword): $Title"
        Start-Sleep -Seconds 1
        return $false
    }
    Write-Log "INFO" "Critical confirmed: $Title"
    return $true
}

# ============================================================
# ☁️ CONFIRMACION DE SCRIPTS REMOTOS (URL + INTERNET)
# ============================================================
function Confirm-RemoteScript {
    param([Parameter(Mandatory = $true)][string]$Url)
    Show-MainTitle
    Write-Host "`n   📡 [!] SE EJECUTARÁ UN SCRIPT REMOTO:" -ForegroundColor $COLOR_ALERT
    Write-Host "      $Url" -ForegroundColor $COLOR_MENU
    Write-Host "      Esto puede modificar el sistema." -ForegroundColor $COLOR_ALERT
    $ok = Read-MenuOption "   ❓ CONTINUAR? (S/N)" -Valid @("S","N")
    if ($ok -ne "S") {
        Write-Log "INFO" "Remote script canceled: $Url"
        return $false
    }
    if (-not (Test-HasInternet)) {
        Write-Host "`n   🚫 [!] Sin conexión a Internet." -ForegroundColor $COLOR_DANGER
        Write-Log "WARN" "Remote script blocked (no internet): $Url"
        Pause-Enter "   ⌨️ ENTER"
        return $false
    }
    Write-Log "INFO" "Remote script confirmed: $Url"
    return $true
}

# ============================================================
# 📏 FORMATEO DE BYTES A UNIDADES LEGIBLES (B/KB/MB/GB/TB)
# ============================================================
function Format-Bytes([Int64]$Bytes) {
    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    if ($Bytes -lt 1GB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -lt 1TB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    return "{0:N2} TB" -f ($Bytes / 1TB)
}

# ============================================================
# 📁 ESCANER DE UNIDADES INTELIGENTE (BACKOP/RESTORE)
# ============================================================

function Scan-DriveUnits {
    $units = @()
    $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -in 2,3 } | Sort-Object DeviceID
    
    $i = 1
    foreach ($disk in $disks) {
        $driveType = switch ($disk.DriveType) {
            2 { "USB/Extraíble" }
            3 { "Disco Fijo" }
            default { "Desconocido" }
        }
        
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        $percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
        $label = if ($disk.VolumeName) { $disk.VolumeName } else { "Sin etiqueta" }
        
        $units += [PSCustomObject]@{
            Index = $i
            DeviceID = $disk.DeviceID
            Label = $label
            Type = $driveType
            TotalGB = $totalGB
            UsedGB = $usedGB
            FreeGB = $freeGB
            PercentFree = $percentFree
            Path = $disk.DeviceID + "\"
        }
        $i++
    }
    return $units
}

function Show-DriveSelector {
    param(
        [string]$Title = "SELECCIÓN DE UNIDAD",
        [string]$Action = "seleccionar"
    )
    
    $units = Scan-DriveUnits
    if ($units.Count -eq 0) {
        Write-Host "`n ❌ No se detectaron unidades disponibles." -ForegroundColor $COLOR_DANGER
        return $null
    }
    
    Clear-Host
    Show-MainTitle
    
    Write-Host "`n 📂 $Title" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host "   #   UNIDAD   ETIQUETA         TIPO        TOTAL    LIBRE    USADO"
    Write-Host " ───────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    foreach ($unit in $units) {
        $freeColor = if ($unit.PercentFree -lt 10) { $COLOR_DANGER } 
                     elseif ($unit.PercentFree -lt 25) { $COLOR_ALERT } 
                     else { $COLOR_PRIMARY }
        
        $labelDisplay = $unit.Label.PadRight(15)
        if ($labelDisplay.Length -gt 15) { $labelDisplay = $labelDisplay.Substring(0,12) + "..." }
        
        Write-Host ("   [{0}]  {1}    {2}  {3,-12}  {4,8}GB  {5,8}GB  {6,7}GB" -f 
            $unit.Index.ToString().PadRight(2),
            $unit.DeviceID.PadRight(2),
            $labelDisplay,
            $unit.Type,
            $unit.TotalGB,
            $unit.FreeGB,
            $unit.UsedGB
        ) -ForegroundColor $COLOR_MENU
        
        $barLength = 30
        $filled = [math]::Round($barLength * ($unit.FreeGB / $unit.TotalGB))
        $bar = "█" * $filled + "░" * ($barLength - $filled)
        Write-Host ("      Libre: [{0}] {1}%" -f $bar, $unit.PercentFree) -ForegroundColor $freeColor
        Write-Host ""
    }
    
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host " [X] CANCELAR" -ForegroundColor $COLOR_DANGER
    
    $sel = Read-Host "`n > SELECCIONE UNA UNIDAD (NÚMERO)"
    if ($sel -eq "X" -or $sel -eq "x") { return $null }
    
    if ($sel -match "^\d+$" -and [int]$sel -ge 1 -and [int]$sel -le $units.Count) {
        return $units[[int]$sel - 1]
    } else {
        Write-Host "`n ❌ Selección inválida." -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 1.5
        return Show-DriveSelector -Title $Title
    }
}

function Find-BACKOPsInUnit {
    param(
        [Parameter(Mandatory=$true)][string]$UnitPath
    )
    
    $BACKOPs = @()
    Write-Host "   🔍 Escaneando $UnitPath (búsqueda recursiva)..." -ForegroundColor DarkGray
    
    # Asegurar que la ruta termina con \
    $searchPath = if ($UnitPath.EndsWith("\")) { $UnitPath } else { $UnitPath + "\" }
    
    try {
        $found = Get-ChildItem -Path $searchPath -Directory -Recurse -ErrorAction Stop | 
                 Where-Object { $_.Name -match "BACKOP" }
        
        if ($found) {
            foreach ($item in $found) {
                $sizeGB = [math]::Round((Get-FolderSizeBytes $item.FullName) / 1GB, 2)
                $BACKOPs += [PSCustomObject]@{
                    FullName = $item.FullName
                    Name = $item.Name
                    CreationTime = $item.CreationTime
                    SizeGB = $sizeGB
                }
            }
			
            $BACKOPs = $BACKOPs | Sort-Object CreationTime -Descending
          
        }
    } catch {
        # Si hay error de permisos, mostrar advertencia
        Write-Host "      ⚠️ Error de permisos en $searchPath" -ForegroundColor Yellow
    }
    
    return $BACKOPs
}

function Show-BACKOPSelector {
    param(
        [string]$UnitPath
    )
    
    $BACKOPs = Find-BACKOPsInUnit -UnitPath $UnitPath
    
    if ($BACKOPs.Count -eq 0) {
        Write-Host "`n ❌ No se encontraron BACKOPs en esta unidad." -ForegroundColor $COLOR_DANGER
        return $null
    }
    
    Clear-Host
    Show-MainTitle
    
    Write-Host "`n 📋 BACKOPS ENCONTRADOS:" -ForegroundColor $COLOR_PRIMARY
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    
    for ($i = 0; $i -lt $BACKOPs.Count; $i++) {
        Write-Host "   [$($i+1)] $($BACKOPs[$i].Name)" -ForegroundColor $COLOR_MENU
        Write-Host "          📅 Creado: $($BACKOPs[$i].CreationTime)" -ForegroundColor DarkGray
        Write-Host "          💾 Tamaño: $($BACKOPs[$i].SizeGB) GB" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host " [X] CANCELAR" -ForegroundColor $COLOR_DANGER
    
    $sel = Read-Host "`n > SELECCIONE BACKOP (NÚMERO)"
    if ($sel -eq "X" -or $sel -eq "x") { return $null }
    
    if ($sel -match "^\d+$" -and [int]$sel -le $BACKOPs.Count) {
        return $BACKOPs[[int]$sel-1].FullName
    } else {
        Write-Host "`n ❌ Selección inválida." -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 1.5
        return Show-BACKOPSelector -UnitPath $UnitPath
    }
}

# ============================================================
# 📁 CALCULO DE TAMAÑO TOTAL DE CARPETA (RECURSIVO)
# ============================================================
function Get-FolderSizeBytes {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        $sum = 0L
        Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue -File |
            ForEach-Object { $sum += $_.Length }
        return $sum
    } catch {
        return 0L
    }
}

# ============================================================
# 💾 OBTENER ESPACIO LIBRE DISPONIBLE EN UNA UNIDAD
# ============================================================
function Get-DriveFreeBytes {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        $root = [System.IO.Path]::GetPathRoot($Path)
        $name = $root.TrimEnd('\')
        $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + $name + "'") -ErrorAction SilentlyContinue
        if ($d) { return [Int64]$d.FreeSpace }
        return 0L
    } catch { return 0L }
}

# ============================================================
# 🚀 OBTENER NÚMERO ÓPTIMO DE HILOS PARA ROBOCOPY SEGÚN TIPO DE UNIDAD
# ============================================================
function Get-OptimalRobocopyThreads {
    param([string]$Path)
    try {
        $root = [System.IO.Path]::GetPathRoot($Path)
        $name = $root.TrimEnd('\')
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$name'" -ErrorAction SilentlyContinue
        if ($disk) {
            # SSD: usar más hilos (16-32), HDD: menos hilos (4-8) para evitar latencia
            if ($disk.MediaType -like "*SSD*" -or $disk.VolumeName -like "*SSD*") {
                return 16
            } else {
                return 8
            }
        }
    } catch {}
    return 8  # Valor por defecto seguro
}

# ============================================================
# 🔍 VALIDACIÓN DE RUTA DE RESPALDO (EVITAR CARPETAS DE SISTEMA)
# ============================================================
function Is-SuspiciousBACKOPBase {
    param([Parameter(Mandatory = $true)][string]$Base)
    $b = $Base.Trim().ToLower()
    return ($b -like "*\\windows*" -or $b -like "*\\system32*" -or $b -like "*\\program files*")
}

# ============================================================
# 🔌 DETECCIÓN DE UNIDADES EXTRAÍBLES CONECTADAS (USB/DISCOS)
# ============================================================
function Select-RemovableVolumes {
    try {
        return Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 2 }
    } catch {
        return @()
    }
}

# ============================================================
# 📡 DESCARGA DE SCRIPTS EXTERNOS A CARPETA TEMPORAL
# ============================================================
function Download-RemoteScript {
    param([Parameter(Mandatory = $true)][string]$Url)
    $dest = Join-Path $env:TEMP ("techflow_remote_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".ps1")
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $dest
    return $dest
}

# ============================================================
# 🔐 GENERACIÓN DE HASH SHA256 PARA VERIFICACIÓN DE ARCHIVOS
# ============================================================
function Get-FileHashSafe {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    } catch {
        return $null
    }
}

# ============================================================
# 👥 OBTENER RUTAS DE PERFILES DE USUARIO ACTIVOS EN EL DISCO
# ============================================================
function Get-UserProfilePaths {
    $profilesPath = "$env:SystemDrive\Users"
    Get-ChildItem -Path $profilesPath -Directory | Where-Object {
        $_.Name -notin @('All Users', 'Default', 'Default User', 'Public', 'desktop.ini', 'DefaultAppPool')
    } | Select-Object -ExpandProperty FullName
}

# ============================================================
# 📁 GENERAR Y CREAR NUEVA CARPETA DE RESPALDO NUMERADA (BACKOP_01...)
# ============================================================
function Get-BACKOPRoot($basePath) {
    $existing = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "BACKOP_*" } | ForEach-Object { $_.Name -replace "BACKOP_", "" } | Where-Object { $_ -match "^\d+$" } | Sort-Object {[int]$_} -Descending
    if ($existing) { $next = [int]$existing[0] + 1 } else { $next = 1 }
    $root = Join-Path $basePath ("BACKOP_" + $next.ToString("00"))
    if (!(Test-Path $root)) { New-Item -Path $root -ItemType Directory -Force | Out-Null }
    return $root
}

# ============================================================
# 💾 EJECUCIÓN DE COPIA DE SEGURIDAD DE PERFIL (CON TABLA DE PROGRESO)
# ============================================================
function BACKOP-ProfileData($profilePath, $BACKOPRoot) {
    $userName = Split-Path $profilePath -Leaf
    $destRoot = Join-Path $BACKOPRoot $userName
    
    # 📁 Crear directorio destino si no existe
    if (-not (Test-Path $destRoot)) {
        New-Item -Path $destRoot -ItemType Directory -Force | Out-Null
    }
    
    # 🔍 Recopilar carpetas válidas
    $validFolders = @()
    foreach ($folder in $USER_FOLDER_NAMES) {
        $source = Join-Path $profilePath $folder
        if (Test-Path $source) {
            $validFolders += $folder
        }
    }
    
    $total = $validFolders.Count
    $completed = 0
    $totalSize = 0
    $copiedSize = 0
    
    # 📏 Calcular tamaño total aproximado
    Write-Host "`n 📁 ANALIZANDO CARPETAS DE $userName ..." -ForegroundColor $COLOR_ALERT
    foreach ($folder in $validFolders) {
        $source = Join-Path $profilePath $folder
        $size = Get-FolderSizeBytes $source
        $totalSize += $size
        Write-Host "    • 📂 $folder : $(Format-Bytes $size)" -ForegroundColor Gray
    }
    
    Write-Host "`n 📊 TOTAL A RESPALDAR: $(Format-Bytes $totalSize)" -ForegroundColor Cyan
    Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    foreach ($folder in $validFolders) {
        $source = Join-Path $profilePath $folder
        $target = Join-Path $destRoot $folder
        
        $folderSize = Get-FolderSizeBytes $source
        $percentTotal = if ($totalSize -gt 0) { [math]::Round(($copiedSize / $totalSize) * 100) } else { 0 }
        $percentFolder = 0
        
        Write-Host ""
        Write-Host " ┌─────────────────────────────────────────────────────────" -ForegroundColor Cyan
        Write-Host " │ 📤 RESPALDANDO: $userName\$folder" -ForegroundColor Yellow
        Write-Host " │ 📏 TAMAÑO: $(Format-Bytes $folderSize)" -ForegroundColor Gray
        Write-Host " │ 📍 ORIGEN: $source" -ForegroundColor DarkGray
        Write-Host " │ 🎯 DESTINO: $target" -ForegroundColor DarkGray
        Write-Host " │" -ForegroundColor Cyan
        
        # 🧮 Obtener número óptimo de hilos según tipo de unidad
        $optimalThreads = Get-OptimalRobocopyThreads $target
        Write-Host " │ ⚙️ HILOS ROBOCOPY: $optimalThreads" -ForegroundColor DarkGray
        
        # 🚀 Ejecutar robocopy con parámetros optimizados
        $robocopyOutput = robocopy $source $target /E /MT:$optimalThreads /R:3 /W:5 /XJ /NP /NFL /NDL /NJH /NJS /NC /NS /XF "pagefile.sys" "hiberfil.sys" "swapfile.sys" 2>&1
        
        # 📈 Actualizar contadores
        $completed++
        $copiedSize += $folderSize
        
        $percentTotal = if ($totalSize -gt 0) { [math]::Round(($copiedSize / $totalSize) * 100) } else { 0 }
        
        # 🟢 Mostrar barra de progreso GENERAL
        $barLength = 40
        $filled = [math]::Round($barLength * $percentTotal / 100)
        $bar = "█" * $filled + "░" * ($barLength - $filled)
        
        Write-Host " │" -ForegroundColor Cyan
        Write-Host " │ 📊 PROGRESO GENERAL: [$bar] $percentTotal%" -ForegroundColor Green
        Write-Host " │ ✅ COMPLETADAS: $completed de $total carpetas" -ForegroundColor Green
        Write-Host " │ 💾 COPIADO: $(Format-Bytes $copiedSize) de $(Format-Bytes $totalSize)" -ForegroundColor Green
        Write-Host " └─────────────────────────────────────────────────────────" -ForegroundColor Cyan
    }
    
    Write-Host "`n ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " ✅ RESPALDO COMPLETADO: $userName" -ForegroundColor Green
    Write-Host "    📂 UBICACIÓN: $destRoot" -ForegroundColor Gray
    Write-Host "    📊 TOTAL: $(Format-Bytes $totalSize) en $total carpetas" -ForegroundColor Gray
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
}

function Restore-ProfileData($BACKOPProfilePath, $TargetUsersRoot = $null) {
    $profileName = Split-Path $BACKOPProfilePath -Leaf
    if(-not $TargetUsersRoot){ $TargetUsersRoot = "$env:SystemDrive\Users" }
    $targetRoot = Join-Path $TargetUsersRoot $profileName
    
    # 📁 Crear directorio destino si no existe
    if (!(Test-Path $targetRoot)) { 
        New-Item -Path $targetRoot -ItemType Directory -Force | Out-Null 
    }
    
    # 🔍 Recopilar carpetas a restaurar
    $foldersToRestore = Get-ChildItem -Path $BACKOPProfilePath -Directory -ErrorAction SilentlyContinue
    $total = $foldersToRestore.Count
    $completed = 0
    $totalSize = 0
    $restoredSize = 0
    
    # 📏 Calcular tamaño total a restaurar
    Write-Host "`n 📁 ANALIZANDO CARPETAS DE $profileName ..." -ForegroundColor $COLOR_ALERT
    foreach ($folder in $foldersToRestore) {
        $size = Get-FolderSizeBytes $folder.FullName
        $totalSize += $size
        Write-Host "    • 📂 $($folder.Name) : $(Format-Bytes $size)" -ForegroundColor Gray
    }
    
    Write-Host "`n 📊 TOTAL A RESTAURAR: $(Format-Bytes $totalSize)" -ForegroundColor Cyan
    Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    foreach ($folder in $foldersToRestore) {
        $source = $folder.FullName
        $dest = Join-Path $targetRoot $folder.Name
        
        $folderSize = Get-FolderSizeBytes $source
        $percentTotal = if ($totalSize -gt 0) { [math]::Round(($restoredSize / $totalSize) * 100) } else { 0 }
        
        Write-Host ""
        Write-Host " ┌─────────────────────────────────────────────────────────" -ForegroundColor Cyan
        Write-Host " │ 📥 RESTAURANDO: $profileName\$($folder.Name)" -ForegroundColor Yellow
        Write-Host " │ 📏 TAMAÑO: $(Format-Bytes $folderSize)" -ForegroundColor Gray
        Write-Host " │ 📍 ORIGEN: $source" -ForegroundColor DarkGray
        Write-Host " │ 🎯 DESTINO: $dest" -ForegroundColor DarkGray
        Write-Host " │" -ForegroundColor Cyan
        
        # 🚀 Ejecutar robocopy (parámetros optimizados)
        robocopy $source $dest /E /MT:8 /R:0 /W:0 /XJ /NP /NFL /NDL /NJH /NJS /NC /NS /XF "pagefile.sys" "hiberfil.sys" "swapfile.sys" | Out-Null
        
        # 📈 Actualizar contadores
        $completed++
        $restoredSize += $folderSize
        
        $percentTotal = if ($totalSize -gt 0) { [math]::Round(($restoredSize / $totalSize) * 100) } else { 0 }
        
        # 🔵 Mostrar barra de progreso GENERAL
        $barLength = 40
        $filled = [math]::Round($barLength * $percentTotal / 100)
        $bar = "█" * $filled + "░" * ($barLength - $filled)
        
        Write-Host " │" -ForegroundColor Cyan
        Write-Host " │ 📊 PROGRESO GENERAL: [$bar] $percentTotal%" -ForegroundColor Green
        Write-Host " │ ✅ COMPLETADAS: $completed de $total carpetas" -ForegroundColor Green
        Write-Host " │ 💾 RESTAURADO: $(Format-Bytes $restoredSize) de $(Format-Bytes $totalSize)" -ForegroundColor Green
        Write-Host " └─────────────────────────────────────────────────────────" -ForegroundColor Cyan
    }
    
    Write-Host "`n ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " ✅ RESTAURACIÓN COMPLETADA: $profileName" -ForegroundColor Green
    Write-Host "    📁 UBICACIÓN: $targetRoot" -ForegroundColor Gray
    Write-Host "    📊 TOTAL: $(Format-Bytes $totalSize) en $total carpetas" -ForegroundColor Gray
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
}

# ============================================================
# 🖥️ INTERFAZ: DIBUJAR TÍTULO Y LOGO PRINCIPAL DE LA SUITE
# ============================================================
function Show-MainTitle {
    # 🧹 Limpiar pantalla de forma FORZADA
    if ($Host.Name -eq "ConsoleHost") {
        Clear-Host
    } else {
        [System.Console]::Clear()
    }
    
    # 🔄 También forzar refresco de buffer
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0,0
    
    Write-Host @"
	
 ╔══════════════════════════════════════════════════════════════════════════════════╗
 ║                                                                                  ║
 ║    ████████╗███████╗ ██████╗██╗  ██╗    ███████╗██╗      ██████╗ ██╗    ██╗      ║
 ║    ╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██║     ██╔═══██╗██║    ██║      ║
 ║       ██║   █████╗  ██║     ███████║    █████╗  ██║     ██║   ██║██║ █╗ ██║      ║
 ║       ██║   ██╔══╝  ██║     ██╔══██║    ██╔══╝  ██║     ██║   ██║██║███╗██║      ║
 ║       ██║   ███████╗╚██████╗██║  ██║    ██║     ███████╗╚██████╔╝╚███╔███╔╝      ║
 ║       ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝       ║
 ║                                                                                  ║
 ║                                 PRO EDITION v5.9                                 ║
 ║                                                                                  ║
 ║                    SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                   ║
 ║                                                                                  ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # ⚡ Forzar que se muestre inmediatamente
    [System.Console]::Out.Flush()
}

function Pause-Enter {
    param($Msg = "")
    Write-Host "`n ⌨️ Presione ENTER para continuar $Msg..." -ForegroundColor $COLOR_ALERT
    $null = Read-Host
}
# ============================================================
# 🚀 MOTOR DE INSTALACIÓN HÍBRIDA INTELIGENTE (WINGET + CHOCO)
# ============================================================
function Invoke-SmartInstall ($AppID, $AppName) {
    Write-Host "`n [!] INSTALANDO: $AppName..." -ForegroundColor $COLOR_MENU
    
    # 🗺️ MAPEO MANUAL: ID de Winget -> Nombre corto en Chocolatey
    $chocoMapping = @{
        "Google.Chrome" = "googlechrome"; "Mozilla.Firefox" = "firefox"; "Opera.Opera" = "opera"
        "Discord.Discord" = "discord"; "Telegram.TelegramDesktop" = "telegram"; "Zoom.Zoom" = "zoom"
        "Microsoft.Teams" = "teams"; "SlackTechnologies.Slack" = "slack"; "WhatsApp.WhatsApp" = "whatsapp"
        "7zip.7zip" = "7zip"; "RARLab.WinRAR" = "winrar"; "Microsoft.PowerToys" = "powertoys"
        "voidtools.Everything" = "everything"; "BleachBit.BleachBit" = "bleachbit"; "RevoUninstaller.RevoUninstaller" = "revo"
        "Bitwarden.Bitwarden" = "bitwarden"; "Malwarebytes.Malwarebytes" = "malwarebytes"; "CPUID.CPU-Z" = "cpuz"
        "TechPowerUp.GPU-Z" = "gpuz"; "CPUID.HWMonitor" = "hwmonitor"; "REALiX.HWiNFO" = "hwinfo"
        "MSI.Afterburner" = "msiafterburner"; "Guru3D.Afterburner" = "msiafterburner"; "PeaZip.PeaZip" = "peazip"
        "Notepad++.Notepad++" = "notepadplusplus"; "Microsoft.VisualStudioCode" = "vscode"; "Git.Git" = "git"
        "GitHub.GitHubDesktop" = "github-desktop"; "Docker.DockerDesktop" = "docker-desktop"; "Kitware.CMake" = "cmake"
        "OpenJS.NodeJS" = "nodejs"; "Python.Python.3" = "python"; "PuTTY.PuTTY" = "putty"
        "WinSCP.WinSCP" = "winscp"; "FileZilla.Client" = "filezilla"; "GIMP.GIMP" = "gimp"
        "Inkscape.Inkscape" = "inkscape"; "KritaFoundation.Krita" = "krita"; "BlenderFoundation.Blender" = "blender"
        "dotPDN.PaintDotNet" = "paint.net"; "HandBrake.HandBrake" = "handbrake"; "VideoLAN.VLC" = "vlc"
        "OBSProject.OBSStudio" = "obs-studio"; "Audacity.Audacity" = "audacity"; "Calibre.Calibre" = "calibre"
        "CodecGuide.K-LiteCodecPack.Basic" = "klitecodec"; "Spotify.Spotify" = "spotify"; "TheDocumentFoundation.LibreOffice" = "libreoffice"
        "Microsoft.OfficeDeploymentTool" = "office365"; "Notion.Notion" = "notion"; "Obsidian.Obsidian" = "obsidian"
        "Zotero.Zotero" = "zotero"; "Adobe.Acrobat.Reader.64-bit" = "adobereader"; "Foxit.FoxitReader" = "foxitreader"
        "SumatraPDF.SumatraPDF" = "sumatrapdf"; "PDF24.PDF24" = "pdf24"; "Typora.Typora" = "typora"
        "WiresharkFoundation.Wireshark" = "wireshark"; "Nmap.Nmap" = "nmap"; "Famatech.AdvancedIPScanner" = "advanced-ip-scanner"
        "Mobatek.MobaXterm" = "mobaxterm"; "Alacritty.Alacritty" = "alacritty"; "Microsoft.WindowsTerminal" = "windows-terminal"
        "AnyDesk.AnyDesk" = "anydesk"; "RustDesk.RustDesk" = "rustdesk"; "TeamViewer.TeamViewer" = "teamviewer"
        "Valve.Steam" = "steam"; "EpicGames.EpicGamesLauncher" = "epicgameslauncher"; "ElectronicArts.EADesktop" = "ea-app"
        "Ubisoft.Connect" = "ubisoft-connect"; "GOG.Galaxy" = "gog-galaxy"; "Parsec.Parsec" = "parsec"
        "Oracle.VirtualBox" = "virtualbox"; "VMware.WorkstationPlayer" = "vmware-player"; "RaspberryPiFoundation.RaspberryPiImager" = "raspberry-pi-imager"
        "Microsoft.WSL" = "wsl"; "Microsoft.PowerShell" = "powershell"; "Duplicati.Duplicati" = "duplicati"
        "Nextcloud.NextcloudDesktop" = "nextcloud"; "Google.Drive" = "googledrive"; "Dropbox.Dropbox" = "dropbox"
        "SyncThing.SyncThing" = "syncthing"; "Resilio.ResilioSync" = "resiliosync"; "Rclone.Rclone" = "rclone"
        "ProtonTechnologies.ProtonDrive" = "protondrive"; "ProtonTechnologies.ProtonVPN" = "protonvpn"; "Windscribe.Windscribe" = "windscribe"
        "OpenVPNTechnologies.OpenVPN" = "openvpn"; "OpenHardwareMonitor.OpenHardwareMonitor" = "openhardwaremonitor"; "CoreTemp.CoreTemp" = "coretemp"
        "CrystalDiskInfo.CrystalDiskInfo" = "crystaldiskinfo"; "CrystalDiskMark.CrystalDiskMark" = "crystaldiskmark"; "Simplenote.Simplenote" = "simplenote"
        "Joplin.Joplin" = "joplin"; "BulkRenameUtility.BulkRenameUtility" = "bulkrenameutility"; "AutoHotkey.AutoHotkey" = "autohotkey"
        "Espanso.Espanso" = "espanso"; "Gsudo.Gsudo" = "gsudo"; "Nushell.Nushell" = "nushell"
        "Fastfetch.Fastfetch" = "fastfetch"; "Monitorian.Monitorian" = "monitorian"; "qBittorrent.qBittorrent" = "qbittorrent"
        "Motrix.Motrix" = "motrix"; "LocalSend.LocalSend" = "localsend"; "KDE.KDEConnect" = "kdeconnect"
        "Schollz.croc" = "croc"; "TreeSize.TreeSize" = "treesize"; "WizTree.WizTree" = "wiztree"
        "DiskGenius.DiskGenius" = "diskgenius"; "Rainmeter.Rainmeter" = "rainmeter"; "f.lux.f.lux" = "flux"
        "Ditto.Ditto" = "ditto"; "CopyQ.CopyQ" = "copyq"; "Microsoft.PowerAutomateDesktop" = "power-automate-desktop"
    }
    
    # 🔍 Verificar disponibilidad de Winget
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue

    # 🛠️ VERIFICACIÓN Y REPARACIÓN DE WINGET
    if (-not $wingetAvailable) {
        Write-Host "    ⚠️ Winget no disponible. Intentando reparar..." -ForegroundColor Yellow
        Repair-Winget | Out-Null
        $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    }

    if ($wingetAvailable) {
        $wingetVersion = (winget --version 2>&1) -replace 'v', ''
        Write-Host "    🟢 Winget detectado: v$wingetVersion" -ForegroundColor Green
        
        # 🔄 Verificar si requiere actualización (mínimo v1.6.3133)
        $versionParts = $wingetVersion -split '\.'
        $major = [int]$versionParts[0]; $minor = [int]$versionParts[1]; $build = [int]$versionParts[2]
        
        if ($major -lt 1 -or ($major -eq 1 -and $minor -lt 6) -or ($major -eq 1 -and $minor -eq 6 -and $build -lt 3133)) {
            Write-Host "    ⚠️ Winget desactualizado. Actualizando core..." -ForegroundColor Yellow
            Repair-Winget | Out-Null
            $wingetVersionNew = (winget --version 2>&1) -replace 'v', ''
            Write-Host "    🟢 Winget actualizado a: v$wingetVersionNew" -ForegroundColor Green
        }
    } else {
        Write-Host "    🔴 Winget NO disponible. Se usarán métodos alternativos." -ForegroundColor Red
    }

    # 📦 Función interna para instalación silenciosa (WindowStyle Hidden)
    function Install-WithWinget {
        if (-not $wingetAvailable) { return $false }
        Write-Host "      → Ejecutando winget en segundo plano..." -ForegroundColor DarkGray
        
        $tempScript = "$env:TEMP\winget_install_$([System.Guid]::NewGuid().ToString().Substring(0,8)).ps1"
        $scriptContent = @"
`$output = winget install --id `"$AppID`" --exact --accept-package-agreements --accept-source-agreements --silent 2>&1
`$outputString = `$output -join " "
if (`$outputString -like "*No available upgrade found*" -or `$outputString -like "*already installed*") { exit 0 }
if (`$LASTEXITCODE -eq 0) { exit 0 } else { exit 1 }
"@
        $scriptContent | Out-File -FilePath $tempScript -Encoding utf8
        $process = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tempScript`"" -Verb RunAs -Wait -PassThru
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
        return ($process.ExitCode -eq 0)
    }

    # 1️⃣ Intento con Winget (Modo Usuario/Silent)
    Write-Host " [+] Intentando con winget..." -ForegroundColor $COLOR_PRIMARY
    if (Install-WithWinget) { 
        Write-Host " [✔] Instalado correctamente con Winget" -ForegroundColor Green
        return "OK" 
    }
    
    # 2️⃣ Intento con Chocolatey (Mapeo o Automático)
    $chocoName = if ($chocoMapping.ContainsKey($AppID)) { $chocoMapping[$AppID] } else { $AppID.Split('.')[-1].ToLower() }
    Write-Host " [+] Usando Chocolatey: $chocoName" -ForegroundColor $COLOR_ALERT
    
    choco install $chocoName -y --no-progress 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { 
        Write-Host " [✔] Instalado correctamente con Chocolatey" -ForegroundColor Green
        return "OK" 
    }
    
    # 3️⃣ Reintento final con Winget (Visible)
    Write-Host " [+] Reintentando winget (último recurso)..." -ForegroundColor $COLOR_ALERT
    Start-Sleep -Seconds 2
    winget install --id $AppID --exact --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { return "OK" }
    
    # ❌ Fallo y reporte
    $manualUrl = $manualUrls[$AppName]
    if ($manualUrl) {
        Write-Host " [✘] FALLO DEFINITIVO." -ForegroundColor Red
        Write-Host "     → Descarga manual: $manualUrl" -ForegroundColor Yellow
        Write-Log "INSTALL" "Failed: $AppName ($AppID) - Link: $manualUrl"
        return "MANUAL|$manualUrl"
    } else {
        Write-Host " [✘] FALLO DEFINITIVO. No se encontró instalador." -ForegroundColor Red
        Write-Log "INSTALL" "Failed: $AppName ($AppID) via all methods"
        return "ERROR"
    }
}

# ============================================================
# KIT POST FORMAT V5 (125 APPS CONFIABLES)
# ============================================================
function Invoke-KitPostFormat {
    # Diccionario de URLs oficiales para descarga manual
    $manualUrls = @{
        "Jitsi Meet" = "https://jitsi.org/downloads"
        "Stable Diffusion WebUI" = "https://github.com/AUTOMATIC1111/stable-diffusion-webui"
        "ComfyUI" = "https://github.com/comfyanonymous/ComfyUI"
        "Jellyfin Server" = "https://jellyfin.org/downloads"
        "Sonarr" = "https://sonarr.tv"
        "Radarr" = "https://radarr.video"
        "Prowlarr" = "https://prowlarr.com"
        "Overseerr" = "https://overseerr.dev"
        "Tautulli" = "https://tautulli.com"
        "Ventoy" = "https://ventoy.net"
        "WhatsApp Desktop" = "https://www.whatsapp.com/download"
        "Notepad++" = "https://notepad-plus-plus.org/downloads"
        "FileZilla Client" = "https://filezilla-project.org/download.php"
        "TeamViewer" = "https://www.teamviewer.com/descargas"
        "ProtonVPN" = "https://protonvpn.com/download"
        "Windscribe VPN" = "https://windscribe.com/download"
        "OpenVPN" = "https://openvpn.net/client/client-downloads"
        "DaVinci Resolve" = "https://www.blackmagicdesign.com/products/davinciresolve"
        "Blender" = "https://www.blender.org/download"
        "Docker Desktop" = "https://www.docker.com/products/docker-desktop"
        "VMware Workstation Player" = "https://www.vmware.com/products/workstation-player.html"
        "Microsoft 365" = "https://www.office.com"
        "Cursor AI Editor" = "https://cursor.sh"
        "Adobe Acrobat Reader" = "https://get.adobe.com/reader"
        "WinRAR" = "https://www.win-rar.com/download.html"
        "Malwarebytes" = "https://www.malwarebytes.com/mwb-download"
        "Spotify" = "https://www.spotify.com/download"
        "Obsidian" = "https://obsidian.md/download"
        "Notion" = "https://www.notion.so/desktop"
        "AnyDesk" = "https://anydesk.com/download"
        "RustDesk" = "https://rustdesk.com/download"
        "ExpressVPN" = "https://www.expressvpn.com/download"
        "CyberGhost" = "https://www.cyberghostvpn.com/download"
        "Private Internet Access" = "https://www.privateinternetaccess.com/download"
        "Surfshark" = "https://surfshark.com/download"
        "AtlasVPN" = "https://atlasvpn.com/download"
        "Hotspot Shield" = "https://www.hotspotshield.com/download"
        "TunnelBear" = "https://www.tunnelbear.com/download"
        "CCleaner" = "https://www.ccleaner.com/ccleaner/download"
        "PrivaZer" = "https://privazer.com/download.php"
        "Glary Utilities" = "https://www.glarysoft.com/glary-utilities/download"
        "MemTest86" = "https://www.memtest86.com/download.htm"
        "HDDScan" = "https://hddscan.com/download.html"
    }
    
    # ============================================================
    # ESTRUCTURA DE APPS POR CATEGORÍAS (20 APPS CADA UNA = 440 TOTAL)
    # ============================================================
    
    $categorias = @{
        # ========== 1. 🌐 NAVEGADORES (20 apps) ==========
        "1" = @{
            Nombre = "🌐 NAVEGADORES"
            Apps = @(
                @{Num=1; Nombre="Google Chrome"; ID="Google.Chrome"}
                @{Num=2; Nombre="Mozilla Firefox"; ID="Mozilla.Firefox"}
                @{Num=3; Nombre="Brave Browser"; ID="Brave.Brave"}
                @{Num=4; Nombre="Microsoft Edge"; ID="Microsoft.Edge"}
                @{Num=5; Nombre="Opera"; ID="Opera.Opera"}
                @{Num=6; Nombre="Vivaldi"; ID="Vivaldi.Vivaldi"}
                @{Num=7; Nombre="Arc Browser"; ID="Arc.Arc"}
                @{Num=8; Nombre="Tor Browser"; ID="TorProject.TorBrowser"}
                @{Num=9; Nombre="Firefox Developer"; ID="Mozilla.Firefox.DeveloperEdition"}
                @{Num=10; Nombre="Chromium"; ID="Chromium.Chromium"}
                @{Num=11; Nombre="Brave Beta"; ID="Brave.Brave.Beta"}
                @{Num=12; Nombre="Opera GX"; ID="Opera.OperaGX"}
                @{Num=13; Nombre="Pale Moon"; ID="PaleMoon.PaleMoon"}
                @{Num=14; Nombre="Waterfox"; ID="Waterfox.Waterfox"}
                @{Num=15; Nombre="LibreWolf"; ID="LibreWolf.LibreWolf"}
                @{Num=16; Nombre="Falkon"; ID="Falkon.Falkon"}
                @{Num=17; Nombre="Midori"; ID="Midori.Midori"}
                @{Num=18; Nombre="SeaMonkey"; ID="SeaMonkey.SeaMonkey"}
                @{Num=19; Nombre="Ungoogled Chromium"; ID="UngoogledChromium.UngoogledChromium"}
                @{Num=20; Nombre="Slimjet"; ID="Slimjet.Slimjet"}
            )
        }
        # ========== 2. 💬 COMUNICACIÓN (20 apps) ==========
        "2" = @{
            Nombre = "💬 COMUNICACIÓN"
            Apps = @(
                @{Num=21; Nombre="Discord"; ID="Discord.Discord"}
                @{Num=22; Nombre="Telegram Desktop"; ID="Telegram.TelegramDesktop"}
                @{Num=23; Nombre="Signal Desktop"; ID="OpenWhisperSystems.Signal"}
                @{Num=24; Nombre="Zoom"; ID="Zoom.Zoom"}
                @{Num=25; Nombre="Microsoft Teams"; ID="Microsoft.Teams"}
                @{Num=26; Nombre="Slack"; ID="SlackTechnologies.Slack"}
                @{Num=27; Nombre="WhatsApp Desktop"; ID="9NKSQGP7F2NH"}
                @{Num=28; Nombre="Element (Matrix)"; ID="Element.Element"}
                @{Num=29; Nombre="Thunderbird"; ID="Mozilla.Thunderbird"}
                @{Num=30; Nombre="BlueMail"; ID="BlueMail.BlueMail"}
                @{Num=31; Nombre="Skype"; ID="Microsoft.Skype"}
                @{Num=32; Nombre="Google Meet"; ID="Google.Meet"}
                @{Num=33; Nombre="Webex"; ID="Cisco.Webex"}
                @{Num=34; Nombre="Jitsi Meet"; ManualUrl="https://jitsi.org/downloads"}
                @{Num=35; Nombre="Mattermost"; ID="Mattermost.Mattermost"}
                @{Num=36; Nombre="Rocket.Chat"; ID="RocketChat.RocketChat"}
                @{Num=37; Nombre="Flock"; ID="Flock.Flock"}
                @{Num=38; Nombre="Keybase"; ID="Keybase.Keybase"}
                @{Num=39; Nombre="Wire"; ID="Wire.Wire"}
                @{Num=40; Nombre="Tox"; ID="Tox.Tox"}
            )
        }
        # ========== 3. 🛠️ UTILIDADES (20 apps) ==========
        "3" = @{
            Nombre = "🛠️ UTILIDADES                   "
            Apps = @(
                @{Num=41; Nombre="7-Zip"; ID="7zip.7zip"}
                @{Num=42; Nombre="WinRAR"; ID="RARLab.WinRAR"}
                @{Num=43; Nombre="Microsoft PowerToys"; ID="Microsoft.PowerToys"}
                @{Num=44; Nombre="Everything Search"; ID="voidtools.Everything"}
                @{Num=45; Nombre="BleachBit"; ID="BleachBit.BleachBit"}
                @{Num=46; Nombre="Revo Uninstaller"; ID="RevoUninstaller.RevoUninstaller"}
                @{Num=47; Nombre="Bitwarden"; ID="Bitwarden.Bitwarden"}
                @{Num=48; Nombre="Malwarebytes"; ID="Malwarebytes.Malwarebytes"}
                @{Num=49; Nombre="CPU-Z"; ID="CPUID.CPU-Z"}
                @{Num=50; Nombre="GPU-Z"; ID="TechPowerUp.GPU-Z"}
                @{Num=51; Nombre="HWMonitor"; ID="CPUID.HWMonitor"}
                @{Num=52; Nombre="HWINFO"; ID="REALiX.HWiNFO"}
                @{Num=53; Nombre="MSI Afterburner"; ID="Guru3D.Afterburner"}
                @{Num=54; Nombre="PeaZip"; ID="PeaZip.PeaZip"}
                @{Num=55; Nombre="Notepad++"; ID="Notepad++.Notepad++"}
                @{Num=56; Nombre="Greenshot"; ID="Greenshot.Greenshot"}
                @{Num=57; Nombre="ShareX"; ID="ShareX.ShareX"}
                @{Num=58; Nombre="Windirstat"; ID="Windirstat.Windirstat"}
                @{Num=59; Nombre="WizTree"; ID="WizTree.WizTree"}
                @{Num=60; Nombre="TreeSize Free"; ID="TreeSize.TreeSize"}
            )
        }
        # ========== 4. 💻 DESARROLLO (20 apps) ==========
          "4" = @{
            Nombre = "💻 DESARROLLO"
            Apps = @(
                @{Num=61; Nombre="Visual Studio Code"; ID="Microsoft.VisualStudioCode"}
                @{Num=62; Nombre="Git"; ID="Git.Git"}
                @{Num=63; Nombre="GitHub Desktop"; ID="GitHub.GitHubDesktop"}
                @{Num=64; Nombre="Docker Desktop"; ID="Docker.DockerDesktop"}
                @{Num=65; Nombre="CMake"; ID="Kitware.CMake"}
                @{Num=66; Nombre="Node.js"; ID="OpenJS.NodeJS"}
                @{Num=67; Nombre="Python 3"; ID="Python.Python.3"}
                @{Num=68; Nombre="PuTTY"; ID="PuTTY.PuTTY"}
                @{Num=69; Nombre="WinSCP"; ID="WinSCP.WinSCP"}
                @{Num=70; Nombre="FileZilla Client"; ID="FileZilla.Client"}
                @{Num=71; Nombre="Sublime Text"; ID="SublimeHQ.SublimeText.4"}
                @{Num=72; Nombre="Neovim"; ID="Neovim.Neovim"}
                @{Num=73; Nombre="IntelliJ IDEA Community"; ID="JetBrains.IntelliJIDEA.Community"}
                @{Num=74; Nombre="PyCharm Community"; ID="JetBrains.PyCharm.Community"}
                @{Num=75; Nombre="Postman"; ID="Postman.Postman"}
                @{Num=76; Nombre="Insomnia"; ID="Insomnia.Insomnia"}
                @{Num=77; Nombre="Azure Data Studio"; ID="Microsoft.AzureDataStudio"}
                @{Num=78; Nombre="DBeaver"; ID="DBeaver.DBeaver"}
                @{Num=79; Nombre="Fork"; ID="GitFork.Fork"}
                @{Num=80; Nombre="Android Studio"; ID="Google.AndroidStudio"}
            )
        }
        # ========== 5. 🎬 MULTIMEDIA (20 apps) ==========
        "5" = @{
            Nombre = "🎬 MULTIMEDIA"
            Apps = @(
                @{Num=81; Nombre="GIMP"; ID="GIMP.GIMP"}
                @{Num=82; Nombre="Inkscape"; ID="Inkscape.Inkscape"}
                @{Num=83; Nombre="Krita"; ID="KritaFoundation.Krita"}
                @{Num=84; Nombre="Blender"; ID="BlenderFoundation.Blender"}
                @{Num=85; Nombre="Paint.NET"; ID="dotPDN.PaintDotNet"}
                @{Num=86; Nombre="HandBrake"; ID="HandBrake.HandBrake"}
                @{Num=87; Nombre="VLC Media Player"; ID="VideoLAN.VLC"}
                @{Num=88; Nombre="Audacity"; ID="Audacity.Audacity"}
                @{Num=89; Nombre="Calibre"; ID="Calibre.Calibre"}
                @{Num=90; Nombre="K-Lite Codec Pack Basic"; ID="CodecGuide.K-LiteCodecPack.Basic"}
                @{Num=91; Nombre="Spotify"; ID="Spotify.Spotify"}
                @{Num=92; Nombre="DaVinci Resolve"; ID="BlackmagicDesign.DaVinciResolve"}
                @{Num=93; Nombre="Shotcut"; ID="Shotcut.Shotcut"}
                @{Num=94; Nombre="OpenShot"; ID="OpenShot.OpenShot"}
                @{Num=95; Nombre="LMMS"; ID="LMMS.LMMS"}
                @{Num=96; Nombre="Darktable"; ID="Darktable.Darktable"}
                @{Num=97; Nombre="RawTherapee"; ID="RawTherapee.RawTherapee"}
                @{Num=98; Nombre="Kdenlive"; ID="Kdenlive.Kdenlive"}
                @{Num=99; Nombre="OBS Studio"; ID="OBSProject.OBSStudio"}
                @{Num=100; Nombre="Stremio"; ID="Stremio.Stremio"}
            )
        }
        # ========== 6. 📄 OFIMÁTICA (20 apps) ==========
        "6" = @{
            Nombre = "📄 OFIMÁTICA"
            Apps = @(
                @{Num=101; Nombre="LibreOffice"; ID="TheDocumentFoundation.LibreOffice"}
                @{Num=102; Nombre="Microsoft 365"; ID="Microsoft.OfficeDeploymentTool"}
                @{Num=103; Nombre="Notion"; ID="Notion.Notion"}
                @{Num=104; Nombre="Obsidian"; ID="Obsidian.Obsidian"}
                @{Num=105; Nombre="Zotero"; ID="Zotero.Zotero"}
                @{Num=106; Nombre="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"}
                @{Num=107; Nombre="Foxit PDF Reader"; ID="Foxit.FoxitReader"}
                @{Num=108; Nombre="SumatraPDF"; ID="SumatraPDF.SumatraPDF"}
                @{Num=109; Nombre="PDF24 Creator"; ID="PDF24.PDF24"}
                @{Num=110; Nombre="Typora Markdown Editor"; ID="Typora.Typora"}
                @{Num=111; Nombre="OnlyOffice"; ID="ONLYOFFICE.DesktopEditors"}
                @{Num=112; Nombre="WPS Office"; ID="WPS.WPSOffice"}
                @{Num=113; Nombre="FreeOffice"; ID="SoftMaker.FreeOffice"}
                @{Num=114; Nombre="Evernote"; ID="Evernote.Evernote"}
                @{Num=115; Nombre="Joplin"; ID="Joplin.Joplin"}
                @{Num=116; Nombre="Anytype"; ID="Anytype.Anytype"}
                @{Num=117; Nombre="Zoho Workplace"; ID="Zoho.ZohoWorkplace"}
                @{Num=118; Nombre="Calligra"; ID="Calligra.Calligra"}
                @{Num=119; Nombre="Apache OpenOffice"; ID="Apache.OpenOffice"}
                @{Num=120; Nombre="Google Drive Desktop"; ID="Google.Drive"}
            )
        }
        # ========== 7. 🌐 REDES Y TERMINAL (20 apps) ==========
        "7" = @{
            Nombre = "🌐 REDES Y TERMINAL"
            Apps = @(
                @{Num=121; Nombre="Wireshark"; ID="WiresharkFoundation.Wireshark"}
                @{Num=122; Nombre="Nmap"; ID="Nmap.Nmap"}
                @{Num=123; Nombre="Advanced IP Scanner"; ID="Famatech.AdvancedIPScanner"}
                @{Num=124; Nombre="MobaXterm"; ID="Mobatek.MobaXterm"}
                @{Num=125; Nombre="Alacritty"; ID="Alacritty.Alacritty"}
                @{Num=126; Nombre="Windows Terminal"; ID="Microsoft.WindowsTerminal"}
                @{Num=127; Nombre="AnyDesk"; ID="AnyDesk.AnyDesk"}
                @{Num=128; Nombre="RustDesk"; ID="RustDesk.RustDesk"}
                @{Num=129; Nombre="TeamViewer"; ID="TeamViewer.TeamViewer"}
                @{Num=130; Nombre="Angry IP Scanner"; ID="AngryIPScanner.AngryIPScanner"}
                @{Num=131; Nombre="NetScan"; ID="NetScan.NetScan"}
                @{Num=132; Nombre="Termius"; ID="Termius.Termius"}
                @{Num=133; Nombre="Tabby"; ID="Eugeny.Tabby"}
                @{Num=134; Nombre="Hyper"; ID="Hyper.Hyper"}
                @{Num=135; Nombre="Flipper"; ID="Flipper.Flipper"}
                @{Num=136; Nombre="MRemoteNG"; ID="MRemoteNG.MRemoteNG"}
                @{Num=137; Nombre="KiTTY"; ID="KiTTY.KiTTY"}
                @{Num=138; Nombre="Royal TS"; ID="RoyalApps.RoyalTS"}
                @{Num=139; Nombre="WinSCP"; ID="WinSCP.WinSCP"}
                @{Num=140; Nombre="FileZilla"; ID="FileZilla.Client"}
            )
        }
        # ========== 8. 🎮 JUEGOS (20 apps) ==========
        "8" = @{
            Nombre = "🎮 JUEGOS"
            Apps = @(
                @{Num=141; Nombre="Steam"; ID="Valve.Steam"}
                @{Num=142; Nombre="Epic Games Launcher"; ID="EpicGames.EpicGamesLauncher"}
                @{Num=143; Nombre="EA Desktop"; ID="ElectronicArts.EADesktop"}
                @{Num=144; Nombre="Ubisoft Connect"; ID="Ubisoft.Connect"}
                @{Num=145; Nombre="GOG Galaxy"; ID="GOG.Galaxy"}
                @{Num=146; Nombre="Parsec"; ID="Parsec.Parsec"}
                @{Num=147; Nombre="PlayStation Remote Play"; ID="Sony.PlayStationRemotePlay"}
                @{Num=148; Nombre="Xbox App"; ID="Microsoft.Xbox"}
                @{Num=149; Nombre="Battle.net"; ID="Blizzard.BattleNet"}
                @{Num=150; Nombre="Riot Games"; ID="RiotGames.RiotClient"}
                @{Num=151; Nombre="Amazon Games"; ID="Amazon.Games"}
                @{Num=152; Nombre="Itch.io"; ID="Itch.Itch"}
                @{Num=153; Nombre="Modrinth"; ID="Modrinth.Modrinth"}
                @{Num=154; Nombre="CurseForge"; ID="Overwolf.CurseForge"}
                @{Num=155; Nombre="Playnite"; ID="Playnite.Playnite"}
                @{Num=156; Nombre="Lutris"; ID="Lutris.Lutris"}
                @{Num=157; Nombre="Heroic Games Launcher"; ID="HeroicGamesLauncher.HeroicGamesLauncher"}
                @{Num=158; Nombre="Greenlight"; ID="Greenlight.Greenlight"}
                @{Num=159; Nombre="NVIDIA GeForce Now"; ID="NVIDIA.GeForceNow"}
                @{Num=160; Nombre="Boosteroid"; ID="Boosteroid.Boosteroid"}
            )
        }
        # ========== 9. 🖥️ VIRTUALIZACIÓN (20 apps) ==========
        "9" = @{
            Nombre = "🖥️ VIRTUALIZACIÓN               "
            Apps = @(
                @{Num=161; Nombre="Oracle VM VirtualBox"; ID="Oracle.VirtualBox"}
                @{Num=162; Nombre="VMware Workstation Player"; ID="VMware.WorkstationPlayer"}
                @{Num=163; Nombre="Raspberry Pi Imager"; ID="RaspberryPiFoundation.RaspberryPiImager"}
                @{Num=164; Nombre="WSL (Windows Subsystem Linux)"; ID="Microsoft.WSL"}
                @{Num=165; Nombre="PowerShell 7"; ID="Microsoft.PowerShell"}
                @{Num=166; Nombre="QEMU"; ID="QEMU.QEMU"}
                @{Num=167; Nombre="Podman"; ID="RedHat.Podman"}
                @{Num=168; Nombre="Vagrant"; ID="HashiCorp.Vagrant"}
                @{Num=169; Nombre="Multipass"; ID="Canonical.Multipass"}
                @{Num=170; Nombre="Windows Sandbox"; ManualUrl="https://learn.microsoft.com/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview"}
                @{Num=171; Nombre="Lima"; ID="Lima.Lima"}
                @{Num=172; Nombre="UTM"; ID="UTM.UTM"}
                @{Num=173; Nombre="Proxmox VE Client"; ID="Proxmox.ProxmoxVE"}
                @{Num=174; Nombre="XCP-ng Center"; ID="XCPng.XCPngCenter"}
                @{Num=175; Nombre="Hyper-V Manager"; ID="Microsoft.HyperVManager"}
                @{Num=176; Nombre="Docker Desktop"; ID="Docker.DockerDesktop"}
                @{Num=177; Nombre="Rancher Desktop"; ID="Rancher.RancherDesktop"}
                @{Num=178; Nombre="Colima"; ID="Colima.Colima"}
                @{Num=179; Nombre="Minikube"; ID="Kubernetes.Minikube"}
                @{Num=180; Nombre="Kind"; ID="Kubernetes.Kind"}
            )
        }
        # ========== 10. 💾 RESPALDOS (20 apps) ==========
            "10" = @{
            Nombre = "💾 RESPALDOS"
            Apps = @(
                @{Num=181; Nombre="Duplicati"; ID="Duplicati.Duplicati"}
                @{Num=182; Nombre="Nextcloud Desktop"; ID="Nextcloud.NextcloudDesktop"}
                @{Num=183; Nombre="Google Drive"; ID="Google.Drive"}
                @{Num=184; Nombre="Dropbox"; ID="Dropbox.Dropbox"}
                @{Num=185; Nombre="SyncThing"; ID="SyncThing.SyncThing"}
                @{Num=186; Nombre="Resilio Sync"; ID="Resilio.ResilioSync"}
                @{Num=187; Nombre="Rclone"; ID="Rclone.Rclone"}
                @{Num=188; Nombre="Proton Drive"; ID="ProtonTechnologies.ProtonDrive"}
                @{Num=189; Nombre="OneDrive"; ID="Microsoft.OneDrive"}
                @{Num=190; Nombre="Mega"; ID="Mega.Mega"}
                @{Num=191; Nombre="pCloud"; ID="pCloud.pCloud"}
                @{Num=192; Nombre="FreeFileSync"; ID="FreeFileSync.FreeFileSync"}
                @{Num=193; Nombre="Duplicacy"; ID="Duplicacy.Duplicacy"}
                @{Num=194; Nombre="Kopia"; ID="Kopia.Kopia"}
                @{Num=195; Nombre="BorgBackup"; ID="BorgBackup.BorgBackup"}
                @{Num=196; Nombre="Restic"; ID="Restic.Restic"}
                @{Num=197; Nombre="UrBackup"; ID="UrBackup.UrBackup"}
                @{Num=198; Nombre="BackupPC"; ID="BackupPC.BackupPC"}
                @{Num=199; Nombre="Cobian Backup"; ID="CobianSoft.CobianBackup"}
                @{Num=200; Nombre="EaseUS Todo Backup"; ID="EaseUS.TodoBackup"}
            )
        }
        # ========== 11. 🔒 VPN (20 apps) ==========
        "11" = @{
            Nombre = "🔒 VPN"
            Apps = @(
                @{Num=201; Nombre="ProtonVPN"; ID="ProtonTechnologies.ProtonVPN"}
                @{Num=202; Nombre="Windscribe VPN"; ID="Windscribe.Windscribe"}
                @{Num=203; Nombre="OpenVPN"; ID="OpenVPNTechnologies.OpenVPN"}
                @{Num=204; Nombre="Mullvad VPN"; ID="Mullvad.MullvadVPN"}
                @{Num=205; Nombre="NordVPN"; ID="NordSecurity.NordVPN"}
                @{Num=206; Nombre="Tailscale"; ID="Tailscale.Tailscale"}
                @{Num=207; Nombre="ZeroTier"; ID="ZeroTier.ZeroTier"}
                @{Num=208; Nombre="WireGuard"; ID="WireGuard.WireGuard"}
                @{Num=209; Nombre="ExpressVPN"; ManualUrl="https://www.expressvpn.com/download"}
                @{Num=210; Nombre="CyberGhost"; ManualUrl="https://www.cyberghostvpn.com/download"}
                @{Num=211; Nombre="Private Internet Access"; ManualUrl="https://www.privateinternetaccess.com/download"}
                @{Num=212; Nombre="Surfshark"; ManualUrl="https://surfshark.com/download"}
                @{Num=213; Nombre="AtlasVPN"; ManualUrl="https://atlasvpn.com/download"}
                @{Num=214; Nombre="Hotspot Shield"; ManualUrl="https://www.hotspotshield.com/download"}
                @{Num=215; Nombre="TunnelBear"; ManualUrl="https://www.tunnelbear.com/download"}
                @{Num=216; Nombre="VyprVPN"; ID="VyprVPN.VyprVPN"}
                @{Num=217; Nombre="Hide.me"; ID="HideMe.HideMe"}
                @{Num=218; Nombre="IPVanish"; ID="IPVanish.IPVanish"}
                @{Num=219; Nombre="PureVPN"; ID="PureVPN.PureVPN"}
                @{Num=220; Nombre="PrivateVPN"; ID="PrivateVPN.PrivateVPN"}
            )
        }
        # ========== 12. 📊 MONITOR (20 apps) ==========
        "12" = @{
            Nombre = "📊 MONITOR"
            Apps = @(
                @{Num=221; Nombre="OpenHardwareMonitor"; ID="OpenHardwareMonitor.OpenHardwareMonitor"}
                @{Num=222; Nombre="Core Temp"; ID="CoreTemp.CoreTemp"}
                @{Num=223; Nombre="CrystalDiskInfo"; ID="CrystalDiskInfo.CrystalDiskInfo"}
                @{Num=224; Nombre="CrystalDiskMark"; ID="CrystalDiskMark.CrystalDiskMark"}
                @{Num=225; Nombre="HWiNFO64"; ID="REALiX.HWiNFO"}
                @{Num=226; Nombre="Performance Monitor"; ID="Microsoft.PerformanceMonitor"}
                @{Num=227; Nombre="Resource Monitor"; ID="Microsoft.ResourceMonitor"}
                @{Num=228; Nombre="Task Manager"; ID="Microsoft.TaskManager"}
                @{Num=229; Nombre="Process Explorer"; ID="Microsoft.Sysinternals.ProcessExplorer"}
                @{Num=230; Nombre="Process Monitor"; ID="Microsoft.Sysinternals.ProcessMonitor"}
                @{Num=231; Nombre="RAMMap"; ID="Microsoft.Sysinternals.RAMMap"}
                @{Num=232; Nombre="VMMap"; ID="Microsoft.Sysinternals.VMMap"}
                @{Num=233; Nombre="TCPView"; ID="Microsoft.Sysinternals.TCPView"}
                @{Num=234; Nombre="Disk2VHD"; ID="Microsoft.Sysinternals.Disk2VHD"}
                @{Num=235; Nombre="Autoruns"; ID="Microsoft.Sysinternals.Autoruns"}
                @{Num=236; Nombre="BgInfo"; ID="Microsoft.Sysinternals.BgInfo"}
                @{Num=237; Nombre="PsTools"; ID="Microsoft.Sysinternals.PsTools"}
                @{Num=238; Nombre="Sysmon"; ID="Microsoft.Sysinternals.Sysmon"}
                @{Num=239; Nombre="WinObj"; ID="Microsoft.Sysinternals.WinObj"}
                @{Num=240; Nombre="ZoomIt"; ID="Microsoft.Sysinternals.ZoomIt"}
            )
        }
        # ========== 13. 📝 NOTAS (20 apps) ==========
        "13" = @{
            Nombre = "📝 NOTAS"
            Apps = @(
                @{Num=241; Nombre="Simplenote"; ID="Simplenote.Simplenote"}
                @{Num=242; Nombre="Joplin"; ID="Joplin.Joplin"}
                @{Num=243; Nombre="Obsidian"; ID="Obsidian.Obsidian"}
                @{Num=244; Nombre="Notion"; ID="Notion.Notion"}
                @{Num=245; Nombre="Standard Notes"; ID="StandardNotes.StandardNotes"}
                @{Num=246; Nombre="CherryTree"; ID="CherryTree.CherryTree"}
                @{Num=247; Nombre="Zim Desktop Wiki"; ID="Zim.Zim"}
                @{Num=248; Nombre="QOwnNotes"; ID="QOwnNotes.QOwnNotes"}
                @{Num=249; Nombre="Trilium Notes"; ID="TriliumNotes.TriliumNotes"}
                @{Num=250; Nombre="BoostNote"; ID="BoostNote.BoostNote"}
                @{Num=251; Nombre="Zettlr"; ID="Zettlr.Zettlr"}
                @{Num=252; Nombre="Mark Text"; ID="MarkText.MarkText"}
                @{Num=253; Nombre="Typora"; ID="Typora.Typora"}
                @{Num=254; Nombre="Ghostwriter"; ID="Ghostwriter.Ghostwriter"}
                @{Num=255; Nombre="Remarkable"; ID="Remarkable.Remarkable"}
                @{Num=256; Nombre="Org mode"; ID="OrgMode.OrgMode"}
                @{Num=257; Nombre="Logseq"; ID="Logseq.Logseq"}
                @{Num=258; Nombre="Dendron"; ID="Dendron.Dendron"}
                @{Num=259; Nombre="Foam"; ID="Foam.Foam"}
                @{Num=260; Nombre="Notable"; ID="Notable.Notable"}
            )
        }
        # ========== 14. ⚡ UTILIDADES AVANZADAS (20 apps) ==========
        "14" = @{
            Nombre = "⚡ UTILIDADES AVANZADAS"
            Apps = @(
                @{Num=261; Nombre="Bulk Rename Utility"; ID="BulkRenameUtility.BulkRenameUtility"}
                @{Num=262; Nombre="AutoHotkey"; ID="AutoHotkey.AutoHotkey"}
                @{Num=263; Nombre="Espanso Text Expander"; ID="Espanso.Espanso"}
                @{Num=264; Nombre="Gsudo"; ID="Gsudo.Gsudo"}
                @{Num=265; Nombre="Nushell"; ID="Nushell.Nushell"}
                @{Num=266; Nombre="Fastfetch"; ID="Fastfetch.Fastfetch"}
                @{Num=267; Nombre="Monitorian"; ID="Monitorian.Monitorian"}
                @{Num=268; Nombre="qBittorrent"; ID="qBittorrent.qBittorrent"}
                @{Num=269; Nombre="TeraBox (Baidu)"; ID="Baidu.TeraBox"}
                @{Num=270; Nombre="Power Automate Desktop"; ID="Microsoft.PowerAutomateDesktop"}
                @{Num=271; Nombre="Cheat Engine"; ID="CheatEngine.CheatEngine"}
                @{Num=272; Nombre="dnSpy"; ID="dnSpy.dnSpy"}
                @{Num=273; Nombre="OllyDbg"; ID="OllyDbg.OllyDbg"}
                @{Num=274; Nombre="x64dbg"; ID="x64dbg.x64dbg"}
                @{Num=275; Nombre="Process Hacker"; ID="ProcessHacker.ProcessHacker"}
                @{Num=276; Nombre="Registry Workshop"; ID="RegistryWorkshop.RegistryWorkshop"}
                @{Num=277; Nombre="Sysinternals Suite"; ID="Microsoft.Sysinternals"}
                @{Num=278; Nombre="Windows ADK"; ID="Microsoft.WindowsADK"}
                @{Num=279; Nombre="Windows PE"; ID="Microsoft.WindowsPE"}
                @{Num=280; Nombre="WinDbg"; ID="Microsoft.WinDbg"}
            )
        }
        # ========== 15. 📦 CLIENTES (20 apps) ==========
        "15" = @{
            Nombre = "📦 CLIENTES"
            Apps = @(
                @{Num=281; Nombre="Motrix Download Manager"; ID="Motrix.Motrix"}
                @{Num=282; Nombre="LocalSend"; ID="LocalSend.LocalSend"}
                @{Num=283; Nombre="KDE Connect"; ID="KDE.KDEConnect"}
                @{Num=284; Nombre="croc file transfer"; ID="Schollz.croc"}
                @{Num=285; Nombre="Transmission"; ID="Transmission.Transmission"}
                @{Num=286; Nombre="Deluge"; ID="DelugeTeam.Deluge"}
                @{Num=287; Nombre="Aria2"; ID="Aria2.Aria2"}
                @{Num=288; Nombre="JDownloader"; ID="JDownloader.JDownloader"}
                @{Num=289; Nombre="Internet Download Manager"; ID="InternetDownloadManager.IDM"}
                @{Num=290; Nombre="EagleGet"; ID="EagleGet.EagleGet"}
                @{Num=291; Nombre="Xtreme Download Manager"; ID="XtremeDownloadManager.XDM"}
                @{Num=292; Nombre="Free Download Manager"; ID="FreeDownloadManager.FDM"}
                @{Num=293; Nombre="uGet"; ID="uGet.uGet"}
                @{Num=294; Nombre="Persepolis Download Manager"; ID="Persepolis.Persepolis"}
                @{Num=295; Nombre="Neat Download Manager"; ID="NeatDownloadManager.NDM"}
                @{Num=296; Nombre="DownThemAll"; ID="DownThemAll.DownThemAll"}
                @{Num=297; Nombre="Wget"; ID="Wget.Wget"}
                @{Num=298; Nombre="Curl"; ID="Curl.Curl"}
                @{Num=299; Nombre="HTTPie"; ID="HTTPie.HTTPie"}
                @{Num=300; Nombre="Postman"; ID="Postman.Postman"}
            )
        }
        # ========== 16. 🧹 LIMPIEZA (20 apps) ==========
        "16" = @{
            Nombre = "🧹 LIMPIEZA"
            Apps = @(
                @{Num=301; Nombre="TreeSize Free"; ID="TreeSize.TreeSize"}
                @{Num=302; Nombre="WizTree"; ID="WizTree.WizTree"}
                @{Num=303; Nombre="DiskGenius"; ID="DiskGenius.DiskGenius"}
                @{Num=304; Nombre="Rainmeter"; ID="Rainmeter.Rainmeter"}
                @{Num=305; Nombre="BleachBit"; ID="BleachBit.BleachBit"}
                @{Num=306; Nombre="CCleaner"; ManualUrl="https://www.ccleaner.com/ccleaner/download"}
                @{Num=307; Nombre="PrivaZer"; ManualUrl="https://privazer.com/download.php"}
                @{Num=308; Nombre="Glary Utilities"; ManualUrl="https://www.glarysoft.com/glary-utilities/download"}
                @{Num=309; Nombre="Wise Disk Cleaner"; ID="WiseCleaner.WiseDiskCleaner"}
                @{Num=310; Nombre="System Ninja"; ID="SystemNinja.SystemNinja"}
                @{Num=311; Nombre="Clean Master"; ID="CleanMaster.CleanMaster"}
                @{Num=312; Nombre="Advanced SystemCare"; ID="IObit.AdvancedSystemCare"}
                @{Num=313; Nombre="Ashampoo WinOptimizer"; ID="Ashampoo.WinOptimizer"}
                @{Num=314; Nombre="Auslogics Disk Defrag"; ID="Auslogics.DiskDefrag"}
                @{Num=315; Nombre="Defraggler"; ID="Piriform.Defraggler"}
                @{Num=316; Nombre="MyDefrag"; ID="MyDefrag.MyDefrag"}
                @{Num=317; Nombre="O&O Defrag"; ID="OODefrag.OODefrag"}
                @{Num=318; Nombre="UltraDefrag"; ID="UltraDefrag.UltraDefrag"}
                @{Num=319; Nombre="Windows Disk Cleanup"; ID="Microsoft.DiskCleanup"}
                @{Num=320; Nombre="Storage Sense"; ID="Microsoft.StorageSense"}
            )
        }
        # ========== 17. 🎨 PERSONALIZACIÓN (20 apps) ==========
        "17" = @{
            Nombre = "🎨 PERSONALIZACIÓN"
            Apps = @(
                @{Num=321; Nombre="f.lux"; ID="f.lux.f.lux"}
                @{Num=322; Nombre="Ditto Clipboard Manager"; ID="Ditto.Ditto"}
                @{Num=323; Nombre="CopyQ Clipboard Manager"; ID="CopyQ.CopyQ"}
                @{Num=324; Nombre="Wallpaper Engine"; ID="WallpaperEngine.WallpaperEngine"}
                @{Num=325; Nombre="Lively Wallpaper"; ID="LivelyWallpaper.LivelyWallpaper"}
                @{Num=326; Nombre="TranslucentTB"; ID="TranslucentTB.TranslucentTB"}
                @{Num=327; Nombre="WindowBlinds"; ID="Stardock.WindowBlinds"}
                @{Num=328; Nombre="Start11"; ID="Stardock.Start11"}
                @{Num=329; Nombre="Fences"; ID="Stardock.Fences"}
                @{Num=330; Nombre="Groupy"; ID="Stardock.Groupy"}
                @{Num=331; Nombre="ObjectDock"; ID="Stardock.ObjectDock"}
                @{Num=332; Nombre="Rainmeter"; ID="Rainmeter.Rainmeter"}
                @{Num=333; Nombre="RocketDock"; ID="RocketDock.RocketDock"}
                @{Num=334; Nombre="Nexus Dock"; ID="Winstep.NexusDock"}
                @{Num=335; Nombre="TaskbarX"; ID="TaskbarX.TaskbarX"}
                @{Num=336; Nombre="StartAllBack"; ID="StartAllBack.StartAllBack"}
                @{Num=337; Nombre="Open-Shell"; ID="OpenShell.OpenShell"}
                @{Num=338; Nombre="Classic Shell"; ID="ClassicShell.ClassicShell"}
                @{Num=339; Nombre="Winaero Tweaker"; ID="Winaero.WinaeroTweaker"}
                @{Num=340; Nombre="Ultimate Windows Tweaker"; ID="UltimateWindowsTweaker.UWT"}
            )
        }
        # ========== 18. 🤖 INTELIGENCIA ARTIFICIAL (20 apps) ==========
        "18" = @{
            Nombre = "🤖 INTELIGENCIA ARTIFICIAL"
            Apps = @(
                @{Num=341; Nombre="LM Studio"; ID="LMStudio.LMStudio"}
                @{Num=342; Nombre="Ollama"; ID="Ollama.Ollama"}
                @{Num=343; Nombre="GPT4All"; ID="GPT4All.GPT4All"}
                @{Num=344; Nombre="Upscayl"; ID="Upscayl.Upscayl"}
                @{Num=345; Nombre="Continue (VS Code AI)"; ID="Continue.continue"}
                @{Num=346; Nombre="Cody AI"; ID="Sourcegraph.cody"}
                @{Num=347; Nombre="TabNine"; ID="TabNine.tabnine"}
                @{Num=348; Nombre="Codeium"; ID="Codeium.Codeium"}
                @{Num=349; Nombre="Stable Diffusion WebUI"; ManualUrl="https://github.com/AUTOMATIC1111/stable-diffusion-webui"}
                @{Num=350; Nombre="ComfyUI"; ManualUrl="https://github.com/comfyanonymous/ComfyUI"}
                @{Num=351; Nombre="Whisper Desktop"; ID="Const-me.Whisper"}
                @{Num=352; Nombre="ChatGPT Desktop"; ID="ChatGPT.ChatGPT"}
                @{Num=353; Nombre="Claude Desktop"; ID="Anthropic.Claude"}
                @{Num=354; Nombre="Perplexity AI"; ManualUrl="https://www.perplexity.ai/download"}
                @{Num=355; Nombre="KoboldCP"; ID="KoboldAI.KoboldCP"}
                @{Num=356; Nombre="Text Generation WebUI"; ManualUrl="https://github.com/oobabooga/text-generation-webui"}
                @{Num=357; Nombre="InvokeAI"; ManualUrl="https://github.com/invoke-ai/InvokeAI"}
                @{Num=358; Nombre="Automatic1111 WebUI"; ManualUrl="https://github.com/AUTOMATIC1111/stable-diffusion-webui"}
                @{Num=359; Nombre="Fooocus"; ManualUrl="https://github.com/lllyasviel/Fooocus"}
                @{Num=360; Nombre="EasyDiffusion"; ManualUrl="https://github.com/easydiffusion/easydiffusion"}
            )
        }
        # ========== 19. 🔐 SEGURIDAD AVANZADA (20 apps) ==========
        "19" = @{
            Nombre = "🔐 SEGURIDAD AVANZADA"
            Apps = @(
                @{Num=361; Nombre="VeraCrypt"; ID="IDRIX.VeraCrypt"}
                @{Num=362; Nombre="KeePassXC"; ID="KeePassXCTeam.KeePassXC"}
                @{Num=363; Nombre="ProtonMail Bridge"; ID="ProtonTechnologies.ProtonMailBridge"}
                @{Num=364; Nombre="Sysinternals Suite"; ID="Microsoft.Sysinternals"}
                @{Num=365; Nombre="Process Hacker"; ID="ProcessHacker.ProcessHacker"}
                @{Num=366; Nombre="Autoruns"; ID="Microsoft.Autoruns"}
                @{Num=367; Nombre="TCPView"; ID="Microsoft.TCPView"}
                @{Num=368; Nombre="Wireshark"; ID="WiresharkFoundation.Wireshark"}
                @{Num=369; Nombre="Nmap"; ID="Nmap.Nmap"}
                @{Num=370; Nombre="Metasploit"; ManualUrl="https://metasploit.help.rapid7.com"}
                @{Num=371; Nombre="Burp Suite"; ID="PortSwigger.BurpSuite"}
                @{Num=372; Nombre="Nikto"; ID="Nikto.Nikto"}
                @{Num=373; Nombre="SQLmap"; ID="SQLmap.SQLmap"}
                @{Num=374; Nombre="Hydra"; ID="Hydra.Hydra"}
                @{Num=375; Nombre="John the Ripper"; ID="JohnTheRipper.John"}
                @{Num=376; Nombre="HashCat"; ID="HashCat.HashCat"}
                @{Num=377; Nombre="AirCrack-ng"; ID="AirCrackNG.AirCrackNG"}
                @{Num=378; Nombre="Kismet"; ID="Kismet.Kismet"}
                @{Num=379; Nombre="Reaver"; ID="Reaver.Reaver"}
                @{Num=380; Nombre="OpenSSL"; ID="OpenSSL.OpenSSL"}
            )
        }
        # ========== 20. 📊 DATA SCIENCE (20 apps) ==========
        "20" = @{
            Nombre = "📊 DATA SCIENCE"
            Apps = @(
                @{Num=381; Nombre="Anaconda"; ID="Anaconda.Anaconda3"}
                @{Num=382; Nombre="Miniconda"; ID="Anaconda.Miniconda3"}
                @{Num=383; Nombre="R for Windows"; ID="RProject.R"}
                @{Num=384; Nombre="RStudio"; ID="RStudio.RStudio"}
                @{Num=385; Nombre="Julia"; ID="JuliaComputing.Julia"}
                @{Num=386; Nombre="Tableau Public"; ID="Tableau.TableauPublic"}
                @{Num=387; Nombre="Power BI Desktop"; ID="Microsoft.PowerBIDesktop"}
                @{Num=388; Nombre="QGIS"; ID="QGIS.QGIS"}
                @{Num=389; Nombre="Orange"; ID="Orange.Orange"}
                @{Num=390; Nombre="KNIME"; ID="KNIME.KNIME"}
                @{Num=391; Nombre="Weka"; ID="Weka.Weka"}
                @{Num=392; Nombre="RapidMiner"; ID="RapidMiner.RapidMiner"}
                @{Num=393; Nombre="DataGrip"; ID="JetBrains.DataGrip"}
                @{Num=394; Nombre="DBeaver"; ID="DBeaver.DBeaver"}
                @{Num=395; Nombre="HeidiSQL"; ID="HeidiSQL.HeidiSQL"}
                @{Num=396; Nombre="MongoDB Compass"; ID="MongoDB.Compass"}
                @{Num=397; Nombre="PostgreSQL"; ID="PostgreSQL.PostgreSQL"}
                @{Num=398; Nombre="MySQL Workbench"; ID="Oracle.MySQLWorkbench"}
                @{Num=399; Nombre="Azure Data Studio"; ID="Microsoft.AzureDataStudio"}
                @{Num=400; Nombre="TensorFlow"; ManualUrl="https://tensorflow.org"}
            )
        }
        # ========== 21. 🎬 MEDIA SERVER (20 apps) ==========
        "21" = @{
            Nombre = "🎬 MEDIA SERVER"
            Apps = @(
                @{Num=401; Nombre="Plex Media Server"; ID="Plex.Plex"}
                @{Num=402; Nombre="Jellyfin Server"; ManualUrl="https://jellyfin.org/downloads"}
                @{Num=403; Nombre="Emby Server"; ID="Emby.Emby"}
                @{Num=404; Nombre="Sonarr"; ManualUrl="https://sonarr.tv"}
                @{Num=405; Nombre="Radarr"; ManualUrl="https://radarr.video"}
                @{Num=406; Nombre="Prowlarr"; ManualUrl="https://prowlarr.com"}
                @{Num=407; Nombre="Overseerr"; ManualUrl="https://overseerr.dev"}
                @{Num=408; Nombre="Tautulli"; ManualUrl="https://tautulli.com"}
                @{Num=409; Nombre="Jackett"; ManualUrl="https://github.com/Jackett/Jackett"}
                @{Num=410; Nombre="Bazarr"; ManualUrl="https://www.bazarr.media"}
                @{Num=411; Nombre="Lidarr"; ManualUrl="https://lidarr.audio"}
                @{Num=412; Nombre="Readarr"; ManualUrl="https://readarr.com"}
                @{Num=413; Nombre="Mylar3"; ManualUrl="https://github.com/mylar3/mylar3"}
                @{Num=414; Nombre="NZBGet"; ManualUrl="https://nzbget.net"}
                @{Num=415; Nombre="SABnzbd"; ManualUrl="https://sabnzbd.org"}
                @{Num=416; Nombre="qBittorrent"; ID="qBittorrent.qBittorrent"}
                @{Num=417; Nombre="Transmission"; ID="Transmission.Transmission"}
                @{Num=418; Nombre="Deluge"; ID="DelugeTeam.Deluge"}
                @{Num=419; Nombre="Tdarr"; ManualUrl="https://tdarr.io"}
                @{Num=420; Nombre="FileFlows"; ManualUrl="https://fileflows.com"}
            )
        }
        # ========== 22. 🛠️ HERRAMIENTAS SISTEMA (20 apps) ==========
        "22" = @{
            Nombre = "🛠️ HERRAMIENTAS SISTEMA"
            Apps = @(
                @{Num=421; Nombre="Process Lasso"; ID="Bitsum.ProcessLasso"}
                @{Num=422; Nombre="Macrium Reflect Free"; ID="Macrium.MacriumReflect"}
                @{Num=423; Nombre="Veeam Agent"; ID="Veeam.VeeamAgent"}
                @{Num=424; Nombre="Rufus"; ID="Rufus.Rufus"}
                @{Num=425; Nombre="Ventoy"; ManualUrl="https://ventoy.net"}
                @{Num=426; Nombre="BalenaEtcher"; ID="Balena.Etcher"}
                @{Num=427; Nombre="Clonezilla"; ManualUrl="https://clonezilla.org"}
                @{Num=428; Nombre="Hiren's BootCD PE"; ManualUrl="https://www.hirensbootcd.org"}
                @{Num=429; Nombre="Medicat USB"; ManualUrl="https://medicatusb.com"}
                @{Num=430; Nombre="GParted Live"; ManualUrl="https://gparted.org"}
                @{Num=431; Nombre="HDDScan"; ManualUrl="https://hddscan.com/download.html"}
                @{Num=432; Nombre="MemTest86"; ManualUrl="https://www.memtest86.com/download.htm"}
                @{Num=433; Nombre="Prime95"; ID="Prime95.Prime95"}
                @{Num=434; Nombre="FurMark"; ID="FurMark.FurMark"}
                @{Num=435; Nombre="Cinebench"; ID="Maxon.Cinebench"}
                @{Num=436; Nombre="Geekbench"; ID="PrimateLabs.Geekbench"}
                @{Num=437; Nombre="3DMark"; ID="UL.3DMark"}
                @{Num=438; Nombre="PassMark"; ID="PassMark.PassMark"}
                @{Num=439; Nombre="OCCT"; ID="OCCT.OCCT"}
                @{Num=440; Nombre="HWMonitor"; ID="CPUID.HWMonitor"}
            )
        }
    }
    
    # ============================================================
    # FUNCIONES AUXILIARES
    # ============================================================
    
    function Show-CategoryApps {
        param($CatId)
        $cat = $categorias[$CatId]
        Clear-Host
        Show-MainTitle
        Write-Host "`n 📂 $($cat.Nombre) - $($cat.Apps.Count) aplicaciones" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        
        # Mostrar en 2 columnas
        $cols = 2
        for ($i = 0; $i -lt $cat.Apps.Count; $i += $cols) {
            $row = "   "
            for ($j = 0; $j -lt $cols; $j++) {
                if (($i + $j) -lt $cat.Apps.Count) {
                    $app = $cat.Apps[$i + $j]
                    $numStr = "[$($app.Num.ToString().PadLeft(3))]"
                    $nameStr = $app.Nombre
                    if ($nameStr.Length -gt 30) { $nameStr = $nameStr.Substring(0, 27) + "..." }
                    $row += "$numStr $($nameStr.PadRight(35))"
                }
            }
            Write-Host $row
        }
        
        Write-Host "`n ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 💡 CONSEJO: Selecciona números separados por comas (ej: 1,3,5) o rangos (1-5)" -ForegroundColor $COLOR_ALERT
        Write-Host " 📌 También puedes escribir 'TODO' para instalar TODAS las apps de esta categoría" -ForegroundColor $COLOR_ALERT
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        Write-Host " 🔍 [B] BUSCAR en TODAS las categorías" -ForegroundColor $COLOR_MENU
        
        $input = Read-Host "`n ``> SELECCIONE números, rangos, TODO o X"
        
        if ($input.ToUpper() -eq "X") { return $null }
        if ($input.ToUpper() -eq "B") { return "BUSCAR" }
        if ($input.ToUpper() -eq "TODO") {
            return ($cat.Apps | ForEach-Object { $_.Num.ToString() })
        }
        
        $selection = @()
        $parts = $input -split ','
        foreach($part in $parts){
            $part = $part.Trim()
            if($part -match '^(\d+)-(\d+)$'){
                $start = [int]$matches[1]
                $end = [int]$matches[2]
                for($k=$start; $k -le $end; $k++){ $selection += $k.ToString() }
            } elseif ($part -match '^\d+$') {
                $selection += $part
            }
        }
        
        $validNums = $cat.Apps | ForEach-Object { $_.Num.ToString() }
        $selection = $selection | Where-Object { $_ -in $validNums }
        
        if ($selection.Count -eq 0) {
            Write-Host "`n ❌ No seleccionaste ninguna app válida." -ForegroundColor $COLOR_DANGER
            Start-Sleep -Seconds 1.5
            return $null
        }
        
        return $selection
    }
    
    function Search-AllApps {
        param($SearchTerm)
        Clear-Host
        Show-MainTitle
        Write-Host "`n 🔍 BUSCANDO: '$SearchTerm'" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        
        $results = @()
        foreach ($catId in $categorias.Keys | Sort-Object {[int]$_}) {
            $cat = $categorias[$catId]
            foreach ($app in $cat.Apps) {
                if ($app.Nombre -like "*$SearchTerm*") {
                    $results += [PSCustomObject]@{
                        Num = $app.Num
                        Nombre = $app.Nombre
                        Categoria = $cat.Nombre
                        CatId = $catId
                    }
                }
            }
        }
        
        if ($results.Count -eq 0) {
            Write-Host "`n   ❌ No se encontraron apps con '$SearchTerm'" -ForegroundColor $COLOR_DANGER
            Pause-Enter "`n   ENTER"
            return $null
        }
        
        Write-Host "`n   📊 Se encontraron $($results.Count) resultados:`n" -ForegroundColor Cyan
        
        foreach ($res in $results) {
            Write-Host "   [$($res.Num.ToString().PadLeft(3))] $($res.Nombre.PadRight(40)) ($($res.Categoria))" -ForegroundColor $COLOR_MENU
        }
        
        Write-Host "`n ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 💡 Selecciona los números para instalar (separados por comas o rangos)" -ForegroundColor $COLOR_ALERT
        Write-Host " ❌ [X] Cancelar" -ForegroundColor $COLOR_DANGER
        
        $input = Read-Host "`n ``> SELECCIONE"
        if ($input.ToUpper() -eq "X") { return $null }
        
        $selection = @()
        $parts = $input -split ','
        foreach($part in $parts){
            $part = $part.Trim()
            if($part -match '^(\d+)-(\d+)$'){
                $start = [int]$matches[1]
                $end = [int]$matches[2]
                for($k=$start; $k -le $end; $k++){ $selection += $k.ToString() }
            } elseif ($part -match '^\d+$') {
                $selection += $part
            }
        }
        
        $validNums = $results | ForEach-Object { $_.Num.ToString() }
        $selection = $selection | Where-Object { $_ -in $validNums }
        
        if ($selection.Count -eq 0) {
            Write-Host "`n ❌ Selección inválida" -ForegroundColor $COLOR_DANGER
            Start-Sleep -Seconds 1.5
            return $null
        }
        
        return $selection
    }
    
    # ============================================================
    # MENÚ PRINCIPAL DEL KIT
    # ============================================================
    
    $prefs = Get-Prefs
    $lastOpt = $null
    try { $lastOpt = $prefs.lastKitOption } catch { $lastOpt = $null }

    while($true){
        Clear-Host
        Show-MainTitle
        Write-Host "`n 📦 KIT POST FORMAT - INSTALACION INTELIGENTE (440 APPS)" -ForegroundColor $COLOR_PRIMARY
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        
		# Mostrar menú de categorías en 2 columnas (ordenado numéricamente)
		$cols = 2
		$catList = $categorias.Keys | Sort-Object {[int]$_}
		for ($i = 0; $i -lt $catList.Count; $i += $cols) {
			$row = ""
			for ($j = 0; $j -lt $cols; $j++) {
				if (($i + $j) -lt $catList.Count) {
					$catId = $catList[$i + $j]
					$cat = $categorias[$catId]
					# 👇 CORREGIDO: usa PadLeft en lugar de PadRight
					$row += "[$($catId.ToString().PadLeft(2))]`t$($cat.Nombre.PadRight(32))"
					#                                       ↑↑
					#                        DOS espacios después del corchete
				}
			}
			Write-Host " $row" -ForegroundColor $COLOR_MENU
		}
        
        Write-Host ""
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🎮 [P] PERFILES PREDEFINIDOS (Gaming, Básico, IA, Seguridad, Data, Media, Dev, Office)" -ForegroundColor Cyan
        Write-Host " 🔄 [U] ACTUALIZAR TODO EL SOFTWARE" -ForegroundColor Yellow
        Write-Host " 🗑️ [R] DESINSTALAR PROGRAMAS" -ForegroundColor Red
        Write-Host " 🧹 [0] LIMPIEZA DE BLOATWARE" -ForegroundColor Magenta
        Write-Host " 🔍 [B] BUSCAR APP (por nombre)" -ForegroundColor Green
        Write-Host ""
        Write-Host " ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $opt = Read-MenuOption "`n ``> SELECCIONE (número de categoría, P, U, R, 0, B, X)" -Valid @("0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","P","U","R","B","X")
        if($opt -eq "X"){break}
        
        # Limpieza de Bloatware
        if($opt -eq "0") {
            Write-Host "`n [!] Eliminando Bloatware..." -ForegroundColor $COLOR_ALERT
            $bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*", "*Facebook*", "*Twitter*", "*Pandora*", "*Spotify*", "*LinkedIn*")
            foreach($b in $bloat){ Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue }
            Pause-Enter " OK. ENTER"
            continue
        }
        
        # Perfiles predefinidos
        if($opt -eq "P") {
            Clear-Host
            Show-MainTitle
            Write-Host "`n 🎮 PERFILES PREDEFINIDOS" -ForegroundColor $COLOR_MENU
            Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
            Write-Host " 🎮 [1] PERFIL GAMING (Steam, Discord, OBS, 7-Zip, Epic Games)"
            Write-Host " 🛠️ [2] PERFIL BASICO (Chrome, 7-Zip, VLC, AnyDesk, Teams, WhatsApp)"
            Write-Host " 🤖 [3] PERFIL IA/ML (LM Studio, Ollama, Continue, Codeium, GPT4All)"
            Write-Host " 🔒 [4] PERFIL SEGURIDAD (VeraCrypt, KeePassXC, ProtonVPN, Wireshark)"
            Write-Host " 📊 [5] PERFIL DATA SCIENCE (Anaconda, RStudio, DBeaver, Power BI)"
            Write-Host " 🎬 [6] PERFIL MEDIA SERVER (Plex, Sonarr, Radarr, Jellyfin, qBittorrent)"
            Write-Host " 💻 [7] PERFIL DESARROLLADOR (VSCode, Git, Docker, Node.js, Python, Postman)"
            Write-Host " 📄 [8] PERFIL OFIMATICA (LibreOffice, Adobe Reader, Notion, Obsidian)"
            Write-Host " 🌐 [9] PERFIL REDES (Wireshark, Nmap, AnyDesk, TeamViewer, Windows Terminal)"
            Write-Host " 🎨 [10] PERFIL PERSONALIZACION (f.lux, Ditto, Wallpaper Engine, Rainmeter)"
            Write-Host "`n ❌ [X] VOLVER"
            
            $perfil = Read-MenuOption "`n ``> SELECCIONE PERFIL" -Valid @("1","2","3","4","5","6","7","8","9","10","X")
            if($perfil -eq "X"){ continue }
            
            $selection = @()
            switch ($perfil) {
                "1" { $selection = "141","21","99","41","142" }  # Steam, Discord, OBS, 7Zip, Epic
                "2" { $selection = "1","41","87","127","25","27" }  # Chrome, 7Zip, VLC, AnyDesk, Teams, WhatsApp
                "3" { $selection = "341","342","345","348","343" }  # IA Profile
                "4" { $selection = "361","362","201","121" }  # Security
                "5" { $selection = "381","384","78","387" }  # Data Science
                "6" { $selection = "401","404","405","402","268" }  # Media Server
                "7" { $selection = "61","62","64","66","67","75" }  # Developer
                "8" { $selection = "101","106","103","104" }  # Office
                "9" { $selection = "121","122","127","129","126" }  # Networking
                "10" { $selection = "321","322","324","304" }  # Personalization
            }
            
            # Instalar selección
            $results = @()
            $successCount = 0
            $errorCount = 0
            
            foreach($item in $selection){
                $found = $false
                foreach($cat in $categorias.Values) {
                    $app = $cat.Apps | Where-Object { $_.Num -eq [int]$item }
                    if($app) {
                        $res = Invoke-SmartInstall -AppID $app.ID -AppName $app.Nombre
                        if($res -ne "OK" -and $res -notlike "MANUAL|*"){
                            $res = Invoke-SmartInstall -AppID $app.ID -AppName $app.Nombre
                        }
                        if ($res -like "MANUAL|*") {
                            $url = ($res -split "\|")[1]
                            $results += "[ ERROR ] $($app.Nombre)`n   → Descárgala manualmente desde: $url"
                            $errorCount++
                        } elseif ($res -eq "OK") {
                            $results += "[ OK ] $($app.Nombre)"
                            $successCount++
                        } else {
                            $results += "[ ERROR ] $($app.Nombre)"
                            $errorCount++
                        }
                        $found = $true
                        break
                    }
                }
                if(-not $found){
                    $results += "[ ERROR ] App no encontrada: $item"
                    $errorCount++
                }
            }
            
            Show-MainTitle
            Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host " 📊 RESUMEN DE INSTALACIÓN" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            $results | ForEach-Object { Write-Host " $_" }
            Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "   ✅ Exitosas: $successCount  |  ❌ Fallidas: $errorCount" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Pause-Enter "`n PRESIONE ENTER PARA CONTINUAR"
            continue
        }
        
        # Actualizar software (mismo código que antes)
        if($opt -eq "U") {
            Clear-Host
            Show-MainTitle
            Write-Host "`n 🔄 ACTUALIZACIÓN INTELIGENTE DE SOFTWARE" -ForegroundColor $COLOR_MENU
            Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
            
            $appsToUpdate = @()
            $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
            
            if ($wingetAvailable) {
                Write-Host "`n 📡 Escaneando actualizaciones disponibles..." -ForegroundColor $COLOR_ALERT
                $upgradeList = winget upgrade --accept-source-agreements 2>$null | Where-Object { $_ -match "^\S" -and $_ -notmatch "Nombre|Versión|Disponible|ID" -and $_ -notmatch "^-" } | Select-Object -Skip 1
                
                if ($upgradeList -and $upgradeList.Count -gt 0) {
                    foreach ($line in $upgradeList) {
                        if ($line -match "^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)") {
                            $appsToUpdate += [PSCustomObject]@{
                                ID = $matches[1]
                                VersionActual = $matches[2]
                                VersionNueva = $matches[3]
                                Nombre = $matches[4] -replace "\s+", " "
                            }
                        }
                    }
                }
            }
            
            if ($appsToUpdate.Count -eq 0) {
                Write-Host "`n   ✅ ¡TODO ESTÁ ACTUALIZADO!" -ForegroundColor Green
                Pause-Enter "`n   ENTER"
                continue
            }
            
            Write-Host "`n   📊 Se encontraron $($appsToUpdate.Count) actualizaciones:`n" -ForegroundColor Cyan
            foreach ($app in $appsToUpdate) {
                Write-Host "      • $($app.Nombre)" -ForegroundColor White
                Write-Host "        📦 $($app.VersionActual) → $($app.VersionNueva)" -ForegroundColor Gray
            }
            
            $confirm = Read-Host "`n   ❓ ¿Deseas actualizar todo? (S/N)"
            if ($confirm -ne "S") {
                Write-Host "   ❌ Actualización cancelada." -ForegroundColor $COLOR_DANGER
                Pause-Enter "   ENTER"
                continue
            }
            
            $actualizados = 0
            $fallidos = 0
            
            foreach ($app in $appsToUpdate) {
                Write-Host "   📦 Actualizando $($app.Nombre)..." -ForegroundColor Yellow
                winget upgrade --id $app.ID --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $actualizados++ } else { $fallidos++ }
            }
            
            Write-Host "`n   ✅ Actualizados: $actualizados  |  ❌ Fallidos: $fallidos" -ForegroundColor Cyan
            Write-Log "KIT" "UpdateSummary Success=$actualizados Errors=$fallidos Total=$($appsToUpdate.Count)"
            Pause-Enter "`n   ENTER"
            continue
        }
        
        # Desinstalar programas (mismo código que antes)
        if($opt -eq "R") {
            while ($true) {
                Clear-Host
                Show-MainTitle
                Write-Host "`n 🗑️ DESINSTALACIÓN DE PROGRAMAS" -ForegroundColor $COLOR_MENU
                Write-Host " 🖥️ [1] PANEL DE CONTROL (appwiz.cpl) - Gráfico nativo" -ForegroundColor $COLOR_MENU
                Write-Host " ⚡ [2] WINGET UNINSTALL - Código nativo (rápido)" -ForegroundColor $COLOR_MENU
                Write-Host " 🔧 [3] REVO UNINSTALLER - App gráfica avanzada" -ForegroundColor $COLOR_MENU
                Write-Host " 🧹 [4] BCUNINSTALLER - Bulk Crap Uninstaller" -ForegroundColor $COLOR_MENU
                Write-Host "`n ❌ [X] VOLVER AL KIT" -ForegroundColor $COLOR_DANGER
                
                $subOpt = Read-Host "`n 🔽 > SELECCIONE"
                
                switch ($subOpt.ToUpper()) {
                    "1" { Start-Process "appwiz.cpl"; Pause-Enter " ENTER después de cerrar"; continue }
                    "2" { 
                        Write-Host "`n [+] LISTA DE PROGRAMAS INSTALADOS:" -ForegroundColor $COLOR_PRIMARY
                        winget list
                        $app = Read-Host "`n NOMBRE EXACTO DEL PROGRAMA A DESINSTALAR"
                        if ($app) {
                            Write-Host " [+] Desinstalando $app..." -ForegroundColor Yellow
                            winget uninstall "$app" --silent
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host " [✔] Desinstalación completada" -ForegroundColor Green
                            } else {
                                Write-Host " [✘] Error. Prueba con la opción 1 o 3." -ForegroundColor Red
                            }
                        }
                        Pause-Enter " ENTER"
                        continue
                    }
                    "3" {
                        $installed = Get-Command revo -ErrorAction SilentlyContinue
                        if (-not $installed) {
                            Write-Host "`n [+] Instalando Revo Uninstaller..." -ForegroundColor Yellow
                            winget install RevoUninstaller.RevoUninstaller --silent
                            Start-Sleep -Seconds 5
                            Write-Host " [✔] Revo instalado." -ForegroundColor Green
                        }
                        Write-Host "`n [+] Abre Revo Uninstaller manualmente desde el menú inicio." -ForegroundColor Yellow
                        Pause-Enter " ENTER después de cerrar Revo"
                        continue
                    }
                    "4" {
                        $installed = Get-Command bcuninstaller -ErrorAction SilentlyContinue
                        if (-not $installed) {
                            Write-Host "`n [+] Instalando Bulk Crap Uninstaller..." -ForegroundColor Yellow
                            winget install Klocman.BulkCrapUninstaller --silent
                            Start-Sleep -Seconds 5
                            Write-Host " [✔] BCUninstaller instalado." -ForegroundColor Green
                        }
                        Write-Host "`n [+] Abre BCUninstaller manualmente desde el menú inicio." -ForegroundColor Yellow
                        Pause-Enter " ENTER después de cerrar BCUninstaller"
                        continue
                    }
                    "X" { break }
                    default { Write-Host " Opción no válida" -ForegroundColor Red; Start-Sleep -Seconds 1 }
                }
                if ($subOpt.ToUpper() -eq "X") { break }
            }
            continue
        }
        
        # Buscar app
        if($opt -eq "B") {
            $searchTerm = Read-Host "`n 🔍 INGRESE NOMBRE DE LA APP A BUSCAR"
            if ($searchTerm) {
                $selection = Search-AllApps -SearchTerm $searchTerm
                if ($selection -and $selection.Count -gt 0) {
                    $results = @()
                    $successCount = 0
                    $errorCount = 0
                    
                    foreach($item in $selection){
                        $found = $false
                        foreach($cat in $categorias.Values) {
                            $app = $cat.Apps | Where-Object { $_.Num -eq [int]$item }
                            if($app) {
                                $res = Invoke-SmartInstall -AppID $app.ID -AppName $app.Nombre
                                if($res -ne "OK" -and $res -notlike "MANUAL|*"){
                                    $res = Invoke-SmartInstall -AppID $app.ID -AppName $app.Nombre
                                }
                                if ($res -like "MANUAL|*") {
                                    $url = ($res -split "\|")[1]
                                    $results += "[ ERROR ] $($app.Nombre)`n   → Descárgala manualmente desde: $url"
                                    $errorCount++
                                } elseif ($res -eq "OK") {
                                    $results += "[ OK ] $($app.Nombre)"
                                    $successCount++
                                } else {
                                    $results += "[ ERROR ] $($app.Nombre)"
                                    $errorCount++
                                }
                                $found = $true
                                break
                            }
                        }
                        if(-not $found){
                            $results += "[ ERROR ] App no encontrada: $item"
                            $errorCount++
                        }
                    }
                    
                    Show-MainTitle
                    Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                    Write-Host " 📊 RESUMEN DE INSTALACIÓN" -ForegroundColor Cyan
                    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                    $results | ForEach-Object { Write-Host " $_" }
                    Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                    Write-Host "   ✅ Exitosas: $successCount  |  ❌ Fallidas: $errorCount" -ForegroundColor Yellow
                    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                    
                    $wingetFinal = Get-Command winget -ErrorAction SilentlyContinue
                    if ($wingetFinal) {
                        $versionFinal = (winget --version 2>&1) -replace 'v', ''
                        Write-Host "`n   🟢 Estado de winget: FUNCIONAL (v$versionFinal)" -ForegroundColor Green
                    } else {
                        Write-Host "`n   🔴 Estado de winget: NO DISPONIBLE" -ForegroundColor Red
                    }
                    
                    Write-Log "KIT" "InstallSummary Success=$successCount Errors=$errorCount Total=$($selection.Count)"
                    Pause-Enter "`n PRESIONE ENTER PARA CONTINUAR"
                }
            }
            continue
        }
        
        # Selección por categoría
        if ($categorias.ContainsKey($opt)) {
            $selection = Show-CategoryApps -CatId $opt
            
            if ($selection -eq "BUSCAR") {
                $searchTerm = Read-Host "`n 🔍 INGRESE NOMBRE DE LA APP A BUSCAR"
                if ($searchTerm) {
                    $selection = Search-AllApps -SearchTerm $searchTerm
                }
            }
            
            if ($selection -and $selection.Count -gt 0) {
                $results = @()
                $successCount = 0
                $errorCount = 0
                
                foreach($item in $selection){
                    $found = $false
                    foreach($cat in $categorias.Values) {
                        $app = $cat.Apps | Where-Object { $_.Num -eq [int]$item }
                        if($app) {
                            Write-Host "`n [!] INSTALANDO: $($app.Nombre)..." -ForegroundColor $COLOR_MENU
                            $res = Invoke-SmartInstall -AppID $app.ID -AppName $app.Nombre
                            if($res -ne "OK" -and $res -notlike "MANUAL|*"){
                                Write-Host " [!] Reintentando: $($app.Nombre)" -ForegroundColor $COLOR_ALERT
                                $res = Invoke-SmartInstall -AppID $app.ID -AppName $app.Nombre
                            }
                            
                            if ($res -like "MANUAL|*") {
                                $url = ($res -split "\|")[1]
                                $results += "[ ERROR ] $($app.Nombre)`n   → Descárgala manualmente desde: $url"
                                $errorCount++
                            } elseif ($res -eq "OK") {
                                $results += "[ OK ] $($app.Nombre)"
                                $successCount++
                            } else {
                                $results += "[ ERROR ] $($app.Nombre)"
                                $errorCount++
                            }
                            $found = $true
                            break
                        }
                    }
                    if(-not $found){
                        $results += "[ ERROR ] App no encontrada: $item"
                        $errorCount++
                    }
                }
                
                Show-MainTitle
                Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                Write-Host " 📊 RESUMEN DE INSTALACIÓN" -ForegroundColor Cyan
                Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                $results | ForEach-Object { Write-Host " $_" }
                Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                Write-Host "   ✅ Exitosas: $successCount  |  ❌ Fallidas: $errorCount" -ForegroundColor Yellow
                Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
                
                $wingetFinal = Get-Command winget -ErrorAction SilentlyContinue
                if ($wingetFinal) {
                    $versionFinal = (winget --version 2>&1) -replace 'v', ''
                    Write-Host "`n   🟢 Estado de winget: FUNCIONAL (v$versionFinal)" -ForegroundColor Green
                } else {
                    Write-Host "`n   🔴 Estado de winget: NO DISPONIBLE" -ForegroundColor Red
                }
                
                Write-Log "KIT" "InstallSummary Success=$successCount Errors=$errorCount Total=$($selection.Count)"
                Pause-Enter "`n PRESIONE ENTER PARA CONTINUAR"
            }
        }
    }
}

# ============================================================
# MOTOR DE RESPALDO Y RESTAURACION
# ============================================================
function Invoke-Engine ($Mode, $Msg) {
    Show-MainTitle
    $DriveLetter = if ($PSScriptRoot -and $PSScriptRoot.Length -ge 2) { $PSScriptRoot.Substring(0,2) } else { "C:" }

if ($Mode -eq "BACKOP") {
    Write-Host "`n 💾 BACKUP TOTAL - SELECCIONA EL TIPO DE RESPALDO" -ForegroundColor $COLOR_ALERT
    Write-Host " 👤 [A] PERFIL ACTUAL - Respaldar tu usuario (Escritorio, Documentos, etc.)" -ForegroundColor $COLOR_PRIMARY
    Write-Host " 👥 [B] TODOS LOS PERFILES LOCALES - Respaldar todos los usuarios del equipo" -ForegroundColor $COLOR_PRIMARY
    Write-Host " 📊 [C] EXPORTAR INVENTARIO - Lista de programas instalados y drivers" -ForegroundColor $COLOR_PRIMARY
    Write-Host " ☁️ [D] DUPLICATI - BACKUP avanzado a la nube (encriptado, programado)" -ForegroundColor $COLOR_PRIMARY
    Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
    Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
    Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
    
    $o = Read-MenuOption "`n > SELECCIONE" -Valid @("A","B","C","D","X")
    if($o -eq "X"){ return }

    # --- Para opciones A, B y C usamos el selector de unidades ---
    if ($o -ne "D") {
        $selectedUnit = Show-DriveSelector -Title "SELECCIONAR DESTINO DE BACKUP"
        if (-not $selectedUnit) { return }
        $Base = Join-Path $selectedUnit.Path "BACKOPs"
        
        # Crear carpeta si no existe
        if (-not (Test-Path $Base)) {
            New-Item -Path $Base -ItemType Directory -Force | Out-Null
        }
    }

    # Resumen + tamaño aproximado (solo para BACKOPs de perfil)
    if ($o -eq "A" -or $o -eq "B") {
        Show-MainTitle
        Write-Host "`n 📋 RESUMEN DE BACKUP" -ForegroundColor $COLOR_MENU
        Write-Host " 📂 DESTINO BASE: $Base" -ForegroundColor $COLOR_PRIMARY
        Write-Host " 💾 UNIDAD SELECCIONADA: $($selectedUnit.DeviceID) ($($selectedUnit.Label))" -ForegroundColor $COLOR_MENU
        Write-Host " 📊 ESPACIO LIBRE: $($selectedUnit.FreeGB) GB de $($selectedUnit.TotalGB) GB" -ForegroundColor Gray
        Write-Host " 📁 CARPETAS INCLUIDAS:" -ForegroundColor $COLOR_PRIMARY
        $USER_FOLDER_NAMES | ForEach-Object { Write-Host "  - 📄 $_" -ForegroundColor $COLOR_MENU }
        
        $estBytes = 0L
        if ($o -eq "A") {
            foreach ($rel in $USER_FOLDER_NAMES) {
                $p = Join-Path $env:USERPROFILE $rel
                if (Test-Path $p) { $estBytes += Get-FolderSizeBytes $p }
            }
        } else {
            $profiles = Get-UserProfilePaths
            foreach ($profile in $profiles) {
                foreach ($rel in $USER_FOLDER_NAMES) {
                    $p = Join-Path $profile $rel
                    if (Test-Path $p) { $estBytes += Get-FolderSizeBytes $p }
                }
            }
        }
        
        $freeBytes = Get-DriveFreeBytes $Base
        Write-Host "`n 📊 TAMAÑO APROX (SUMA DE CARPETAS): $(Format-Bytes $estBytes)" -ForegroundColor $COLOR_ALERT
        Write-Host " 💾 ESPACIO LIBRE DESTINO:            $(Format-Bytes $freeBytes)" -ForegroundColor $COLOR_ALERT
        Write-Log "BACKOP" "EstimateBytes=$estBytes FreeBytes=$freeBytes Base=$Base Choice=$o"
        
        if ($freeBytes -gt 0 -and $estBytes -gt 0 -and $freeBytes -lt ($estBytes * 1.2)) {
            Write-Host "`n [!] POSIBLE FALTA DE ESPACIO (recomendado >= 20% extra)." -ForegroundColor $COLOR_DANGER
            if (-not (Confirm-Critical "CONTINUAR CON POSIBLE POCO ESPACIO" "APLICAR")) { return }
        } else {
            Pause-Enter " ENTER PARA CONTINUAR"
        }
    }

    $BACKOPRoot = Get-BACKOPRoot $Base
    Write-Log "BACKOP" "BACKOPRoot=$BACKOPRoot Base=$Base Choice=$o"

    if ($o -eq "A") {
        Write-Log "BACKOP" "Choice=A ProfileRoot=$env:USERPROFILE"
        BACKOP-ProfileData $env:USERPROFILE $BACKOPRoot
        $verify = Read-MenuOption "`n VERIFICAR BACKOP (conteo rápido)? (S/N)" -Valid @("S","N")
        if($verify -eq "S"){
            $count = (Get-ChildItem -Path $BACKOPRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Host " [+] ARCHIVOS EN BACKOP: $count" -ForegroundColor $COLOR_PRIMARY
            Write-Log "BACKOP" "VerifyFiles=$count BACKOPRoot=$BACKOPRoot"
        }
        Pause-Enter "`n BACKOP DE PERFIL ACTUAL COMPLETADO EN: $BACKOPRoot. ENTER"
        return
    }

    if ($o -eq "B") {
        $profiles = Get-UserProfilePaths
        Write-Log "BACKOP" "Choice=B ProfilesCount=$(@($profiles).Count) BACKOPRoot=$BACKOPRoot"
        foreach ($profile in $profiles) {
            BACKOP-ProfileData $profile $BACKOPRoot
        }
        $verify = Read-MenuOption "`n VERIFICAR BACKOP (conteo rápido)? (S/N)" -Valid @("S","N")
        if($verify -eq "S"){
            $count = (Get-ChildItem -Path $BACKOPRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Host " [+] ARCHIVOS EN BACKOP: $count" -ForegroundColor $COLOR_PRIMARY
            Write-Log "BACKOP" "VerifyFiles=$count BACKOPRoot=$BACKOPRoot"
        }
        Pause-Enter "`n BACKOP DE TODOS LOS PERFILES COMPLETADO EN: $BACKOPRoot. ENTER"
        return
    }

    if ($o -eq "C") {
        if (!(Test-Path $BACKOPRoot)) { New-Item -Path $BACKOPRoot -ItemType Directory -Force | Out-Null }
        $appsFile = Join-Path $BACKOPRoot "InstalledApps_$((Get-Date).ToString('yyyyMMdd_HHmmss')).txt"
        $driversPath = Join-Path $BACKOPRoot "Drivers"
        $zipFile = Join-Path $BACKOPRoot "Drivers_$env:COMPUTERNAME.zip"
        
        Write-Log "BACKOP" "Choice=C Export Apps+Drivers to $BACKOPRoot"
        Write-Host "`n [+] EXPORTANDO LISTA DE PROGRAMAS INSTALADOS..." -ForegroundColor $COLOR_PRIMARY
        Get-Package | Sort-Object Name | Format-Table -AutoSize | Out-String | Out-File $appsFile -Encoding utf8
        
        Write-Host "[+] EXPORTANDO DRIVERS INSTALADOS..." -ForegroundColor $COLOR_PRIMARY
        if (!(Test-Path $driversPath)) { New-Item -Path $driversPath -ItemType Directory -Force | Out-Null }
        Export-WindowsDriver -Online -Destination $driversPath | Out-Null
        
        $comprimir = Read-MenuOption "`n ¿COMPRIMIR DRIVERS EN ZIP? (S/N)" -Valid @("S","N")
        if ($comprimir -eq "S") {
            Write-Host "[+] COMPRIMIENDO DRIVERS..." -ForegroundColor $COLOR_ALERT
            try {
                Compress-Archive -Path "$driversPath\*" -DestinationPath $zipFile -Force -ErrorAction Stop
                Write-Host " [✔] ZIP CREADO: $zipFile" -ForegroundColor Green
                $eliminar = Read-MenuOption " ¿ELIMINAR CARPETA ORIGINAL DE DRIVERS? (S/N)" -Valid @("S","N")
                if ($eliminar -eq "S") {
                    Remove-Item -Path $driversPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host " [✔] CARPETA ORIGINAL ELIMINADA" -ForegroundColor Green
                }
            } catch {
                Write-Host " [✘] ERROR AL COMPRIMIR: $($_.Exception.Message)" -ForegroundColor $COLOR_DANGER
            }
        }
        
        if (Test-Path $zipFile) {
            $zipSize = (Get-Item $zipFile).Length
            Write-Host "`n 📦 TAMAÑO DEL ZIP: $(Format-Bytes $zipSize)" -ForegroundColor Cyan
        }
        
        Pause-Enter "`n INVENTARIO CREADO EN: $BACKOPRoot. ENTER"
        return
    }

    if ($o -eq "D") {
        while ($true) {
            Clear-Host
            Show-MainTitle
            Write-Host "`n ☁️ DUPLICATI - BACKUP EN LA NUBE (Encriptado + Programado)" -ForegroundColor $COLOR_MENU
            Write-Host " -----------------------------------------------------------------------------"
            
            $duplicatiExe = Get-ChildItem -Path @(
                "$env:ProgramFiles\Duplicati*",
                "${env:ProgramFiles(x86)}\Duplicati*",
                "$env:LOCALAPPDATA\Programs\Duplicati*"
            ) -Filter "Duplicati.Server.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            
            $duplicatiService = Get-Service -Name "Duplicati" -ErrorAction SilentlyContinue
            $isInstalled = ($duplicatiExe -ne $null) -or ($duplicatiService -ne $null)
            
            if ($isInstalled) {
                Write-Host "                               [OK] Duplicati ya está instalado" -ForegroundColor Green
            } else {
                Write-Host "                               [!] Duplicati NO está instalado" -ForegroundColor Red
            }
            
            Write-Host "`n ⚙️ OPCIONES:" -ForegroundColor $COLOR_PRIMARY
            Write-Host " -----------------------------------------------------------------------------"
            Write-Host " 🌐 [1] ABRIR PANEL DE CONTROL (WEB) - http://localhost:8200"
            Write-Host " 🔄 [2] REINICIAR SERVICIO / RESTAURAR ICONO DE BANDEJA"
            Write-Host " 📦 [3] INSTALAR / REPARAR DUPLICATI"
            Write-Host " 🗑️ [4] DESINSTALAR DUPLICATI"
            Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
            Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
            Write-Host " ❌ [X] VOLVER AL MENÚ DE BACKUP" -ForegroundColor $COLOR_DANGER
            
            $dupOpt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","X")
            if ($dupOpt -eq "X") { break }

            switch ($dupOpt) {
                "1" {
                    Write-Host "`n [+] Abriendo panel de Duplicati en el navegador..." -ForegroundColor $COLOR_PRIMARY
                    $serviceRunning = Get-Service -Name "Duplicati" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
                    if (-not $serviceRunning -and $isInstalled) {
                        Write-Host " [!] El servicio de Duplicati no está corriendo. Iniciando..." -ForegroundColor Yellow
                        Start-Service -Name "Duplicati" -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 3
                    }
                    try { Start-Process "http://localhost:8200" } catch { Write-Host " [✘] Error al abrir navegador." -ForegroundColor $COLOR_DANGER }
                    Pause-Enter "`n ENTER para volver"
                }
                "2" {
                    Write-Host "`n [+] Reiniciando servicio..." -ForegroundColor $COLOR_PRIMARY
                    if (-not $isInstalled) { Write-Host " [!] No instalado."; Pause-Enter " ENTER"; continue }
                    Stop-Service -Name "Duplicati" -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                    Start-Service -Name "Duplicati" -ErrorAction SilentlyContinue
                    Write-Host " [✔] Servicio reiniciado." -ForegroundColor Green
                    Pause-Enter "`n ENTER para volver"
                }
                "3" {
                    if ($isInstalled) { if ((Read-MenuOption " ¿Reinstalar? (S/N)" -Valid @("S","N")) -ne "S") { continue } }
                    Write-Host "`n [+] Instalando..." -ForegroundColor Yellow
                    winget install Duplicati.Duplicati --silent --accept-package-agreements
                    Pause-Enter "`n ENTER para volver"
                }
                "4" {
                    if (-not $isInstalled) { Pause-Enter " [!] No instalado."; continue }
                    if (-not (Confirm-Critical "DESINSTALAR DUPLICATI" "BORRAR")) { continue }
                    winget uninstall Duplicati.Duplicati --silent
                    Write-Host " [✔] Desinstalado." -ForegroundColor Green
                    Pause-Enter " ENTER para volver"
                }
            }
        }
        return
    }
    return
}

if ($Mode -eq "RESTORE") {
    Write-Host "`n 📀 RESTORE TOTAL" -ForegroundColor $COLOR_ALERT
    Write-Host " 🔍 [B] BUSCAR BACKOP EN TODAS LAS UNIDADES (C:, D:, USB, etc.)" -ForegroundColor $COLOR_PRIMARY
    Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
    Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
    Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
    
    $choice = Read-MenuOption "🔽 > SELECCIONE" -Valid @("B","X")
    if ($choice -eq "X") { return }
    
    if ($choice -eq "B") {
        Write-Host "`n [+] Buscando en todas las unidades locales y USB..." -ForegroundColor $COLOR_PRIMARY
        $units = Scan-DriveUnits
        $allBACKOPs = @()
        
        foreach ($unit in $units) {
            $found = Find-BACKOPsInUnit -UnitPath $unit.Path
            if ($found.Count -gt 0) {
                $allBACKOPs += $found
            }
        }
        
        if ($allBACKOPs.Count -eq 0) {
            Write-Host "`n ❌ No se encontraron BACKOPs en ninguna unidad." -ForegroundColor $COLOR_DANGER
            Pause-Enter " ENTER"
            return
        }
        
        # Mostrar todos los BACKOPs encontrados
        Clear-Host
        Show-MainTitle
        Write-Host "`n 📋 BACKOPS ENCONTRADOS EN TODAS LAS UNIDADES:" -ForegroundColor $COLOR_PRIMARY
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        
        for ($i = 0; $i -lt $allBACKOPs.Count; $i++) {
            Write-Host "   [$($i+1)] $($allBACKOPs[$i].Name)" -ForegroundColor $COLOR_MENU
            Write-Host "          📍 Unidad: $([System.IO.Path]::GetPathRoot($allBACKOPs[$i].FullName))" -ForegroundColor DarkGray
            Write-Host "          📅 Creado: $($allBACKOPs[$i].CreationTime)" -ForegroundColor DarkGray
            Write-Host "          💾 Tamaño: $($allBACKOPs[$i].SizeGB) GB" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " [X] CANCELAR" -ForegroundColor $COLOR_DANGER
        
        $sel = Read-Host "`n > SELECCIONE BACKOP (NÚMERO)"
        if ($sel -eq "X" -or $sel -eq "x") { return }
        
        if ($sel -match "^\d+$" -and [int]$sel -le $allBACKOPs.Count) {
            $BACKOPRoot = $allBACKOPs[[int]$sel-1].FullName
            Write-Host "`n ✅ BACKOP seleccionado: $BACKOPRoot" -ForegroundColor Green
        } else {
            Write-Host "`n ❌ Selección inválida." -ForegroundColor $COLOR_DANGER
            return
        }
    }
    
    # Verificar que el BACKOP existe
    if (-not (Test-Path $BACKOPRoot)) {
        Write-Host "`n ❌ El BACKOP seleccionado no existe o no es accesible." -ForegroundColor $COLOR_DANGER
        Pause-Enter " ENTER"
        return
    }
    
    # Continuar con la restauración...
    $BACKOPProfiles = Get-ChildItem -Path $BACKOPRoot -Directory -ErrorAction SilentlyContinue
    if (!$BACKOPProfiles) { 
        Write-Host "Backop vacío o no válido." -ForegroundColor $COLOR_DANGER
        Pause-Enter " ENTER"
        return 
    }
    
    Write-Host "`n PERFILES EN EL BACKOP:" -ForegroundColor $COLOR_PRIMARY
    $BACKOPProfiles | ForEach-Object { Write-Host " [ ] $($_.Name)" -ForegroundColor $COLOR_MENU }
    $profileChoice = Read-Host ' NOMBRE DE PERFIL A RESTAURAR (ENTER PARA TODOS, X PARA VOLVER)'
    if ($profileChoice.ToUpper() -eq "X") { return }
    
    $targetUsersRoot = "$env:SystemDrive\Users"
    $alt = Read-MenuOption " RESTAURAR EN UBICACIÓN ALTERNATIVA? (S/N)" -Valid @("S","N")
    if($alt -eq "S"){
        $custom = Read-Host " RUTA BASE (ej: D:\Restores)"
        if($custom){ $targetUsersRoot = $custom }
    }
    
    if (-not $profileChoice) {
        foreach ($profile in $BACKOPProfiles) {
            Restore-ProfileData $profile.FullName $targetUsersRoot
        }
    } else {
        $selected = $BACKOPProfiles | Where-Object { $_.Name -ieq $profileChoice }
        if ($selected) {
            Restore-ProfileData $selected[0].FullName $targetUsersRoot
        }
    }
    Pause-Enter "`n PROCESO FINALIZADO. ENTER"
	}
}

# ============================================================
# PAUSA ESTANDAR CON MENSAJE
# ============================================================
function Pause-Enter {
    param([string]$Message = " PRESIONE ENTER PARA VOLVER")
    Read-Host $Message | Out-Null
}

# ========== NUEVA FUNCIÓN: ELIMINACIÓN PROGRAMADA ==========
function Remove-LockedFileSafely {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [switch]$ForceDelete
    )
    try {
        if (-not (Test-Path $Path)) { return $true }
        
        # Intentar eliminación normal
        Remove-Item $Path -Recurse -Force -ErrorAction Stop
        return $true
    } catch {
        # Si falla, programar eliminación al reinicio
        if ($ForceDelete) {
            try {
                # Método 1: Usar cmd /c del
                cmd /c "del /f /q `"$Path`"" 2>&1 | Out-Null
                
                # Método 2: Mover a carpeta pendiente
                $pendingDir = "$env:TEMP\_pending_delete_"
                if (-not (Test-Path $pendingDir)) { 
                    New-Item $pendingDir -ItemType Directory -Force | Out-Null
                }
                $destName = [System.IO.Path]::GetFileName($Path) + "_" + (Get-Date -Format "yyyyMMddHHmmss")
                $destPath = Join-Path $pendingDir $destName
                Move-Item $Path $destPath -Force -ErrorAction SilentlyContinue
                return $false
            } catch {
                return $false
            }
        }
        return $false
    }
}

# ============================================================
# OPTIMIZADOR DE TEMPORALES
# ============================================================
function Invoke-TempOptimizer {
    Clear-Host
    # Definición local de colores para evitar errores de variables nulas
    $C_PRIMARY = "Green"; $C_MENU = "Cyan"; $C_WARN = "Yellow"; $C_ERR = "Red"; $C_GRAY = "Gray"

    while($true){
        Show-MainTitle
		Write-Host "`n 🗂️ GESTIÓN DE ALMACENAMIENTO Y LIMPIEZA" -ForegroundColor $C_MENU
        
        Write-Host " ---------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " 🔧 [1] TODO (Mantenimiento Integral) " -NoNewline -ForegroundColor $C_GRAY
        Write-Host "-> Limpieza total de basura y archivos residuales." -ForegroundColor $C_GRAY
        
        Write-Host " 🗑️ [2] Papelera de Reciclaje         " -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Vacía archivos eliminados de todos los discos." -ForegroundColor $C_GRAY
        
        Write-Host " 🧹 [3] Temporales de Usuario         " -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Caché de apps y navegación del perfil actual." -ForegroundColor $C_GRAY
        
        Write-Host " ⚙️ [4] Temporales del Sistema        " -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Archivos residuales de Windows y actualizaciones." -ForegroundColor $C_GRAY

        Write-Host " 🧽 [5] LIMPIEZA AVANZADA (BleachBit) - App gráfica" -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Limpieza profunda de navegadores, cachés, y más." -ForegroundColor $C_GRAY

        Write-Host "`n ⌨️ CONTROL" -ForegroundColor $C_GRAY 
        Write-Host " -------------------" -ForegroundColor $C_ERR 
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $C_ERR
        
        $o = (Read-Host "🔽 > SELECCIONE UNA OPCIÓN").ToUpper()
        if($o -eq "X"){break}
        
        $targets = @()
        $clearTrash = $false

        switch ($o) {
            "1" { $targets = @("$env:TEMP", "C:\Windows\Temp"); $clearTrash = $true }
            "2" { $clearTrash = $true }
            "3" { $targets = @("$env:TEMP") }
            "4" { $targets = @("C:\Windows\Temp") }
            "5" {
                # Verificar si está instalado
                $installed = Get-Command bleachbit -ErrorAction SilentlyContinue
                
                if (-not $installed) {
                    Write-Host "`n [+] Instalando BleachBit..." -ForegroundColor Yellow
                    winget install BleachBit.BleachBit --silent
                    Start-Sleep -Seconds 5
                    Write-Host " [✔] BleachBit instalado." -ForegroundColor Green
                }
                
                Write-Host "`n [+] Por favor, abre BleachBit manualmente desde el menú inicio." -ForegroundColor Yellow
                Write-Host "     (El comando automático no funcionó en este equipo)" -ForegroundColor Gray
                Pause-Enter " ENTER después de cerrar BleachBit"
                continue
            }
                    }

        $demoMode = (Read-Host " ¿Ejecutar en MODO DEMO? (S/N)").ToUpper()
        $isDemo = ($demoMode -eq "S")

# ============================================================
# EJECUCIÓN: PAPELERA
# ============================================================
        if ($clearTrash -and -not $isDemo) {
            Write-Host "`n [*] Vaciando Papelera..." -ForegroundColor $C_WARN
            Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host " [+] Papelera limpia." -ForegroundColor $C_PRIMARY
        }

        # ============================================================
# EJECUCIÓN: TEMPORALES
# ============================================================
        if ($targets.Count -gt 0) {
            Write-Host "`n [*] Eliminando archivos temporales..." -ForegroundColor $C_WARN
            $failCount = 0
            $pendingCount = 0
            
            # ========== LISTA DE EXCLUSIONES ==========
            $excludedPatterns = @(
                "*cpuz*",      # CPU-Z driver
                "*hwmonitor*", # HWMonitor
                "*gpuz*",      # GPU-Z
                "*aida64*",    # AIDA64
                "*msiafterburner*"
            )
            
            foreach ($target in $targets) {
                if (Test-Path $target) {
                    $items = Get-ChildItem -Path "$target\*" -Force -Recurse -ErrorAction SilentlyContinue
                    Write-Host "  - Procesando: $target..." -ForegroundColor $C_GRAY
                    
                    # ========== FILTRAR ELEMENTOS EXCLUIDOS ==========
                    $filteredItems = @()
                    foreach ($it in $items) {
                        $excluded = $false
                        foreach ($pattern in $excludedPatterns) {
                            if ($it.Name -like $pattern) {
                                $excluded = $true
                                Write-Host "    [EXCLUIDO] $($it.Name) (en uso por hardware monitor)" -ForegroundColor DarkGray
                                break
                            }
                        }
                        if (-not $excluded) {
                            $filteredItems += $it
                        }
                    }
                    
                    # ========== ELIMINACIÓN CON FUNCIÓN MEJORADA ==========
                    if (-not $isDemo) {
                        foreach ($it in $filteredItems) {
                            try {
                                if (Test-Path $it.FullName) {
                                    $result = Remove-LockedFileSafely -Path $it.FullName -ForceDelete
                                    if (-not $result) { 
                                        $pendingCount++ 
                                    }
                                }
                            } catch { 
                                $failCount++ 
                            }
                        }
                    }
                }
            }
            
            # Mostrar resumen
            if ($pendingCount -gt 0) {
                Write-Host "  [!] $pendingCount archivos programados para eliminación al reinicio." -ForegroundColor DarkGray
            }
        }

        # ============================================================
# RESULTADOS
# ============================================================
        if (-not $isDemo) {
            Write-Host "`n [+] PROCESO FINALIZADO." -ForegroundColor $C_PRIMARY
            if ($failCount -gt 0) {
                Write-Host " [!] Nota: $failCount elementos no se borraron (están en uso)." -ForegroundColor DarkGray
            }
        } else {
            Write-Host "`n [DEMO] No se realizaron cambios." -ForegroundColor $C_WARN
        }
        
        Pause-Enter "para volver"
        Clear-Host
    }
}

# ============================================================
# GESTION DE PAQUETES (WINGET/CHOCO)
# ============================================================
function Invoke-WingetMenu {
    Clear-Host
    while($true){
        Show-MainTitle
        Write-Host ([Environment]::NewLine + ' 📦 GESTION DE PAQUETES (WINGET & CHOCOLATEY)') -ForegroundColor $COLOR_MENU
        
        # Columna izquierda: WINGET | Columna derecha: CHOCOLATEY
        Write-Host " 🔄 [A] WINGET: ACTUALIZAR TODO             🍫 [D] CHOCO: ACTUALIZAR TODO"        -ForegroundColor $COLOR_MENU
        Write-Host " 📋 [B] WINGET: LISTAR DISPONIBLES          📋 [E] CHOCO: LISTAR DISPONIBLES"      -ForegroundColor $COLOR_MENU
        Write-Host " 🔍 [S] WINGET: BUSCAR PAQUETE              🔍 [F] CHOCO: BUSCAR PAQUETE"          -ForegroundColor $COLOR_MENU
        Write-Host " 📥 [G] WINGET: INSTALAR POR ID EXACTO      🍫 [H] CHOCO: INSTALAR CHOCOLATEY   "        -ForegroundColor $COLOR_MENU
        Write-Host " 🔧 [C] WINGET: REPARAR CLIENTE                                                " -ForegroundColor $COLOR_MENU
        
        Write-Host "`n 💡 TIP: Usa primero [S] para buscar el ID exacto, luego [G] para instalarlo." -ForegroundColor $COLOR_ALERT
        Write-Host ""
        Write-Host " ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
        $hasChoco  = [bool](Get-Command choco -ErrorAction SilentlyContinue)
        
        Write-Host "`n ESTADO:" -ForegroundColor Gray
        Write-Host ("  - winget: {0}" -f ($(if($hasWinget){"OK"}else{"NO"}))) -ForegroundColor $(if($hasWinget){"Green"}else{"Red"})
        Write-Host ("  - choco : {0}" -f ($(if($hasChoco){"OK"}else{"NO"}))) -ForegroundColor $(if($hasChoco){"Green"}else{"Red"})

        $o = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","S","D","E","F","G","H","X")
        if($o -eq "X"){break}
        
        # ========== A - WINGET: ACTUALIZAR TODO ==========
        if($o -eq "A"){
            if(-not $hasWinget){ Write-Host "`n [!] winget no está disponible." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n ACTUALIZANDO VIA WINGET..." -ForegroundColor $COLOR_PRIMARY
            winget upgrade --all --accept-package-agreements --accept-source-agreements 2>&1
            Write-Log "PKG" ("winget upgrade all exit={0}" -f $LASTEXITCODE)
            Pause-Enter "`n FIN. ENTER"
        }
        
        # ========== B - WINGET: LISTAR DISPONIBLES ==========
        if($o -eq "B"){
            if(-not $hasWinget){ Write-Host "`n [!] winget no está disponible." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            winget upgrade
            Pause-Enter "`n ENTER"
        }
        
        # ========== S - WINGET: BUSCAR PAQUETE (DUAL) ==========
        if($o -eq "S"){
            if(-not $hasWinget -and -not $hasChoco){ 
                Write-Host "`n [!] Ni winget ni chocolatey están disponibles." -ForegroundColor $COLOR_DANGER
                Pause-Enter " ENTER"
                continue 
            }
            
            $searchTerm = (Read-Host "`n ``> INGRESE EL NOMBRE DEL PROGRAMA A BUSCAR (ej: whatsapp, chrome, vlc)").Trim()
            
            if ($searchTerm) {
                # Búsqueda con Winget
                if ($hasWinget) {
                    Write-Host "`n ═══════════════════════════════════════════════════════" -ForegroundColor Cyan
                    Write-Host " 🔍 RESULTADOS DE WINGET PARA: '$searchTerm'" -ForegroundColor $COLOR_PRIMARY
                    Write-Host " ═══════════════════════════════════════════════════════" -ForegroundColor Cyan
                    winget search "$searchTerm" 2>&1
                    Write-Log "PKG" "winget search executed for: $searchTerm"
                    
                    # Sugerir alternativas si no hay resultados exactos
                    if ($LASTEXITCODE -ne 0 -or $searchTerm -notmatch "^\.") {
                        Write-Host "`n 💡 ¿No encontraste lo que buscabas? Prueba con estos IDs alternativos:" -ForegroundColor $COLOR_ALERT
                        Write-Host "    - Si buscas navegadores: Google.Chrome, Mozilla.Firefox, Brave.Brave, Opera.Opera"
                        Write-Host "    - Si buscas editores: Notepad++.Notepad++, Microsoft.VisualStudioCode, SublimeHQ.SublimeText"
                        Write-Host "    - Si buscas compressores: 7zip.7zip, RARLab.WinRAR, PeaZip.PeaZip"
                        Write-Host "    - Si buscas reproductores: VideoLAN.VLC, Spotify.Spotify, Apple.iTunes"
                    }
                }
                
                # Búsqueda con Chocolatey (si está disponible)
                if ($hasChoco) {
                    Write-Host "`n ═══════════════════════════════════════════════════════" -ForegroundColor Magenta
                    Write-Host " 🔍 RESULTADOS DE CHOCOLATEY PARA: '$searchTerm'" -ForegroundColor $COLOR_ALERT
                    Write-Host " ═══════════════════════════════════════════════════════" -ForegroundColor Magenta
                    choco search "$searchTerm" --limit-output 2>&1 | Select-Object -First 20
                    Write-Log "PKG" "choco search executed for: $searchTerm"
                }
                
                # Preguntar si quiere instalar algo de lo encontrado
                Write-Host ""
                Write-Host " ═══════════════════════════════════════════════════════" -ForegroundColor Gray
                $installNow = Read-MenuOption "`n ❓ ¿DESEAS INSTALAR ALGUNO DE LOS RESULTADOS? (S/N)" -Valid @("S","N")
                if ($installNow -eq "S") {
                    Write-Host "`n 💡 COPIA EL 'ID' EXACTO DEL PROGRAMA (ej: Google.Chrome, 9NKSQGP7F2NH)" -ForegroundColor $COLOR_ALERT
                    $appToInstall = (Read-Host "`n ``> PEGA AQUÍ EL ID EXACTO DEL PROGRAMA").Trim()
                    if ($appToInstall) {
                        $res = Invoke-SmartInstall -AppID $appToInstall -AppName $appToInstall
                        Write-Log "PKG" "SmartInstall from search app=$appToInstall result=$res"
                        
                        # Si falló, sugerir alternativa
                        if ($res -ne "OK" -and $res -notlike "MANUAL|*") {
                            Write-Host "`n ⚠️ LA INSTALACIÓN FALLÓ." -ForegroundColor $COLOR_DANGER
                            Write-Host " 💡 CONSEJOS:" -ForegroundColor $COLOR_ALERT
                            Write-Host "    • Revisa que el ID esté escrito correctamente"
                            Write-Host "    • Prueba con chocolatey en la opción [F] o [H]"
                            Write-Host "    • Busca alternativas similares con la opción [S]"
                            Write-Host "    • Descarga manual desde la web oficial del programa"
                        }
                    }
                }
            }
            Pause-Enter "`n ENTER PARA VOLVER"
        }

        # ========== G - WINGET: INSTALAR POR ID EXACTO ==========
        if($o -eq "G"){
            if(-not $hasWinget){ Write-Host "`n [!] winget no está disponible." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            
            Write-Host "`n 💡 EJEMPLOS DE ID: Google.Chrome | 7zip.7zip | VideoLAN.VLC | WhatsApp.WhatsApp" -ForegroundColor $COLOR_ALERT
            Write-Host " 💡 Usa la opción [S] primero para buscar el ID correcto." -ForegroundColor $COLOR_ALERT
            
            $appID = (Read-Host "`n ``> INGRESE EL ID EXACTO DEL PROGRAMA A INSTALAR").Trim()
            if ($appID) {
                $appName = Read-Host " ``> NOMBRE DESCRIPTIVO (ej: Google Chrome) - ENTER para usar el ID"
                if (-not $appName) { $appName = $appID }
                
                Write-Host "`n [+] INSTALANDO: $appName (ID: $appID)..." -ForegroundColor $COLOR_PRIMARY
                $res = Invoke-SmartInstall -AppID $appID -AppName $appName
                Write-Log "PKG" "SmartInstall app=$appName id=$appID result=$res"
            }
            Pause-Enter "`n PROCESO TERMINADO. ENTER"
        }
        
        # ========== D - CHOCO: ACTUALIZAR TODO ==========
        if($o -eq "D"){
            if(-not $hasChoco){ Write-Host "`n [!] CHOCO NO INSTALADO - Usa la opción [H] para instalarlo." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n ACTUALIZANDO VIA CHOCOLATEY..." -ForegroundColor $COLOR_PRIMARY
            choco upgrade all -y --no-progress 2>&1
            Write-Log "PKG" ("choco upgrade all exit={0}" -f $LASTEXITCODE)
            Pause-Enter " ENTER"
        }
        
        # ========== E - CHOCO: LISTAR DISPONIBLES ==========
        if($o -eq "E"){
            if(-not $hasChoco){ Write-Host "`n [!] CHOCO NO INSTALADO - Usa la opción [H] para instalarlo." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n PAQUETES DESACTUALIZADOS EN CHOCOLATEY:" -ForegroundColor $COLOR_PRIMARY
            choco outdated 2>&1
            Pause-Enter "`n ENTER"
        }
        
        # ========== F - CHOCO: BUSCAR PAQUETE ==========
        if($o -eq "F"){
            if(-not $hasChoco){ Write-Host "`n [!] CHOCO NO INSTALADO - Usa la opción [H] para instalarlo." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            $p = (Read-Host "`n NOMBRE DEL PROGRAMA A BUSCAR EN CHOCOLATEY").Trim()
            if($p){ 
                Write-Host "`n RESULTADOS PARA: '$p'" -ForegroundColor $COLOR_PRIMARY
                choco search $p --limit-output 2>&1 | Select-Object -First 20
            }
            Pause-Enter "`n ENTER"
        }
        
        # ========== H - CHOCO: INSTALAR CHOCOLATEY ==========
        if($o -eq "H"){
            if(-not (Test-HasInternet)){ Write-Host "`n [!] Sin Internet." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            if(-not (Require-Admin "instalar Chocolatey")){ continue }
            Write-Host "`n INSTALANDO CHOCOLATEY..." -ForegroundColor $COLOR_ALERT
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Log "PKG" ("choco install bootstrap exit={0}" -f $LASTEXITCODE)
            Pause-Enter "`n INSTALACION FINALIZADA. ENTER"
        }
        
        # ========== C - WINGET: REPARAR CLIENTE ==========
        if($o -eq "C"){
            if(-not (Test-HasInternet)){ Write-Host "`n [!] Sin Internet." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n RE-INSTALANDO CLIENTE WINGET..." -ForegroundColor $COLOR_ALERT
            $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $dest = "$env:TEMP\winget.msixbundle"
            Invoke-WebRequest -Uri $url -OutFile $dest
            Add-AppxPackage -Path $dest
            Write-Log "PKG" "winget client reinstalled from $url"
            Pause-Enter "`n CLIENTE ACTUALIZADO. ENTER"
        }
    }
}
# ============================================================
# MONITOR DE SISTEMA PRO
# ============================================================
function Show-LiveMonitor {
	Clear-Host #nuevo
    $refreshMs = 1500
    while ($true) {
        Show-MainTitle
        Write-Host "`n [O] MONITOR DE SISTEMA Y GESTION DE TAREAS" -ForegroundColor $COLOR_MENU
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
        
        $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        $mem = Get-CimInstance Win32_OperatingSystem | Select-Object @{Name="Free";Expression={"{0:N2}" -f ($_.FreePhysicalMemory / 1MB)}}, @{Name="Total";Expression={"{0:N2}" -f ($_.TotalVisibleMemorySize / 1MB)}}
        
        Write-Host " ESTADO ACTUAL:" -ForegroundColor $COLOR_ALERT
        Write-Host (' {0}{0} CPU: {1} %' -f '>', $cpu) -ForegroundColor $COLOR_PRIMARY
        Write-Host (' {0}{0} RAM LIBRE: {1} GB / {2} GB' -f '>', $mem.Free, $mem.Total) -ForegroundColor $COLOR_PRIMARY
        
        Write-Host "`n TOP 10 PROCESOS ``(ORDENADOS POR CONSUMO DE RAM`)`:" -ForegroundColor $COLOR_ALERT
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
        
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | ForEach-Object {
            $memMB = "{0:N2}" -f ($_.WorkingSet / 1MB)
            $procName = $_.ProcessName
            if($procName.Length -gt 25) { $procName = $procName.Substring(0,22) + "..." }
            Write-Host " [ID: $($_.Id.ToString().PadRight(6))]  $($procName.PadRight(25)) | Uso: $memMB MB"
        }

        Write-Host "`n TOP 10 PROCESOS (CPU):" -ForegroundColor $COLOR_ALERT
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
        Get-Process | Where-Object { $_.CPU -ne $null } | Sort-Object CPU -Descending | Select-Object -First 10 | ForEach-Object {
            $cpuT = "{0:N2}" -f $_.CPU
            $procName = $_.ProcessName
            if($procName.Length -gt 25) { $procName = $procName.Substring(0,22) + "..." }
            Write-Host " [ID: $($_.Id.ToString().PadRight(6))]  $($procName.PadRight(25)) | CPU: $cpuT s"
        }
		
                Write-Host "`n ACCIONES DE MONITOREO" -ForegroundColor $COLOR_ALERT
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_MENU
        Write-Host " [K] KILL: Finalizar proceso      [T] TIEMPO: Cambiar intervalo (ms)" -ForegroundColor $COLOR_DANGER
        Write-Host " [P] PROCESS LASSO: Gestión avanzada de procesos" -ForegroundColor $COLOR_DANGER
        Write-Host " [E] EVERYTHING: Búsqueda instantánea de archivos" -ForegroundColor $COLOR_DANGER
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] SALIR" -ForegroundColor $COLOR_DANGER
        Write-Host "`n (Auto refresco: $refreshMs ms | ENTER = refrescar)" -ForegroundColor Gray
        
        $action = Read-Host "`n > SELECCIONE"
        $action = $action.ToUpper()
        $salir = $false
        
        switch ($action) {
            "X" { 
                $salir = $true
                break
            }
            "K" {
                $target = Read-Host " INGRESE NOMBRE O ID DEL PROCESO"
                if ($target) {
                    try {
                        if ($target -match "^\d+$") { Stop-Process -Id $target -Force -ErrorAction Stop }
                        else { Stop-Process -Name $target -Force -ErrorAction Stop }
                        Write-Host "`n [+] PROCESO FINALIZADO EXITOSAMENTE." -ForegroundColor $COLOR_PRIMARY
                        Write-Log "MONITOR" "Killed process target=$target"
                    } catch {
                        Write-Host "`n [!] ERROR: NO SE PUDO CERRAR EL PROCESO." -ForegroundColor $COLOR_DANGER
                        Write-Log "MONITOR" ("Kill failed target={0} err={1}" -f $target, $_.Exception.Message)
                    }
                    Start-Sleep -Seconds 2
                }
                continue
            }
            "T" {
                $v = Read-Host " NUEVO INTERVALO (MS) (ej 1000)"
                if ($v -match "^\d+$") {
                    $refreshMs = [int]$v
                    Write-Log "MONITOR" "RefreshMs set to $refreshMs"
                }
                continue
            }
            "P" {
                $installed = Get-Command processlasso -ErrorAction SilentlyContinue
                if (-not $installed) {
                    Write-Host "`n [+] Instalando Process Lasso..." -ForegroundColor Yellow
                    winget install Bitsum.ProcessLasso --silent
                    Start-Sleep -Seconds 5
                    Write-Host " [✔] Process Lasso instalado." -ForegroundColor Green
                }
                Write-Host "`n [+] Por favor, abre Process Lasso manualmente desde el menú inicio." -ForegroundColor Yellow
                Pause-Enter " ENTER después de cerrar Process Lasso"
                continue
            }
            "E" {
                $installed = Get-Command everything -ErrorAction SilentlyContinue
                if (-not $installed) {
                    Write-Host "`n [+] Instalando Everything Search..." -ForegroundColor Yellow
                    winget install voidtools.Everything --silent
                    Start-Sleep -Seconds 5
                    Write-Host " [✔] Everything instalado." -ForegroundColor Green
                }
                Write-Host "`n [+] Por favor, abre Everything Search manualmente desde el menú inicio." -ForegroundColor Yellow
                Pause-Enter " ENTER después de cerrar Everything"
                continue
            }
            default {
                Start-Sleep -Milliseconds $refreshMs
            }
        }
        
        if ($salir) { break }
    }
}

# ============================================================
# ACTIVACIÓN INTEGRADA (MASSGRAVE)
# ============================================================
function Invoke-MassGraveIntegrated {
    Show-MainTitle
    Write-Host "`n ACTIVACIÓN DE WINDOWS/OFFICE" -ForegroundColor $COLOR_MENU
    Write-Host " Este proceso ejecutará directamente desde la fuente oficial." -ForegroundColor $COLOR_PRIMARY
    Write-Host " Se abrirá una nueva ventana de PowerShell con el proceso." -ForegroundColor $COLOR_ALERT
    
    if (-not (Confirm-Critical "EJECUTAR" "ACTIVAR")) { return }
    
    Write-Host "`n[+] Ejecutando" -ForegroundColor $COLOR_PRIMARY
    
    # Ejecución directa sin guardar archivos
    $scriptBlock = {
    #    irm https://get.activated.win | iex
		irm "https://raw.githubusercontent.com/Hellowen6060/Office-AIO-FULL-1.0/refs/heads/main/MenuGIT.ps1" | iex	
    }
    
    # Lanzar en ventana nueva con permisos de admin
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$scriptBlock`"" -Verb RunAs
    
    Write-Host "`n[✔]  Ejecutado Instalador." -ForegroundColor Green
	Write-Host "`n[✔]  Autor Diego Garcia." -ForegroundColor Green
    Write-Host "     Revisa la nueva ventana que se abrió y sigue las instrucciones." -ForegroundColor $COLOR_ALERT
    Pause-Enter "`n PRESIONE ENTER CUANDO TERMINE"
}

# ============================================================
# CONTROL DE DEFENDER
# ============================================================
# ============================================================
# 🛡️ [REPAIR-DEFENDER] - REHABILITACIÓN COMPLETA
# ============================================================
function Repair-Defender {
    Clear-Host
    Show-MainTitle
    Write-Host "`n 🔧 REPARACIÓN DE WINDOWS DEFENDER" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    
    if (-not (Require-Admin "reparar Defender")) { return }
    
    # 1. Eliminar políticas conflictivas
    Write-Host "`n [+] Eliminando políticas conflictivas (GPO)..." -ForegroundColor $COLOR_ALERT
    
    $policiesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    $rtpPath = "$policiesPath\Real-Time Protection"
    
    $blockingPolicies = @(
        "DisableAntiSpyware",
        "DisableRealtimeMonitoring",
        "DisableBehaviorMonitoring",
        "DisableOnAccessProtection",
        "DisableScanOnRealtimeEnable"
    )
    
    if (Test-Path $policiesPath) {
        foreach ($policy in $blockingPolicies) {
            Remove-ItemProperty -Path $policiesPath -Name $policy -ErrorAction SilentlyContinue
        }
        Write-Host "   ✓ Políticas principales eliminadas" -ForegroundColor DarkGray
    }
    
    if (Test-Path $rtpPath) {
        foreach ($policy in $blockingPolicies) {
            Remove-ItemProperty -Path $rtpPath -Name $policy -ErrorAction SilentlyContinue
        }
        Write-Host "   ✓ Políticas de protección en tiempo real eliminadas" -ForegroundColor DarkGray
    }
    
    # 2. Restaurar servicios
    Write-Host "`n [+] Restaurando servicios de seguridad..." -ForegroundColor $COLOR_ALERT
    
    $services = @(
        @{Name="WinDefend"; Display="Antivirus Defender"},
        @{Name="WdNisSvc"; Display="Inspección de red"},
        @{Name="Sense"; Display="ATP (Advanced Threat Protection)"}
    )
    
    foreach ($svc in $services) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.StartType -ne "Automatic") {
                Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
                Write-Host "   ✓ $($svc.Display): configurado como Automático" -ForegroundColor DarkGray
            }
            if ($service.Status -ne "Running") {
                Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
                Write-Host "   ✓ $($svc.Display): iniciado" -ForegroundColor DarkGray
            }
        }
    }
    
    # 3. Forzar activación vía WMI (método silencioso)
    Write-Host "`n [+] Forzando activación de protección..." -ForegroundColor $COLOR_ALERT
    
    try {
        $mpPreferences = Get-CimInstance -Namespace "root/Microsoft/Windows/Defender" -ClassName "MSFT_MpPreference" -ErrorAction SilentlyContinue
        if ($mpPreferences) {
            Invoke-CimMethod -InputObject $mpPreferences -MethodName "Set" -Arguments @{
                DisableRealtimeMonitoring = $false
                DisableBehaviorMonitoring = $false
                DisableBlockAtFirstSeen = $false
                DisableIOAVProtection = $false
            } -ErrorAction SilentlyContinue
            Write-Host "   ✓ Protección en tiempo real activada" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️ Método alternativo aplicado (usa reinicio si no funciona)" -ForegroundColor DarkGray
    }
    
    # 4. Actualizar definiciones
    Write-Host "`n [+] Actualizando definiciones de malware..." -ForegroundColor $COLOR_ALERT
    Start-Process -FilePath "mpcmdrun.exe" -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host "   ✓ Definiciones actualizadas" -ForegroundColor DarkGray
    
    Write-Host "`n ═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " ✅ REPARACIÓN COMPLETADA" -ForegroundColor Green
    Write-Host "    Si Defender sigue sin funcionar, reinicia el equipo." -ForegroundColor $COLOR_ALERT
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
    
    Write-Log "DEFENDER" "Repair-Defender executed"
    Pause-Enter " ENTER para volver"
}

# ============================================================
# 🛡️ CONTROL TOTAL DE WINDOWS DEFENDER (VERSIÓN MEJORADA)
# ============================================================
function Invoke-DefenderControl {
    Clear-Host
    while($true){
        Show-MainTitle
        Write-Host "`n 🛡️ CONTROL TOTAL DE WINDOWS DEFENDER" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        Write-Host " ✅ [1] ACTIVAR DEFENDER" -ForegroundColor Green
        Write-Host " 🔧 [2] REPARAR DEFENDER (Elimina GPO y restaura servicios)" -ForegroundColor Cyan
        Write-Host " 🦠 [3] ESCANEO DE MALWARE" -ForegroundColor Yellow
        Write-Host "    ├─ [R] Escaneo Rápido" -ForegroundColor Gray
        Write-Host "    ├─ [C] Escaneo Completo" -ForegroundColor Gray
        Write-Host "    ├─ [U] Actualizar Definiciones" -ForegroundColor Gray
        Write-Host "    └─ [V] Ver Amenazas Encontradas" -ForegroundColor Gray
        Write-Host " ⚠️ [4] DESACTIVAR DEFENDER (NO RECOMENDADO)" -ForegroundColor Red
        Write-Host ""
        Write-Host " ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $o = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","R","C","U","V","X")
        if(-not $o){ continue }
        if($o -eq "X"){break}
        
        # ========== OPCIÓN 1: ACTIVAR DEFENDER ==========
        if($o -eq "1"){
            if(-not (Require-Admin "activar Defender")){ continue }
            if(-not (Confirm-Critical "ACTIVAR WINDOWS DEFENDER" "APLICAR")){ continue }
            
            Write-Host "`n [+] Activando Windows Defender..." -ForegroundColor $COLOR_PRIMARY
            
            # Método silencioso usando script temporal
            $tempScript = "$env:TEMP\defender_activate.ps1"
            @"
# Activación silenciosa de Defender
`$mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
if (`$mp) {
    try {
        Set-MpPreference -DisableRealtimeMonitoring `$false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring `$false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBlockAtFirstSeen `$false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection `$false -ErrorAction SilentlyContinue
        Write-Host "Defender reactivado exitosamente"
    } catch {
        Write-Host "Error al reactivar Defender"
    }
}
"@ | Out-File -FilePath $tempScript -Encoding ascii
            
            & powershell -NoProfile -ExecutionPolicy Bypass -File $tempScript -WindowStyle Hidden
            Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
            
            Write-Host " ✅ DEFENDER ACTIVADO" -ForegroundColor Green
            Write-Log "DEFENDER" "Defender activated"
            Pause-Enter " ENTER"
        }
        
        # ========== OPCIÓN 2: REPARAR DEFENDER ==========
        if($o -eq "2"){
            Repair-Defender
        }
        
        # ========== OPCIÓN 3: SUBMENÚ DE ESCANEO ==========
        if($o -eq "3"){
            while($true){
                Clear-Host
                Show-MainTitle
                Write-Host "`n 🦠 ESCANEO DE MALWARE - WINDOWS DEFENDER" -ForegroundColor $COLOR_MENU
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host ""
                Write-Host " 🔍 [R] ESCANEO RÁPIDO (recomendado, 5-10 min)"
                Write-Host " 🔍 [C] ESCANEO COMPLETO (puede tardar horas)"
                Write-Host " 🔄 [U] ACTUALIZAR DEFINICIONES"
                Write-Host " 📋 [V] VER AMENAZAS ENCONTRADAS"
                Write-Host "`n ❌ [X] VOLVER AL MENÚ ANTERIOR"
                
                $scanOpt = Read-MenuOption "`n > SELECCIONE" -Valid @("R","C","U","V","X")
                if ($scanOpt -eq "X") { break }
                
                $mpcmdrun = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
                
                if (-not (Test-Path $mpcmdrun)) {
                    Write-Host "`n ❌ WINDOWS DEFENDER NO ESTÁ INSTALADO" -ForegroundColor Red
                    Write-Host "    Versión MODIFICADA o LITE de Windows" -ForegroundColor Yellow
                    Write-Host "    Usa el menú I (KIT POST FORMAT) para instalar Malwarebytes" -ForegroundColor Cyan
                    Pause-Enter " ENTER"
                    continue
                }
                
                switch ($scanOpt) {
                    "R" {
                        Write-Host "`n [+] Escaneo rápido en progreso..." -ForegroundColor Yellow
                        Start-Process -FilePath $mpcmdrun -ArgumentList "-Scan -ScanType 1" -NoNewWindow -Wait
                        Write-Host "`n ✅ Escaneo completado" -ForegroundColor Green
                        Pause-Enter " ENTER"
                    }
                    "C" {
                        Write-Host "`n [!] ADVERTENCIA: Escaneo completo puede tardar HORAS" -ForegroundColor Red
                        $confirm = Read-MenuOption " ¿REALMENTE DESEAS CONTINUAR? (S/N)" -Valid @("S","N")
                        if ($confirm -ne "S") { continue }
                        Write-Host "`n [+] Escaneo completo en progreso..." -ForegroundColor Yellow
                        Start-Process -FilePath $mpcmdrun -ArgumentList "-Scan -ScanType 2" -NoNewWindow -Wait
                        Write-Host "`n ✅ Escaneo completado" -ForegroundColor Green
                        Pause-Enter " ENTER"
                    }
                    "U" {
                        Write-Host "`n [+] Actualizando definiciones..." -ForegroundColor Yellow
                        Start-Process -FilePath $mpcmdrun -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait
                        Write-Host "`n ✅ Definiciones actualizadas" -ForegroundColor Green
                        Pause-Enter " ENTER"
                    }
                    "V" {
                        Write-Host "`n [+] AMENAZAS ENCONTRADAS EN EL HISTORIAL:" -ForegroundColor Yellow
                        Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
                        $threats = Get-MpThreat -ErrorAction SilentlyContinue
                        if ($threats -and $threats.Count -gt 0) {
                            $threats | Format-Table -AutoSize ThreatID, Name, Severity, Status
                        } else {
                            Write-Host "    ✅ No hay amenazas en el historial" -ForegroundColor Green
                        }
                        Pause-Enter " ENTER"
                    }
                }
            }
        }
        
        # ========== OPCIÓN 4: DESACTIVAR DEFENDER (PELIGROSO) ==========
        if($o -eq "4"){
            if(-not (Require-Admin "desactivar Defender")){ continue }
            
            Write-Host "`n ⚠️ ⚠️ ⚠️ ADVERTENCIA EXTREMA ⚠️ ⚠️ ⚠️" -ForegroundColor Red
            Write-Host " DESACTIVAR WINDOWS DEFENDER DEJA TU EQUIPO VULNERABLE A:" -ForegroundColor Yellow
            Write-Host "    • Ransomware (secuestro de archivos)" -ForegroundColor Red
            Write-Host "    • Troyanos bancarios" -ForegroundColor Red
            Write-Host "    • Keyloggers (robo de contraseñas)" -ForegroundColor Red
            Write-Host "    • Spyware (espionaje)" -ForegroundColor Red
            Write-Host ""
            Write-Host " SOLO RECOMENDADO PARA PRUEBAS O POR OTRO ANTIVIRUS INSTALADO" -ForegroundColor Yellow
            
            $confirm = Read-MenuOption "`n ¿REALMENTE DESEAS CONTINUAR? (S/N)" -Valid @("S","N")
            if ($confirm -ne "S") { continue }
            
            if(-not (Confirm-Critical "DESACTIVAR WINDOWS DEFENDER PERMANENTEMENTE" "DESACTIVAR")){ continue }
            
            Write-Host "`n [+] Desactivando Windows Defender..." -ForegroundColor Red
            
            # Método más extremo (solo para este caso)
            $tempScript = "$env:TEMP\defender_disable.ps1"
            @"
# Desactivación de Defender (USO BAJO PROPIA RESPONSABILIDAD)
try {
    Set-MpPreference -DisableRealtimeMonitoring `$true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring `$true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen `$true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection `$true -ErrorAction SilentlyContinue
    Set-MpPreference -DisablePrivacyMode `$true -ErrorAction SilentlyContinue
    Write-Host "Defender desactivado"
} catch {
    Write-Host "Error al desactivar Defender"
}
"@ | Out-File -FilePath $tempScript -Encoding ascii
            
            & powershell -NoProfile -ExecutionPolicy Bypass -File $tempScript -WindowStyle Hidden
            Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
            
            # También políticas de registro para mayor seguridad (bloqueo total)
            $policiesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
            if (-not (Test-Path $policiesPath)) { New-Item $policiesPath -Force | Out-Null }
            Set-ItemProperty -Path $policiesPath -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
            
            Write-Host " ✅ DEFENDER DESACTIVADO" -ForegroundColor Red
            Write-Host " ⚠️ REINICIA EL EQUIPO PARA APLICAR CAMBIOS" -ForegroundColor Yellow
            Write-Log "DEFENDER" "Defender DISABLED (user confirmed critical operation)"
            Pause-Enter " ENTER"
        }
        
        # ========== OPCIONES DIRECTAS DEL SUBMENÚ (R,C,U,V) ==========
        if($o -in @("R","C","U","V")){
            $mpcmdrun = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
            
            if (-not (Test-Path $mpcmdrun)) {
                Write-Host "`n ❌ WINDOWS DEFENDER NO ESTÁ INSTALADO" -ForegroundColor Red
                Pause-Enter " ENTER"
                continue
            }
            
            switch ($o) {
                "R" {
                    Write-Host "`n [+] Escaneo rápido en progreso..." -ForegroundColor Yellow
                    Start-Process -FilePath $mpcmdrun -ArgumentList "-Scan -ScanType 1" -NoNewWindow -Wait
                    Write-Host "`n ✅ Escaneo completado" -ForegroundColor Green
                    Pause-Enter " ENTER"
                }
                "C" {
                    Write-Host "`n [!] ADVERTENCIA: Escaneo completo puede tardar HORAS" -ForegroundColor Red
                    $confirm = Read-MenuOption " ¿REALMENTE DESEAS CONTINUAR? (S/N)" -Valid @("S","N")
                    if ($confirm -ne "S") { continue }
                    Write-Host "`n [+] Escaneo completo en progreso..." -ForegroundColor Yellow
                    Start-Process -FilePath $mpcmdrun -ArgumentList "-Scan -ScanType 2" -NoNewWindow -Wait
                    Write-Host "`n ✅ Escaneo completado" -ForegroundColor Green
                    Pause-Enter " ENTER"
                }
                "U" {
                    Write-Host "`n [+] Actualizando definiciones..." -ForegroundColor Yellow
                    Start-Process -FilePath $mpcmdrun -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait
                    Write-Host "`n ✅ Definiciones actualizadas" -ForegroundColor Green
                    Pause-Enter " ENTER"
                }
                "V" {
                    Write-Host "`n [+] AMENAZAS ENCONTRADAS:" -ForegroundColor Yellow
                    Get-MpThreat | Format-Table -AutoSize
                    Pause-Enter " ENTER"
                }
            }
        }
    }
}

# ============================================================
# PERFIL DE MANTENIMIENTO AUTOMATIZADO (EXPRESS)
# ============================================================
function Invoke-AutoFlow {
	Clear-Host #nuevo
    Show-MainTitle
Write-Host ([Environment]::NewLine + ' 🚀 [!] PERFIL: MANTENIMIENTO EXPRESS (AUTO-FLOW)') -ForegroundColor $COLOR_ALERT
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray
    Write-Host " 📝 DESCRIPCION:" -ForegroundColor $COLOR_MENU
    Write-Host ' 🧹 1. Elimina Apps basura (Netflix, Disney, etc.)'
    Write-Host " 🗑️ 2. Limpia archivos temporales del sistema."
Write-Host " 📦 3. Instala Apps (Chrome, 7-Zip, VLC, Sumatra, WinRAR, WhatsApp, VCRedist)"
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray
    
    Write-Host "`n ▶️ [ENTER] COMENZAR INSTALACION" -ForegroundColor $COLOR_PRIMARY
    Write-Host " ❌ [X]     VOLVER AL MENU PRINCIPAL" -ForegroundColor $COLOR_DANGER
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray

    # ============================================================
# MOTOR DE DETECCION DE TECLAS (X o ENTER)
# ============================================================
    $Decision = $null
    while ($true) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $TeclaPresionada = $KeyInfo.Character.ToString().ToUpper()
            $CodigoASCII = [int]$KeyInfo.Character

            if ($TeclaPresionada -eq "X") { $Decision = "SALIR"; break }
            if ($CodigoASCII -eq 13) { $Decision = "INICIAR"; break } # 13 es ENTER
        }
        Start-Sleep -Milliseconds 100
    }

    # ============================================================
# LOGICA DE SALIDA
# ============================================================
if ($Decision -eq "SALIR") {
        Write-Host "`n [X] REGRESANDO AL MENU..." -ForegroundColor $COLOR_ALERT
        Start-Sleep -Seconds 1
        Clear-Host
        Show-MainTitle
        return
    }

    Write-Host "`n [>] INICIANDO OPERACIONES..." -ForegroundColor $COLOR_PRIMARY
    Start-Sleep -Seconds 1

    # Función para abortar DURANTE el proceso (Si dejas presionada X)
    $CheckAbort = {
        if ($Host.UI.RawUI.KeyAvailable) {
            $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($k.Character -eq 'x' -or $k.Character -eq 'X') {
                Write-Host "`n`n [XXX] DETENIDO POR EL USUARIO." -ForegroundColor $COLOR_DANGER
                Start-Sleep -Seconds 1
                return $true
            }
        }
        return $false
    }

    # ============================================================
# PASO 1: BLOATWARE
# ============================================================
Write-Host "`n [>] Eliminando Bloatware..." -ForegroundColor $COLOR_MENU
    $bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*")
    foreach($b in $bloat){ 
        if (& $CheckAbort) { return }
        Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue 
    }
    
    # ============================================================
# PASO 2: TEMPORALES
# ============================================================
    if (& $CheckAbort) { return }
Write-Host "`n[>] Limpiando sistema..." -ForegroundColor $COLOR_PROCESO
    Start-Sleep -Seconds 1
    $targets = @("$env:TEMP\*", "C:\Windows\Temp\*")
    $targets | ForEach-Object { 
        if (& $CheckAbort) { return }
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue 
    }

    # ============================================================
# PASO 3: INSTALACION
# ============================================================
    if (& $CheckAbort) { return }
Write-Host "[>] Instalando Apps..." -ForegroundColor $COLOR_MENU
$basico = @(
        @{Name="Google Chrome"; ID="Google.Chrome"},
        @{Name="Sumatra PDF"; ID="SumatraPDF.SumatraPDF"},
        @{Name="WinRAR"; ID="RARLab.WinRAR"},
        @{Name="7-Zip"; ID="7zip.7zip"},
        @{Name="VLC Media Player"; ID="VideoLAN.VLC"},
        @{Name="WhatsApp Desktop"; ID="WhatsApp.WhatsApp"},
        @{Name="Microsoft VCRedist"; ID="Microsoft.VCRedist"}
    )
    foreach($app in $basico){
        if (& $CheckAbort) { return }
        Invoke-SmartInstall -AppID $app.ID -AppName $app.Name | Out-Null
    }

    Write-Host "`n [OK] AUTO-FLOW FINALIZADO." -ForegroundColor Green
    Read-Host " PRESIONE ENTER PARA VOLVER"
}

# ============================================================
# GESTION DE DRIVERS MEJORADA (OFICIAL MS)
# ============================================================
function Invoke-DriverManagement {
    while($true){ 
        Show-MainTitle
		Write-Host "`n 🔧 GESTION DE DRIVERS PRO" -ForegroundColor $COLOR_MENU
        Write-Host ' 💾 [A] EXPORTAR DRIVERS (BACKUP LOCAL EN USB/SCRIPT)'
        Write-Host ' 🔄 [B] RE-INSTALAR DRIVERS (DESDE BACKUP)'
        Write-Host ' 🔍 [C] BUSCAR EN SERVIDORES OFICIALES (WINDOWS UPDATE)'
        Write-Host ' 🆔 [D] VER IDENTIFICADORES DE HARDWARE (SIN DRIVER)'
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
      
        $o = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","X")
        if($o -eq "X"){break}
        
        if($o -eq "A") {
            if(-not (Require-Admin "exportar drivers")){ continue }
            $p="$PSScriptRoot\Drivers_$env:COMPUTERNAME"
            if(!(Test-Path $p)){ New-Item $p -ItemType Directory -Force | Out-Null }
            Write-Host " [+] Exportando drivers instalados... esto puede tardar." -ForegroundColor $COLOR_MENU
            Export-WindowsDriver -Online -Destination $p
            Write-Log "DRIVER" "Export drivers to $p"
            Pause-Enter " [+] BACKOP CREADO EN: $p. ENTER PARA VOLVER"
        }

        if($o -eq "B") {
            if(-not (Require-Admin "instalar drivers")){ continue }
            $path = "$PSScriptRoot\Drivers_$env:COMPUTERNAME"
            if(Test-Path $path){
                Write-Host " [+] Re-instalando drivers desde BACKOP..." -ForegroundColor $COLOR_PRIMARY
                $infs = Get-ChildItem "$path\*.inf" -Recurse -ErrorAction SilentlyContinue
                $count = if($infs){$infs.Count}else{0}
                Write-Host " [+] INF encontrados: $count" -ForegroundColor $COLOR_MENU
                if($count -gt 0){
                    Write-Host "`n TOP 10 INF:" -ForegroundColor $COLOR_ALERT
                    $infs | Select-Object -First 10 | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor $COLOR_MENU }
                }
                Write-Log "DRIVER" "Reinstall from $path INFCount=$count"
                foreach($inf in $infs){
                    $out = pnputil /add-driver $inf.FullName /install 2>&1
                    $exit = $LASTEXITCODE
                    Write-Log "DRIVER" ("pnputil exit={0} inf={1}" -f $exit, $inf.FullName)
                }
                Pause-Enter " [+] PROCESO TERMINADO. ENTER"
            } else { 
                Write-Host " [!] NO SE ENCONTRO CARPETA DE BACKOP." -ForegroundColor $COLOR_DANGER
                Start-Sleep -Seconds 2 
            }
        }

        if($o -eq "C") {
            if(-not (Require-Admin "buscar drivers en Windows Update")){ continue }
            Write-Host "`n [+] CONFIGURANDO ENTORNO SEGURO..." -ForegroundColor Gray
# ============================================================
# MEJORA CRITICA: Bypass de confirmaciones y protocolos
# ============================================================
Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            
            Write-Host " 🔌 [+] CONECTANDO CON MICROSOFT UPDATE..." -ForegroundColor $COLOR_PRIMARY
            
            if(!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)){
                Write-Host " 📦 [+] Instalando proveedor NuGet..." -ForegroundColor Gray
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
            }
            
            if(!(Get-Module -ListAvailable PSWindowsUpdate)){
                Write-Host " 📥 [+] Instalando módulo PSWindowsUpdate..." -ForegroundColor Gray
                Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser | Out-Null
            }
            
            Import-Module PSWindowsUpdate
            Write-Host " 🔍 [+] Buscando e instalando controladores certificados..." -ForegroundColor $COLOR_MENU
            
            # El comando clave: Solo baja Categoría "Drivers" (ignora parches de seguridad pesados)
            $wuOut = Get-WindowsUpdate -Category "Drivers" -Install -AcceptAll -IgnoreReboot 2>&1
            $needsReboot = ($wuOut | Out-String) -match "reboot|reiniciar|restart"
            Write-Log "DRIVER" ("WindowsUpdate Drivers finished NeedsReboot={0}" -f $needsReboot)
            
            Write-Host "`n ✅ [OK] BUSQUEDA Y CARGA FINALIZADA." -ForegroundColor Green
            if($needsReboot){ Write-Host " ⚠️ [!] Puede requerir reinicio." -ForegroundColor $COLOR_ALERT }
            Pause-Enter " ↩️ ENTER PARA VOLVER"
        }

        if($o -eq "D") {
            Show-MainTitle
            Write-Host "`n [!] DISPOSITIVOS CON ERRORES O SIN DRIVER:" -ForegroundColor $COLOR_ALERT
            $missing = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
            if ($missing) {
                $missing | Select-Object Name, Status, DeviceID | Out-GridView -Title "Drivers Faltantes - TechFlow"
                Write-Host " [+] Se ha abierto una ventana con el listado detallado." -ForegroundColor $COLOR_PRIMARY
            } else {
                Write-Host ' [+] No se detectaron problemas de hardware (Todo OK).' -ForegroundColor Green
            }
            Pause-Enter " ENTER PARA VOLVER"
        }
    }
}

# ============================================================
# ANÁLISIS DE SALUD Y REPORTE DE BATERÍA
# ============================================================
function Show-BatteryHealth {
	Clear-Host #nuevo	
    Show-MainTitle
    Write-Host "`n ===== SALUD DE BATERÍA =====`n" -ForegroundColor Cyan
    
    # Verificar si hay batería
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if (-not $battery) {
        Write-Host " [!] No se detectó ninguna batería en este equipo." -ForegroundColor $COLOR_DANGER
        Write-Host "     (Equipo de escritorio o batería no compatible)" -ForegroundColor $COLOR_ALERT
        Pause-Enter " ENTER"
        return
    }
    
    # Mostrar información básica
    $charge = if ($battery.EstimatedChargeRemaining) { "$($battery.EstimatedChargeRemaining)%" } else { "N/A" }
    $status = switch ($battery.BatteryStatus) {
        1 { "Otra" }
        2 { "Desconocido" }
        3 { "Cargando completamente" }
        4 { "Carga baja" }
        5 { "Cargando" }
        6 { "Nivel crítico" }
        7 { "Cargando (alta)" }
        8 { "Cargando (tiempo limitado)" }
        9 { "Carga activa" }
        10 { "No cargando" }
        default { "Desconocido ($($battery.BatteryStatus))" }
    }
    
    Write-Host " ESTADO ACTUAL:" -ForegroundColor $COLOR_PRIMARY
    Write-Host "   Estado   : $status" -ForegroundColor $COLOR_MENU
    Write-Host "   Carga    : $charge" -ForegroundColor $COLOR_MENU
    
    # Intentar obtener capacidad de diseño y actual
    $design = $battery.DesignCapacity
    $full = $battery.FullChargeCapacity
    if ($design -and $full -and $design -gt 0) {
        $health = [math]::Round(($full / $design) * 100, 1)
        Write-Host "   Salud    : $health% (Cap. actual: $full mAh / Diseño: $design mAh)" -ForegroundColor $(if ($health -lt 50) { $COLOR_DANGER } else { $COLOR_PRIMARY })
    } else {
        Write-Host "   Salud    : No disponible (usa el reporte HTML para más detalles)" -ForegroundColor $COLOR_ALERT
    }
    
    # Generar reporte HTML en una ubicación SEGURA (primero en TEMP)
    $tempDir = $env:TEMP
    if (-not $tempDir) { $tempDir = "C:\Windows\Temp" }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $tempHtml = Join-Path $tempDir "BatteryReport_$timestamp.html"
    
    Write-Host "`n [+] Generando reporte detallado..." -ForegroundColor $COLOR_ALERT
    try {
        # Ejecutar powercfg y guardar en TEMP
        powercfg /batteryreport /output "$tempHtml" 2>&1 | Out-Null
        
        if (Test-Path $tempHtml) {
            # Intentar mover al escritorio (si es posible)
            $desktop = [Environment]::GetFolderPath("Desktop")
            if ($desktop -and (Test-Path $desktop)) {
                $finalReport = Join-Path $desktop "BatteryReport_$timestamp.html"
                Move-Item -Path $tempHtml -Destination $finalReport -Force -ErrorAction SilentlyContinue
                Write-Host " [✔] Reporte guardado en: $finalReport" -ForegroundColor Green
                $open = Read-Host "`n ¿Abrir el reporte HTML en el navegador? (S/N)"
                if ($open -eq "S") { Start-Process $finalReport }
            } else {
                # Si no hay escritorio, dejar en TEMP
                Write-Host " [✔] Reporte guardado en: $tempHtml" -ForegroundColor Green
                $open = Read-Host "`n ¿Abrir el reporte HTML en el navegador? (S/N)"
                if ($open -eq "S") { Start-Process $tempHtml }
            }
        } else {
            Write-Host " [✘] No se pudo generar el reporte. Intenta ejecutar PowerShell como administrador." -ForegroundColor $COLOR_DANGER
        }
    } catch {
        Write-Host " [✘] Error al generar el reporte: $($_.Exception.Message)" -ForegroundColor $COLOR_DANGER
    }
    
    Pause-Enter "`n ENTER"
}


# ============================================================
# TEMPERATURAS CPU/GPU (Monitoreo en tiempo real)
# ============================================================
function Show-Temperatures {
    Clear-Host
    Show-MainTitle
    
    Write-Host "`n 🌡️ TEMPERATURAS DEL SISTEMA" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    
    # Temperaturas de la CPU (WMI)
    Write-Host "`n 🔥 CPU:" -ForegroundColor $COLOR_PRIMARY
    try {
        $temps = Get-CimInstance -Namespace root/WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($temps) {
            foreach ($temp in $temps) {
                $celsius = [math]::Round(($temp.CurrentTemperature - 2732) / 10, 1)
                $nombre = if ($temp.InstanceName) { $temp.InstanceName } else { "Sensor CPU" }
                
                # Color según temperatura
                $color = if ($celsius -lt 50) { "Green" } 
                         elseif ($celsius -lt 70) { "Yellow" } 
                         else { "Red" }
                
                Write-Host "    🌡️ $nombre : $celsius °C" -ForegroundColor $color
            }
        } else {
            Write-Host "    ⚠️ No se detectaron sensores de temperatura" -ForegroundColor $COLOR_DANGER
            Write-Host "    (Puede que tu hardware no lo soporte)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    ❌ Error al leer temperatura CPU" -ForegroundColor $COLOR_DANGER
    }
    
    # Temperatura de discos (SMART)
    Write-Host "`n 💾 DISCOS (Salud):" -ForegroundColor $COLOR_PRIMARY
    try {
        $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        if ($disks) {
            foreach ($disk in $disks) {
                $healthColor = if ($disk.HealthStatus -eq 'Healthy') { "Green" } else { "Red" }
                Write-Host "    💿 $($disk.FriendlyName)" -ForegroundColor Gray
                Write-Host "       📊 Salud: $($disk.HealthStatus)" -ForegroundColor $healthColor
                Write-Host "       📦 Tipo: $($disk.MediaType)" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "    ⚠️ No se pudo leer información de discos" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "    ❌ Error al leer discos" -ForegroundColor DarkGray
    }
    
    Write-Host "`n ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host " 💡 RECOMENDACIONES:" -ForegroundColor $COLOR_ALERT
    Write-Host "    - Temperatura normal CPU: 30-50°C (reposo) / 50-70°C (carga)"
    Write-Host "    - Temperatura normal GPU: 35-60°C (reposo) / 60-85°C (carga)"
    Write-Host "    - Más de 90°C puede indicar problemas de refrigeración"
    Write-Host "    - Si no ves temperaturas, tu hardware no tiene sensores compatibles"
    
    Pause-Enter "`n ENTER para volver"
}

# ============================================================
# ESCANEO DE MALWARE - WINDOWS DEFENDER
# ============================================================
function Invoke-DefenderScan {
    Clear-Host
    Show-MainTitle
    
    Write-Host "`n 🦠 ESCANEO DE MALWARE - WINDOWS DEFENDER" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host ""
	Write-Host " ⚡ [1] ESCANEO RÁPIDO (recomendado)"
    Write-Host " 🔍 [2] ESCANEO COMPLETO (puede tardar horas)"
    Write-Host " 🦠 [3] VER AMENAZAS ENCONTRADAS"
    Write-Host " 🔄 [4] ACTUALIZAR DEFINICIONES"
    Write-Host "`n ❌ [X] VOLVER"
    
    $opt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","X")
    if ($opt -eq "X") { return }
    
    switch ($opt) {
        "1" {
            Write-Host "`n[+] Escaneo rápido en progreso..." -ForegroundColor Yellow
            Start-Process -FilePath "mpcmdrun.exe" -ArgumentList "-Scan -ScanType 1" -NoNewWindow -Wait
            Write-Host "`n ✅ Escaneo completado" -ForegroundColor Green
        }
        "2" {
            Write-Host "`n[!] Escaneo completo puede tardar HORAS" -ForegroundColor Red
            $confirm = Read-Host "¿Continuar? (S/N)"
            if ($confirm -ne "S") { return }
            Write-Host "[+] Escaneo completo en progreso..." -ForegroundColor Yellow
            Start-Process -FilePath "mpcmdrun.exe" -ArgumentList "-Scan -ScanType 2" -NoNewWindow -Wait
            Write-Host "`n ✅ Escaneo completado" -ForegroundColor Green
        }
        "3" {
            Write-Host "`n[+] Amenazas encontradas:" -ForegroundColor Yellow
            Get-MpThreat | Format-Table -AutoSize
        }
        "4" {
            Write-Host "`n[+] Actualizando definiciones..." -ForegroundColor Yellow
            Start-Process -FilePath "mpcmdrun.exe" -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait
            Write-Host "`n ✅ Definiciones actualizadas" -ForegroundColor Green
        }
    }
    Pause-Enter " ENTER"
}

# ============================================================
# GENERADOR DE CONTRASEÑAS SEGURAS
# ============================================================
function Invoke-PasswordGenerator {
    [Console]::Clear()
    Show-MainTitle
    
    Write-Host "`n GENERADOR DE CONTRASEÑAS SEGURAS" -ForegroundColor $COLOR_MENU
    Write-Host " -----------------------------------------------------------------------------"
    
    # Opciones por defecto
    $longitud = 16
    $usarMayusculas = $true
    $usarMinusculas = $true
    $usarNumeros = $true
    $usarSimbolos = $true
    $cantidad = 5
    
    while ($true) {
        [Console]::Clear()
        Show-MainTitle
		Write-Host "`n 🔐 GENERADOR DE CONTRASEÑAS SEGURAS" -ForegroundColor $COLOR_MENU
        Write-Host " -----------------------------------------------------------------------------"
        Write-Host " ⚙️ CONFIGURACIÓN ACTUAL:" -ForegroundColor $COLOR_ALERT
        Write-Host "   🔢 [1] Longitud: $longitud caracteres"
        Write-Host "   🔠 [2] Mayúsculas (A-Z): $(if($usarMayusculas){'✅ Activado'}else{'❌ Desactivado'})"
        Write-Host "   🔡 [3] Minúsculas (a-z): $(if($usarMinusculas){'✅ Activado'}else{'❌ Desactivado'})"
        Write-Host "   🔢 [4] Números (0-9): $(if($usarNumeros){'✅ Activado'}else{'❌ Desactivado'})"
        Write-Host "   ✨ [5] Símbolos (!@#$%^&*): $(if($usarSimbolos){'✅ Activado'}else{'❌ Desactivado'})"
        Write-Host "   🔢 [6] Cantidad a generar: $cantidad"
        Write-Host ""
        Write-Host " 🎯 ACCIONES:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   🔑 [G] GENERAR CONTRASEÑAS"
        Write-Host "   📋 [C] COPIAR AL PORTAPAPELES (la primera contraseña)"
        Write-Host ""
        Write-Host " ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------"
        Write-Host "   ❌ [X] VOLVER AL MENÚ PRINCIPAL"
        
        $opt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","5","6","G","C","X")
        
        if ($opt -eq "X") { break }
        
        switch ($opt) {
            "1" {
                $nuevaLong = Read-Host " LONGITUD (8-64, recomendado 16)"
                if ($nuevaLong -match "^\d+$" -and [int]$nuevaLong -ge 8 -and [int]$nuevaLong -le 64) {
                    $longitud = [int]$nuevaLong
                } else {
                    Write-Host " [!] Longitud inválida. Usando $longitud" -ForegroundColor $COLOR_DANGER
                    Start-Sleep -Seconds 1
                }
            }
            "2" { $usarMayusculas = -not $usarMayusculas }
            "3" { $usarMinusculas = -not $usarMinusculas }
            "4" { $usarNumeros = -not $usarNumeros }
            "5" { $usarSimbolos = -not $usarSimbolos }
            "6" {
                $nuevaCant = Read-Host " CANTIDAD (1-20)"
                if ($nuevaCant -match "^\d+$" -and [int]$nuevaCant -ge 1 -and [int]$nuevaCant -le 20) {
                    $cantidad = [int]$nuevaCant
                } else {
                    Write-Host " [!] Cantidad inválida. Usando $cantidad" -ForegroundColor $COLOR_DANGER
                    Start-Sleep -Seconds 1
                }
            }
            "G" {
                # Validar que al menos un tipo de caracter esté activado
                if (-not ($usarMayusculas -or $usarMinusculas -or $usarNumeros -or $usarSimbolos)) {
                    Write-Host "`n [!] ERROR: Debes activar al menos un tipo de caracter!" -ForegroundColor $COLOR_DANGER
                    Start-Sleep -Seconds 2
                    continue
                }
                
                [Console]::Clear()
                Show-MainTitle
                Write-Host "`n CONTRASEÑAS GENERADAS:" -ForegroundColor $COLOR_PRIMARY
                Write-Host " -----------------------------------------------------------------------------"
                
                $contrasenas = @()
                $caracteres = ""
                
                if ($usarMayusculas) { $caracteres += "ABCDEFGHJKLMNPQRSTUVWXYZ" }  # Excluí I, O por confusión
                if ($usarMinusculas) { $caracteres += "abcdefghijkmnpqrstuvwxyz" }  # Excluí l, o
                if ($usarNumeros) { $caracteres += "23456789" }  # Excluí 0,1 por confusión
                if ($usarSimbolos) { $caracteres += "!@#$%^&*()_+-=[]{}|;:,.<>?" }
                
                $charsArray = $caracteres.ToCharArray()
                $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
                $bytes = New-Object byte[] 4
                
                for ($i = 1; $i -le $cantidad; $i++) {
                    $password = ""
                    for ($j = 0; $j -lt $longitud; $j++) {
                        $rng.GetBytes($bytes)
                        $randomIndex = [BitConverter]::ToUInt32($bytes, 0) % $charsArray.Length
                        $password += $charsArray[$randomIndex]
                    }
                    $contrasenas += $password
                    
                    # Mostrar con formato
                    $numStr = $i.ToString().PadRight(3)
                    Write-Host " [$numStr] $password" -ForegroundColor $COLOR_MENU
                }
                
                Write-Host "`n -----------------------------------------------------------------------------"
                Write-Host " 💡 RECOMENDACIONES:" -ForegroundColor $COLOR_ALERT
                Write-Host "    - Usa contraseñas de al menos 12 caracteres"
                Write-Host "    - Combina mayúsculas, minúsculas, números y símbolos"
                Write-Host "    - No uses la misma contraseña en múltiples sitios"
                
                # Guardar para la opción de copiar
                $script:ultimaPassword = $contrasenas[0]
                $script:ultimasPasswords = $contrasenas
                
                Write-Host "`n Presiona ENTER para volver al menú..." -ForegroundColor $COLOR_ALERT
                $null = Read-Host
            }
            "C" {
                if ($script:ultimaPassword) {
                    try {
                        Set-Clipboard -Value $script:ultimaPassword
                        Write-Host "`n ✅ CONTRASEÑA COPIADA AL PORTAPAPELES: $script:ultimaPassword" -ForegroundColor Green
                        Write-Host "    (Pega con Ctrl+V)"
                    } catch {
                        Write-Host "`n ❌ No se pudo copiar al portapapeles" -ForegroundColor $COLOR_DANGER
                    }
                } else {
                    Write-Host "`n [!] Primero debes generar contraseñas (opción G)" -ForegroundColor $COLOR_ALERT
                }
                Start-Sleep -Seconds 2
            }
        }
    }
}

# ============================================================
# GENERACIÓN DE INFORME TÉCNICO DE HARDWARE
# ============================================================
function Show-FullSystemInfo {
	Clear-Host #nuevo
    Show-MainTitle
    Write-Host "`n ===== INFORME TÉCNICO COMPLETO =====`n" -ForegroundColor Cyan
    Write-Host " GENERANDO INFORMACIÓN, ESPERE..." -ForegroundColor Yellow
    Write-Log "INFO" "Show-FullSystemInfo iniciado"

    $output = @()
    $computerName = $env:COMPUTERNAME
    $output += "EQUIPO: $computerName"
    
    $cs = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
    $model = if ($cs) { $cs.Name } else { "No disponible" }
    $serial = if ($cs) { $cs.IdentifyingNumber } else { "No disponible" }
    $output += "MODELO: $model"
    $output += "SERIE: $serial"

    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    if ($cpu) {
        $cpuName = $cpu.Name.Trim()
        $cores = $cpu.NumberOfCores
        $logical = $cpu.NumberOfLogicalProcessors
        $output += "PROCESADOR: $cpuName"
        $output += "  > Núcleos físicos: $cores | Lógicos: $logical"
    } else {
        $output += "PROCESADOR: No disponible"
    }

    $physMem = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
    $totalInstalledGB = if ($physMem) { [math]::Round(($physMem | Measure-Object Capacity -Sum).Sum / 1GB, 2) } else { 0 }
    $memArray = Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction SilentlyContinue
    $maxCapacityGB = if ($memArray -and $memArray.MaxCapacity) { [math]::Round($memArray.MaxCapacity / 1MB, 0) } else { "No disponible" }
    $output += "MEMORIA RAM INSTALADA: ${totalInstalledGB} GB"
    $output += "SOPORTE MÁXIMO PLACA: ${maxCapacityGB} GB"

    $mb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
    $mbProduct = if ($mb) { $mb.Product } else { "No disponible" }
    $mbManufacturer = if ($mb) { $mb.Manufacturer } else { "No disponible" }
    $output += "PLACA BASE: $mbProduct ($mbManufacturer)"

    $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Remote*" -and $_.Name -notlike "*Mirror*" }
    if ($gpus) {
        $output += "TARJETA(S) GRÁFICA(S):"
        foreach ($gpu in $gpus) {
            $gpuName = $gpu.Name.Trim()
            $vram = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { "?" }
            $output += "  - $gpuName (VRAM: ${vram} GB)"
        }
    } else {
        $output += "TARJETA GRÁFICA: No disponible"
    }

    $output += "`n--- ALMACENAMIENTO ---"
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    if ($disks) {
        foreach ($disk in $disks) {
            $friendly = $disk.FriendlyName
            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            $mediaType = $disk.MediaType
            $busType = $disk.BusType
            $health = $disk.HealthStatus
            $healthColor = if ($health -eq 'Healthy') { "BUENO" } else { $health }
            $output += "UNIDAD: $friendly [$mediaType, $busType]"
            $output += "  > CAPACIDAD: ${sizeGB} GB"
            $output += "  > SALUD: $healthColor"
        }
    } else {
        $output += "No se pudo obtener información de discos."
    }

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        $caption = $os.Caption
        $version = $os.Version
        $build = $os.BuildNumber
        $output += "`n--- SISTEMA OPERATIVO ---"
        $output += "EDICIÓN: $caption"
        $output += "VERSIÓN: $version (Build $build)"
    } else {
        $output += "SISTEMA OPERATIVO: No disponible"
    }

    Clear-Host
    Show-MainTitle
    Write-Host "`n ===== INFORME TÉCNICO COMPLETO =====`n" -ForegroundColor Cyan
    foreach ($line in $output) {
        if ($line -match "^EQUIPO|^MODELO|^SERIE|^PROCESADOR|^MEMORIA|^SOPORTE|^PLACA|^TARJETA|^UNIDAD|^EDICIÓN|^VERSIÓN") {
            Write-Host $line -ForegroundColor Green
        } elseif ($line -match "^  >") {
            Write-Host $line -ForegroundColor Yellow
        } elseif ($line -match "^---") {
            Write-Host $line -ForegroundColor Cyan
        } else {
            Write-Host $line
        }
    }

    $save = Read-Host "`n ¿Guardar informe en archivo de texto? (S/N)"
    if ($save -eq "S") {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path $PSScriptRoot "TechFlow_SystemInfo_$timestamp.txt"
        $output | Out-File -FilePath $reportFile -Encoding utf8
        Write-Host "`n [+] Informe guardado en: $reportFile" -ForegroundColor Green
        Write-Log "INFO" "System info saved to $reportFile"
    }
    Write-Log "INFO" "Show-FullSystemInfo finalizado"
    Pause-Enter "`n PRESIONE ENTER PARA CONTINUAR"
}

# ============================================================
# PROCESOS Y HANDLES (INTEGRACIÓN CON SYSINTERNALS)
# ============================================================
function Invoke-ProcessExplorer {
	Clear-Host #nuevo
    $arch = if ([Environment]::Is64BitOperatingSystem) { "procexp64.exe" } else { "procexp.exe" }
    $dest = "$PSScriptRoot\$arch"
    if (-not (Test-Path $dest)) {
        Write-Host "`n[+] Descargando Process Explorer desde live.sysinternals.com..." -ForegroundColor $COLOR_PRIMARY
        $url = "https://live.sysinternals.com/$arch"
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
            Write-Host "[✔] Descargado en: $dest" -ForegroundColor Green
        } catch {
            Write-Host "[✘] Error al descargar: $_" -ForegroundColor Red
            Pause-Enter " ENTER"
            return
        }
    }
    Write-Host "[+] Ejecutando Process Explorer (como administrador si es posible)..." -ForegroundColor $COLOR_PRIMARY
    Start-Process $dest -Verb RunAs
}

# ============================================================
# VISUALIZACIÓN DE JERARQUÍA DE PROCESOS (ÁRBOL)
# ============================================================
function Show-ProcessTree {
	Clear-Host #nuevo
    Show-MainTitle
    Write-Host "`n ÁRBOL DE PROCESOS (Jerarquía)" -ForegroundColor $COLOR_MENU
    Write-Host " (PID - Nombre del proceso)" -ForegroundColor Gray
    Write-Host "`n"

    Write-Host "[*] Obteniendo lista de procesos..." -ForegroundColor $COLOR_ALERT
    $allProcs = Get-WmiObject -Class Win32_Process -ErrorAction SilentlyContinue | ForEach-Object {
        [PSCustomObject]@{
            Id = $_.ProcessId
            Name = $_.Name -replace '\.exe$', ''
            ParentId = $_.ParentProcessId
        }
    }
    
    if (-not $allProcs) {
        Write-Host "[!] No se pudo obtener la lista de procesos. Ejecuta como administrador." -ForegroundColor $COLOR_DANGER
        Pause-Enter "`n ENTER"
        return
    }
    
    Write-Host "[*] Construyendo árbol (esto puede tardar unos segundos)..." -ForegroundColor $COLOR_ALERT
    
    # Función recursiva - ¡cambiamos $pid por $parentId!
    function Draw-Tree($parentId, $indent) {
        $children = $allProcs | Where-Object { $_.ParentId -eq $parentId }
        $count = $children.Count
        $i = 0
        foreach ($child in $children) {
            $isLast = ($i -eq $count - 1)
            $prefix = if ($indent -eq 0) { "" } else { if ($isLast) { "└─ " } else { "├─ " } }
            $line = (" " * $indent) + $prefix + "$($child.Name) ($($child.Id))"
            Write-Host $line -ForegroundColor $COLOR_PRIMARY
            # Llamada recursiva con el ID del hijo como nuevo padre
            Draw-Tree $child.Id ($indent + 2)
            $i++
        }
    }
    
    # Dibujar desde el proceso con ParentId = 0 (el sistema)
    Draw-Tree 0 0
    
    Write-Host "`n[+] Nota: Algunos procesos pueden no mostrar su padre si ya terminaron." -ForegroundColor Gray
    Pause-Enter "`n ENTER"
}

# ============================================================
# DETECCIÓN DE PROCESOS QUE BLOQUEAN ARCHIVOS (HANDLE)
# ============================================================
function Get-FileLockingProcess {
	
	Clear-Host #nuevo
    $filePath = Read-Host "`n Ruta completa del archivo o carpeta (ej: C:\Windows\System32\drivers\etc\hosts)"
    if (-not $filePath -or -not (Test-Path $filePath)) {
        Write-Host "[!] Ruta no válida o no existe." -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 2
        return
    }
    
    $handleExe = "$PSScriptRoot\handle64.exe"
    if (-not (Test-Path $handleExe)) {
        Write-Host "`n[+] Descargando Handle (Sysinternals)..." -ForegroundColor $COLOR_PRIMARY
        $url = "https://live.sysinternals.com/handle64.exe"
        try {
            Invoke-WebRequest -Uri $url -OutFile $handleExe -UseBasicParsing
            Write-Host "[✔] Descargado en: $handleExe" -ForegroundColor Green
        } catch {
            Write-Host "[✘] Error al descargar: $_" -ForegroundColor Red
            Pause-Enter " ENTER"
            return
        }
    }
    
    Write-Host "`n[+] Buscando procesos que tengan abierto: $filePath" -ForegroundColor $COLOR_ALERT
    Write-Host "    (Esto puede tardar unos segundos...)" -ForegroundColor Gray
    & $handleExe -accepteula "$filePath" 2>&1 | ForEach-Object { Write-Host $_ }
    Write-Log "HANDLE" "Searched handle for path: $filePath"
    Pause-Enter "`n ENTER"
}

# ============================================================
# ESCRITORIO REMOTO
# ============================================================
function Invoke-RemoteDesktop {
    while ($true) {
        Clear-Host
        Show-MainTitle
		Write-Host "`n 🖥️ ESCRITORIO REMOTO - CONEXIONES" -ForegroundColor $COLOR_MENU
        Write-Host " 🖥️ [1] ESCRITORIO REMOTO (mstsc) - Nativo Windows" -ForegroundColor $COLOR_PRIMARY
        Write-Host " 🚀 [2] ANYDESK - App gráfica ligera" -ForegroundColor $COLOR_MENU
        Write-Host " 🔓 [3] RUSTDESK - Open source, gratuito" -ForegroundColor $COLOR_MENU
        Write-Host " 👁️ [4] TEAMVIEWER - App gráfica completa" -ForegroundColor $COLOR_MENU
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER"
        
        $sub = Read-Host "🔽 > SELECCIONE"
        
        switch ($sub.ToUpper()) {
            "1" {
                Start-Process "mstsc.exe"
                continue
            }
            "2" {
                $installed = Get-Command anydesk -ErrorAction SilentlyContinue
                if (-not $installed) {
                    Write-Host "`n [+] Instalando AnyDesk..." -ForegroundColor Yellow
                    winget install AnyDesk.AnyDesk --silent
                    Start-Sleep -Seconds 5
                    Write-Host " [✔] AnyDesk instalado." -ForegroundColor Green
                }
                Write-Host "`n [+] Por favor, abre AnyDesk manualmente desde el menú inicio." -ForegroundColor Yellow
                Pause-Enter " ENTER después de cerrar AnyDesk"
                continue
            }
            "3" {
                $installed = Get-Command rustdesk -ErrorAction SilentlyContinue
                if (-not $installed) {
                    Write-Host "`n [+] Instalando RustDesk..." -ForegroundColor Yellow
                    winget install RustDesk.RustDesk --silent
                    Start-Sleep -Seconds 5
                    Write-Host " [✔] RustDesk instalado." -ForegroundColor Green
                }
                Write-Host "`n [+] Por favor, abre RustDesk manualmente desde el menú inicio." -ForegroundColor Yellow
                Pause-Enter " ENTER después de cerrar RustDesk"
                continue
            }
            "4" {
                $installed = Get-Command teamviewer -ErrorAction SilentlyContinue
                if (-not $installed) {
                    Write-Host "`n [+] Instalando TeamViewer..." -ForegroundColor Yellow
                    winget install TeamViewer.TeamViewer --silent
                    Start-Sleep -Seconds 5
                    Write-Host " [✔] TeamViewer instalado." -ForegroundColor Green
                }
                Write-Host "`n [+] Por favor, abre TeamViewer manualmente desde el menú inicio." -ForegroundColor Yellow
                Pause-Enter " ENTER después de cerrar TeamViewer"
                continue
            }
            "X" { break }
            default {
                Write-Host " Opción no válida" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
        if ($sub.ToUpper() -eq "X") { break }
    }
}

# ============================================================
# PURGA Y FORMATEO - HERRAMIENTAS DE LIMPIEZA AVANZADA
# ============================================================
function Show-DiagnosticMenu {
    while($true){
        Clear-Host
        Show-MainTitle
		Write-Host "`n 🧹 PURGA Y FORMATEO - LIMPIEZA AVANZADA" -ForegroundColor $COLOR_DANGER
        Write-Host " ---------------------------------------------------------------------------"
        Write-Host " 🗑️ [1] LIMPIAR ARCHIVOS TEMPORALES PROFUNDO"
        Write-Host " 🧽 [2] LIMPIAR CACHÉ DE WINDOWS (WinSxS)"
        Write-Host " 🔄 [3] ELIMINAR RESTOS DE ACTUALIZACIONES ANTIGUAS"
        Write-Host " 📊 [4] ANALIZAR Y LIMPIAR DISCO (cleanmgr)"
        Write-Host " ⚡ [5] FORMATEO RÁPIDO DE UNIDAD USB (DiskPart)"
        Write-Host " 💿 [6] CREAR USB BOOTEABLE (Rufus - web)"
        Write-Host " 🛠️ [8] DISKPART SIMPLIFICADO - Gestión fácil de discos/USB" -ForegroundColor $COLOR_MENU
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER"
        
        $opt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","5","6","8","X")
        
        if($opt -eq "X") { break }
        
        switch($opt) {
            "1" {
                Write-Host "`n[+] Limpieza profunda de temporales..." -ForegroundColor Yellow
                Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "[✔] Completado" -ForegroundColor Green
                Pause-Enter
            }
            "2" {
                if(-not (Require-Admin "limpiar WinSxS")) { continue }
                Write-Host "`n[+] Limpiando WinSxS..." -ForegroundColor Yellow
                dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
                Write-Host "[✔] Completado" -ForegroundColor Green
                Pause-Enter
            }
            "3" {
                if(-not (Require-Admin "limpiar actualizaciones")) { continue }
                Write-Host "`n[+] Eliminando versiones antiguas de Windows..." -ForegroundColor Yellow
                dism /online /Cleanup-Image /SPSuperseded
                Write-Host "[✔] Completado" -ForegroundColor Green
                Pause-Enter
            }
            "4" {
                Write-Host "`n[+] Abriendo Liberador de espacio en disco..." -ForegroundColor Yellow
                Start-Process "cleanmgr.exe"
                Pause-Enter " ENTER después de cerrar"
            }
            "5" {
                Write-Host "`n[!] ADVERTENCIA: Esto formateará una unidad USB" -ForegroundColor Red
                $driveLetter = Read-Host " LETRA DE LA UNIDAD USB (ej: D, sin dos puntos)"
                if($driveLetter -and (Confirm-Critical "FORMATEAR UNIDAD $($driveLetter):" "FORMATEAR")) {
                    Write-Host "[+] Ejecutando format..." -ForegroundColor Yellow
                    & cmd /c "format $($driveLetter): /FS:FAT32 /Q /Y"
                    Write-Host "[✔] Formateo completado" -ForegroundColor Green
                }
                Pause-Enter
            }
            "6" {
                Write-Host "`n[+] Abriendo página de Rufus..." -ForegroundColor Cyan
                Start-Process "https://rufus.ie/es/"
                Write-Host " Descarga Rufus para crear USB booteable" -ForegroundColor Yellow
                Pause-Enter
            }
            "8" {
                Invoke-SimpleDiskPart
                continue
            }
        }
    }
}

# ============================================================
# DISKPART SIMPLIFICADO - INTERFAZ AMIGABLE CON DOBLE AUTENTICACIÓN
# ============================================================
function Invoke-SimpleDiskPart {
    Clear-Host
    Show-MainTitle
    
    while ($true) {
        Clear-Host
        Show-MainTitle
        Write-Host "`n DISKPART SIMPLIFICADO - GESTIÓN DE DISCOS" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        Write-Host " 📋 INFORMACIÓN BÁSICA:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   [1] LISTAR DISCOS (ver todos los discos conectados)"
        Write-Host "   [2] VER DETALLES DE UN DISCO (tamaño, estilo, particiones)"
        Write-Host "   [3] VER VOLÚMENES (todas las particiones con letras)"
        Write-Host ""
        Write-Host " 🔧 OPERACIONES SEGURAS (sin riesgo de pérdida de datos):" -ForegroundColor $COLOR_ALERT
        Write-Host "   [4] ASIGNAR LETRA (ej: E:, F:, etc.)"
        Write-Host "   [5] EXTENDER PARTICIÓN (usar espacio no asignado)"
        Write-Host "   [6] REDUCIR PARTICIÓN (shrink - liberar espacio)"
        Write-Host "   [7] VERIFICAR DISCO (chkdsk desde diskpart)"
        Write-Host "   [8] OCULTAR/REVELAR PARTICIÓN"
        Write-Host ""
        Write-Host " ⚠️ OPERACIONES CRÍTICAS (requieren doble autenticación):" -ForegroundColor $COLOR_DANGER
        Write-Host "   [9]  LIMPIAR USB (clean - borra TODO el disco)"
        Write-Host "   [10] FORMATEAR como FAT32 (borra datos)"
        Write-Host "   [11] FORMATEAR como NTFS (borra datos)"
        Write-Host "   [12] ACTIVAR PARTICIÓN (hacerla booteable)"
        Write-Host "   [13] CONVERTIR MBR → GPT (cambia estilo de partición)"
        Write-Host "   [14] CONVERTIR GPT → MBR (cambia estilo de partición)"
        Write-Host "   [15] ELIMINAR PARTICIÓN (delete partition)"
        Write-Host ""
        Write-Host " CONTROL" -ForegroundColor Gray
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER AL MENÚ ANTERIOR" -ForegroundColor $COLOR_DANGER
        
        $opt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","X")
        if ($opt -eq "X") { break }
        
        switch ($opt) {
            "1" {
                Write-Host "`n[+] DISCOS CONECTADOS:" -ForegroundColor $COLOR_PRIMARY
                Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
                $script = "list disk`nexit"
                $tempFile = [System.IO.Path]::GetTempFileName()
                $script | Out-File -FilePath $tempFile -Encoding ascii
                diskpart /s $tempFile
                Remove-Item $tempFile -Force
                Write-Host "`n 💡 TIP: Anota el número del disco que quieres modificar" -ForegroundColor $COLOR_ALERT
                Pause-Enter " ENTER"
            }
            "2" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                if ($diskNum -match "^\d+$") {
                    Write-Host "`n[+] DETALLES DEL DISCO $diskNum :" -ForegroundColor $COLOR_PRIMARY
                    Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
                    $script = "select disk $diskNum`ndetail disk`nexit"
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $script | Out-File -FilePath $tempFile -Encoding ascii
                    diskpart /s $tempFile
                    Remove-Item $tempFile -Force
                } else {
                    Write-Host " [!] Número de disco inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "3" {
                Write-Host "`n[+] VOLÚMENES (particiones con letra):" -ForegroundColor $COLOR_PRIMARY
                Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
                $script = "list volume`nexit"
                $tempFile = [System.IO.Path]::GetTempFileName()
                $script | Out-File -FilePath $tempFile -Encoding ascii
                diskpart /s $tempFile
                Remove-Item $tempFile -Force
                Pause-Enter " ENTER"
            }
            "4" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN"
                $letra = Read-Host " LETRA A ASIGNAR (ej: E)"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$" -and $letra -match "^[A-Za-z]$") {
                    Write-Host "[+] Asignando letra $letra :..." -ForegroundColor Yellow
                    $script = "select disk $diskNum`nselect partition $partNum`nassign letter=$letra`nexit"
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $script | Out-File -FilePath $tempFile -Encoding ascii
                    diskpart /s $tempFile
                    Remove-Item $tempFile -Force
                    Write-Host "`n ✅ LETRA $letra : ASIGNADA" -ForegroundColor Green
                } else {
                    Write-Host " [!] Número o letra inválida" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "5" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN A EXTENDER"
                $sizeMB = Read-Host " TAMAÑO A EXTENDER EN MB (ENTER = todo)"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$") {
                    Write-Host "[+] Extendiendo partición..." -ForegroundColor Yellow
                    if ($sizeMB -match "^\d+$") {
                        $script = "select disk $diskNum`nselect partition $partNum`nextend size=$sizeMB`nexit"
                    } else {
                        $script = "select disk $diskNum`nselect partition $partNum`nextend`nexit"
                    }
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $script | Out-File -FilePath $tempFile -Encoding ascii
                    diskpart /s $tempFile
                    Remove-Item $tempFile -Force
                    Write-Host "`n ✅ PARTICIÓN EXTENDIDA" -ForegroundColor Green
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "6" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN A REDUCIR"
                $sizeMB = Read-Host " TAMAÑO A REDUCIR EN MB (ej: 1024 = 1GB)"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$" -and $sizeMB -match "^\d+$") {
                    Write-Host "[+] Reduciendo partición..." -ForegroundColor Yellow
                    $script = "select disk $diskNum`nselect partition $partNum`nshrink desired=$sizeMB`nexit"
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $script | Out-File -FilePath $tempFile -Encoding ascii
                    diskpart /s $tempFile
                    Remove-Item $tempFile -Force
                    Write-Host "`n ✅ PARTICIÓN REDUCIDA en $sizeMB MB" -ForegroundColor Green
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "7" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$") {
                    Write-Host "[+] Verificando disco..." -ForegroundColor Yellow
                    $script = "select disk $diskNum`nselect partition $partNum`nchkdsk /f`nexit"
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $script | Out-File -FilePath $tempFile -Encoding ascii
                    diskpart /s $tempFile
                    Remove-Item $tempFile -Force
                    Write-Host "`n ✅ VERIFICACIÓN COMPLETADA" -ForegroundColor Green
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "8" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN"
                $accion = Read-MenuOption " OCULTAR (H) o REVELAR (R)?" -Valid @("H","R")
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$") {
                    if ($accion -eq "H") {
                        Write-Host "[+] Ocultando partición..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nselect partition $partNum`nremove letter=`nexit"
                    } else {
                        Write-Host "[+] Revelando partición..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nselect partition $partNum`nassign`nexit"
                    }
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $script | Out-File -FilePath $tempFile -Encoding ascii
                    diskpart /s $tempFile
                    Remove-Item $tempFile -Force
                    Write-Host "`n ✅ OPERACIÓN COMPLETADA" -ForegroundColor Green
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            # === OPERACIONES CRÍTICAS CON DOBLE AUTENTICACIÓN ===
            "9" {
                Write-Host "`n[!] ⚠️ ADVERTENCIA: Esto BORRARÁ TODO el contenido del disco!" -ForegroundColor $COLOR_DANGER
                $diskNum = Read-Host " NÚMERO DE DISCO (ver con opción 1)"
                if ($diskNum -match "^\d+$") {
                    if (Confirm-Critical "LIMPIAR DISCO $diskNum (BORRARÁ TODOS LOS DATOS PERMANENTEMENTE)" "BORRAR") {
                        Write-Host "[+] Limpiando disco $diskNum..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nclean`ncreate partition primary`nactive`nformat fs=ntfs quick`nassign`nexit"
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $script | Out-File -FilePath $tempFile -Encoding ascii
                        diskpart /s $tempFile
                        Remove-Item $tempFile -Force
                        Write-Host "`n ✅ DISCO LIMPIADO Y FORMATEADO (NTFS)" -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] Número de disco inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "10" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$") {
                    if (Confirm-Critical "FORMATEAR DISCO $diskNum PARTICIÓN $partNum como FAT32 (BORRA DATOS)" "FORMATEAR") {
                        Write-Host "[+] Formateando como FAT32..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nselect partition $partNum`nformat fs=fat32 quick`nexit"
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $script | Out-File -FilePath $tempFile -Encoding ascii
                        diskpart /s $tempFile
                        Remove-Item $tempFile -Force
                        Write-Host "`n ✅ FORMATEO FAT32 COMPLETADO" -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "11" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$") {
                    if (Confirm-Critical "FORMATEAR DISCO $diskNum PARTICIÓN $partNum como NTFS (BORRA DATOS)" "FORMATEAR") {
                        Write-Host "[+] Formateando como NTFS..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nselect partition $partNum`nformat fs=ntfs quick`nexit"
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $script | Out-File -FilePath $tempFile -Encoding ascii
                        diskpart /s $tempFile
                        Remove-Item $tempFile -Force
                        Write-Host "`n ✅ FORMATEO NTFS COMPLETADO" -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "12" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$") {
                    if (Confirm-Critical "ACTIVAR PARTICIÓN $partNum en DISCO $diskNum (hacerla booteable)" "APLICAR") {
                        Write-Host "[+] Activando partición..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nselect partition $partNum`nactive`nexit"
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $script | Out-File -FilePath $tempFile -Encoding ascii
                        diskpart /s $tempFile
                        Remove-Item $tempFile -Force
                        Write-Host "`n ✅ PARTICIÓN ACTIVADA" -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "13" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                if ($diskNum -match "^\d+$") {
                    if (Confirm-Critical "CONVERTIR DISCO $diskNum de MBR a GPT (BORRA TODOS LOS DATOS)" "CONVERTIR") {
                        Write-Host "[+] Convirtiendo MBR → GPT..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nclean`nconvert gpt`nexit"
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $script | Out-File -FilePath $tempFile -Encoding ascii
                        diskpart /s $tempFile
                        Remove-Item $tempFile -Force
                        Write-Host "`n ✅ DISCO CONVERTIDO A GPT (limpio, sin particiones)" -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "14" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                if ($diskNum -match "^\d+$") {
                    if (Confirm-Critical "CONVERTIR DISCO $diskNum de GPT a MBR (BORRA TODOS LOS DATOS)" "CONVERTIR") {
                        Write-Host "[+] Convirtiendo GPT → MBR..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nclean`nconvert mbr`nexit"
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $script | Out-File -FilePath $tempFile -Encoding ascii
                        diskpart /s $tempFile
                        Remove-Item $tempFile -Force
                        Write-Host "`n ✅ DISCO CONVERTIDO A MBR (limpio, sin particiones)" -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
            "15" {
                $diskNum = Read-Host "`n NÚMERO DE DISCO"
                $partNum = Read-Host " NÚMERO DE PARTICIÓN A ELIMINAR"
                if ($diskNum -match "^\d+$" -and $partNum -match "^\d+$") {
                    if (Confirm-Critical "ELIMINAR PARTICIÓN $partNum en DISCO $diskNum (BORRA DATOS)" "BORRAR") {
                        Write-Host "[+] Eliminando partición..." -ForegroundColor Yellow
                        $script = "select disk $diskNum`nselect partition $partNum`ndelete partition`nexit"
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $script | Out-File -FilePath $tempFile -Encoding ascii
                        diskpart /s $tempFile
                        Remove-Item $tempFile -Force
                        Write-Host "`n ✅ PARTICIÓN ELIMINADA" -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] Número inválido" -ForegroundColor $COLOR_DANGER
                }
                Pause-Enter " ENTER"
            }
        }
    }
}

# ============================================================
# 🎵 CENTRO DE DESCARGAS INTELIGENTE (yt-dlp)
# ============================================================
function Invoke-DownloadCenter {
    # Configuración inicial
    $ErrorActionPreference = "Continue"
    $ProgressPreference = "SilentlyContinue"
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Definir rutas
    $Escritorio = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"))
    $Herramientas = [System.IO.Path]::Combine($Escritorio, "Herramientas_Descarga")
    $DescargasPredeterminada = [System.IO.Path]::Combine($Escritorio, "Descargas_YTDLP")
    $HistorialPath = [System.IO.Path]::Combine($Herramientas, "historial_descargas.txt")
    $script:DescargasExitosas = 0
    $script:LimiteDescarga = 50
    
    # Crear carpetas
    if (-not (Test-Path $Herramientas)) { New-Item -ItemType Directory -Path $Herramientas -Force | Out-Null }
    if (-not (Test-Path $DescargasPredeterminada)) { New-Item -ItemType Directory -Path $DescargasPredeterminada -Force | Out-Null }
    Set-Location $Herramientas
    
    function Descargar-FFmpeg {
        Write-Host "   🔧 FFmpeg no encontrado. Descargando..." -ForegroundColor $COLOR_ALERT
        $url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
        $zipPath = "$Herramientas\ffmpeg.zip"
        $extractPath = "$Herramientas\ffmpeg-temp"
        try {
            Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
            Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
            $ffmpegFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
            $binPath = Join-Path $ffmpegFolder.FullName "bin"
            Copy-Item "$binPath\ffmpeg.exe" "$Herramientas\ffmpeg.exe" -Force
            Copy-Item "$binPath\ffprobe.exe" "$Herramientas\ffprobe.exe" -Force
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ FFmpeg instalado!" -ForegroundColor $COLOR_PRIMARY
            Write-Log "DOWN" "FFmpeg installed successfully"
            return $true
        }
        catch {
            Write-Host "   ⚠️ No se pudo instalar FFmpeg." -ForegroundColor $COLOR_WARNING
            Write-Log "WARN" "FFmpeg installation failed"
            return $false
        }
    }
    
    function Verificar-Herramientas {
        if (-not (Test-Path "$Herramientas\yt-dlp.exe")) {
            Write-Host "   📥 Descargando yt-dlp..." -ForegroundColor $COLOR_ALERT
            try {
                Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile "$Herramientas\yt-dlp.exe" -UseBasicParsing
                Write-Host "   ✅ yt-dlp listo!" -ForegroundColor $COLOR_PRIMARY
                Write-Log "DOWN" "yt-dlp downloaded"
            }
            catch {
                Write-Host "   ❌ ERROR: No se pudo descargar yt-dlp.exe" -ForegroundColor $COLOR_DANGER
                Write-Log "ERROR" "yt-dlp download failed"
                Read-Host "   Presiona Enter para volver"
                return $false
            }
        }
        $ffmpegPath = Get-Command ffmpeg -ErrorAction SilentlyContinue
        if (-not $ffmpegPath -and (Test-Path "$Herramientas\ffmpeg.exe")) {
            $ffmpegPath = "$Herramientas\ffmpeg.exe"
        }
        if (-not $ffmpegPath) {
            $global:FFmpegDisponible = Descargar-FFmpeg
        } else {
            $global:FFmpegDisponible = $true
        }
        return $true
    }
    
    function Guardar-Historial {
        param([string]$Titulo, [string]$Plataforma, [string]$URL, [string]$Destino)
        $fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $linea = "$fecha | $Plataforma | $Titulo | $URL | $Destino"
        Add-Content -Path $HistorialPath -Value $linea -Encoding UTF8
        Write-Log "DOWN" "Downloaded: $Titulo from $Plataforma"
    }
    
    function Mostrar-Historial {
        Clear-Host
        Show-MainTitle
        Write-Host "`n 📜 HISTORIAL DE DESCARGAS" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        if (Test-Path $HistorialPath) {
            $historial = Get-Content $HistorialPath -Encoding UTF8
            if ($historial.Count -eq 0) {
                Write-Host "   ℹ️ Aún no hay descargas registradas." -ForegroundColor $COLOR_ALERT
            } else {
                Write-Host "   📋 Últimas 20 descargas:" -ForegroundColor $COLOR_PRIMARY
                Write-Host ""
                $historial | Select-Object -Last 20 | ForEach-Object {
                    Write-Host "   $_" -ForegroundColor Gray
                }
                Write-Host ""
                Write-Host "   📊 Total de descargas registradas: $($historial.Count)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "   ℹ️ Aún no hay historial. Realiza tu primera descarga!" -ForegroundColor $COLOR_ALERT
        }
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    }
    
    function Detectar-USB {
        try {
            $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and $_.Size -gt 0 }
            if ($drives) { return $drives[0].DeviceID.Replace(":", "") }
        } catch { 
            $vol = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter } | Select-Object -First 1
            if ($vol) { return $vol.DriveLetter }
        }
        return $null
    }
    
    function Evaluar-Apagado {
        if ($Global:ModoNocturno) {
            Write-Host "`n   🔥 MODO NOCTURNO ACTIVO. Apagando PC en 60 segundos..." -ForegroundColor $COLOR_DANGER
            Write-Host "   📊 Total descargas: $script:DescargasExitosas" -ForegroundColor Cyan
            Start-Sleep -Seconds 5
            shutdown /s /f /t 60
            exit
        }
    }
    
    function Limpiar-Nombre {
        param([string]$Nombre)
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        foreach ($char in $invalidChars) { $Nombre = $Nombre.Replace($char, '_') }
        return $Nombre.Trim()
    }
    
    function Mostrar-Notas {
        Clear-Host
        Show-MainTitle
        Write-Host "`n 📖 GUÍA RÁPIDA - CENTRO DE DESCARGAS" -ForegroundColor $COLOR_ALERT
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   1. LÍMITE DE RESULTADOS: Controla cuántas canciones descarga"
        Write-Host "   2. DESCARGA POR LOTES: Crea archivo lista_descargas.txt"
        Write-Host "   3. SOLO CONTENIDO PÚBLICO"
        Write-Host "   4. Presiona Ctrl+C para cancelar"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    }
    
    function Descargar-DesdeArchivo {
        param([string]$RutaDestino)
        Clear-Host
        Show-MainTitle
        Write-Host "`n 📦 DESCARGA POR LOTES DESDE ARCHIVO" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        $archivoLista = Join-Path $Herramientas "lista_descargas.txt"
        if (-not (Test-Path $archivoLista)) {
            Write-Host "   ⚠️ No se encontró el archivo 'lista_descargas.txt'" -ForegroundColor $COLOR_DANGER
            $ejemplo = @("# Lista de descargas", "https://youtube.com/watch?v=ejemplo")
            $ejemplo | Out-File -FilePath $archivoLista -Encoding UTF8
            Write-Host "   ✅ Se creó archivo de ejemplo." -ForegroundColor $COLOR_PRIMARY
            Read-Host "   Presiona Enter para continuar"
            return
        }
        $urls = Get-Content $archivoLista -Encoding UTF8 | Where-Object { $_ -and $_ -notmatch '^\s*#' -and $_ -match '^https?://' }
        if ($urls.Count -eq 0) {
            Write-Host "   ❌ No se encontraron URLs válidas." -ForegroundColor $COLOR_DANGER
            Read-Host "   Presiona Enter para continuar"
            return
        }
        Write-Host "   📊 Se encontraron $($urls.Count) URLs" -ForegroundColor $COLOR_PRIMARY
        $confirmar = Read-Host "   ❓ Descargar todas? (S/N)"
        if ($confirmar -ne "s" -and $confirmar -ne "S") {
            Write-Host "   ❌ Cancelado." -ForegroundColor $COLOR_ALERT
            Read-Host "   Presiona Enter para continuar"
            return
        }
        $contador = 0
        foreach ($url in $urls) {
            $contador++
            Write-Host "   [$contador/$($urls.Count)] $url" -ForegroundColor Cyan
            & .\yt-dlp.exe --no-playlist -o "$RutaDestino/%(title)s.%(ext)s" $url 2>$null
            if ($LASTEXITCODE -eq 0) {
                $script:DescargasExitosas++
                Write-Host "      ✅ Éxito!" -ForegroundColor Green
            } else {
                Write-Host "      ❌ Fallo" -ForegroundColor Red
            }
        }
        Write-Host "`n   📊 RESUMEN: Exitosas: $contador" -ForegroundColor Cyan
        Read-Host "   Presiona Enter para continuar"
    }
    
    # Inicializar
    if (-not (Verificar-Herramientas)) { return }
    
    # Variables de estado
    if ($null -eq $Global:CalidadAudio) { $Global:CalidadAudio = "5" }
    if ($null -eq $Global:CalidadVideo) { $Global:CalidadVideo = "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720][ext=mp4]" }
    if ($null -eq $Global:TextoCalidad) { $Global:TextoCalidad = "Media (192kbps / 720p)" }
    if ($null -eq $Global:ModoNocturno) { $Global:ModoNocturno = $false }
    if ($null -eq $Global:ModoSilencioso) { $Global:ModoSilencioso = $false }
    $Global:RutaDestinoActual = $DescargasPredeterminada
    
    # MENU PRINCIPAL DEL CENTRO
    do {
        $USBDrive = Detectar-USB
        if ($USBDrive) {
            $MensajeUSB = "USB DETECTADA (Unidad ${USBDrive}:)"
            $ColorUSB = "Green"
        } else {
            $MensajeUSB = "Sin USB conectada"
            $ColorUSB = "DarkGray"
        }
        $EstadoNocturno = if ($Global:ModoNocturno) { "ACTIVO" } else { "DESACTIVADO" }
        $EstadoSilencioso = if ($Global:ModoSilencioso) { "SI" } else { "NO" }
        $ColorNocturno = if ($Global:ModoNocturno) { "Red" } else { "Gray" }
        
        Clear-Host
        Show-MainTitle
        Write-Host "`n 🎵 CENTRO DE DESCARGAS INTELIGENTE v4.0" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host "   📂 Destino actual: $Global:RutaDestinoActual" -ForegroundColor Yellow
        Write-Host "   💿 $MensajeUSB" -ForegroundColor $ColorUSB
        Write-Host "   🎚️ Calidad    : $Global:TextoCalidad" -ForegroundColor Cyan
        Write-Host "   🔢 Límite     : $script:LimiteDescarga canciones" -ForegroundColor Cyan
        Write-Host "   🔇 Modo Silent: $EstadoSilencioso" -ForegroundColor Cyan
        Write-Host "   🌙 Modo Noche : $EstadoNocturno" -ForegroundColor $ColorNocturno
        Write-Host "   📊 Descargas  : $script:DescargasExitosas" -ForegroundColor Green
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   🎬 YOUTUBE:" -ForegroundColor Magenta
        Write-Host "   [1] Descargar Disco / Playlist"
        Write-Host "   [2] Descargar Canción sola"
        Write-Host "   [3] YouTube por ENLACE"
        Write-Host ""
        Write-Host "   📱 OTRAS PLATAFORMAS:" -ForegroundColor Cyan
        Write-Host "   [4] TikTok, Instagram, Facebook, Twitter"
        Write-Host ""
        Write-Host "   🛠️ HERRAMIENTAS:" -ForegroundColor Yellow
        if ($global:FFmpegDisponible) {
            Write-Host "   [5] MODO DJ: Recortar audio"
        } else {
            Write-Host "   [5] MODO DJ: NO DISPONIBLE" -ForegroundColor DarkGray
        }
        Write-Host "   [6] Configurar Calidad"
        Write-Host "   [7] Configurar Límite"
        Write-Host "   [8] Configurar Modo Nocturno"
        Write-Host "   [9] Configurar Modo Silencioso"
        Write-Host "   [C] Seleccionar Carpeta"
        Write-Host "   [H] Ver Historial"
        Write-Host "   [L] Descarga por lotes"
        Write-Host "   [N] Ver NOTAS"
        Write-Host "   [U] Actualizar yt-dlp"
        Write-Host ""
        Write-Host "   ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host "   ═══════════════════════════════════════════════════════════════════" -ForegroundColor $COLOR_DANGER
        Write-Host "   [X] SALIR DEL CENTRO DE DESCARGAS" -ForegroundColor $COLOR_DANGER
        
        $opcion = Read-Host "`n   > SELECCIONE"
        
        if ($Global:ModoSilencioso) {
            $argsBase = @("--restrict-filenames", "--no-mtime", "--quiet", "--no-warnings")
        } else {
            $argsBase = @("--restrict-filenames", "--no-mtime")
        }
        
        switch -Wildcard ($opcion) {
            "1" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n 🎵 DESCARGAR DISCO / PLAYLIST" -ForegroundColor Magenta
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                $album = Read-Host "   Artista y nombre del Álbum"
                $nombreLimpio = Limpiar-Nombre -Nombre $album
                Write-Host "   ⏳ Descargando (máx $script:LimiteDescarga)..." -ForegroundColor Yellow
                & .\yt-dlp.exe -x --audio-format mp3 --audio-quality $Global:CalidadAudio --yes-playlist --playlist-end $script:LimiteDescarga $argsBase "ytsearchplaylist$script:LimiteDescarga:$album" -o "$Global:RutaDestinoActual/$nombreLimpio/%(playlist_index)s - %(title)s.%(ext)s" 2>$null
                if ($LASTEXITCODE -eq 0) { 
                    $script:DescargasExitosas++
                    Write-Host "   ✅ Disco descargado!" -ForegroundColor $COLOR_PRIMARY 
                    Guardar-Historial -Titulo $album -Plataforma "YouTube" -URL "Búsqueda: $album" -Destino $Global:RutaDestinoActual
                } else {
                    Write-Host "   ❌ No se encontró" -ForegroundColor $COLOR_DANGER
                }
                Read-Host "   Presiona Enter"
                Evaluar-Apagado
            }
            "2" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n 🎵 DESCARGAR CANCIÓN SOLA" -ForegroundColor Magenta
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                $busqueda = Read-Host "   Nombre del tema"
                Write-Host "   ⏳ Descargando..." -ForegroundColor Yellow
                & .\yt-dlp.exe -x --audio-format mp3 --audio-quality $Global:CalidadAudio --no-playlist $argsBase "ytsearch1:$busqueda" -o "$Global:RutaDestinoActual/%(title)s.%(ext)s" 2>$null
                if ($LASTEXITCODE -eq 0) { 
                    $script:DescargasExitosas++
                    Write-Host "   ✅ Canción guardada!" -ForegroundColor $COLOR_PRIMARY 
                    Guardar-Historial -Titulo $busqueda -Plataforma "YouTube" -URL "Búsqueda: $busqueda" -Destino $Global:RutaDestinoActual
                } else {
                    Write-Host "   ❌ No se encontró" -ForegroundColor $COLOR_DANGER
                }
                Read-Host "   Presiona Enter"
                Evaluar-Apagado
            }
            "3" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n 🎬 YOUTUBE POR ENLACE" -ForegroundColor White
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                $link = Read-Host "   Pega la URL"
                $tipo = Read-Host "   Música [M] o Video [V]?"
                Write-Host "   ⏳ Descargando..." -ForegroundColor Yellow
                if ($tipo -eq "v" -or $tipo -eq "V") {
                    & .\yt-dlp.exe -f $Global:CalidadVideo --no-playlist $argsBase -o "$Global:RutaDestinoActual/%(title)s.%(ext)s" $link 2>$null
                } else {
                    & .\yt-dlp.exe -x --audio-format mp3 --audio-quality $Global:CalidadAudio --no-playlist $argsBase -o "$Global:RutaDestinoActual/%(title)s.%(ext)s" $link 2>$null
                }
                if ($LASTEXITCODE -eq 0) { 
                    $script:DescargasExitosas++
                    Write-Host "   ✅ Descargado!" -ForegroundColor $COLOR_PRIMARY 
                    Guardar-Historial -Titulo "URL" -Plataforma "YouTube" -URL $link -Destino $Global:RutaDestinoActual
                } else {
                    Write-Host "   ❌ URL inválida" -ForegroundColor $COLOR_DANGER
                }
                Read-Host "   Presiona Enter"
                Evaluar-Apagado
            }
            "4" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n 📱 REDES SOCIALES" -ForegroundColor Cyan
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host "   ⚠️ ATENCIÓN: Solo videos PÚBLICOS" -ForegroundColor $COLOR_ALERT
                $url = Read-Host "   Pega la URL"
                $tipo = Read-Host "   Solo audio [S] o Video [N]?"
                Write-Host "   ⏳ Descargando..." -ForegroundColor Yellow
                if ($tipo -eq "s" -or $tipo -eq "S") {
                    & .\yt-dlp.exe -x --audio-format mp3 --audio-quality $Global:CalidadAudio --no-playlist $argsBase -o "$Global:RutaDestinoActual/%(title)s.%(ext)s" $url 2>$null
                } else {
                    & .\yt-dlp.exe --no-playlist $argsBase -o "$Global:RutaDestinoActual/%(title)s.%(ext)s" $url 2>$null
                }
                if ($LASTEXITCODE -eq 0) { 
                    $script:DescargasExitosas++
                    Write-Host "   ✅ Descargado!" -ForegroundColor $COLOR_PRIMARY
                } else {
                    Write-Host "   ❌ Fallo - video privado o URL incorrecta" -ForegroundColor $COLOR_DANGER
                }
                Read-Host "   Presiona Enter"
                Evaluar-Apagado
            }
            "5" {
                Clear-Host
                Show-MainTitle
                if (-not $global:FFmpegDisponible) {
                    Write-Host "`n   ⚠️ MODO DJ NO DISPONIBLE" -ForegroundColor $COLOR_DANGER
                    Write-Host "   💡 FFmpeg no está instalado correctamente" -ForegroundColor $COLOR_ALERT
                    Read-Host "   Presiona Enter"
                    continue
                }
                Write-Host "`n 🎧 MODO DJ: RECORTAR AUDIO" -ForegroundColor Yellow
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                $busqueda = Read-Host "   Nombre de la canción"
                $inicio = Read-Host "   Inicio (00:00:00)"
                $fin = Read-Host "   Fin (00:00:00)"
                Write-Host "   ⏳ Procesando..." -ForegroundColor Yellow
                & .\yt-dlp.exe -x --audio-format mp3 --audio-quality $Global:CalidadAudio --no-playlist $argsBase --download-sections "*$inicio-$fin" --force-keyframes-at-cuts "ytsearch1:$busqueda" -o "$Global:RutaDestinoActual/%(title)s_recortado.%(ext)s" 2>$null
                if ($LASTEXITCODE -eq 0) { 
                    $script:DescargasExitosas++
                    Write-Host "   ✅ Fragmento guardado!" -ForegroundColor $COLOR_PRIMARY 
                } else {
                    Write-Host "   ❌ No se pudo recortar" -ForegroundColor $COLOR_DANGER
                }
                Read-Host "   Presiona Enter"
                Evaluar-Apagado
            }
            "6" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n ⚙️ CONFIGURAR CALIDAD" -ForegroundColor Yellow
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host "   [1] Alta (320kbps / 1080p)"
                Write-Host "   [2] Media (192kbps / 720p)"
                Write-Host "   [3] Baja (128kbps / 480p)"
                $setCalidad = Read-Host "`n   Opción"
                switch ($setCalidad) {
                    "1" { 
                        $Global:CalidadAudio = "0"
                        $Global:CalidadVideo = "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]"
                        $Global:TextoCalidad = "Alta (320kbps / 1080p)"
                    }
                    "3" { 
                        $Global:CalidadAudio = "9"
                        $Global:CalidadVideo = "bv*[height<=480][ext=mp4]+ba[ext=m4a]/b[height<=480][ext=mp4]"
                        $Global:TextoCalidad = "Baja (128kbps / 480p)"
                    }
                    default { 
                        $Global:CalidadAudio = "5"
                        $Global:CalidadVideo = "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720][ext=mp4]"
                        $Global:TextoCalidad = "Media (192kbps / 720p)"
                    }
                }
                Write-Host "`n   ✅ Calidad cambiada a: $Global:TextoCalidad" -ForegroundColor $COLOR_PRIMARY
                Write-Log "DOWN" "Quality changed to: $Global:TextoCalidad"
                Start-Sleep -Seconds 2
            }
            "7" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n ⚙️ CONFIGURAR LÍMITE" -ForegroundColor Yellow
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host "   Límite actual: $script:LimiteDescarga"
                Write-Host "   [1] 10   [2] 25   [3] 50   [4] 100   [5] Todos"
                $opcionLimite = Read-Host "`n   Opción"
                switch ($opcionLimite) {
                    "1" { $script:LimiteDescarga = 10 }
                    "2" { $script:LimiteDescarga = 25 }
                    "3" { $script:LimiteDescarga = 50 }
                    "4" { $script:LimiteDescarga = 100 }
                    "5" { $script:LimiteDescarga = 9999 }
                    default { Write-Host "   ❌ Inválido" -ForegroundColor $COLOR_DANGER }
                }
                Write-Host "`n   ✅ Límite cambiado a $script:LimiteDescarga" -ForegroundColor $COLOR_PRIMARY
                Start-Sleep -Seconds 2
            }
            "8" {
                $Global:ModoNocturno = (-not $Global:ModoNocturno)
                if ($Global:ModoNocturno) {
                    Write-Host "`n   🌙 Modo Nocturno ACTIVADO" -ForegroundColor $COLOR_ALERT
                    Write-Host "   ⚠️ El PC se apagará automáticamente al finalizar las descargas" -ForegroundColor $COLOR_DANGER
                } else {
                    Write-Host "`n   🌙 Modo Nocturno DESACTIVADO" -ForegroundColor $COLOR_PRIMARY
                }
                Start-Sleep -Seconds 2
            }
            "9" {
                $Global:ModoSilencioso = (-not $Global:ModoSilencioso)
                if ($Global:ModoSilencioso) {
                    Write-Host "`n   🔇 Modo Silencioso ACTIVADO (sin mensajes detallados)" -ForegroundColor $COLOR_ALERT
                } else {
                    Write-Host "`n   🔇 Modo Silencioso DESACTIVADO" -ForegroundColor $COLOR_PRIMARY
                }
                Start-Sleep -Seconds 2
            }
            "c" { 
                Clear-Host
                Show-MainTitle
                Write-Host "`n 📂 SELECCIONAR CARPETA" -ForegroundColor Cyan
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host "   [1] Carpeta por defecto (Escritorio\Descargas_YTDLP)"
                Write-Host "   [2] Escribir ruta manual"
                $opt = Read-Host "`n   Opción"
                if ($opt -eq "2") {
                    $ruta = Read-Host "   Escribe la ruta completa"
                    if (-not (Test-Path $ruta)) { New-Item -ItemType Directory -Path $ruta -Force | Out-Null }
                    $Global:RutaDestinoActual = $ruta
                    Write-Host "`n   ✅ Carpeta cambiada a: $ruta" -ForegroundColor $COLOR_PRIMARY
                } else {
                    $Global:RutaDestinoActual = $DescargasPredeterminada
                    Write-Host "`n   ✅ Carpeta cambiada a: $DescargasPredeterminada" -ForegroundColor $COLOR_PRIMARY
                }
                Write-Log "DOWN" "Download folder changed to: $Global:RutaDestinoActual"
                Start-Sleep -Seconds 2
            }
            "C" { 
                Clear-Host
                Show-MainTitle
                Write-Host "`n 📂 SELECCIONAR CARPETA" -ForegroundColor Cyan
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host "   [1] Carpeta por defecto (Escritorio\Descargas_YTDLP)"
                Write-Host "   [2] Escribir ruta manual"
                $opt = Read-Host "`n   Opción"
                if ($opt -eq "2") {
                    $ruta = Read-Host "   Escribe la ruta completa"
                    if (-not (Test-Path $ruta)) { New-Item -ItemType Directory -Path $ruta -Force | Out-Null }
                    $Global:RutaDestinoActual = $ruta
                    Write-Host "`n   ✅ Carpeta cambiada a: $ruta" -ForegroundColor $COLOR_PRIMARY
                } else {
                    $Global:RutaDestinoActual = $DescargasPredeterminada
                    Write-Host "`n   ✅ Carpeta cambiada a: $DescargasPredeterminada" -ForegroundColor $COLOR_PRIMARY
                }
                Write-Log "DOWN" "Download folder changed to: $Global:RutaDestinoActual"
                Start-Sleep -Seconds 2
            }
            "h" { Mostrar-Historial; Read-Host "`n   Presiona Enter" }
            "H" { Mostrar-Historial; Read-Host "`n   Presiona Enter" }
            "l" { Descargar-DesdeArchivo -RutaDestino $Global:RutaDestinoActual }
            "L" { Descargar-DesdeArchivo -RutaDestino $Global:RutaDestinoActual }
            "n" { Mostrar-Notas; Read-Host "`n   Presiona Enter" }
            "N" { Mostrar-Notas; Read-Host "`n   Presiona Enter" }
            "u" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n 🔄 ACTUALIZANDO YT-DLP" -ForegroundColor Cyan
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host "   ⏳ Descargando última versión..." -ForegroundColor Yellow
                & .\yt-dlp.exe -U 2>$null
                Write-Host "`n   ✅ yt-dlp actualizado!" -ForegroundColor $COLOR_PRIMARY
                Write-Log "DOWN" "yt-dlp updated"
                Read-Host "`n   Presiona Enter"
            }
            "U" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n 🔄 ACTUALIZANDO YT-DLP" -ForegroundColor Cyan
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Write-Host "   ⏳ Descargando última versión..." -ForegroundColor Yellow
                & .\yt-dlp.exe -U 2>$null
                Write-Host "`n   ✅ yt-dlp actualizado!" -ForegroundColor $COLOR_PRIMARY
                Write-Log "DOWN" "yt-dlp updated"
                Read-Host "`n   Presiona Enter"
            }
            "x" { break }
        }
    } while ($opcion -ne "x")
    
    Clear-Host
    Show-MainTitle
    Write-Host "`n ═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "   📊 RESUMEN - Descargas exitosas: $script:DescargasExitosas" -ForegroundColor Cyan
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "   🎵 Gracias por usar el centro de descargas!" -ForegroundColor Magenta
    Write-Log "DOWN" "Download center closed. Total downloads: $script:DescargasExitosas"
    Start-Sleep -Seconds 2
}

# ============================================================
# MENU PRINCIPAL
# ============================================================
while ($true) {
#	Clear-Host #nuevo
    Show-MainTitle
	    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.ControlKeyChar -eq 3) {
            Write-Host "`n`n[!] Ctrl+C detectado. Saliendo del script..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            exit
        }
    }
	$horaActual = Get-Date -Format "HH:mm:ss"
	Write-Host "`n ✅ SISTEMA OK | 👤 USUARIO $env:USERNAME | 🖥️ VISTA $vista | ⏰ HORA: $horaActual" -ForegroundColor Gray
    Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
    
    if ($Global:MenuHorizontal) {
		Write-Host "    💾 [A]  BACKUP TOTAL             🧹 [E]  OPTIMIZAR TEMP           📦 [I]  KIT POST FORMAT" 		-ForegroundColor Green
        Write-Host "    📀 [B]  RESTORE TOTAL            🛠️ [F]  WIN UTIL TITUS           👥 [J]  GESTION USUARIOS" 		-ForegroundColor Green
        Write-Host "    🔧 [C]  GESTION DRIVERS          🔑 [G]  MICROSOFT OFFICE AIO     🛠️ [K]  SOPORTE TECNICO PRO" 	-ForegroundColor Green
        Write-Host "    🧹 [D]  PURGA Y FORMATEO         📦 [H]  GESTION PAQUETES PRO     🚀 [L]  BYPASS WINDOWS 11" 	 	-ForegroundColor Green
        Write-Host '    🌐 [M]  RED Y REPARACION         💾 [N]  MANTENIM DISCO           📊 [O]  MONITOR EN VIVO (PRO)'	 -ForegroundColor Green
        Write-Host '    🛡️ [P]  WINDOWS DEFENDER TOTAL   ⚡ [Q]  AUTO-FLOW (EXPRESS)      🛠️ [U]  SYSINTERNALS KIT' 		-ForegroundColor Green
		Write-Host '    🖥️ [T]  ESCRITORIO REMOTO        🔐 [Y]  GENERADOR CONTRASEÑAS    🎵 [Z]  CENTRO DESCARGAS (yt-dlp)	 ' -ForegroundColor Green	
         } else {
             Write-Host "    💾 [A] BACKUP TOTAL"
             Write-Host "    📀 [B] RESTORE TOTAL"
             Write-Host "    🔧 [C] GESTION DRIVERS"
             Write-Host "    🧹 [D] PURGA Y FORMATEO"
             Write-Host "    🧹 [E] OPTIMIZAR TEMP"
             Write-Host "    🛠️ [F] WIN UTIL TITUS"
             Write-Host "    🔑 [G] MICROSOFT OFFICE AIO"
             Write-Host "    📦 [H] GESTION PAQUETES PRO"
             Write-Host "    📦 [I] KIT POST FORMAT"
             Write-Host "    👥 [J] GESTION USUARIOS"
             Write-Host "    🛠️ [K] SOPORTE TECNICO PRO"
             Write-Host "    🚀 [L] BYPASS WINDOWS 11"
             Write-Host "    🌐 [M] RED Y REPARACION"
             Write-Host "    💾 [N] MANTENIM DISCO"
             Write-Host "    📊 [O] MONITOR EN VIVO (PRO)"
             Write-Host "    🛡️ [P] WINDOWS DEFENDER TOTAL"
             Write-Host "    ⚡ [Q] AUTO-FLOW (MANTENIMIENTO EXPRESS)"
             Write-Host "    🖥️ [T] ESCRITORIO REMOTO"
             Write-Host "    🛠️ [U] SYSINTERNALS KIT (11 herramientas)"
             Write-Host "	 🔐 [Y] GENERADOR CONTRASEÑAS"
			 Write-Host "	 🎵 [Z] CENTRO DESCARGAS (yt-dlp)"
         }
	Write-Host "`n ⚙️ CONFIGURACION Y VISTA" -ForegroundColor Gray
    Write-Host "  -----------------------------------------------------------------------------" -ForegroundColor $COLOR_MENU
    Write-Host '    🔄 [R] REFRESCAR MENU            🖥️ [V] CAMBIAR VISTA (V)' -ForegroundColor $COLOR_MENU
    Write-Host "    ❌ [X] SALIR DEL SCRIPT" -ForegroundColor $COLOR_DANGER

    $opt = (Read-Host "`n ``> OPCION").ToUpper()
    switch ($opt) {
        "R" { continue }
        "V" { $Global:MenuHorizontal = !$Global:MenuHorizontal; continue }
        "Q" { Invoke-AutoFlow }
        "U" {  while ($true) {
        Show-MainTitle
		Write-Host "`n 🛠️ SYSINTERNALS KIT - 11 HERRAMIENTAS PRO" -ForegroundColor $COLOR_MENU
        Write-Host " 🔍 [1]  PROCEXP         - Process Explorer (gestor de procesos avanzado)"
        Write-Host " 🚀 [2]  AUTORUNS       - Programas de inicio, servicios, drivers"
        Write-Host " 📊 [3]  PROCMON        - Monitor en vivo de archivos, registro, red"
        Write-Host " 🌐 [4]  TCPVIEW        - Conexiones de red abiertas"
        Write-Host " 🧠 [5]  RAMMAP         - Análisis detallado de memoria física"
        Write-Host " 📋 [6]  VMMAP          - Mapa de memoria virtual por proceso"
        Write-Host " 💿 [7]  DISK2VHD       - Convierte disco físico a VHD (virtualización)"
        Write-Host " 🔧 [8]  WINOBJ         - Explorador de objetos del kernel"
        Write-Host " ✅ [9]  SIGCHECK       - Verifica firmas digitales y VirusTotal"
        Write-Host " 🗑️ [10] SDELETE        - Borrado seguro de archivos (sobrescritura)"
        Write-Host " 🔐 [11] ACCESSENUM     - Examina permisos de carpetas y archivos"
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER AL MENU PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $sub = Read-MenuOption "`n ``> SELECCIONE (1-11 o X)" -Valid @("1","2","3","4","5","6","7","8","9","10","11","X")
        if ($sub -eq "X") { break }
        
        $toolMap = @{
            "1"  = "procexp64.exe"
            "2"  = "autoruns64.exe"
            "3"  = "procmon64.exe"
            "4"  = "tcpview64.exe"
            "5"  = "RAMMap64.exe"
            "6"  = "vmmap64.exe"
            "7"  = "disk2vhd64.exe"
            "8"  = "winobj64.exe"
            "9"  = "sigcheck64.exe"
            "10" = "sdelete64.exe"
            "11" = "AccessEnum.exe"
        }
        
        $toolName = $toolMap[$sub]
        $dest = "$PSScriptRoot\$toolName"
        
        if (-not (Test-Path $dest)) {
            Write-Host "`n[+] Descargando $toolName desde live.sysinternals.com..." -ForegroundColor $COLOR_PRIMARY
            try {
                Invoke-WebRequest -Uri "https://live.sysinternals.com/$toolName" -OutFile $dest -UseBasicParsing
                Write-Host "[✔] Descargado correctamente" -ForegroundColor Green
            } catch {
                Write-Host "[✘] Error al descargar: $_" -ForegroundColor $COLOR_DANGER
                Pause-Enter " ENTER"
                continue
            }
        }
        
        Write-Host "[+] Ejecutando $toolName..." -ForegroundColor $COLOR_PRIMARY
        Start-Process $dest -Verb RunAs
    }
	
}
		"T" { Invoke-RemoteDesktop }
        "A" { Invoke-Engine "BACKOP" "RESPALDO" }
        "B" { Invoke-Engine "RESTORE" "RESTAURACION" }
        "C" { Invoke-DriverManagement }
        "D" { Show-DiagnosticMenu }
        "E" { Invoke-TempOptimizer }
        "F" { 
            $url = "https://christitus.com/win"
            if(Confirm-RemoteScript $url){
                $file = Download-RemoteScript $url
                $hash = Get-FileHashSafe $file
                Write-Host "`n [+] DESCARGADO EN: $file" -ForegroundColor $COLOR_PRIMARY
                if($hash){ Write-Host " [+] SHA256: $hash" -ForegroundColor $COLOR_MENU }
                Write-Log "REMOTE" "Downloaded url=$url file=$file sha256=$hash"
                $go = Read-MenuOption " EJECUTAR AHORA? (S/N)" -Valid @("S","N")
                if($go -eq "S"){
                    Write-Log "REMOTE" "Executing file=$file"
                    & powershell -NoProfile -ExecutionPolicy Bypass -File $file
                }
                Pause-Enter " OK. ENTER"
            }
        }
        "G" { Invoke-MassGraveIntegrated
				
			}
        "H" { Invoke-WingetMenu }
        "I" { Invoke-KitPostFormat }
        "J" { 
            while($true){ 
                Show-MainTitle
				Write-Host "`n 👥 GESTION USUARIOS" -ForegroundColor $COLOR_MENU
                Write-Host " 👤 Usuarios locales / administrar comun" -ForegroundColor $COLOR_PRIMARY
                Write-Host "  📋 [A] LISTAR USUARIOS"
                Write-Host "  ➕ [B] CREAR LOCAL ADMIN"
                Write-Host "  ❌ [C] ELIMINAR USUARIO`n" -ForegroundColor $COLOR_MENU
                Write-Host " 👑 Admin Oculto" -ForegroundColor $COLOR_PRIMARY
                Write-Host "  ✅ [D] ACTIVAR SUPER ADMIN"
                Write-Host "  ⛔ [E] DESACTIVAR SUPER ADMIN"
                Write-Host "  🔑 [F] CAMBIAR PASSWORD"

                Write-Host ""
                Write-Host " 💡 Ejecutar el comando: Escribe net user administrador /active:yes (o net user administrator /active:yes si tu Windows está en inglés) y presiona Enter." -ForegroundColor $COLOR_ALERT
                Write-Host "para activar y desactivar`n" -ForegroundColor $COLOR_MENU
                Write-Host " ⌨️ CONTROL" -ForegroundColor Gray
                Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
                Write-Host "  ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $u = Read-MenuOption "`n `> SELECCIONE:" -Valid @("A","B","C","D","E","F","X")
                if($u -eq "X"){ break }

                if(-not (Require-Admin "gestión de usuarios")){ continue }

                switch($u){
                    "A" {
                        Show-MainTitle
                        Write-Host " Listando usuarios..." -ForegroundColor $COLOR_PRIMARY
                        net user
                        Pause-Enter " ENTER PARA CONTINUAR"
                    }
                    "B" {
                        Show-MainTitle
                        Write-Host " Creando local admin..." -ForegroundColor $COLOR_PRIMARY
                        $n = (Read-Host " NOMBRE").Trim()
                        if($n){
                            net user "$n" /add
                            net localgroup administrators "$n" /add
                            Write-Log "USER" "Created admin user=$n"
                            Write-Host " ✅ Usuario admin '$n' creado correctamente" -ForegroundColor $COLOR_PRIMARY
                        }
                        Pause-Enter " ENTER PARA CONTINUAR"
                    }
                    "C" {
                        Show-MainTitle
                        Write-Host " Eliminando usuario..." -ForegroundColor $COLOR_PRIMARY
                        $n = (Read-Host " NOMBRE").Trim()
                        if($n -and ($n.ToLower() -ne $env:USERNAME.ToLower())){
                            if (Confirm-Critical "ELIMINAR USUARIO '$n'" "BORRAR"){
                                net user "$n" /delete
                                Write-Host " ✅ Usuario '$n' eliminado" -ForegroundColor $COLOR_PRIMARY
                                Write-Log "USER" "Deleted user=$n"
                            }
                        } else {
                            Write-Host "`n [!] No se puede eliminar el usuario actual ($env:USERNAME)." -ForegroundColor $COLOR_DANGER
                        }
                        Pause-Enter " ENTER PARA CONTINUAR"
                    }
                    "D" {
                        Show-MainTitle
                        if(-not (Confirm-Critical "ACTIVAR CUENTA ADMINISTRATOR (SUPER ADMIN)" "APLICAR")){ break }
                        $adminUser = Get-AdminUsername
                        net user $adminUser /active:yes
                        Write-Host " ✅ Super administrador ACTIVADO ($adminUser)" -ForegroundColor $COLOR_PRIMARY
                        Write-Log "USER" ("Activated built-in administrator account: " + $adminUser)
                        Pause-Enter " ENTER PARA CONTINUAR"
                    }
                    "E" {
                        Show-MainTitle
                        if(-not (Confirm-Critical "DESACTIVAR CUENTA ADMINISTRATOR (SUPER ADMIN)" "APLICAR")){ break }
                        $adminUser = Get-AdminUsername
                        net user $adminUser /active:no
                        Write-Host " ✅ Super administrador DESACTIVADO ($adminUser)" -ForegroundColor $COLOR_PRIMARY
                        Write-Log "USER" ("Deactivated built-in administrator account: " + $adminUser)
                        Pause-Enter " ENTER PARA CONTINUAR"
                    }
                    "F" {
                        Show-MainTitle
                        Write-Host " Cambiando password..." -ForegroundColor $COLOR_PRIMARY
                        $n = (Read-Host " USUARIO").Trim()
                        $p = Read-Host " CLAVE NUEVA" 
                        if($n -and $p){
                            if (Confirm-Critical "CAMBIAR PASSWORD DE '$n'" "APLICAR"){
                                net user "$n" $p
                                Write-Host " ✅ Password de '$n' actualizada" -ForegroundColor $COLOR_PRIMARY
                                Write-Log "USER" "Password changed for user=$n"
                            }
                        }
                        Pause-Enter " ENTER PARA CONTINUAR"
                    }
                    default {
                        Write-Host " [!] Opción no válida. Intenta de nuevo." -ForegroundColor $COLOR_DANGER
                        Start-Sleep 1.5
                    }
                }
            }
        }
	    "K" { 
            while($true){ 
                Show-MainTitle
				Write-Host "`n 🛠️ SOPORTE TECNICO PRO" -ForegroundColor $COLOR_MENU
                Write-Host " 💾 [A] SALUD DISCO"
                Write-Host " 🔧 [B] REPARAR SISTEMA"
                Write-Host " 🔑 [C] CLAVE BIOS - Recupera la licencia original del equipo."
                Write-Host " ⏰ [D] SINCRONIZAR HORA"
                Write-Host " 🔋 [F] SALUD DE BATERIA"
                Write-Host " 🌡️ [T] TEMPERATURAS CPU/GPU - Monitoreo en tiempo real" -ForegroundColor $COLOR_MENU	
                Write-Host " ℹ️ [G] INFO TÉCNICA COMPLETA (HW/SW)"
                Write-Host " ⚡ [Z] MODO DIOS - Todos los accesos de configuración" -ForegroundColor $COLOR_MENU
                Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
                Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
                Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER

                $s = Read-MenuOption ([Environment]::NewLine + ' >') -Valid @("A","B","C","D","F","G","T","Z","X")
                if ($s -eq "X") { break }

                if ($s -eq "A") {
                    Write-Host "`n[+] Verificando salud de discos..." -ForegroundColor $COLOR_PRIMARY
                    Get-PhysicalDisk | Format-Table -AutoSize FriendlyName, MediaType, HealthStatus, OperationalStatus
                    chkdsk C:
                    Pause-Enter "`n ENTER"
                }
                if ($s -eq "B") {
                    if (-not (Require-Admin "reparar el sistema")) { continue }
                    Write-Host "`n[+] Ejecutando SFC /SCANNOW..." -ForegroundColor $COLOR_PRIMARY
                    sfc /scannow
                    Write-Host "`n[+] Ejecutando DISM /RestoreHealth..." -ForegroundColor $COLOR_PRIMARY
                    dism /online /cleanup-image /restorehealth
                    Pause-Enter "`n ENTER"
                }
                if ($s -eq "C") {
                    Write-Host "`n[+] Recuperando clave de producto OEM (BIOS)..." -ForegroundColor $COLOR_PRIMARY
                    $key = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
                    if ($key) { Write-Host " CLAVE ORIGINAL: $key" -ForegroundColor Green }
                    else { Write-Host " No se encontró clave OEM en la BIOS." -ForegroundColor $COLOR_DANGER }
                    Pause-Enter "`n ENTER"
                }
                if ($s -eq "D") {
                    if (-not (Require-Admin "sincronizar hora")) { continue }
                    Write-Host "`n[+] Sincronizando hora..." -ForegroundColor $COLOR_PRIMARY
                    net stop w32time | Out-Null; net start w32time | Out-Null
                    w32tm /resync /force
                    Write-Host " Hora sincronizada." -ForegroundColor Green
                    Pause-Enter " ENTER"
                }
                if ($s -eq "F") {
                    Show-BatteryHealth
                }
                if ($s -eq "G") {
                    Show-FullSystemInfo
                }
                if ($s -eq "T") {
                    Show-Temperatures
                }
                if ($s -eq "Z") {
                    Write-Host "`n[+] Abriendo Modo Dios (Todos los accesos de configuración)..." -ForegroundColor $COLOR_PRIMARY
                    Write-Host "    Se abrirá una carpeta especial con TODAS las herramientas de Windows." -ForegroundColor $COLOR_ALERT
                    Start-Process "explorer.exe" "shell:::{ED7BA470-8E54-465E-825C-99712043E01C}"
                    Pause-Enter "`n ENTER para volver"
                }
            }
        }
        "L" { 
            while($true){ 
                Show-MainTitle
				Write-Host "`n 🚀 BYPASS WINDOWS 11" -ForegroundColor $COLOR_ALERT
                Write-Host " 🔓 [A] BYPASS HARDWARE   - Omitir TPM, SecureBoot y chequeos de RAM"
                Write-Host " 🌐 [B] BYPASS INTERNET   - Evitar conexión a Internet durante la instalación"
                Write-Host " 📊 [C] VER ESTADO ACTUAL (REGISTRO)"
                Write-Host " 🔄 [D] REVERTIR BYPASS HARDWARE"
                Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
                Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
                Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER

                $b = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","X")
                if (-not $b) { continue }
                if ($b -eq "X") { break }

                $reg = "HKLM:\System\Setup\LabConfig"

                if ($b -eq "A") {
                    if (-not (Require-Admin "aplicar bypass Windows 11")) { continue }
                    if (-not (Confirm-Critical "BYPASS HARDWARE (LabConfig)" "APLICAR")) { continue }
                    Write-Host "`n [+] Aplicando bypass de hardware..." -ForegroundColor $COLOR_PRIMARY
                    if (-not (Test-Path $reg)) { New-Item $reg -Force | Out-Null }
                    "BypassTPMCheck","BypassSecureBootCheck","BypassRAMCheck" | ForEach-Object {
                        New-ItemProperty -Path $reg -Name $_ -Value 1 -PropertyType DWord -Force | Out-Null
                    }
                    Write-Log "BYPASS" "Applied hardware bypass LabConfig"
                    Pause-Enter " OK"
                }

                if ($b -eq "B") {
                    Write-Host "`n [+] Aplicando bypass de Internet..." -ForegroundColor $COLOR_PRIMARY
                    if (Test-Path "$env:SystemRoot\System32\oobe\bypassnro.cmd") {
                        & "$env:SystemRoot\System32\oobe\bypassnro.cmd"
                        Write-Log "BYPASS" "Ran bypassnro.cmd"
                    } else {
                        Write-Host " [!] El archivo bypassnro.cmd no existe. Este bypass solo funciona durante la instalación (OOBE)." -ForegroundColor $COLOR_DANGER
                    }
                    Pause-Enter " OK"
                }

                if ($b -eq "C") {
                    Show-MainTitle
                    Write-Host "`n ESTADO LabConfig:" -ForegroundColor $COLOR_ALERT
                    if (Test-Path $reg) {
                        Get-ItemProperty $reg -ErrorAction SilentlyContinue | Select-Object BypassTPMCheck, BypassSecureBootCheck, BypassRAMCheck | Format-List
                    } else {
                        Write-Host " (No existe)" -ForegroundColor $COLOR_MENU
                    }
                    Pause-Enter " ENTER"
                }

                if ($b -eq "D") {
                    if (-not (Require-Admin "revertir bypass Windows 11")) { continue }
                    if (-not (Confirm-Critical "REVERTIR BYPASS HARDWARE (LabConfig)" "APLICAR")) { continue }
                    if (Test-Path $reg) {
                        "BypassTPMCheck","BypassSecureBootCheck","BypassRAMCheck" | ForEach-Object {
                            try { Remove-ItemProperty -Path $reg -Name $_ -ErrorAction SilentlyContinue } catch {}
                        }
                    }
                    Write-Log "BYPASS" "Reverted hardware bypass LabConfig"
                    Pause-Enter " OK"
                }
            }
        }
		"M" {  
    while($true){ 
        Show-MainTitle
		Write-Host "`n 🌐 RED Y REPARACION" -ForegroundColor $COLOR_MENU
        Write-Host ' 🔄 [A] RESETEAR RED           🧭 [F] TRAZA DE RUTA (TRACERT)'
        Write-Host ' 🔧 [B] REPARAR UPDATE         ⚡ [G] TEST VELOCIDAD (FAST.COM)'
        Write-Host " 📡 [C] VER IP                 🔑 [E] VER CLAVES WI FI"
        Write-Host " 📊 [D] PING MONITOR           🦈 [W] WIRESHARK - Análisis gráfico de red"
        Write-Host " 🗑️ [H] LIMPIAR DNS CACHE      🔍 [P] ESCANEAR PUERTOS (IP local)" -ForegroundColor $COLOR_MENU
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $m = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","E","F","G","H","P","W","X")
        if(-not $m){ continue }
        if($m -eq "X"){break}
        
        if($m -eq "A"){
            if(-not (Require-Admin "resetear red")){ continue }
            netsh winsock reset
            netsh int ip reset
            ipconfig /flushdns
            Write-Host "`n ✅ RED RESTAURADA. Es posible que necesites reiniciar." -ForegroundColor Green
            Pause-Enter " OK"
        }
        if($m -eq "B"){
            if(-not (Require-Admin "reparar Windows Update")){ continue }
            if(-not (Confirm-Critical "REPARAR WINDOWS UPDATE (LIMPIA SOFTWAREDISTRIBUTION)" "APLICAR")){ continue }
            $demo = Read-MenuOption " MODO DEMO (S=solo mostrar, N=ejecutar)" -Valid @("S","N")
            $isDemo = ($demo -eq "S")
            Write-Log "UPDATE" "RepairUpdate DemoMode=$isDemo"
            if($isDemo){
                Write-Host " (Demo) Se detendrían servicios: wuauserv, bits" -ForegroundColor $COLOR_ALERT
                Write-Host " (Demo) Se limpiaría: C:\\Windows\\SoftwareDistribution\\*" -ForegroundColor $COLOR_ALERT
                Write-Host " (Demo) Se iniciarían servicios: wuauserv, bits" -ForegroundColor $COLOR_ALERT
            } else {
                "wuauserv","bits" | ForEach-Object { Stop-Service $_ -Force -ErrorAction SilentlyContinue }
                Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
                "wuauserv","bits" | ForEach-Object { Start-Service $_ -ErrorAction SilentlyContinue }
            }
            Pause-Enter " OK"
        }
        if($m -eq "C"){
            Get-NetIPAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -notmatch "Loopback" | Format-Table
            Pause-Enter " ENTER"
        }
        if($m -eq "D"){
            $target = Read-Host ([Environment]::NewLine + ' IP O DOMINIO (DEFECTO 8.8.8.8)'); if(!$target){$target="8.8.8.8"}
            Write-Host "`n PING a $target (presiona cualquier tecla para detener)" -ForegroundColor $COLOR_ALERT
            while($true){
                Test-Connection $target -Count 1 -ErrorAction SilentlyContinue
                if([console]::KeyAvailable){ break }
                Start-Sleep -Seconds 1
            }
            Write-Host "`n ✅ MONITOREO DETENIDO" -ForegroundColor Green
            Pause-Enter " ENTER"
        } 
        if($m -eq "E"){
            Show-MainTitle
            Write-Host "`n CLAVES WI FI" -ForegroundColor $COLOR_PRIMARY
            Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
            $profiles = netsh wlan show profiles | Select-String "\:(.+)$" | ForEach-Object {$_.Matches.Groups[1].Value.Trim()}
            if($profiles.Count -eq 0){
                Write-Host " [!] No se encontraron redes Wi-Fi guardadas." -ForegroundColor $COLOR_DANGER
            } else {
                foreach($name in $profiles){
                    $passLine = (netsh wlan show profile name="$name" key=clear) | Select-String "Contenido de la clave|Key Content"
                    if($passLine){ 
                        $pass = $passLine.ToString().Split(":")[1].Trim()
                        Write-Host " 📡 $name" -ForegroundColor $COLOR_MENU
                        Write-Host "    🔑 Clave: $pass" -ForegroundColor Green
                    } else {
                        Write-Host " 📡 $name (sin clave guardada)" -ForegroundColor Gray
                    }
                }
            }
            Pause-Enter "`n ENTER PARA VOLVER"
        }
        if($m -eq "F"){ 
            $target = Read-Host " DOMINIO (ej: google.com)"
            if($target){ tracert $target }
            Pause-Enter " ENTER"
        }
        if($m -eq "G"){ 
            Write-Host "`n[+] Abriendo fast.com para test de velocidad..." -ForegroundColor $COLOR_PRIMARY
            Start-Process "https://fast.com"
            Pause-Enter " OK"
        }
        if($m -eq "H"){
            Write-Host "`n[+] LIMPIANDO DNS CACHE..." -ForegroundColor $COLOR_PRIMARY
            ipconfig /flushdns | Out-Null
            Write-Host "   ✅ DNS cache limpiada" -ForegroundColor Green
            Write-Host "[+] RENOVANDO IP..." -ForegroundColor $COLOR_PRIMARY
            ipconfig /renew | Out-Null
            Write-Host "   ✅ IP renovada" -ForegroundColor Green
            Write-Host "[+] RESETEANDO WINSOCK..." -ForegroundColor $COLOR_PRIMARY
            netsh winsock reset | Out-Null
            Write-Host "   ✅ Winsock reseteado" -ForegroundColor Green
            Write-Host "[+] RESETEANDO TCP/IP..." -ForegroundColor $COLOR_PRIMARY
            netsh int ip reset | Out-Null
            Write-Host "   ✅ TCP/IP reseteado" -ForegroundColor Green
            Write-Host "`n ⚠️ Es posible que necesites REINICIAR para que los cambios surtan efecto." -ForegroundColor Yellow
            Pause-Enter " ENTER"
        }
        if($m -eq "P"){
            $target = Read-Host "`n IP A ESCANEAR (ENTER para 127.0.0.1 o ej: 192.168.1.1)"
            if(-not $target) { $target = "127.0.0.1" }
            
            Write-Host "`n[+] ESCANEANDO PUERTOS DE $target ..." -ForegroundColor $COLOR_PRIMARY
            Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
            
            $puertos = @(21,22,23,25,53,80,110,135,139,143,443,445,993,995,1433,3306,3389,5432,5900,8080)
            $abiertos = @()
            $cerrados = 0
            
            foreach ($port in $puertos) {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $asyncResult = $tcpClient.BeginConnect($target, $port, $null, $null)
                $wait = $asyncResult.AsyncWaitHandle.WaitOne(200, $false)
                
                if ($wait) {
                    $abiertos += $port
                    Write-Host "   ✅ PUERTO $port : ABIERTO" -ForegroundColor Green
                } else {
                    $cerrados++
                    Write-Host "   ❌ PUERTO $port : CERRADO" -ForegroundColor DarkGray
                }
                $tcpClient.Close()
            }
            
            Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
            Write-Host " 📊 RESUMEN:" -ForegroundColor Cyan
            Write-Host "    ✅ Puertos abiertos: $($abiertos.Count)" -ForegroundColor Green
            Write-Host "    ❌ Puertos cerrados: $cerrados" -ForegroundColor DarkGray
            if ($abiertos.Count -gt 0) {
                Write-Host "`n    Puertos abiertos: $($abiertos -join ', ')" -ForegroundColor $COLOR_MENU
            }
            Pause-Enter "`n ENTER"
        }
        if($m -eq "W") {
            $installed = Get-Command wireshark -ErrorAction SilentlyContinue
            if (-not $installed) {
                Write-Host "`n [+] Instalando Wireshark..." -ForegroundColor Yellow
                winget install WiresharkFoundation.Wireshark --silent
                Start-Sleep -Seconds 5
                Write-Host " [✔] Wireshark instalado." -ForegroundColor Green
            }
            Write-Host "`n [+] Abriendo Wireshark..." -ForegroundColor Yellow
            Start-Process "wireshark"
            Pause-Enter " ENTER después de cerrar Wireshark"
        }		
    }
}
        "N" { 
            while($true){ 
                Show-MainTitle; Write-Host "`n MANTENIMIENTO DE DISCOS" -ForegroundColor $COLOR_MENU
                Write-Host " [A] DESFRAGMENTAR HDD`n [B] OPTIMIZAR SSD`n [C] LIMPIEZA DISM"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $o = Read-MenuOption ([Environment]::NewLine + ' >') -Valid @("A","B","C","X")
                if(-not $o){ continue }
                if($o -eq "X"){break}
                if(-not (Require-Admin "mantenimiento de discos")){ continue }
                if($o -eq "A"){
                    if(-not (Confirm-Critical "DESFRAGMENTAR/OPTIMIZAR DISCO C:" "APLICAR")){ continue }
                    defrag C: /O
                    Pause-Enter " OK"
					Clear-Host #nuevo
                }
                if($o -eq "B"){
                    if(-not (Confirm-Critical "OPTIMIZAR SSD (TRIM) EN DISCO C:" "APLICAR")){ continue }
                    Optimize-Volume -DriveLetter C -ReTrim -Verbose
                    Pause-Enter " OK"
					Clear-Host #nuevo
                }
                if($o -eq "C"){
                    if(-not (Confirm-Critical "LIMPIEZA DISM (STARTCOMPONENTCLEANUP)" "APLICAR")){ continue }
                    dism /online /Cleanup-Image /StartComponentCleanup
                    Pause-Enter " OK"
					Clear-Host #nuevo
                }
            }
        }
        "O" { Show-LiveMonitor }
		"Y" { Invoke-PasswordGenerator }
        "P" { Invoke-DefenderControl }
		"Z" { Invoke-DownloadCenter }
        "X" { exit }
    }
}
