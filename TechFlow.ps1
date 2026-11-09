[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ruta raíz anclada a C:\TechFlow_Suite_Pro_v6
$Global:AppRoot = "C:\TechFlow_Suite_Pro_v6"
$ModulesPath = Join-Path $Global:AppRoot "Modules"

$Global:COLOR_PRIMARY = "Green"
$Global:COLOR_ALERT   = "Yellow"
$Global:COLOR_DANGER  = "Red"
$Global:COLOR_MENU    = "Cyan"
$Global:COLOR_WARNING = "Yellow"
$Global:LINEA         = " ═══════════════════════════════════════════════════════════════════"

function Show-MainTitle {
    Clear-Host
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
 ║                            PRO EDITION v7.0 (MODULAR)                            ║
 ║                                                                                  ║
 ║                    SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                   ║
 ║                                                                                  ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}

function Show-OriginalBanner { Show-MainTitle }

# Cargar módulos
$RequiredModules = @(
    "Core.ps1",
    "AppsKit.ps1",
    "BackupRestore.ps1",
    "Maintenance.ps1",
    "HardwareTools.ps1",
    "MediaDownloader.ps1"
)

foreach ($Module in $RequiredModules) {
    $ModulePath = Join-Path $ModulesPath $Module
    if (Test-Path $ModulePath) {
        . $ModulePath
    } else {
        Write-Host " [FATAL] No se encontró el módulo: $Module" -ForegroundColor Red
        Write-Host " Ruta esperada: $ModulePath" -ForegroundColor Yellow
        Read-Host " Presiona ENTER para salir..."
        exit
    }
}

# ============================================================
# PANTALLA PREVIA INTERACTIVA DE INICIO
# ============================================================
Invoke-StartupChecks

# ============================================================
# BUCLE DEL MENÚ PRINCIPAL
# ============================================================
while ($true) {
    Show-MainTitle
    
    $horaActual = Get-Date -Format "HH:mm:ss"
    Write-Host "`n ✅ SISTEMA OK | 👤 USUARIO $env:USERNAME | ⏰ HORA: $horaActual" -ForegroundColor Gray
    Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
    
    Write-Host "    💾 [A] BACKUP TOTAL             🧹 [E] OPTIMIZAR TEMP           📦 [I] KIT POST FORMAT" -ForegroundColor Green
    Write-Host "    📀 [B] RESTORE TOTAL            🛠️ [F] WIN UTIL TITUS           👥 [J] GESTION USUARIOS" -ForegroundColor Green
    Write-Host "    🔧 [C] GESTION DRIVERS          🔑 [G] MICROSOFT OFFICE AIO     🛠️ [K] SOPORTE TECNICO PRO" -ForegroundColor Green
    Write-Host "    🧹 [D] PURGA Y FORMATEO         📦 [H] GESTION PAQUETES PRO     🚀 [L] BYPASS WINDOWS 11" -ForegroundColor Green
    Write-Host "    🌐 [M] RED Y REPARACION         💾 [N] MANTENIM DISCO           📊 [O] MONITOR EN VIVO (PRO)" -ForegroundColor Green
    Write-Host "    🛡️ [P] WINDOWS DEFENDER TOTAL   ⚡ [Q] AUTO-FLOW (EXPRESS)      🛠️ [U] SYSINTERNALS KIT" -ForegroundColor Green
    Write-Host "    🖥️ [T] ESCRITORIO REMOTO        🔐 [Y] GENERADOR CONTRASEÑAS    🎵 [Z] CENTRO DESCARGAS (yt-dlp)" -ForegroundColor Green
    
    Write-Host "`n ⚙️ CONFIGURACION Y VISTA" -ForegroundColor Gray
    Write-Host "  -----------------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "    🔄 [R] REFRESCAR MENU" -ForegroundColor Cyan
    Write-Host "    ❌ [X] SALIR DEL SCRIPT" -ForegroundColor Red

        $opt = ""
    try {
        $rawOpt = Read-Host "`n > OPCION"
        if ($null -ne $rawOpt) { $opt = $rawOpt.Trim().ToUpper() }
    } catch {
        # Si se presiona Ctrl+C en el mismo prompt de entrada
        continue
    }
    
    try {
        switch ($opt) {
            "R" { continue }
            "A" { Invoke-Engine "BACKOP" "RESPALDO" }
            "B" { Invoke-Engine "RESTORE" "RESTAURACION" }
            "C" { Invoke-DriverManagement }
            "D" { Show-DiagnosticMenu }
            "E" { Invoke-TempOptimizer }
            "F" { Invoke-WinUtilTitus } 
            "G" { Invoke-OfficeAIO }
            "H" { Invoke-WingetMenu }
            "I" { Invoke-KitPostFormat }
            "J" { Invoke-UserManager } 
            "K" { Invoke-TechSupport } 
            "L" { Invoke-Win11Bypass } 
            "M" { Invoke-NetworkRepair }
            "N" { Invoke-DiskMaintenance }
            "O" { Show-LiveMonitor }
            "P" { Invoke-DefenderControl }
            "Q" { Invoke-AutoFlow }
            "T" { Invoke-RemoteDesktop }
            "U" { Invoke-SysinternalsKit } 
            "Y" { Invoke-PasswordGenerator }
            "Z" { Invoke-DownloadCenter }
                    "X" { 
            # Auto-escaneo silencioso de contexto al cerrar sesión
            if (Test-Path "$Global:AppRoot\DevTools\AI_SCANNER.ps1") {
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Global:AppRoot\DevTools\AI_SCANNER.ps1`"" -WindowStyle Hidden
            }
            break 
        }
            default { 
                if ($opt -ne "") {
                    Write-Host " Opción no válida." -ForegroundColor Red
                    Start-Sleep -Milliseconds 600
                }
            }
        }
    } catch {
        Write-Host "`n [!] Tarea interrumpida o retornada al menú." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 800
    }
}







