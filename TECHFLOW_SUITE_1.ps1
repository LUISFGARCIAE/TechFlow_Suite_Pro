Clear-Host #nuevo﻿
# ============================================================
# [SISTEMA] - AUTO-ELEVACIÓN A ADMINISTRADOR
# ============================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -nologo -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
    exit
}

# --- CONFIGURACIÓN DE RUTAS, COLORES Y VARIABLES GLOBALES ---
$CONFIG_FILE = "$PSScriptRoot\suite_config.dat"
$COLOR_PRIMARY = "Green"; $COLOR_ALERT = "Yellow"; $COLOR_DANGER = "Red"; $COLOR_MENU = "Cyan"
$Global:MenuHorizontal = $true

# --- GESTIÓN DE CREDENCIALES Y ACCESO (MASTER PASSWORD) ---
if (!(Test-Path $CONFIG_FILE)) { "ADMIN2026" | Out-File $CONFIG_FILE -Encoding ascii -Force }
$Global:MasterPass = (Get-Content $CONFIG_FILE -Raw).Trim()

# --- DEFINICIÓN DE ESTRUCTURA DE USUARIO Y BACKUP ---
$USER_FOLDER_NAMES = @("Desktop", "Documents", "Pictures", "Videos", "Music", "Downloads", "Favorites", "Contacts")
$USER_FOLDERS = $USER_FOLDER_NAMES
$DEFAULT_BACKUP_BASE = "$env:SystemDrive\Backups"

# --- INICIALIZACIÓN DE ARCHIVOS DE REGISTRO (LOGS) Y PREFERENCIAS ---
$LOG_FILE = Join-Path $PSScriptRoot ("techflowlog_" + (Get-Date).ToString("yyyyMMdd") + ".log")
$PREFS_FILE = Join-Path $PSScriptRoot "suite_prefs.json"

# ========== NUEVA FUNCIÓN: ROTACIÓN DE LOGS ==========
function Rotate-Log {
    param([string]$LogPath = $LOG_FILE)
    try {
        if (Test-Path $LogPath) {
            $fileInfo = Get-Item $LogPath -ErrorAction SilentlyContinue
            if ($fileInfo.Length -gt 10MB) {  # 10 MB
                $oldLog = $LogPath -replace '\.log$', '_old.log'
                # Eliminar backup anterior si existe
                if (Test-Path $oldLog) {
                    Remove-Item $oldLog -Force -ErrorAction SilentlyContinue
                    Write-Host "[LOG] Backup anterior eliminado" -ForegroundColor DarkGray
                }
                # Mover el log actual a backup
                Move-Item $LogPath $oldLog -Force -ErrorAction Stop
                Write-Host "[LOG] Rotación completada: $oldLog" -ForegroundColor Green
                Write-Log "INFO" "Log rotated (size >10MB). Old log: $oldLog"
            }
        }
    } catch {
        # No falla el script si la rotación tiene error
        Write-Host "[LOG] Error en rotación: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# Ejecutar rotación al inicio del script
Rotate-Log

function Clear-PendingDeletes {
    $pendingDir = "$env:TEMP\_pending_delete_"
    if (Test-Path $pendingDir) {
        Write-Host "[LIMPIADOR] Eliminando archivos pendientes del reinicio anterior..." -ForegroundColor DarkGray
        try {
            Remove-Item "$pendingDir\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item $pendingDir -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}
Clear-PendingDeletes

# --- MOTOR DE LOGGING Y REGISTRO DE EVENTOS ---
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message,
        [switch]$NoConsole
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "$ts [$Level] $Message"
    
    # Escribir en archivo
    Add-Content -Path $LOG_FILE -Value $logEntry -Encoding utf8 -ErrorAction SilentlyContinue
    
    # Mostrar en consola (excepto si NoConsole está activado)
    if (-not $NoConsole) {
        switch ($Level) {
            "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
            "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "INFO"    { Write-Host $logEntry -ForegroundColor Gray }
            default   { Write-Host $logEntry }
        }
    }
}

# Agregar función para obtener estadísticas del log
function Get-LogStats {
    if (Test-Path $LOG_FILE) {
        $lines = Get-Content $LOG_FILE -ErrorAction SilentlyContinue
        $errorCount = ($lines | Select-String "\[ERROR\]").Count
        $warnCount = ($lines | Select-String "\[WARN\]").Count
        $size = (Get-Item $LOG_FILE).Length
        Write-Host "`n📊 ESTADÍSTICAS DE LOG:" -ForegroundColor Cyan
        Write-Host "  Archivo: $LOG_FILE"
        Write-Host "  Tamaño: $([math]::Round($size/1KB,2)) KB"
        Write-Host "  Líneas totales: $($lines.Count)"
        Write-Host "  Errores: $errorCount"
        Write-Host "  Advertencias: $warnCount"
    }
}
# --- LECTURA DE CONFIGURACION PERSISTENTE ---
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

# --- GUARDADO DE CONFIGURACION PERSISTENTE ---
function Save-Prefs($prefs){
    try {
        ($prefs | ConvertTo-Json -Depth 5) | Out-File -FilePath $PREFS_FILE -Encoding utf8 -Force
        Write-Log "INFO" "Prefs saved to $PREFS_FILE"
    } catch {
        Write-Log "WARN" ("Prefs save failed: " + $_.Exception.Message)
    }
}

# --- PAUSA ESTANDAR CON MENSAJE ---
function Pause-Enter {
    param([string]$Message = " PRESIONE ENTER PARA VOLVER")
    Read-Host $Message | Out-Null
}

# --- LECTOR DE OPCIONES DE MENU ROBUSTO ---
function Read-MenuOption {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string[]]$Valid = @(),
        [switch]$AllowEmpty
    )
    while ($true) {
        $raw = Read-Host $Prompt
        if (-not $raw -or -not $raw.Trim()) {
            # Enter vacío: no repreguntar aquí (evita prompts duplicados). El caller decide si refresca o sale.
            return ""
        }
        $opt = $raw.Trim().ToUpper()
        if ($Valid.Count -eq 0 -or $Valid -contains $opt) { return $opt }
        Write-Host "`n [!] OPCIÓN NO VÁLIDA: $opt" -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 1
    }
}

# --- DETECTOR DE PERMISOS ADMINISTRADOR (VERIFICA TOKEN DE SEGURIDAD) ---
function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

# --- IDENTIFICADOR DE USUARIO ADMIN LOCALIZADO (DETECTA ESPAÑOL/INGLES) ---
function Get-AdminUsername {
    $locale = (Get-WinSystemLocale).Name
    if ($locale -like "*es*") {
        return "administrador"
    } else {
        return "administrator"
    }
}

# --- VALIDADOR Y SOLICITADOR DE ADMIN (VERIFICA Y ADVIERTE SI NO ES ADMIN) ---
function Require-Admin {
    param([string]$ActionName = "esta operación")
    if (-not (Test-IsAdmin)) {
        Write-Host "`n [!] Requiere permisos de ADMIN para $ActionName." -ForegroundColor $COLOR_DANGER
        Write-Host "     Cierra y ejecuta PowerShell como Administrador." -ForegroundColor $COLOR_ALERT
        Write-Log "WARN" "Admin required for: $ActionName"
        Pause-Enter " ENTER"
        return $false
    }
    return $true
}

# --- DETECTOR DE CONEXION A INTERNET (PING A 1.1.1.1) ---
function Test-HasInternet {

    try {
        return Test-Connection -ComputerName "1.1.1.1" -Count 1 -Quiet -ErrorAction SilentlyContinue
    } catch {
        return $false
    }
}

# --- CONFIRMACION DE OPERACIONES CRITICAS (PIN + KEYWORD) ---
function Confirm-Critical {

    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Keyword
    )
    Show-MainTitle
    Write-Host "`n OPERACIÓN CRÍTICA: $Title" -ForegroundColor $COLOR_DANGER
    $pin = Get-Random -Min 1000 -Max 9999
    Write-Host "`n PIN DE SEGURIDAD $pin" -BackgroundColor Red -ForegroundColor White
    $p = Read-Host " INGRESE PIN PARA CONFIRMAR"
    if ($p -ne $pin.ToString()) {
        Write-Host "`n [!] PIN INCORRECTO." -ForegroundColor $COLOR_DANGER
        Write-Log "WARN" "Critical confirm failed (PIN): $Title"
        Start-Sleep -Seconds 1
        return $false
    }
    $k = (Read-Host " ESCRIBA '$Keyword' PARA CONTINUAR").Trim().ToUpper()
    if ($k -ne $Keyword.Trim().ToUpper()) {
        Write-Host "`n [!] PALABRA DE CONFIRMACIÓN INCORRECTA." -ForegroundColor $COLOR_DANGER
        Write-Log "WARN" "Critical confirm failed (keyword): $Title"
        Start-Sleep -Seconds 1
        return $false
    }
    Write-Log "INFO" "Critical confirmed: $Title"
    return $true
}

# --- CONFIRMACION DE SCRIPTS REMOTOS (URL + INTERNET) ---
function Confirm-RemoteScript {

    param([Parameter(Mandatory = $true)][string]$Url)
    Show-MainTitle
    Write-Host "`n [!] SE EJECUTARÁ UN SCRIPT REMOTO:" -ForegroundColor $COLOR_ALERT
    Write-Host "     $Url" -ForegroundColor $COLOR_MENU
    Write-Host "     Esto puede modificar el sistema." -ForegroundColor $COLOR_ALERT
    $ok = Read-MenuOption " CONTINUAR? (S/N)" -Valid @("S","N")
    if ($ok -ne "S") {
        Write-Log "INFO" "Remote script canceled: $Url"
        return $false
    }
    if (-not (Test-HasInternet)) {
        Write-Host "`n [!] Sin conexión a Internet." -ForegroundColor $COLOR_DANGER
        Write-Log "WARN" "Remote script blocked (no internet): $Url"
        Pause-Enter " ENTER"
        return $false
    }
    Write-Log "INFO" "Remote script confirmed: $Url"
    return $true
}

# --- FORMATEO DE BYTES A UNIDADES LEGIBLES (B/KB/MB/GB/TB) ---
function Format-Bytes([Int64]$Bytes) {

    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    if ($Bytes -lt 1GB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -lt 1TB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    return "{0:N2} TB" -f ($Bytes / 1TB)
}

# --- CALCULO DE TAMAÑO TOTAL DE CARPETA (RECURSIVO) ---
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

# --- OBTENER ESPACIO LIBRE DISPONIBLE EN UNA UNIDAD ---
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

# --- VALIDACIÓN DE RUTA DE RESPALDO (EVITAR CARPETAS DE SISTEMA) ---
function Is-SuspiciousBackupBase {
    param([Parameter(Mandatory = $true)][string]$Base)
    $b = $Base.Trim().ToLower()
    return ($b -like "*\\windows*" -or $b -like "*\\system32*" -or $b -like "*\\program files*")
}

# --- DETECCIÓN DE UNIDADES EXTRAÍBLES CONECTADAS (USB/DISCOS) ---
function Select-RemovableVolumes {
    try {
        return Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 2 }
    } catch {
        return @()
    }
}

# --- DESCARGA DE SCRIPTS EXTERNOS A CARPETA TEMPORAL ---
function Download-RemoteScript {
    param([Parameter(Mandatory = $true)][string]$Url)
    $dest = Join-Path $env:TEMP ("techflow_remote_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".ps1")
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $dest
    return $dest
}

# --- GENERACIÓN DE HASH SHA256 PARA VERIFICACIÓN DE ARCHIVOS ---
function Get-FileHashSafe {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    } catch {
        return $null
    }
}

# --- OBTENER RUTAS DE PERFILES DE USUARIO ACTIVOS EN EL DISCO ---
function Get-UserProfilePaths {
    $profilesPath = "$env:SystemDrive\Users"
    Get-ChildItem -Path $profilesPath -Directory | Where-Object {
        $_.Name -notin @('All Users', 'Default', 'Default User', 'Public', 'desktop.ini', 'DefaultAppPool')
    } | Select-Object -ExpandProperty FullName
}

# --- GENERAR Y CREAR NUEVA CARPETA DE RESPALDO NUMERADA (Backup_01...) ---
function Get-BackupRoot($basePath) {
    $existing = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Backup_*" } | ForEach-Object { $_.Name -replace "Backup_", "" } | Where-Object { $_ -match "^\d+$" } | Sort-Object {[int]$_} -Descending
    if ($existing) { $next = [int]$existing[0] + 1 } else { $next = 1 }
    $root = Join-Path $basePath ("Backup_" + $next.ToString("00"))
    if (!(Test-Path $root)) { New-Item -Path $root -ItemType Directory -Force | Out-Null }
    return $root
}

# --- EJECUCIÓN DE COPIA DE SEGURIDAD DE PERFIL (ROBOCOPY) ---
function Backup-ProfileData($profilePath, $backupRoot) {
    $userName = Split-Path $profilePath -Leaf
    $destRoot = Join-Path $backupRoot $userName
    foreach ($folder in $USER_FOLDER_NAMES) {
        $source = Join-Path $profilePath $folder
        $target = Join-Path $destRoot $folder
        if (Test-Path $source) {
            Write-Host " [+] RESPALDANDO $userName\$folder ..." -ForegroundColor $COLOR_PRIMARY
            robocopy $source $target /E /MT:16 /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
        }
    }
}

# --- EJECUCIÓN DE RESTAURACIÓN DE DATOS HACIA PERFIL DE USUARIO ---
function Restore-ProfileData($backupProfilePath, $TargetUsersRoot = $null) {
    $profileName = Split-Path $backupProfilePath -Leaf
    if(-not $TargetUsersRoot){ $TargetUsersRoot = "$env:SystemDrive\Users" }
    $targetRoot = Join-Path $TargetUsersRoot $profileName
    if (!(Test-Path $targetRoot)) { New-Item -Path $targetRoot -ItemType Directory -Force | Out-Null }
    Get-ChildItem -Path $backupProfilePath -Directory | ForEach-Object {
        $source = $_.FullName
        $dest = Join-Path $targetRoot $_.Name
        Write-Host " [+] RESTAURANDO $profileName\$($_.Name) ..." -ForegroundColor $COLOR_PRIMARY
        robocopy $source $dest /E /MT:16 /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    }
}

# --- INTERFAZ: DIBUJAR TÍTULO Y LOGO PRINCIPAL DE LA SUITE ---
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
 ║                                PRO EDITION v5.2                                  ║
 ║                                                                                  ║
 ║                    SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                   ║
 ║                                                                                  ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}

function Pause-Enter {
    param($Msg = "")
    Write-Host "`n Presione ENTER para continuar $Msg..." -ForegroundColor $COLOR_ALERT
    $null = Read-Host
}

# --- MOTOR DE INSTALACION HIBRIDA INTELIGENTE (CON MAPEO CHOCOLATEY) ---
function Invoke-SmartInstall ($AppID, $AppName) {
    Write-Host "`n [!] INSTALANDO: $AppName..." -ForegroundColor $COLOR_MENU
    
    # ============================================================
    # MAPEO MANUAL: ID de Winget -> Nombre corto en Chocolatey
    # ============================================================
    $chocoMapping = @{
        "Google.Chrome" = "googlechrome"
        "Mozilla.Firefox" = "firefox"
        "Opera.Opera" = "opera"
        "Discord.Discord" = "discord"
        "Telegram.TelegramDesktop" = "telegram"
        "Zoom.Zoom" = "zoom"
        "Microsoft.Teams" = "teams"
        "SlackTechnologies.Slack" = "slack"
        "WhatsApp.WhatsApp" = "whatsapp"
        "7zip.7zip" = "7zip"
        "RARLab.WinRAR" = "winrar"
        "Microsoft.PowerToys" = "powertoys"
        "voidtools.Everything" = "everything"
        "BleachBit.BleachBit" = "bleachbit"
        "RevoUninstaller.RevoUninstaller" = "revo"
        "Bitwarden.Bitwarden" = "bitwarden"
        "Malwarebytes.Malwarebytes" = "malwarebytes"
        "CPUID.CPU-Z" = "cpuz"
        "TechPowerUp.GPU-Z" = "gpuz"
        "CPUID.HWMonitor" = "hwmonitor"
        "REALiX.HWiNFO" = "hwinfo"
        "MSI.Afterburner" = "msiafterburner"
        "Guru3D.Afterburner" = "msiafterburner"
        "PeaZip.PeaZip" = "peazip"
        "Notepad++.Notepad++" = "notepadplusplus"
        "Microsoft.VisualStudioCode" = "vscode"
        "Git.Git" = "git"
        "GitHub.GitHubDesktop" = "github-desktop"
        "Docker.DockerDesktop" = "docker-desktop"
        "Kitware.CMake" = "cmake"
        "OpenJS.NodeJS" = "nodejs"
        "Python.Python.3" = "python"
        "PuTTY.PuTTY" = "putty"
        "WinSCP.WinSCP" = "winscp"
        "FileZilla.Client" = "filezilla"
        "GIMP.GIMP" = "gimp"
        "Inkscape.Inkscape" = "inkscape"
        "KritaFoundation.Krita" = "krita"
        "BlenderFoundation.Blender" = "blender"
        "dotPDN.PaintDotNet" = "paint.net"
        "HandBrake.HandBrake" = "handbrake"
        "VideoLAN.VLC" = "vlc"
        "OBSProject.OBSStudio" = "obs-studio"
        "Audacity.Audacity" = "audacity"
        "Calibre.Calibre" = "calibre"
        "CodecGuide.K-LiteCodecPack.Basic" = "klitecodec"
        "Spotify.Spotify" = "spotify"
        "TheDocumentFoundation.LibreOffice" = "libreoffice"
        "Microsoft.OfficeDeploymentTool" = "office365"
        "Notion.Notion" = "notion"
        "Obsidian.Obsidian" = "obsidian"
        "Zotero.Zotero" = "zotero"
        "Adobe.Acrobat.Reader.64-bit" = "adobereader"
        "Foxit.FoxitReader" = "foxitreader"
        "SumatraPDF.SumatraPDF" = "sumatrapdf"
        "PDF24.PDF24" = "pdf24"
        "Typora.Typora" = "typora"
        "WiresharkFoundation.Wireshark" = "wireshark"
        "Nmap.Nmap" = "nmap"
        "Famatech.AdvancedIPScanner" = "advanced-ip-scanner"
        "Mobatek.MobaXterm" = "mobaxterm"
        "Alacritty.Alacritty" = "alacritty"
        "Microsoft.WindowsTerminal" = "windows-terminal"
        "AnyDesk.AnyDesk" = "anydesk"
        "RustDesk.RustDesk" = "rustdesk"
        "TeamViewer.TeamViewer" = "teamviewer"
        "Valve.Steam" = "steam"
        "EpicGames.EpicGamesLauncher" = "epicgameslauncher"
        "ElectronicArts.EADesktop" = "ea-app"
        "Ubisoft.Connect" = "ubisoft-connect"
        "GOG.Galaxy" = "gog-galaxy"
        "Parsec.Parsec" = "parsec"
        "Oracle.VirtualBox" = "virtualbox"
        "VMware.WorkstationPlayer" = "vmware-player"
        "RaspberryPiFoundation.RaspberryPiImager" = "raspberry-pi-imager"
        "Microsoft.WSL" = "wsl"
        "Microsoft.PowerShell" = "powershell"
        "Duplicati.Duplicati" = "duplicati"
        "Nextcloud.NextcloudDesktop" = "nextcloud"
        "Google.Drive" = "googledrive"
        "Dropbox.Dropbox" = "dropbox"
        "SyncThing.SyncThing" = "syncthing"
        "Resilio.ResilioSync" = "resiliosync"
        "Rclone.Rclone" = "rclone"
        "ProtonTechnologies.ProtonDrive" = "protondrive"
        "ProtonTechnologies.ProtonVPN" = "protonvpn"
        "Windscribe.Windscribe" = "windscribe"
        "OpenVPNTechnologies.OpenVPN" = "openvpn"
        "OpenHardwareMonitor.OpenHardwareMonitor" = "openhardwaremonitor"
        "CoreTemp.CoreTemp" = "coretemp"
        "CrystalDiskInfo.CrystalDiskInfo" = "crystaldiskinfo"
        "CrystalDiskMark.CrystalDiskMark" = "crystaldiskmark"
        "Simplenote.Simplenote" = "simplenote"
        "Joplin.Joplin" = "joplin"
        "BulkRenameUtility.BulkRenameUtility" = "bulkrenameutility"
        "AutoHotkey.AutoHotkey" = "autohotkey"
        "Espanso.Espanso" = "espanso"
        "Gsudo.Gsudo" = "gsudo"
        "Nushell.Nushell" = "nushell"
        "Fastfetch.Fastfetch" = "fastfetch"
        "Monitorian.Monitorian" = "monitorian"
        "qBittorrent.qBittorrent" = "qbittorrent"
        "Motrix.Motrix" = "motrix"
        "LocalSend.LocalSend" = "localsend"
        "KDE.KDEConnect" = "kdeconnect"
        "Schollz.croc" = "croc"
        "TreeSize.TreeSize" = "treesize"
        "WizTree.WizTree" = "wiztree"
        "DiskGenius.DiskGenius" = "diskgenius"
        "Rainmeter.Rainmeter" = "rainmeter"
        "f.lux.f.lux" = "flux"
        "Ditto.Ditto" = "ditto"
        "CopyQ.CopyQ" = "copyq"
        "Microsoft.PowerAutomateDesktop" = "power-automate-desktop"
    }
    
    # Verificar si winget está disponible
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue

# Función auxiliar para instalar con winget (SIN admin, ventana OCULTA)
function Install-WithWinget {
    if (-not $wingetAvailable) { return $false }
    
    Write-Host "     → Ejecutando winget en segundo plano..." -ForegroundColor DarkGray
    
    $tempScript = "$env:TEMP\winget_install_$([System.Guid]::NewGuid().ToString().Substring(0,8)).ps1"
    $scriptContent = @"
`$output = winget install --id `"$AppID`" --exact --accept-package-agreements --accept-source-agreements --silent 2>&1
`$outputString = `$output -join " "

if (`$outputString -like "*No available upgrade found*" -or `$outputString -like "*already installed*") {
    exit 0
}

if (`$LASTEXITCODE -eq 0) {
    exit 0
} else {
    exit 1
}
"@
    $scriptContent | Out-File -FilePath $tempScript -Encoding utf8
    
    # Ventana OCULTA
    $process = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tempScript`"" -Verb RunAs -Wait -PassThru
    
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    
    return ($process.ExitCode -eq 0)
}
 
    # Intentar con winget (primer intento - modo usuario)
    Write-Host " [+] Intentando con winget (modo usuario)..." -ForegroundColor $COLOR_PRIMARY
    if (Install-WithWinget) { return "OK" }
    
    # Si falla, verificar si tenemos mapeo para Chocolatey
    $chocoName = $null
    if ($chocoMapping.ContainsKey($AppID)) {
        $chocoName = $chocoMapping[$AppID]
        Write-Host " [+] Usando mapeo manual para Chocolatey: $chocoName" -ForegroundColor $COLOR_ALERT
    } else {
        $chocoName = $AppID.Split('.')[-1].ToLower()
        Write-Host " [+] Generando nombre corto automático: $chocoName" -ForegroundColor $COLOR_ALERT
    }
    
    # Intentar con Chocolatey
    Write-Host " [+] Instalando vía Chocolatey..." -ForegroundColor $COLOR_PRIMARY
    choco install $chocoName -y --no-progress 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { 
        Write-Host " [✔] Instalado correctamente con Chocolatey" -ForegroundColor Green
        return "OK" 
    }
    
    # Segundo intento con winget (reintento normal)
    Write-Host " [+] Reintentando con winget (segundo intento)..." -ForegroundColor $COLOR_ALERT
    Start-Sleep -Seconds 2
    winget install --id $AppID --exact --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { return "OK" }
    
    # Si todo falla, reportar error CON URL si existe
    $manualUrl = $manualUrls[$AppName]
    if ($manualUrl) {
        Write-Host " [✘] FALLO DEFINITIVO." -ForegroundColor Red
        Write-Host "     → Descárgala manualmente desde: $manualUrl" -ForegroundColor Yellow
        Write-Log "INSTALL" "Failed to install $AppName ($AppID) - manual URL: $manualUrl"
        return "MANUAL|$manualUrl"
    } else {
        Write-Host " [✘] FALLO DEFINITIVO. Instalación manual requerida." -ForegroundColor Red
        Write-Log "INSTALL" "Failed to install $AppName ($AppID) via winget and Chocolatey"
        return "ERROR"
    }
}

# --- KIT POST FORMAT V5 (125 APPS CONFIABLES) ---
function Invoke-KitPostFormat {
    # Diccionario de URLs oficiales para descarga manual
    $manualUrls = @{
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
    }
    
    $apps = @{

    # ========== 1-5: NAVEGADORES ==========
    "1" = @{Name="Google Chrome"; ID="Google.Chrome"}
    "2" = @{Name="Mozilla Firefox"; ID="Mozilla.Firefox"}
    "3" = @{Name="Brave Browser"; ID="Brave.Brave"}
    "4" = @{Name="Microsoft Edge"; ID="Microsoft.Edge"}
    "5" = @{Name="Opera"; ID="Opera.Opera"}
    
    # ========== 6-12: COMUNICACIÓN ==========
    "6" = @{Name="Discord"; ID="Discord.Discord"}
    "7" = @{Name="Telegram Desktop"; ID="Telegram.TelegramDesktop"}
    "8" = @{Name="Signal Desktop"; ID="OpenWhisperSystems.Signal"}
    "9" = @{Name="Zoom"; ID="Zoom.Zoom"}
    "10" = @{Name="Microsoft Teams"; ID="Microsoft.Teams"}
    "11" = @{Name="Slack"; ID="SlackTechnologies.Slack"}
    "12" = @{Name="WhatsApp Desktop"; ID="9NKSQGP7F2NH"}
    
    # ========== 13-26: UTILIDADES ==========
    "13" = @{Name="7-Zip"; ID="7zip.7zip"}
    "14" = @{Name="WinRAR"; ID="RARLab.WinRAR"}
    "15" = @{Name="Microsoft PowerToys"; ID="Microsoft.PowerToys"}
    "16" = @{Name="Everything Search"; ID="voidtools.Everything"}
    "17" = @{Name="BleachBit"; ID="BleachBit.BleachBit"}
    "18" = @{Name="Revo Uninstaller"; ID="RevoUninstaller.RevoUninstaller"}
    "19" = @{Name="Bitwarden"; ID="Bitwarden.Bitwarden"}
    "20" = @{Name="Malwarebytes"; ID="Malwarebytes.Malwarebytes"}
    "21" = @{Name="CPU-Z"; ID="CPUID.CPU-Z"}
    "22" = @{Name="GPU-Z"; ID="TechPowerUp.GPU-Z"}
    "23" = @{Name="HWMonitor"; ID="CPUID.HWMonitor"}
    "24" = @{Name="HWINFO"; ID="REALiX.HWiNFO"}
    "25" = @{Name="MSI Afterburner"; ID="Guru3D.Afterburner"}
    "26" = @{Name="PeaZip"; ID="PeaZip.PeaZip"}
    "27" = @{Name="Notepad++"; ID="Notepad++.Notepad++"}
    
    # ========== 28-37: DESARROLLO ==========
    "28" = @{Name="Visual Studio Code"; ID="Microsoft.VisualStudioCode"}
    "29" = @{Name="Git"; ID="Git.Git"}
    "30" = @{Name="GitHub Desktop"; ID="GitHub.GitHubDesktop"}
    "31" = @{Name="Docker Desktop"; ID="Docker.DockerDesktop"}
    "32" = @{Name="CMake"; ID="Kitware.CMake"}
    "33" = @{Name="Node.js"; ID="OpenJS.NodeJS"}
    "34" = @{Name="Python 3"; ID="Python.Python.3"}
    "35" = @{Name="PuTTY"; ID="PuTTY.PuTTY"}
    "36" = @{Name="WinSCP"; ID="WinSCP.WinSCP"}
    "37" = @{Name="FileZilla Client"; ID="FileZilla.Client"}
    
    # ========== 38-49: MULTIMEDIA ==========
    "38" = @{Name="GIMP"; ID="GIMP.GIMP"}
    "39" = @{Name="Inkscape"; ID="Inkscape.Inkscape"}
    "40" = @{Name="Krita"; ID="KritaFoundation.Krita"}
    "41" = @{Name="Blender"; ID="BlenderFoundation.Blender"}
    "42" = @{Name="Paint.NET"; ID="dotPDN.PaintDotNet"}
    "43" = @{Name="HandBrake"; ID="HandBrake.HandBrake"}
    "44" = @{Name="VLC Media Player"; ID="VideoLAN.VLC"}
    "45" = @{Name="OBS Studio"; ID="OBSProject.OBSStudio"}
    "46" = @{Name="Audacity"; ID="Audacity.Audacity"}
    "47" = @{Name="Calibre"; ID="Calibre.Calibre"}
    "48" = @{Name="K-Lite Codec Pack Basic"; ID="CodecGuide.K-LiteCodecPack.Basic"}
    "49" = @{Name="Spotify"; ID="Spotify.Spotify"}
    
    # ========== 50-58: OFIMÁTICA ==========
    "50" = @{Name="LibreOffice"; ID="TheDocumentFoundation.LibreOffice"}
    "51" = @{Name="Microsoft 365"; ID="Microsoft.OfficeDeploymentTool"}
    "52" = @{Name="Notion"; ID="Notion.Notion"}
    "53" = @{Name="Obsidian"; ID="Obsidian.Obsidian"}
    "54" = @{Name="Zotero"; ID="Zotero.Zotero"}
    "55" = @{Name="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"}
    "56" = @{Name="Foxit PDF Reader"; ID="Foxit.FoxitReader"}
    "57" = @{Name="SumatraPDF"; ID="SumatraPDF.SumatraPDF"}
    "58" = @{Name="PDF24 Creator"; ID="PDF24.PDF24"}
    "59" = @{Name="Typora Markdown Editor"; ID="Typora.Typora"}
    
    # ========== 60-68: REDES Y TERMINAL ==========
    "60" = @{Name="Wireshark"; ID="WiresharkFoundation.Wireshark"}
    "61" = @{Name="Nmap"; ID="Nmap.Nmap"}
    "62" = @{Name="Advanced IP Scanner"; ID="Famatech.AdvancedIPScanner"}
    "63" = @{Name="MobaXterm"; ID="Mobatek.MobaXterm"}
    "64" = @{Name="Alacritty"; ID="Alacritty.Alacritty"}
    "65" = @{Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"}
    "66" = @{Name="AnyDesk"; ID="AnyDesk.AnyDesk"}
    "67" = @{Name="RustDesk"; ID="RustDesk.RustDesk"}
    "68" = @{Name="TeamViewer"; ID="TeamViewer.TeamViewer"}
    
    # ========== 69-74: JUEGOS ==========
    "69" = @{Name="Steam"; ID="Valve.Steam"}
    "70" = @{Name="Epic Games Launcher"; ID="EpicGames.EpicGamesLauncher"}
    "71" = @{Name="EA Desktop"; ID="ElectronicArts.EADesktop"}
    "72" = @{Name="Ubisoft Connect"; ID="Ubisoft.Connect"}
    "73" = @{Name="GOG Galaxy"; ID="GOG.Galaxy"}
    "74" = @{Name="Parsec"; ID="Parsec.Parsec"}
    
    # ========== 75-79: VIRTUALIZACIÓN ==========
    "75" = @{Name="Oracle VM VirtualBox"; ID="Oracle.VirtualBox"}
    "76" = @{Name="VMware Workstation Player"; ID="VMware.WorkstationPlayer"}
    "77" = @{Name="Raspberry Pi Imager"; ID="RaspberryPiFoundation.RaspberryPiImager"}
    "78" = @{Name="WSL (Windows Subsystem Linux)"; ID="Microsoft.WSL"}
    "79" = @{Name="PowerShell 7"; ID="Microsoft.PowerShell"}
    
    # ========== 80-87: RESPALDOS ==========
    "80" = @{Name="Duplicati"; ID="Duplicati.Duplicati"}
    "81" = @{Name="Nextcloud Desktop"; ID="Nextcloud.NextcloudDesktop"}
    "82" = @{Name="Google Drive"; ID="Google.Drive"}
    "83" = @{Name="Dropbox"; ID="Dropbox.Dropbox"}
    "84" = @{Name="SyncThing"; ID="SyncThing.SyncThing"}
    "85" = @{Name="Resilio Sync"; ID="Resilio.ResilioSync"}
    "86" = @{Name="Rclone"; ID="Rclone.Rclone"}
    "87" = @{Name="Proton Drive"; ID="ProtonTechnologies.ProtonDrive"}
    
    # ========== 88-90: VPN ==========
    "88" = @{Name="ProtonVPN"; ID="ProtonTechnologies.ProtonVPN"}
    "89" = @{Name="Windscribe VPN"; ID="Windscribe.Windscribe"}
    "90" = @{Name="OpenVPN"; ID="OpenVPNTechnologies.OpenVPN"}
    
    # ========== 91-94: MONITOR ==========
    "91" = @{Name="OpenHardwareMonitor"; ID="OpenHardwareMonitor.OpenHardwareMonitor"}
    "92" = @{Name="Core Temp"; ID="CoreTemp.CoreTemp"}
    "93" = @{Name="CrystalDiskInfo"; ID="CrystalDiskInfo.CrystalDiskInfo"}
    "94" = @{Name="CrystalDiskMark"; ID="CrystalDiskMark.CrystalDiskMark"}
    
    # ========== 95-96: NOTAS ==========
    "95" = @{Name="Simplenote"; ID="Simplenote.Simplenote"}
    "96" = @{Name="Joplin"; ID="Joplin.Joplin"}
    
    # ========== 97-104: UTILIDADES AVANZADAS ==========
    "97" = @{Name="Bulk Rename Utility"; ID="BulkRenameUtility.BulkRenameUtility"}
    "98" = @{Name="AutoHotkey"; ID="AutoHotkey.AutoHotkey"}
    "99" = @{Name="Espanso Text Expander"; ID="Espanso.Espanso"}
    "100" = @{Name="Gsudo"; ID="Gsudo.Gsudo"}
    "101" = @{Name="Nushell"; ID="Nushell.Nushell"}
    "102" = @{Name="Fastfetch"; ID="Fastfetch.Fastfetch"}
    "103" = @{Name="Monitorian"; ID="Monitorian.Monitorian"}
    "104" = @{Name="qBittorrent"; ID="qBittorrent.qBittorrent"}
    
    # ========== 105-108: CLIENTES ==========
    "105" = @{Name="Motrix Download Manager"; ID="Motrix.Motrix"}
    "106" = @{Name="LocalSend"; ID="LocalSend.LocalSend"}
    "107" = @{Name="KDE Connect"; ID="KDE.KDEConnect"}
    "108" = @{Name="croc file transfer"; ID="Schollz.croc"}
    
    # ========== 109-112: LIMPIEZA ==========
    "109" = @{Name="TreeSize Free"; ID="TreeSize.TreeSize"}
    "110" = @{Name="WizTree"; ID="WizTree.WizTree"}
    "111" = @{Name="DiskGenius"; ID="DiskGenius.DiskGenius"}
    "112" = @{Name="Rainmeter"; ID="Rainmeter.Rainmeter"}
    
    # ========== 113-115: PERSONALIZACIÓN ==========
    "113" = @{Name="f.lux"; ID="f.lux.f.lux"}
    "114" = @{Name="Ditto Clipboard Manager"; ID="Ditto.Ditto"}
    "115" = @{Name="CopyQ Clipboard Manager"; ID="CopyQ.CopyQ"}
    
    # ========== 116-117: EXTRAS ==========
    "116" = @{Name="Power Automate Desktop"; ID="Microsoft.PowerAutomateDesktop"}
    "117" = @{Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"}
}

    # Resto del código de la función (el bucle while, el menú, etc.)
    $prefs = Get-Prefs
    $lastOpt = $null
    try { $lastOpt = $prefs.lastKitOption } catch { $lastOpt = $null }

    while($true){
        Clear-Host
        Show-MainTitle
        Write-Host "`n KIT POST FORMAT - INSTALACION INTELIGENTE (125 APPS)" -ForegroundColor $COLOR_PRIMARY
        Write-Host ' [0] LIMPIEZA DE BLOATWARE (CandyCrush, Netflix, etc.)'
        Write-Host ' [1] PERFIL BASICO (Chrome, 7Zip, VLC, AnyDesk, Teams)'
        Write-Host ' [2] PERFIL GAMING (Steam, Discord, OBS, DirectX)'
        Write-Host ' [3] SELECCION MANUAL (Listado Completo 125 apps)'
        Write-Host " [4] ACTUALIZAR TODO EL SOFTWARE"
        Write-Host ' [5] DESINSTALAR PROGRAMAS (Revo, BCUninstaller, Panel de Control)' -ForegroundColor $COLOR_MENU	
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $opt = Read-MenuOption "`n ``> SELECCIONE" -Valid @("0","1","2","3","4","5","X")
        if($opt -eq "X"){break}
        if(-not $opt){ continue }

        $prefs.lastKitOption = $opt
        Save-Prefs $prefs
        Write-Log "KIT" "Selected option=$opt"
        
        $selection = @()
        switch ($opt) {
            "0" {
                Write-Host "`n [!] Eliminando Bloatware..." -ForegroundColor $COLOR_ALERT
                $bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*")
                foreach($b in $bloat){ Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue }
                Pause-Enter " OK. ENTER"
            }
            "1" { $selection = "1","13","45","67","10" }  # Chrome, 7-Zip, VLC, AnyDesk, Teams
            "2" { $selection = "70","6","45" }            # Steam, Discord, VLC
            "3" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n LISTADO MAESTRO (125 APPS) - PAGINADO + BUSCADOR" -ForegroundColor $COLOR_MENU
                $sortedKeysAll = $apps.Keys | Sort-Object {[int]$_}
                $filteredKeys = $sortedKeysAll
                $searchText = ""
                $appsPerPage = 40
                $totalPages = [math]::Ceiling($filteredKeys.Count / $appsPerPage)
                $currentPage = 1
                $cols = 4

                while ($true) {
                    Clear-Host
                    Show-MainTitle
                    $totalFiltered = $filteredKeys.Count
                    $totalPages = [math]::Ceiling($totalFiltered / $appsPerPage)
                    if ($currentPage -gt $totalPages) { $currentPage = $totalPages }
                    if ($currentPage -lt 1) { $currentPage = 1 }
                    
                    Write-Host "`n LISTADO MAESTRO - PÁGINA $currentPage DE $totalPages" -ForegroundColor $COLOR_MENU
                    if ($searchText) { Write-Host " BUSCANDO: '$searchText' (Total: $totalFiltered apps)" -ForegroundColor $COLOR_ALERT }
                    Write-Host "`n APPS DISPONIBLES:" -ForegroundColor $COLOR_PRIMARY
                    
                    $startIdx = ($currentPage - 1) * $appsPerPage
                    $endIdx = [math]::Min($startIdx + $appsPerPage, $totalFiltered) - 1
                    
                    $pageApps = @($filteredKeys[$startIdx..$endIdx])
                    for ($i = 0; $i -lt $pageApps.Count; $i += $cols) {
                        $row = ""
                        for ($j = 0; $j -lt $cols; $j++) {
                            if (($i + $j) -lt $pageApps.Count) {
                                $key = $pageApps[$i + $j]
                                $name = $apps[$key].Name
                                if ($name.Length -gt 22) {
                                    $displayName = $name.Substring(0, 19) + "..."
                                } else {
                                    $displayName = $name
                                }
                                $row += "[$($key.ToString().PadLeft(3))] $($displayName.PadRight(22))"
                            }
                        }
                        Write-Host " $row"
                    }
                    
                    Write-Host "`n CONTROLES:" -ForegroundColor $COLOR_ALERT
                    Write-Host " [N] Siguiente página   [P] Página anterior   [G] Ir a página   [B] Buscar por nombre"
                    Write-Host " [R] Reiniciar búsqueda   [X] Cancelar   [ENTER] Continuar con selección" -ForegroundColor $COLOR_MENU
                    
                    $optPage = Read-Host "`n ``>"
                    switch ($optPage.ToUpper()) {
                        "N" { if ($currentPage -lt $totalPages) { $currentPage++ } else { Write-Host " Ya es la última página." -ForegroundColor $COLOR_DANGER; Start-Sleep -Seconds 1 } }
                        "P" { if ($currentPage -gt 1) { $currentPage-- } else { Write-Host " Ya es la primera página." -ForegroundColor $COLOR_DANGER; Start-Sleep -Seconds 1 } }
                        "G" {
                            $pg = Read-Host " Número de página (1-$totalPages)"
                            if ($pg -match '^\d+$' -and [int]$pg -ge 1 -and [int]$pg -le $totalPages) { $currentPage = [int]$pg }
                            else { Write-Host " Número inválido." -ForegroundColor $COLOR_DANGER; Start-Sleep -Seconds 1 }
                        }
                        "B" {
                            $searchText = Read-Host " INGRESE TEXTO A BUSCAR (nombre parcial)"
                            if ($searchText) {
                                $filteredKeys = @($sortedKeysAll | Where-Object { $apps[$_].Name -like "*$searchText*" })
                                if ($filteredKeys.Count -eq 0) {
                                    Write-Host " No se encontraron apps con '$searchText'." -ForegroundColor $COLOR_DANGER
                                    Start-Sleep -Seconds 1
                                    $filteredKeys = $sortedKeysAll
                                    $searchText = ""
                                } else {
                                    $currentPage = 1
                                }
                            }
                        }
                        "R" {
                            $filteredKeys = $sortedKeysAll
                            $searchText = ""
                            $currentPage = 1
                            Write-Host " Búsqueda reiniciada." -ForegroundColor $COLOR_PRIMARY
                            Start-Sleep -Seconds 1
                        }
                        "X" { $manual = "X"; break }
                        default { break }
                    }
                    if ($optPage.ToUpper() -eq "X") { break }
                    if ($optPage -eq "") { break }
                }
                
                if ($optPage.ToUpper() -eq "X") { continue }
                
                Write-Host "`n CONSEJO: Puedes escribir rangos (ej: 1-10) o lista separada por comas (1,5,20)" -ForegroundColor $COLOR_ALERT
                $manual = Read-Host "`n ``> INGRESE NUMEROS SEPARADOS POR COMA O RANGOS (X para cancelar)"
                if($manual -eq "X"){ continue }
                
                $finalSelection = @()
                $parts = $manual -split ','
                foreach($part in $parts){
                    $part = $part.Trim()
                    if($part -match '^(\d+)-(\d+)$'){
                        $start = [int]$matches[1]
                        $end = [int]$matches[2]
                        for($k=$start; $k -le $end; $k++){ $finalSelection += $k.ToString() }
                    } else {
                        $finalSelection += $part
                    }
                }
                $selection = $finalSelection
            }
            "4" { 
                if(Get-Command winget -ErrorAction SilentlyContinue){
                    winget upgrade --all --silent
                    Write-Log "KIT" ("winget upgrade all exit={0}" -f $LASTEXITCODE)
                } else {
                    Write-Host "`n [!] winget no disponible." -ForegroundColor $COLOR_DANGER
                    Write-Log "KIT" "winget not available"
                }
                Pause-Enter " OK. ENTER"
                continue
            }
            "5" {
           while ($true) {
               Clear-Host
               Show-MainTitle
               Write-Host "`n DESINSTALACIÓN DE PROGRAMAS" -ForegroundColor $COLOR_MENU
               Write-Host " [1] PANEL DE CONTROL (appwiz.cpl) - Gráfico nativo" -ForegroundColor $COLOR_MENU
               Write-Host " [2] WINGET UNINSTALL - Código nativo (rápido)" -ForegroundColor $COLOR_MENU
               Write-Host " [3] REVO UNINSTALLER - App gráfica avanzada" -ForegroundColor $COLOR_MENU
               Write-Host " [4] BCUNINSTALLER - Bulk Crap Uninstaller" -ForegroundColor $COLOR_MENU
               Write-Host "`n [X] VOLVER AL KIT" -ForegroundColor $COLOR_DANGER
               
               $subOpt = Read-Host "`n > SELECCIONE"
               
               switch ($subOpt.ToUpper()) {
                   "1" {
                       Start-Process "appwiz.cpl"
                       Pause-Enter " ENTER después de cerrar"
                       continue
                   }
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
                   default {
                       Write-Host " Opción no válida" -ForegroundColor Red
                       Start-Sleep -Seconds 1
                   }
               }
               if ($subOpt.ToUpper() -eq "X") { break }
           }
           continue
       }		
               }
       
               if($selection.Count -gt 0){
            $results = @()
            foreach($item in $selection){
                if($apps.ContainsKey($item)){
                    $res = Invoke-SmartInstall -AppID $apps[$item].ID -AppName $apps[$item].Name
                    if($res -ne "OK" -and $res -notlike "MANUAL|*"){
                        Write-Host " [!] Reintentando: $($apps[$item].Name)" -ForegroundColor $COLOR_ALERT
                        Write-Log "KIT" "Retry app=$($apps[$item].Name) id=$($apps[$item].ID)"
                        $res = Invoke-SmartInstall -AppID $apps[$item].ID -AppName $apps[$item].Name
                    }
                    
                    if ($res -like "MANUAL|*") {
                        $url = ($res -split "\|")[1]
                        $results += "[ ERROR ] $($apps[$item].Name)`n   → Descárgala manualmente desde: $url"
                    } elseif ($res -eq "OK") {
                        $results += "[ OK ] $($apps[$item].Name)"
                    } else {
                        $results += "[ ERROR ] $($apps[$item].Name)"
                    }
                    
                    Write-Log "KIT" "Install app=$($apps[$item].Name) result=$res"
                } else {
                    Write-Host " [!] Número inválido: $item" -ForegroundColor $COLOR_DANGER
                }
            }
            Show-MainTitle
            Write-Host "`n RESUMEN DE INSTALACION:" -ForegroundColor $COLOR_ALERT
            $results | ForEach-Object { Write-Host " $_" }
            Pause-Enter "`n PRESIONE ENTER PARA LIMPIAR Y CONTINUAR"
        }
    }
}
# --- MOTOR DE RESPALDO Y RESTAURACION ---
function Invoke-Engine ($Mode, $Msg) {
    Show-MainTitle
    $DriveLetter = if ($PSScriptRoot -and $PSScriptRoot.Length -ge 2) { $PSScriptRoot.Substring(0,2) } else { "C:" }

    if ($Mode -eq "BACKUP") {
         Write-Host "`n BACKUP TOTAL - SELECCIONA EL TIPO DE RESPALDO" -ForegroundColor $COLOR_ALERT
         Write-Host " [A] PERFIL ACTUAL - Respaldar tu usuario (Escritorio, Documentos, etc.)" -ForegroundColor $COLOR_PRIMARY
         Write-Host " [B] TODOS LOS PERFILES LOCALES - Respaldar todos los usuarios del equipo" -ForegroundColor $COLOR_PRIMARY
         Write-Host " [C] EXPORTAR INVENTARIO - Lista de programas instalados y drivers" -ForegroundColor $COLOR_PRIMARY
         Write-Host " [D] DUPLICATI - Backup avanzado a la nube (encriptado, programado)" -ForegroundColor $COLOR_PRIMARY
         Write-Host "`n CONTROL" -ForegroundColor Gray
         Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
         Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
	$choice = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","X")
        if ($choice -eq "X") { return }

        $Base = Read-Host (' RUTA DESTINO PARA BACKUP (ENTER para ' + $DEFAULT_BACKUP_BASE + ')')
        if (-not $Base) { $Base = $DEFAULT_BACKUP_BASE }

        if (Is-SuspiciousBackupBase $Base) {
            Write-Host "`n [!] ADVERTENCIA: la ruta destino parece sensible: $Base" -ForegroundColor $COLOR_ALERT
            if (-not (Confirm-Critical "DESTINO DE BACKUP SENSIBLE ($Base)" "APLICAR")) { return }
        }

        # Resumen + tamaño aproximado (solo para backups de perfil)
        if ($choice -eq "A" -or $choice -eq "B") {
            Show-MainTitle
            Write-Host "`n RESUMEN DE BACKUP" -ForegroundColor $COLOR_MENU
            Write-Host " DESTINO BASE: $Base" -ForegroundColor $COLOR_PRIMARY
            Write-Host " CARPETAS INCLUIDAS:" -ForegroundColor $COLOR_PRIMARY
            $USER_FOLDER_NAMES | ForEach-Object { Write-Host "  - $_" -ForegroundColor $COLOR_MENU }

            $estBytes = 0L
            if ($choice -eq "A") {
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
            Write-Host "`n TAMAÑO APROX (SUMA DE CARPETAS): $(Format-Bytes $estBytes)" -ForegroundColor $COLOR_ALERT
            Write-Host " ESPACIO LIBRE DESTINO:            $(Format-Bytes $freeBytes)" -ForegroundColor $COLOR_ALERT
            Write-Log "BACKUP" "EstimateBytes=$estBytes FreeBytes=$freeBytes Base=$Base Choice=$choice"
            if ($freeBytes -gt 0 -and $estBytes -gt 0 -and $freeBytes -lt ($estBytes * 1.2)) {
                Write-Host "`n [!] POSIBLE FALTA DE ESPACIO (recomendado >= 20% extra)." -ForegroundColor $COLOR_DANGER
                if (-not (Confirm-Critical "CONTINUAR CON POSIBLE POCO ESPACIO" "APLICAR")) { return }
            } else {
                Pause-Enter " ENTER PARA CONTINUAR"
            }
        }

        $BackupRoot = Get-BackupRoot $Base
        Write-Log "BACKUP" "BackupRoot=$BackupRoot Base=$Base Choice=$choice"

        if ($choice -eq "A") {
            Write-Log "BACKUP" "Choice=A ProfileRoot=$env:USERPROFILE"
            Backup-ProfileData $env:USERPROFILE $BackupRoot
            $verify = Read-MenuOption "`n VERIFICAR BACKUP (conteo rápido)? (S/N)" -Valid @("S","N")
            if($verify -eq "S"){
                $count = (Get-ChildItem -Path $BackupRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                Write-Host " [+] ARCHIVOS EN BACKUP: $count" -ForegroundColor $COLOR_PRIMARY
                Write-Log "BACKUP" "VerifyFiles=$count BackupRoot=$BackupRoot"
            }
            Pause-Enter "`n BACKUP DE PERFIL ACTUAL COMPLETADO EN: $BackupRoot. ENTER"
            return
        }

        if ($choice -eq "B") {
            $profiles = Get-UserProfilePaths
            Write-Log "BACKUP" "Choice=B ProfilesCount=$(@($profiles).Count) BackupRoot=$BackupRoot"
            foreach ($profile in $profiles) {
                Backup-ProfileData $profile $BackupRoot
            }
            $verify = Read-MenuOption "`n VERIFICAR BACKUP (conteo rápido)? (S/N)" -Valid @("S","N")
            if($verify -eq "S"){
                $count = (Get-ChildItem -Path $BackupRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                Write-Host " [+] ARCHIVOS EN BACKUP: $count" -ForegroundColor $COLOR_PRIMARY
                Write-Log "BACKUP" "VerifyFiles=$count BackupRoot=$BackupRoot"
            }
            Pause-Enter "`n BACKUP DE TODOS LOS PERFILES COMPLETADO EN: $BackupRoot. ENTER"
            return
        }

        if ($choice -eq "C") {
            if (!(Test-Path $BackupRoot)) { New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null }
            $appsFile = Join-Path $BackupRoot "InstalledApps_$((Get-Date).ToString('yyyyMMdd_HHmmss')).txt"
            $driversPath = Join-Path $BackupRoot "Drivers"
            Write-Log "BACKUP" "Choice=C Export Apps+Drivers to $BackupRoot"
            Write-Host "`n [+] EXPORTANDO LISTA DE PROGRAMAS INSTALADOS..." -ForegroundColor $COLOR_PRIMARY
            Get-Package | Sort-Object Name | Format-Table -AutoSize | Out-String | Out-File $appsFile -Encoding utf8
            Write-Host "[+] EXPORTANDO DRIVERS INSTALADOS..." -ForegroundColor $COLOR_PRIMARY
            if (!(Test-Path $driversPath)) { New-Item -Path $driversPath -ItemType Directory -Force | Out-Null }
            Export-WindowsDriver -Online -Destination $driversPath | Out-Null
            Pause-Enter "`n INVENTARIO CREADO EN: $BackupRoot. ENTER"
            return
        }
	
         if ($choice -eq "D") {
             $installed = Get-Command duplicati -ErrorAction SilentlyContinue
             if (-not $installed) {
                 Write-Host "`n [+] Instalando Duplicati..." -ForegroundColor Yellow
                 winget install Duplicati.Duplicati --silent
                 Start-Sleep -Seconds 5
                 Write-Host " [✔] Duplicati instalado." -ForegroundColor Green
             }
             Write-Host "`n [+] Por favor, abre Duplicati manualmente desde el menú inicio." -ForegroundColor Yellow
             Write-Host "     (Para backups programados y encriptados a la nube)" -ForegroundColor Gray
             Pause-Enter " ENTER después de cerrar Duplicati"
             return
         }	

        Write-Host "`n OPCION NO VALIDA. VUELVE A INTENTARLO." -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 1
        return
    }

    if ($Mode -eq "RESTORE") {
        Write-Host "`n RESTORE TOTAL" -ForegroundColor $COLOR_ALERT
        Write-Host ' [A] RESTAURAR DESDE UBICACIÓN PREDETERMINADA (LISTAR BACKUPS DISPONIBLES)' -ForegroundColor $COLOR_PRIMARY
        Write-Host " [B] ESPECIFICAR RUTA MANUAL" -ForegroundColor $COLOR_PRIMARY
        Write-Host " [C] RESTAURAR EL ÚLTIMO BACKUP AUTOMÁTICAMENTE" -ForegroundColor $COLOR_PRIMARY
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $choice = Read-Host "``> SELECCIONE"
        if ($choice.ToUpper() -eq "X") { return }

        if ($choice.ToUpper() -eq "A") {
            $base = $DEFAULT_BACKUP_BASE
            $backups = @()
            if (Test-Path $base) {
                $backups = Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "Backup_*" } |
                    Sort-Object CreationTime -Descending
            }
            if (!$backups) {
                # Si no está en la ubicación predeterminada, buscar en todas las unidades locales
                Write-Host "`n [!] No se encontraron backups en la ubicación predeterminada." -ForegroundColor $COLOR_DANGER
                Write-Host " [+] Buscando carpetas 'Backup_*' en unidades disponibles..." -ForegroundColor $COLOR_PRIMARY
                $backups = @()
                $seen = @{}
                $disks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -in 2,3 }
                foreach($disk in $disks){
                    $root = ($disk.DeviceID + "\")
                    if(Test-Path $root){
                        # Nivel 1: E:\Backup_01 (directo en la raiz)
                        Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -like "Backup_*" } |
                            ForEach-Object {
                                if(-not $seen.ContainsKey($_.FullName)){
                                    $backups += [pscustomobject]@{
                                        Name         = $_.Name
                                        FullName     = $_.FullName
                                        CreationTime = $_.CreationTime
                                        Drive        = $disk.DeviceID
                                    }
                                    $seen[$_.FullName] = $true
                                }
                            }

                        # Nivel 2: E:\Carpeta\Backup_01 (un nivel debajo)
                        $parents = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
                        foreach($p in $parents){
                            Get-ChildItem -Path $p.FullName -Directory -ErrorAction SilentlyContinue |
                                Where-Object { $_.Name -like "Backup_*" } |
                                ForEach-Object {
                                    if(-not $seen.ContainsKey($_.FullName)){
                                        $backups += [pscustomobject]@{
                                            Name         = $_.Name
                                            FullName     = $_.FullName
                                            CreationTime = $_.CreationTime
                                            Drive        = $disk.DeviceID
                                        }
                                        $seen[$_.FullName] = $true
                                    }
                                }
                        }
                    }
                }

                if (!$backups -or $backups.Count -eq 0) {
                    Write-Host "`n [!] NO SE ENCONTRARON BACKUPS EN NINGUNA UNIDAD." -ForegroundColor $COLOR_DANGER
                    Start-Sleep -Seconds 2
                    return
                }
                $backups = $backups | Sort-Object CreationTime -Descending
            }
            Write-Host "`n BACKUPS DISPONIBLES:" -ForegroundColor $COLOR_PRIMARY
            for ($i = 0; $i -lt $backups.Count; $i++) {
                Write-Host " [$($i+1)] $($backups[$i].Name) - $($backups[$i].CreationTime)"
            }
            Write-Host ' [L] ÚLTIMO (MÁS RECIENTE)' -ForegroundColor $COLOR_MENU
            Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
            $sel = Read-Host "``> SELECCIONE BACKUP"
            if ($sel.ToUpper() -eq "X") { return }
            if ($sel.ToUpper() -eq "L") {
                $BackupRoot = $backups[0].FullName
            } elseif ($sel -match "^\d+$" -and [int]$sel -le $backups.Count) {
                $BackupRoot = $backups[[int]$sel - 1].FullName
            } else {
                Write-Host "`n [!] SELECCIÓN INVÁLIDA." -ForegroundColor $COLOR_DANGER
                Start-Sleep -Seconds 2
                return
            }
            Write-Log "RESTORE" "Choice=A BackupRoot=$BackupRoot"
        } elseif ($choice.ToUpper() -eq "B") {
            # Busca auto en USB conectadas (carpetas Backup_* directamente en la raiz, p.ej. E:\Backup_01)
            $found = @()
            $seenUsb = @{}
            $usbDisks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 2 }
            foreach($disk in $usbDisks){
                $root = ($disk.DeviceID + "\")
                if(Test-Path $root){
                    # Nivel 1: E:\Backup_01
                    Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -like "Backup_*" } |
                        ForEach-Object {
                            if(-not $seenUsb.ContainsKey($_.FullName)){
                                $found += [pscustomobject]@{
                                    Name         = $_.Name
                                    FullName     = $_.FullName
                                    CreationTime = $_.CreationTime
                                    Drive        = $disk.DeviceID
                                }
                                $seenUsb[$_.FullName] = $true
                            }
                        }

                    # Nivel 2: E:\Carpeta\Backup_01
                    $parents = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
                    foreach($p in $parents){
                        Get-ChildItem -Path $p.FullName -Directory -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -like "Backup_*" } |
                            ForEach-Object {
                                if(-not $seenUsb.ContainsKey($_.FullName)){
                                    $found += [pscustomobject]@{
                                        Name         = $_.Name
                                        FullName     = $_.FullName
                                        CreationTime = $_.CreationTime
                                        Drive        = $disk.DeviceID
                                    }
                                    $seenUsb[$_.FullName] = $true
                                }
                            }
                    }
                }
            }

            if($found.Count -gt 0){
                $found = $found | Sort-Object CreationTime -Descending
                Write-Host "`n BACKUPS ENCONTRADOS EN USB:" -ForegroundColor $COLOR_PRIMARY
                for ($i = 0; $i -lt $found.Count; $i++) {
                    Write-Host " [$($i+1)] $($found[$i].Drive)\$($found[$i].Name) - $($found[$i].CreationTime) - $($found[$i].FullName)" -ForegroundColor $COLOR_MENU
                }
                Write-Host " [M] MANUAL - INGRESAR RUTA COMPLETA" -ForegroundColor $COLOR_MENU
                Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $sel = (Read-Host "``> SELECCIONE BACKUP (NUMERO)") 
                if($sel.ToUpper() -eq "X"){ return }
                if($sel.ToUpper() -eq "M"){
                    $BackupRoot = Read-Host ' > INGRESE LA RUTA COMPLETA AL BACKUP'
                } elseif ($sel -match "^\d+$" -and [int]$sel -ge 1 -and [int]$sel -le $found.Count) {
                    $BackupRoot = $found[[int]$sel - 1].FullName
                } else {
                    Write-Host "`n [!] SELECCIÓN INVÁLIDA." -ForegroundColor $COLOR_DANGER
                    Start-Sleep -Seconds 2
                    return
                }
            } else {
                $BackupRoot = Read-Host ' > NO SE ENCONTRARON BACKUPS EN USB. INGRESE LA RUTA COMPLETA AL BACKUP'
            }

            Write-Log "RESTORE" "Choice=B BackupRoot=$BackupRoot"
            if (-not $BackupRoot -or -not (Test-Path $BackupRoot)) {
                Write-Host "`n [!] RUTA NO VÁLIDA O NO EXISTE." -ForegroundColor $COLOR_DANGER
                Start-Sleep -Seconds 2
                return
            }
        } elseif ($choice.ToUpper() -eq "C") {
            $base = $DEFAULT_BACKUP_BASE
            # Listar TODOS los backups en todas las unidades y permitir elegir (Enter = más reciente)
            Write-Host "`n [+] Buscando backups en todas las unidades..." -ForegroundColor $COLOR_PRIMARY
            $backups = @()
            $seen = @{}

            if (Test-Path $base) {
                Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "Backup_*" } |
                    ForEach-Object {
                        if(-not $seen.ContainsKey($_.FullName)){
                            $backups += [pscustomobject]@{
                                Name         = $_.Name
                                FullName     = $_.FullName
                                CreationTime = $_.CreationTime
                                Drive        = $_.FullName.Substring(0,2)
                            }
                            $seen[$_.FullName] = $true
                        }
                    }
            }

            $disks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -in 2,3 }
            foreach($disk in $disks){
                $root = ($disk.DeviceID + "\")
                if(Test-Path $root){
                    # Nivel 1
                    Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -like "Backup_*" } |
                        ForEach-Object {
                            if(-not $seen.ContainsKey($_.FullName)){
                                $backups += [pscustomobject]@{
                                    Name         = $_.Name
                                    FullName     = $_.FullName
                                    CreationTime = $_.CreationTime
                                    Drive        = $disk.DeviceID
                                }
                                $seen[$_.FullName] = $true
                            }
                        }

                    # Nivel 2
                    $parents = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
                    foreach($p in $parents){
                        Get-ChildItem -Path $p.FullName -Directory -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -like "Backup_*" } |
                            ForEach-Object {
                                if(-not $seen.ContainsKey($_.FullName)){
                                    $backups += [pscustomobject]@{
                                        Name         = $_.Name
                                        FullName     = $_.FullName
                                        CreationTime = $_.CreationTime
                                        Drive        = $disk.DeviceID
                                    }
                                    $seen[$_.FullName] = $true
                                }
                            }
                    }
                }
            }

            if(!$backups -or $backups.Count -eq 0){
                Write-Host "`n [!] NO SE ENCONTRARON BACKUPS EN NINGUNA UNIDAD." -ForegroundColor $COLOR_DANGER
                Start-Sleep -Seconds 2
                return
            }

            $backups = $backups | Sort-Object CreationTime -Descending
            Write-Host "`n BACKUPS ENCONTRADOS (TODAS LAS UNIDADES):" -ForegroundColor $COLOR_PRIMARY
            for ($i = 0; $i -lt $backups.Count; $i++) {
                Write-Host " [$($i+1)] $($backups[$i].Drive)\$($backups[$i].Name) - $($backups[$i].CreationTime) - $($backups[$i].FullName)" -ForegroundColor $COLOR_MENU
            }
            Write-Host " [ENTER] Usar el más reciente" -ForegroundColor $COLOR_MENU
            Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER

            $sel = Read-Host "``> SELECCIONE BACKUP (NUMERO/ENTER)"
            if($sel -and $sel.ToUpper() -eq "X"){ return }

            $latest = $backups[0]
            if($sel -match "^\d+$" -and [int]$sel -ge 1 -and [int]$sel -le $backups.Count){
                $latest = $backups[[int]$sel - 1]
            }

            $BackupRoot = $latest.FullName
            Write-Log "RESTORE" "Choice=C BackupRoot=$BackupRoot"
            Write-Host "`n [+] USANDO BACKUP: $($latest.Name)" -ForegroundColor $COLOR_PRIMARY
        } else {
            Write-Host "`n OPCIÓN NO VÁLIDA." -ForegroundColor $COLOR_DANGER
            Start-Sleep -Seconds 1
            return
        }

        $backupProfiles = Get-ChildItem -Path $BackupRoot -Directory -ErrorAction SilentlyContinue
        if (!$backupProfiles) {
            Write-Host "`n [!] NO SE ENCONTRARON PERFILES DE BACKUP EN LA RUTA ESPECIFICADA." -ForegroundColor $COLOR_DANGER
            Start-Sleep -Seconds 2
            return
        }
        Write-Log "RESTORE" "BackupRoot=$BackupRoot BackupProfiles=$(@($backupProfiles).Count)"

        # Validación rápida del layout esperado (que los perfiles tengan al menos una carpeta típica)
        $hasExpectedLayout = $false
        foreach($profile in $backupProfiles){
            foreach($rel in $USER_FOLDER_NAMES){
                $checkPath = Join-Path $profile.FullName $rel
                if(Test-Path $checkPath){
                    $hasExpectedLayout = $true
                    break
                }
            }
            if($hasExpectedLayout){ break }
        }
        if(-not $hasExpectedLayout){
            Write-Host "`n [!] El backup no parece tener el layout esperado (no se encuentran carpetas típicas dentro de los perfiles)." -ForegroundColor $COLOR_DANGER
            Start-Sleep -Seconds 2
            return
        }

        Write-Host "`n PERFILES EN EL BACKUP:" -ForegroundColor $COLOR_PRIMARY
        $backupProfiles | ForEach-Object { Write-Host " [ ] $($_.Name)" -ForegroundColor $COLOR_MENU }
        Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $profileChoice = Read-Host ' NOMBRE DE PERFIL A RESTAURAR (ENTER PARA TODOS, X PARA VOLVER)'
        if ($profileChoice -and $profileChoice.ToUpper() -eq "X") {
            return
        }

        $targetUsersRoot = "$env:SystemDrive\Users"
        $alt = Read-MenuOption " RESTAURAR EN UBICACIÓN ALTERNATIVA? (S/N)" -Valid @("S","N")
        if($alt -eq "S"){
            $custom = Read-Host " RUTA BASE (ej: D:\\Restores)"
            if($custom){ $targetUsersRoot = $custom }
        }
        Write-Log "RESTORE" "TargetUsersRoot=$targetUsersRoot"

        if (-not $profileChoice) {
            Write-Log "RESTORE" "Restoring ALL profiles Count=$(@($backupProfiles).Count)"
            foreach ($profile in $backupProfiles) {
                Write-Log "RESTORE" "Restoring profile=$($profile.Name)"
                $dest = Join-Path $targetUsersRoot $profile.Name
                if(Test-Path $dest){
                    if(-not (Confirm-Critical "SOBRESCRIBIR PERFIL EXISTENTE: $dest" "APLICAR")){ continue }
                }
                Restore-ProfileData $profile.FullName $targetUsersRoot
            }
            Read-Host "`n RESTAURACIÓN DE TODOS LOS PERFILES COMPLETADA. ENTER"
            return
        }

        $selected = $backupProfiles | Where-Object { $_.Name -ieq $profileChoice }
        if ($selected) {
            $selProfile = $selected | Select-Object -First 1
            Write-Log "RESTORE" "Restoring profile choice=$profileChoice Actual=$($selProfile.Name)"
            $dest = Join-Path $targetUsersRoot $selProfile.Name
            if(Test-Path $dest){
                if(-not (Confirm-Critical "SOBRESCRIBIR PERFIL EXISTENTE: $dest" "APLICAR")){ return }
            }
            Restore-ProfileData $selProfile.FullName $targetUsersRoot
            Read-Host "`n RESTAURACIÓN DEL PERFIL $profileChoice COMPLETADA. ENTER"
            return
        }

        Write-Host "`n [!] PERFIL NO ENCONTRADO EN EL BACKUP." -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 2
        return
    }
}

# --- PAUSA ESTANDAR CON MENSAJE ---
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

# --- OPTIMIZADOR DE TEMPORALES ---
function Invoke-TempOptimizer {
    Clear-Host
    # Definición local de colores para evitar errores de variables nulas
    $C_PRIMARY = "Green"; $C_MENU = "Cyan"; $C_WARN = "Yellow"; $C_ERR = "Red"; $C_GRAY = "Gray"

    while($true){
        Show-MainTitle
        Write-Host "`n GESTIÓN DE ALMACENAMIENTO Y LIMPIEZA" -ForegroundColor $C_MENU
        
        Write-Host " ---------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " [1] TODO (Mantenimiento Integral) " -NoNewline -ForegroundColor $C_GRAY
        Write-Host "-> Limpieza total de basura y archivos residuales." -ForegroundColor $C_GRAY
        
        Write-Host " [2] Papelera de Reciclaje         " -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Vacía archivos eliminados de todos los discos." -ForegroundColor $C_GRAY
        
        Write-Host " [3] Temporales de Usuario         " -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Caché de apps y navegación del perfil actual." -ForegroundColor $C_GRAY
        
        Write-Host " [4] Temporales del Sistema        " -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Archivos residuales de Windows y actualizaciones." -ForegroundColor $C_GRAY

        Write-Host " [5] LIMPIEZA AVANZADA (BleachBit) - App gráfica" -NoNewline -ForegroundColor $C_MENU
        Write-Host "-> Limpieza profunda de navegadores, cachés, y más." -ForegroundColor $C_GRAY

        Write-Host "`n CONTROL" -ForegroundColor $C_GRAY 
        Write-Host " -------------------" -ForegroundColor $C_ERR 
        Write-Host " [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $C_ERR
        
        $o = (Read-Host "`n > SELECCIONE UNA OPCIÓN").ToUpper()
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

        # --- EJECUCIÓN: PAPELERA ---
        if ($clearTrash -and -not $isDemo) {
            Write-Host "`n [*] Vaciando Papelera..." -ForegroundColor $C_WARN
            Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host " [+] Papelera limpia." -ForegroundColor $C_PRIMARY
        }

        # --- EJECUCIÓN: TEMPORALES ---
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

        # --- RESULTADOS ---
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

# --- GESTION DE PAQUETES (WINGET/CHOCO) ---
function Invoke-WingetMenu {
	Clear-Host #nuevo
    while($true){
        Show-MainTitle
        Write-Host ([Environment]::NewLine + ' GESTION DE PAQUETES (WINGET & CHOCOLATEY)') -ForegroundColor $COLOR_MENU
        Write-Host " [A] WINGET: ACTUALIZAR TODO             [D] CHOCO: INSTALAR CHOCOLATEY"
        Write-Host " [B] WINGET: LISTAR DISPONIBLES          [E] CHOCO: ACTUALIZAR TODO"
        Write-Host " [C] WINGET: REPARAR CLIENTE             [F] CHOCO: BUSCAR PAQUETE"
        Write-Host ' [G] INSTALAR POR NOMBRE (AUTO-SEARCH)'
Write-Host ' [H] INSTALAR WINGET (APP INSTALLER)'
        Write-Host ' [I] SCOOP: Instalar/Setup Scoop + buckets'
        Write-Host ' [J] SCOOP: Buscar/Instalar app'
        Write-Host ' [K] SCOOP: Listar actualizaciones'
        Write-Host ' [L] MULTI-SEARCH: Buscar en todas las fuentes'
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
        $hasChoco  = [bool](Get-Command choco -ErrorAction SilentlyContinue)
        $hasScoop  = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
        Write-Host "`n ESTADO:" -ForegroundColor Gray
        Write-Host ("  - winget: {0}" -f ($(if($hasWinget){"OK"}else{"NO"}))) -ForegroundColor $COLOR_MENU
        Write-Host ("  - choco : {0}" -f ($(if($hasChoco){"OK"}else{"NO"}))) -ForegroundColor $COLOR_MENU
        Write-Host ("  - scoop : {0}" -f ($(if($hasScoop){"OK"}else{"NO"}))) -ForegroundColor $COLOR_MENU

$o = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","E","F","G","H","I","J","K","L","X")
        if($o -eq "X"){break}
        
        if($o -eq "A"){
            if(-not $hasWinget){ Write-Host "`n [!] winget no está disponible." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n ACTUALIZANDO VIA WINGET..." -ForegroundColor $COLOR_PRIMARY
            $out = winget upgrade --all --accept-package-agreements --accept-source-agreements 2>&1
            Write-Log "PKG" ("winget upgrade all exit={0}" -f $LASTEXITCODE)
            Pause-Enter "`n FIN. ENTER"
        }
        if($o -eq "I"){
            Show-MainTitle
            Write-Host "`n [I] SCOOP MANAGER - MÚLTIPLES MÉTODOS" -ForegroundColor $COLOR_PRIMARY
            Write-Host " [1] MÉTODO OFICIAL (scoop.sh - recomendado)"
            Write-Host " [2] MÉTODO MANUAL (PowerShell Gallery)"
            Write-Host " [3] MÉTODO BINARIO (GitHub latest)"
            Write-Host " [4] MÉTODO CHOCO (choco install scoop)"
            Write-Host "`n [X] Cancelar"
            
            $metodo = Read-MenuOption "`n ``> MÉTODO" -Valid @("1","2","3","4","X")
            if($metodo -eq "X"){ continue }
            
            if($hasScoop){
                Write-Host "`n[+] Actualizando Scoop..." -ForegroundColor $COLOR_PRIMARY
                scoop update
                scoop update *
                Pause-Enter "`n ✅ Scoop actualizado. ENTER"
                continue
            }
            
            switch($metodo){
                "1" {
                    if(Confirm-RemoteScript "https://scoop.sh"){
                        iex (iwr -useb get.scoop.sh)
                        Write-Log "PKG" "Scoop método 1 (oficial)"
                    }
                }
                "2" {
                    if(Confirm-RemoteScript "https://raw.githubusercontent.com/ScoopInstaller/Install/master/install.ps1"){
                        irm get.scoop.sh | iex
                        Write-Log "PKG" "Scoop método 2 (Gallery)"
                    }
                }
                "3" {
                    $scoopUrl = "https://github.com/ScoopInstaller/Install/releases/latest/download/scoop-install.ps1"
                    $tempFile = "$env:TEMP\scoop-install.ps1"
                    Invoke-WebRequest -Uri $scoopUrl -OutFile $tempFile
                    iex $tempFile
                    Remove-Item $tempFile -Force
                    Write-Log "PKG" "Scoop método 3 (directo GitHub)"
                }
                "4" {
                    if($hasChoco){
                        choco install scoop -y
                        Write-Log "PKG" "Scoop vía Chocolatey"
                    } else {
                        Write-Host " [!] Chocolatey no disponible" -ForegroundColor $COLOR_DANGER
                    }
                }
            }
            $hasScoop = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
            if($hasScoop){
                Write-Host "`n ✅ Scoop instalado correctamente!" -ForegroundColor $COLOR_PRIMARY
                Pause-Enter " ENTER"
            } else {
                Write-Host "`n [!] Falló la instalación" -ForegroundColor $COLOR_DANGER
                Pause-Enter " ENTER"
            }
        }
        if($o -eq "J"){
            $app = Read-Host "`n ``> NOMBRE APP SCOOP"
            if($app){
                scoop search $app
                $confirm = Read-Host "Instalar? (S/N)"
                if($confirm -eq "S"){
                    scoop install $app
                }
            }
            Pause-Enter "`n ENTER"
        }
        if($o -eq "K"){
            scoop status
            Pause-Enter "`n ENTER"
        }
        if($o -eq "L"){
            $app = Read-Host "`n ``> APP A BUSCAR EN TODAS FUENTES"
            if($app){
                Write-Host "`n[+] Buscando en Winget..." -ForegroundColor $COLOR_MENU
                winget search $app
                Write-Host "`n[+] Buscando en Scoop..." -ForegroundColor $COLOR_MENU
                scoop search $app
                Write-Host "`n[+] Buscando en Choco..." -ForegroundColor $COLOR_MENU
                choco search $app
            }
            Pause-Enter "`n ENTER"
        }
        if($o -eq "B"){
            if(-not $hasWinget){ Write-Host "`n [!] winget no está disponible." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            winget upgrade
            Pause-Enter "`n ENTER"
        }
        if($o -eq "C"){
            if(-not $hasWinget){ Write-Host "`n [!] winget no está disponible." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n RE-INSTALANDO CLIENTE WINGET..." -ForegroundColor $COLOR_ALERT
            $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $dest = "$env:TEMP\winget.msixbundle"
            Invoke-WebRequest -Uri $url -OutFile $dest
            Add-AppxPackage -Path $dest
            Write-Log "PKG" "winget client reinstalled from $url"
            Pause-Enter "`n CLIENTE ACTUALIZADO. ENTER"
        }
        if($o -eq "H"){
            if(-not (Test-HasInternet)){ Write-Host "`n [!] Sin Internet." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n INSTALANDO/REPARANDO WINGET (APP INSTALLER)..." -ForegroundColor $COLOR_ALERT
            $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $dest = "$env:TEMP\\winget.msixbundle"
            Invoke-WebRequest -Uri $url -OutFile $dest
            Add-AppxPackage -Path $dest
            Write-Log "PKG" "winget installed/repaired from $url"
            Pause-Enter "`n LISTO. VUELVE A ENTRAR AL MENU PARA VER SI DICE OK."
        }
        if($o -eq "D"){
            if(-not (Test-HasInternet)){ Write-Host "`n [!] Sin Internet." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            if(-not (Require-Admin "instalar Chocolatey")){ continue }
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Log "PKG" ("choco install bootstrap exit={0}" -f $LASTEXITCODE)
            Pause-Enter "`n INSTALACION FINALIZADA. ENTER"
        }
        if($o -eq "E"){
            if(-not $hasChoco){ Write-Host "`n [!] CHOCO NO INSTALADO" -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            $out = choco upgrade all -y --no-progress 2>&1
            Write-Log "PKG" ("choco upgrade all exit={0}" -f $LASTEXITCODE)
            Pause-Enter " ENTER"
        }
        if($o -eq "F"){
            if(-not $hasChoco){ Write-Host "`n [!] CHOCO NO INSTALADO" -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            $p = Read-Host " NOMBRE DEL PROGRAMA A BUSCAR EN CHOCO"
            if($p){ choco search $p }
            Pause-Enter "`n ENTER"
        }
        if($o -eq "G"){
            $app = (Read-Host "`n ``> ESCRIBA EL NOMBRE DE LA APP A INSTALAR").Trim()
            if($app){
                $res = Invoke-SmartInstall -AppID $app -AppName $app
                Write-Log "PKG" "SmartInstall app=$app result=$res"
            }
            Pause-Enter "`n PROCESO TERMINADO. ENTER"
        }
    }
}

# --- MONITOR DE SISTEMA PRO ---
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

# --- ACTIVACIÓN INTEGRADA (MASSGRAVE) ---
function Invoke-MassGraveIntegrated {
    Show-MainTitle
    Write-Host "`n ACTIVACIÓN DE WINDOWS/OFFICE (MASSGRAVE)" -ForegroundColor $COLOR_MENU
    Write-Host " Este proceso ejecutará MassGrave directamente desde la fuente oficial." -ForegroundColor $COLOR_PRIMARY
    Write-Host " Se abrirá una nueva ventana de PowerShell con el proceso." -ForegroundColor $COLOR_ALERT
    
    if (-not (Confirm-Critical "EJECUTAR MASSGRAVE" "ACTIVAR")) { return }
    
    Write-Host "`n[+] Ejecutando MassGrave desde get.activated.win..." -ForegroundColor $COLOR_PRIMARY
    
    # Ejecución directa sin guardar archivos
    $scriptBlock = {
        irm https://get.activated.win | iex
    }
    
    # Lanzar en ventana nueva con permisos de admin
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$scriptBlock`"" -Verb RunAs
    
    Write-Host "`n[✔] MassGrave ejecutado." -ForegroundColor Green
    Write-Host "     Revisa la nueva ventana que se abrió y sigue las instrucciones." -ForegroundColor $COLOR_ALERT
    Pause-Enter "`n PRESIONE ENTER CUANDO TERMINE"
}

# --- CONTROL DE DEFENDER ---
function Invoke-DefenderControl {
	
	Clear-Host #nuevo
    while($true){
        Show-MainTitle
        Write-Host "`n CONTROL TOTAL DE WINDOWS DEFENDER" -ForegroundColor $COLOR_MENU
        Write-Host " [A] ACTIVAR DEFENDER`n [B] DESACTIVAR DEFENDER"
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $o = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","X")
        if(-not $o){ continue }
        if($o -eq "X"){break}
        if($o -eq "A"){
            if(-not (Require-Admin "activar Defender")){ continue }
            if(-not (Confirm-Critical "ACTIVAR WINDOWS DEFENDER" "APLICAR")){ continue }
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f | Out-Null
            Write-Log "DEFENDER" "Enabled (policy DisableAntiSpyware=0)"
            Write-Host " REINICIE PARA APLICAR CAMBIOS" -ForegroundColor Green
            Pause-Enter " ENTER"
        }
        if($o -eq "B"){
            if(-not (Require-Admin "desactivar Defender")){ continue }
            if(-not (Confirm-Critical "DESACTIVAR WINDOWS DEFENDER" "APLICAR")){ continue }
            $regReal = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
            if (!(Test-Path $regReal)) { New-Item $regReal -Force | Out-Null }
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f | Out-Null
            reg add $regReal /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f | Out-Null
            Write-Log "DEFENDER" "Disabled (policy DisableAntiSpyware=1, DisableRealtimeMonitoring=1)"
            Write-Host " DEFENDER DESACTIVADO" -ForegroundColor Green
            Pause-Enter " ENTER"
        }
    }
}

# --- PERFIL DE MANTENIMIENTO AUTOMATIZADO (EXPRESS) ---
function Invoke-AutoFlow {
	Clear-Host #nuevo
    Show-MainTitle
    Write-Host ([Environment]::NewLine + ' [!] PERFIL: MANTENIMIENTO EXPRESS (AUTO-FLOW)') -ForegroundColor $COLOR_ALERT
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray
    Write-Host " DESCRIPCION:" -ForegroundColor $COLOR_MENU
    Write-Host ' 1. Elimina Apps basura (Netflix, Disney, etc.)'
    Write-Host " 2. Limpia archivos temporales del sistema."
    Write-Host " 3. Instala: Chrome, 7-Zip y VLC Player."
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray
    
    Write-Host "`n [ENTER] COMENZAR INSTALACION" -ForegroundColor $COLOR_PRIMARY
    Write-Host " [X]     VOLVER AL MENU PRINCIPAL" -ForegroundColor $COLOR_DANGER
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray

    # --- MOTOR DE DETECCION DE TECLAS (X o ENTER) ---
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

    # --- LOGICA DE SALIDA ---
    if ($Decision -eq "SALIR") {
        Write-Host "`n [X] REGRESANDO AL MENU..." -ForegroundColor $COLOR_ALERT
        Start-Sleep -Seconds 1
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

    # --- PASO 1: BLOATWARE ---
    Write-Host "`n [+] Paso 1/3: Eliminando Bloatware..." -ForegroundColor $COLOR_MENU
    $bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*")
    foreach($b in $bloat){ 
        if (& $CheckAbort) { return }
        Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue 
    }
    
    # --- PASO 2: TEMPORALES ---
    if (& $CheckAbort) { return }
    Write-Host " [+] Paso 2/3: Limpiando temporales..." -ForegroundColor $COLOR_MENU
    $targets = @("$env:TEMP\*", "C:\Windows\Temp\*")
    $targets | ForEach-Object { 
        if (& $CheckAbort) { return }
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue 
    }

    # --- PASO 3: INSTALACION ---
    if (& $CheckAbort) { return }
    Write-Host " [+] Paso 3/3: Instalando apps esenciales..." -ForegroundColor $COLOR_MENU
    $basico = @(
        @{Name="Chrome"; ID="Google.Chrome"},
        @{Name="7-Zip"; ID="7zip.7zip"},
        @{Name="VLC Player"; ID="VideoLAN.VLC"}
    )
    foreach($app in $basico){
        if (& $CheckAbort) { return }
        Invoke-SmartInstall -AppID $app.ID -AppName $app.Name | Out-Null
    }

    Write-Host "`n [OK] AUTO-FLOW FINALIZADO." -ForegroundColor Green
    Read-Host " PRESIONE ENTER PARA VOLVER"
}

# --- GESTION DE DRIVERS MEJORADA (OFICIAL MS) ---
function Invoke-DriverManagement {
    while($true){ 
        Show-MainTitle
        Write-Host "`n GESTION DE DRIVERS PRO" -ForegroundColor $COLOR_MENU
        Write-Host ' [A] EXPORTAR DRIVERS (BACKUP LOCAL EN USB/SCRIPT)'
        Write-Host ' [B] RE-INSTALAR DRIVERS (DESDE BACKUP)'
        Write-Host ' [C] BUSCAR EN SERVIDORES OFICIALES (WINDOWS UPDATE)'
        Write-Host ' [D] VER IDENTIFICADORES DE HARDWARE (SIN DRIVER)'
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $o = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","X")
        if($o -eq "X"){break}
        
        if($o -eq "A") {
            if(-not (Require-Admin "exportar drivers")){ continue }
            $p="$PSScriptRoot\Drivers_$env:COMPUTERNAME"
            if(!(Test-Path $p)){ New-Item $p -ItemType Directory -Force | Out-Null }
            Write-Host " [+] Exportando drivers instalados... esto puede tardar." -ForegroundColor $COLOR_MENU
            Export-WindowsDriver -Online -Destination $p
            Write-Log "DRIVER" "Export drivers to $p"
            Pause-Enter " [+] BACKUP CREADO EN: $p. ENTER PARA VOLVER"
        }

        if($o -eq "B") {
            if(-not (Require-Admin "instalar drivers")){ continue }
            $path = "$PSScriptRoot\Drivers_$env:COMPUTERNAME"
            if(Test-Path $path){
                Write-Host " [+] Re-instalando drivers desde backup..." -ForegroundColor $COLOR_PRIMARY
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
                Write-Host " [!] NO SE ENCONTRO CARPETA DE BACKUP." -ForegroundColor $COLOR_DANGER
                Start-Sleep -Seconds 2 
            }
        }

        if($o -eq "C") {
            if(-not (Require-Admin "buscar drivers en Windows Update")){ continue }
            Write-Host "`n [+] CONFIGURANDO ENTORNO SEGURO..." -ForegroundColor Gray
            # --- MEJORA CRITICA: Bypass de confirmaciones y protocolos ---
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            
            Write-Host " [+] CONECTANDO CON MICROSOFT UPDATE..." -ForegroundColor $COLOR_PRIMARY
            
            if(!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)){
                Write-Host " [+] Instalando proveedor NuGet..." -ForegroundColor Gray
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
            }
            
            if(!(Get-Module -ListAvailable PSWindowsUpdate)){
                Write-Host " [+] Instalando módulo PSWindowsUpdate..." -ForegroundColor Gray
                Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser | Out-Null
            }
            
            Import-Module PSWindowsUpdate
            Write-Host " [+] Buscando e instalando controladores certificados..." -ForegroundColor $COLOR_MENU
            
            # El comando clave: Solo baja Categoría "Drivers" (ignora parches de seguridad pesados)
            $wuOut = Get-WindowsUpdate -Category "Drivers" -Install -AcceptAll -IgnoreReboot 2>&1
            $needsReboot = ($wuOut | Out-String) -match "reboot|reiniciar|restart"
            Write-Log "DRIVER" ("WindowsUpdate Drivers finished NeedsReboot={0}" -f $needsReboot)
            
            Write-Host "`n [OK] BUSQUEDA Y CARGA FINALIZADA." -ForegroundColor Green
            if($needsReboot){ Write-Host " [!] Puede requerir reinicio." -ForegroundColor $COLOR_ALERT }
            Pause-Enter " ENTER PARA VOLVER"
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

# --- ANÁLISIS DE SALUD Y REPORTE DE BATERÍA ---
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

# --- GENERACIÓN DE INFORME TÉCNICO DE HARDWARE ---
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

# --- PROCESOS Y HANDLES (INTEGRACIÓN CON SYSINTERNALS) ---
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

# --- VISUALIZACIÓN DE JERARQUÍA DE PROCESOS (ÁRBOL) ---
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

# --- DETECCIÓN DE PROCESOS QUE BLOQUEAN ARCHIVOS (HANDLE) ---
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

# --- ESCRITORIO REMOTO ---
function Invoke-RemoteDesktop {
    while ($true) {
        Clear-Host
        Show-MainTitle
        Write-Host "`n ESCRITORIO REMOTO - CONEXIONES" -ForegroundColor $COLOR_MENU
        Write-Host " [1] ESCRITORIO REMOTO (mstsc) - Nativo Windows" -ForegroundColor $COLOR_PRIMARY
        Write-Host " [2] ANYDESK - App gráfica ligera" -ForegroundColor $COLOR_MENU
        Write-Host " [3] RUSTDESK - Open source, gratuito" -ForegroundColor $COLOR_MENU
        Write-Host " [4] TEAMVIEWER - App gráfica completa" -ForegroundColor $COLOR_MENU
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER"
        
        $sub = Read-Host "`n > SELECCIONE"
        
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

# --- MENU PRINCIPAL ---
while ($true) {
	Clear-Host #nuevo
    Show-MainTitle
    $vista = if($Global:MenuHorizontal){"HORIZONTAL"}else{"VERTICAL"}
    Write-Host "`n SISTEMA OK | USUARIO $env:USERNAME | VISTA $vista" -ForegroundColor Gray
    Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
    
    if ($Global:MenuHorizontal) {
        Write-Host "    [A]  BACKUP TOTAL             [E]  OPTIMIZAR TEMP           [I]  KIT POST FORMAT" -ForegroundColor Green
        Write-Host "    [B]  RESTORE TOTAL            [F]  WIN UTIL TITUS           [J]  GESTION USUARIOS" -ForegroundColor Green
        Write-Host "    [C]  GESTION DRIVERS          [G]  MASSGRAVE ACT            [K]  SOPORTE TECNICO PRO" -ForegroundColor Green
        Write-Host "    [D]  PURGA Y FORMATEO         [H]  GESTION PAQUETES PRO     [L]  BYPASS WINDOWS 11" -ForegroundColor Green
        Write-Host '    [M]  RED Y REPARACION         [N]  MANTENIM DISCO           [O]  MONITOR EN VIVO (PRO)' -ForegroundColor Green
        Write-Host '    [P]  WINDOWS DEFENDER TOTAL   [Q]  AUTO-FLOW (EXPRESS)      [U]  SYSINTERNALS KIT' -ForegroundColor Green
        Write-Host '    [T]  ESCRITORIO REMOTO                                                           ' -ForegroundColor Green	
         } else {
             Write-Host "    [A] BACKUP TOTAL"
             Write-Host "    [B] RESTORE TOTAL"
             Write-Host "    [C] GESTION DRIVERS"
             Write-Host "    [D] PURGA Y FORMATEO"
             Write-Host "    [E] OPTIMIZAR TEMP"
             Write-Host "    [F] WIN UTIL TITUS"
             Write-Host "    [G] MASSGRAVE ACT"
             Write-Host "    [H] GESTION PAQUETES PRO"
             Write-Host "    [I] KIT POST FORMAT"
             Write-Host "    [J] GESTION USUARIOS"
             Write-Host "    [K] SOPORTE TECNICO PRO"
             Write-Host "    [L] BYPASS WINDOWS 11"
             Write-Host "    [M] RED Y REPARACION"
             Write-Host "    [N] MANTENIM DISCO"
             Write-Host "    [O] MONITOR EN VIVO (PRO)"
             Write-Host "    [P] WINDOWS DEFENDER TOTAL"
             Write-Host "    [Q] AUTO-FLOW (MANTENIMIENTO EXPRESS)"
             Write-Host "    [T] ESCRITORIO REMOTO"
             Write-Host "    [U] SYSINTERNALS KIT (11 herramientas)"
         }

    Write-Host "`n CONFIGURACION Y VISTA" -ForegroundColor Gray
    Write-Host "  -----------------------------------------------------------------------------" -ForegroundColor $COLOR_MENU
    Write-Host '    [R] REFRESCAR MENU            [V] CAMBIAR VISTA (V)' -ForegroundColor $COLOR_MENU
    Write-Host "    [X] SALIR DEL SCRIPT" -ForegroundColor $COLOR_DANGER

    $opt = (Read-Host "`n ``> OPCION").ToUpper()
    switch ($opt) {
        "R" { continue }
        "V" { $Global:MenuHorizontal = !$Global:MenuHorizontal; continue }
        "Q" { Invoke-AutoFlow }
        "U" {  while ($true) {
        Show-MainTitle
        Write-Host "`n SYSINTERNALS KIT - 11 HERRAMIENTAS PRO" -ForegroundColor $COLOR_MENU
        Write-Host " [1]  PROCEXP         - Process Explorer (gestor de procesos avanzado)"
        Write-Host " [2]  AUTORUNS       - Programas de inicio, servicios, drivers"
        Write-Host " [3]  PROCMON        - Monitor en vivo de archivos, registro, red"
        Write-Host " [4]  TCPVIEW        - Conexiones de red abiertas"
        Write-Host " [5]  RAMMAP         - Análisis detallado de memoria física"
        Write-Host " [6]  VMMAP          - Mapa de memoria virtual por proceso"
        Write-Host " [7]  DISK2VHD       - Convierte disco físico a VHD (virtualización)"
        Write-Host " [8]  WINOBJ         - Explorador de objetos del kernel"
        Write-Host " [9]  SIGCHECK       - Verifica firmas digitales y VirusTotal"
        Write-Host "[10]  SDELETE        - Borrado seguro de archivos (sobrescritura)"
        Write-Host "[11]  ACCESSENUM     - Examina permisos de carpetas y archivos"
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER AL MENU PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
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
        "A" { Invoke-Engine "BACKUP" "RESPALDO" }
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
                Write-Host "`n GESTION USUARIOS" -ForegroundColor $COLOR_MENU
                Write-Host " Usuarios locales / administrar comun" -ForegroundColor $COLOR_PRIMARY
                Write-Host "  [A] LISTAR USUARIOS"
                Write-Host "  [B] CREAR LOCAL ADMIN"
                Write-Host "  [C] ELIMINAR USUARIO`n" -ForegroundColor $COLOR_MENU
                Write-Host " Admin Oculto" -ForegroundColor $COLOR_PRIMARY
                Write-Host "  [D] ACTIVAR SUPER ADMIN"
                Write-Host "  [E] DESACTIVAR SUPER ADMIN"
                Write-Host "  [F] CAMBIAR PASSWORD"

                Write-Host ""
                Write-Host "Ejecutar el comando: Escribe net user administrador /active:yes (o net user administrator /active:yes si tu Windows está en inglés) y presiona Enter." -ForegroundColor $COLOR_ALERT
                Write-Host "para activar y desactivar`n" -ForegroundColor $COLOR_MENU
                Write-Host " CONTROL" -ForegroundColor Gray
                Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
                Write-Host "  [X] VOLVER" -ForegroundColor $COLOR_DANGER
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
                Write-Host "`n SOPORTE TECNICO PRO" -ForegroundColor $COLOR_MENU
                Write-Host " [A] SALUD DISCO"
                Write-Host " [B] REPARAR SISTEMA"
                Write-Host " [C] CLAVE BIOS - Recupera la licencia original del equipo."
                Write-Host " [D] SINCRONIZAR HORA"
                Write-Host " [F] SALUD DE BATERIA"
                Write-Host " [G] INFO TÉCNICA COMPLETA (HW/SW)"
                Write-Host "`n CONTROL" -ForegroundColor Gray
                Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
                Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER

                $s = Read-MenuOption ([Environment]::NewLine + ' >') -Valid @("A","B","C","D","F","G","X")
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
            }
        }
        "L" { 
            while($true){ 
                Show-MainTitle
                Write-Host "`n BYPASS WINDOWS 11" -ForegroundColor $COLOR_ALERT
                Write-Host " [A] BYPASS HARDWARE   - Omitir TPM, SecureBoot y chequeos de RAM"
                Write-Host " [B] BYPASS INTERNET   - Evitar conexión a Internet durante la instalación"
                Write-Host " [C] VER ESTADO ACTUAL (REGISTRO)"
                Write-Host " [D] REVERTIR BYPASS HARDWARE"
                Write-Host "`n CONTROL" -ForegroundColor Gray
                Write-Host " -------------------" -ForegroundColor $COLOR_DANGER
                Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER

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
                Show-MainTitle; Write-Host "`n RED Y REPARACION" -ForegroundColor $COLOR_MENU
                Write-Host ' [A] RESETEAR RED           [F] TRAZA DE RUTA (TRACERT)'
                Write-Host ' [B] REPARAR UPDATE         [G] TEST VELOCIDAD (FAST.COM)'
                Write-Host " [C] VER IP                 [E] VER CLAVES WI FI"
                Write-Host " [D] PING MONITOR           [W] WIRESHARK - Análisis gráfico de red (captura de paquetes)"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $m = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","E","F","G","W","X")
                if(-not $m){ continue }
                if($m -eq "X"){break}
                if($m -eq "A"){
                    if(-not (Require-Admin "resetear red")){ continue }
                    netsh winsock reset
                    netsh int ip reset
                    ipconfig /flushdns
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
                    while($true){Test-Connection $target -Count 1; if([console]::KeyAvailable){break}; Start-Sleep -Seconds 1}
                } 
                if($m -eq "E"){
                    Show-MainTitle; Write-Host "`n CLAVES WI FI" -ForegroundColor $COLOR_PRIMARY
                    $profiles = netsh wlan show profiles | Select-String "\:(.+)$" | ForEach-Object {$_.Matches.Groups[1].Value.Trim()}
                    foreach($name in $profiles){
                        $passLine = (netsh wlan show profile name="$name" key=clear) | Select-String "Contenido de la clave|Key Content"
                        if($passLine){ $pass = $passLine.ToString().Split(":")[1].Trim(); Write-Host " RED $name | CLAVE $pass" -ForegroundColor $COLOR_PRIMARY }
                    }
                    Pause-Enter "`n ENTER PARA VOLVER"
                }
                if($m -eq "F"){ $target=Read-Host " DOMINIO"; if($target){tracert $target}; Pause-Enter " ENTER"}
                if($m -eq "G"){ Start-Process "https://fast.com"; Pause-Enter " OK"}
	       if ($m -eq "W") {
                $installed = Get-Command wireshark -ErrorAction SilentlyContinue
                if (-not $installed) {
                    Write-Host "`n [+] Instalando Wireshark..." -ForegroundColor Yellow
                    winget install WiresharkFoundation.Wireshark --silent
                    Start-Sleep -Seconds 5
                    Write-Host " [✔] Wireshark instalado." -ForegroundColor Green
                }
                Write-Host "`n [+] Por favor, abre Wireshark manualmente desde el menú inicio." -ForegroundColor Yellow
                Write-Host "     (Para análisis de tráfico de red)" -ForegroundColor Gray
                Pause-Enter " ENTER después de cerrar Wireshark"
                continue
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
        "P" { Invoke-DefenderControl }
        "X" { exit }
    }
}