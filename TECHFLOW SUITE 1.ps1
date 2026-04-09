# ============================================================
# [SISTEMA] - AUTO-ELEVACIÓN A ADMINISTRADOR
# ============================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host " [!] Solicitando permisos de Administrador..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
# ============================================================
$CONFIG_FILE = "$PSScriptRoot\suite_config.dat"
$COLOR_PRIMARY = "Green"; $COLOR_ALERT = "Yellow"; $COLOR_DANGER = "Red"; $COLOR_MENU = "Cyan"
$Global:MenuHorizontal = $true

if (!(Test-Path $CONFIG_FILE)) { "ADMIN2026" | Out-File $CONFIG_FILE -Encoding ascii -Force }
$Global:MasterPass = (Get-Content $CONFIG_FILE -Raw).Trim()

$USER_FOLDER_NAMES = @("Desktop", "Documents", "Pictures", "Videos", "Music", "Downloads", "Favorites", "Contacts")
$USER_FOLDERS = $USER_FOLDER_NAMES
$DEFAULT_BACKUP_BASE = "$env:SystemDrive\Backups"

$LOG_FILE = Join-Path $PSScriptRoot ("techflow_suite_log_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".log")
$PREFS_FILE = Join-Path $PSScriptRoot "suite_prefs.json"
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LOG_FILE -Value "$ts [$Level] $Message" -Encoding utf8
}
Write-Log "INFO" "TECHFLOW_SUITE started. ScriptRoot=$PSScriptRoot"

function Get-Prefs {
    if(Test-Path $PREFS_FILE){
        try { return (Get-Content $PREFS_FILE -Raw | ConvertFrom-Json) } catch { return [pscustomobject]@{} }
    }
    return [pscustomobject]@{}
}

function Save-Prefs($prefs){
    try {
        ($prefs | ConvertTo-Json -Depth 5) | Out-File -FilePath $PREFS_FILE -Encoding utf8 -Force
        Write-Log "INFO" "Prefs saved to $PREFS_FILE"
    } catch {
        Write-Log "WARN" ("Prefs save failed: " + $_.Exception.Message)
    }
}

function Pause-Enter {
    param([string]$Message = " PRESIONE ENTER PARA VOLVER")
    Read-Host $Message | Out-Null
}

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

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

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

function Test-HasInternet {
    try {
        return Test-Connection -ComputerName "1.1.1.1" -Count 1 -Quiet -ErrorAction SilentlyContinue
    } catch {
        return $false
    }
}

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

function Format-Bytes([Int64]$Bytes) {
    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    if ($Bytes -lt 1GB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -lt 1TB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    return "{0:N2} TB" -f ($Bytes / 1TB)
}

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

function Is-SuspiciousBackupBase {
    param([Parameter(Mandatory = $true)][string]$Base)
    $b = $Base.Trim().ToLower()
    return ($b -like "*\\windows*" -or $b -like "*\\system32*" -or $b -like "*\\program files*")
}

function Select-RemovableVolumes {
    try {
        return Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 2 }
    } catch {
        return @()
    }
}

function Download-RemoteScript {
    param([Parameter(Mandatory = $true)][string]$Url)
    $dest = Join-Path $env:TEMP ("techflow_remote_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".ps1")
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $dest
    return $dest
}

function Get-FileHashSafe {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    } catch {
        return $null
    }
}

function Get-UserProfilePaths {
    $profilesPath = "$env:SystemDrive\Users"
    Get-ChildItem -Path $profilesPath -Directory | Where-Object {
        $_.Name -notin @('All Users', 'Default', 'Default User', 'Public', 'desktop.ini', 'DefaultAppPool')
    } | Select-Object -ExpandProperty FullName
}

function Get-BackupRoot($basePath) {
    $existing = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Backup_*" } | ForEach-Object { $_.Name -replace "Backup_", "" } | Where-Object { $_ -match "^\d+$" } | Sort-Object {[int]$_} -Descending
    if ($existing) { $next = [int]$existing[0] + 1 } else { $next = 1 }
    $root = Join-Path $basePath ("Backup_" + $next.ToString("00"))
    if (!(Test-Path $root)) { New-Item -Path $root -ItemType Directory -Force | Out-Null }
    return $root
}

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

function Show-MainTitle {
    Clear-Host
    Write-Host " #############################################################################" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #                                                                           #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #          T E C H F L O W   S U I T E   -   P R O   E D I T I O N          #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #                  SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO              #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #                                     V.4.1                                 #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #############################################################################" -ForegroundColor $COLOR_PRIMARY
}

# --- MOTOR DE INSTALACION HIBRIDA INTELIGENTE ---
function Invoke-SmartInstall ($AppID, $AppName) {
    Write-Host "`n [!] INSTALANDO: $AppName..." -ForegroundColor $COLOR_MENU
    $wingetResult = winget install --id $AppID --exact --accept-package-agreements --accept-source-agreements --silent
    if ($LastExitCode -ne 0) {
        Write-Host " [!] WINGET FALLO. BUSCANDO EN CHOCOLATEY CON NOMBRE CORTO..." -ForegroundColor $COLOR_ALERT
        $shortName = $AppID.Split('.')[-1].ToLower() 
        choco install $shortName -y --no-progress
        if ($LastExitCode -eq 0) { return "OK" } else { return "ERROR" }
    }
    return "OK"
}

# --- KIT POST FORMAT V3 (100 APPS INTEGRADAS) ---
function Invoke-KitPostFormat {
    $apps = @{
        "1" = @{Name="Chrome"; ID="Google.Chrome"}; "2" = @{Name="Firefox"; ID="Mozilla.Firefox"}; "3" = @{Name="Brave"; ID="Brave.Brave"}; "4" = @{Name="Opera GX"; ID="Opera.OperaGX"}; "5" = @{Name="Vivaldi"; ID="VivaldiTechnologies.Vivaldi"};
        "6" = @{Name="MS Office"; ID="Microsoft.Office"}; "7" = @{Name="LibreOffice"; ID="LibreOffice.LibreOffice"}; "8" = @{Name="Foxit Reader"; ID="Foxit.FoxitReader"}; "9" = @{Name="Adobe Reader"; ID="Adobe.AdobeReader"}; "10" = @{Name="Notion"; ID="Notion.Notion"};
        "11" = @{Name="Slack"; ID="SlackTechnologies.Slack"}; "12" = @{Name="WPS Office"; ID="Kingsoft.WPSOffice"}; "13" = @{Name="Trello"; ID="Atlassian.Trello"}; "14" = @{Name="Evernote"; ID="Evernote.Evernote"}; "15" = @{Name="PDF24"; ID="PDF24.PDF24"};
        "16" = @{Name="7-Zip"; ID="7zip.7zip"}; "17" = @{Name="WinRAR"; ID="RARLab.WinRAR"}; "18" = @{Name="PowerToys"; ID="Microsoft.PowerToys"}; "19" = @{Name="Everything"; ID="voidtools.Everything"}; "20" = @{Name="BleachBit"; ID="BleachBit.BleachBit"};
        "21" = @{Name="TreeSize"; ID="JAMSoftware.TreeSizeFree"}; "22" = @{Name="Rufus"; ID="Akeo.Rufus"}; "23" = @{Name="Unlocker"; ID="IObit.Unlocker"}; "24" = @{Name="Teracopy"; ID="CodeSector.TeraCopy"}; "25" = @{Name="PowerISO"; ID="PowerSoftware.PowerISO"};
        "26" = @{Name="WhatsApp"; ID="9NBLGGH4LNS7"}; "27" = @{Name="Telegram"; ID="Telegram.TelegramDesktop"}; "28" = @{Name="Discord"; ID="Discord.Discord"}; "29" = @{Name="Zoom"; ID="Zoom.Zoom"}; "30" = @{Name="Skype"; ID="Microsoft.Skype"};
        "31" = @{Name="Teams"; ID="Microsoft.Teams"}; "32" = @{Name="Signal"; ID="OpenWhisperSystems.Signal"}; "33" = @{Name="Line"; ID="LINE.LINE"}; "34" = @{Name="Viber"; ID="ViberMediaSarl.Viber"}; "35" = @{Name="Messenger"; ID="Facebook.Messenger"};
        "36" = @{Name="VLC Player"; ID="VideoLAN.VLC"}; "37" = @{Name="Spotify"; ID="Spotify.Spotify"}; "38" = @{Name="OBS Studio"; ID="obsproject.obs-studio"}; "39" = @{Name="PotPlayer"; ID="Kakao.PotPlayer"}; "40" = @{Name="K-Lite Codecs"; ID="CodecGuide.K-LiteCodecPack.Full"};
        "41" = @{Name="AIMP"; ID="ArtemIzmaylov.AIMP"}; "42" = @{Name="iTunes"; ID="Apple.iTunes"}; "43" = @{Name="Handbrake"; ID="HandBrake.HandBrake"}; "44" = @{Name="Plex"; ID="Plex.PlexDesktop"}; "45" = @{Name="Audacity"; ID="Audacity.Audacity"};
        "46" = @{Name="CapCut"; ID="ByteDance.CapCut"}; "47" = @{Name="Canva"; ID="Canva.Canva"}; "48" = @{Name="GIMP"; ID="GIMP.GIMP"}; "49" = @{Name="Inkscape"; ID="Inkscape.Inkscape"}; "50" = @{Name="Krita"; ID="Krita.Krita"};
        "51" = @{Name="Blender"; ID="BlenderFoundation.Blender"}; "52" = @{Name="Paint.NET"; ID="dotPDN.PaintDotNet"}; "53" = @{Name="Darktable"; ID="Darktable.Darktable"}; "54" = @{Name="DaVinci Resolve"; ID="BlackmagicDesign.DaVinciResolve"}; "55" = @{Name="Figma"; ID="Figma.Figma"};
        "56" = @{Name="AnyDesk"; ID="AnyDesk.AnyDesk"}; "57" = @{Name="RustDesk"; ID="RustDesk.RustDesk"}; "58" = @{Name="CrystalDiskInfo"; ID="CrystalDiskInfo.CrystalDiskInfo"}; "59" = @{Name="CPU-Z"; ID="CPUID.CPU-Z"}; "60" = @{Name="GPU-Z"; ID="TechPowerUp.GPU-Z"};
        "61" = @{Name="HWMonitor"; ID="CPUID.HWMonitor"}; "62" = @{Name="Recuva"; ID="Piriform.Recuva"}; "63" = @{Name="WinDirStat"; ID="WinDirStat.WinDirStat"}; "64" = @{Name="Wireshark"; ID="WiresharkFoundation.Wireshark"}; "65" = @{Name="Angry IP Scanner"; ID="AntonKeks.AngryIPScanner"};
        "66" = @{Name="Putty"; ID="SimonTatham.PuTTY"}; "67" = @{Name="WinSCP"; ID="WinSCP.WinSCP"}; "68" = @{Name="FileZilla"; ID="TimKosse.FileZilla.Client"}; "69" = @{Name="Advanced IP Scanner"; ID="Famatech.AdvancedIPScanner"}; "70" = @{Name="Speccy"; ID="Piriform.Speccy"};
        "71" = @{Name="Steam"; ID="Valve.Steam"}; "72" = @{Name="Epic Games"; ID="EpicGames.EpicGamesLauncher"}; "73" = @{Name="EA Desktop"; ID="ElectronicArts.EADesktop"}; "74" = @{Name="Ubisoft Connect"; ID="Ubisoft.Connect"}; "75" = @{Name="GOG Galaxy"; ID="GOG.Galaxy"};
        "81" = @{Name="Razer Cortex"; ID="Razer.Cortex"}; "82" = @{Name="MSI Afterburner"; ID="MSI.Afterburner"}; "86" = @{Name="VS Code"; ID="Microsoft.VisualStudioCode"}; "87" = @{Name="Git"; ID="Git.Git"}; "90" = @{Name="Docker"; ID="Docker.DockerDesktop"};
        "94" = @{Name="DirectX"; ID="Microsoft.DirectX"}; "95" = @{Name="Google Drive"; ID="Google.Drive"}; "98" = @{Name="Notepad++"; ID="Notepad++.Notepad++"}; "100" = @{Name="VirtualBox"; ID="Oracle.VirtualBox"}
    }
    $prefs = Get-Prefs
    $lastOpt = $null
    try { $lastOpt = $prefs.lastKitOption } catch { $lastOpt = $null }

    while($true){
        Clear-Host
        Show-MainTitle
        Write-Host "`n KIT POST FORMAT - INSTALACION INTELIGENTE" -ForegroundColor $COLOR_PRIMARY
        Write-Host ' [0] LIMPIEZA DE BLOATWARE (CandyCrush, Netflix, etc.)'
        Write-Host ' [1] PERFIL BASICO (Chrome, 7Zip, VLC, AnyDesk, Zoom)'
        Write-Host ' [2] PERFIL GAMING (Steam, Discord, VLC, DirectX)'
        Write-Host ' [3] SELECCION MANUAL (Listado Completo)'
        Write-Host " [4] ACTUALIZAR TODO EL SOFTWARE"
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        if($lastOpt){ Write-Host " [ENTER] Repetir última selección: $lastOpt" -ForegroundColor $COLOR_MENU }
        
        $opt = Read-MenuOption "`n ``> SELECCIONE" -Valid @("0","1","2","3","4","X")
        if(-not $opt -and $lastOpt){ $opt = $lastOpt.ToString().Trim().ToUpper() }
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
            "1" { $selection = "1","16","36","56","29" }
            "2" { $selection = "71","28","36","94" }
            "3" {
                Clear-Host
                Show-MainTitle
                Write-Host "`n LISTADO MAESTRO" -ForegroundColor $COLOR_MENU
                $sortedKeys = $apps.Keys | Sort-Object {[int]$_}
                for ($i=0; $i -lt $sortedKeys.Count; $i += 3) {
                    $row = ""
                    for ($j=0; $j -lt 3; $j++) {
                        if (($i + $j) -lt $sortedKeys.Count) {
                            $key = $sortedKeys[$i + $j]
                            $row += "[$($key.PadLeft(3))] $($apps[$key].Name.PadRight(18)) "
                        }
                    }
                    Write-Host " $row"
                }
                $manual = Read-Host "`n ``> INGRESE NUMEROS SEPARADOS POR COMA ``(X para cancelar`)"
                if($manual -eq "X"){ continue }
                $selection = $manual.Split(",").Trim()
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
        }

        if($selection.Count -gt 0){
            $results = @()
            foreach($item in $selection){
                if($apps.ContainsKey($item)){
                    $res = Invoke-SmartInstall -AppID $apps[$item].ID -AppName $apps[$item].Name
                    if($res -ne "OK"){
                        Write-Host " [!] Reintentando: $($apps[$item].Name)" -ForegroundColor $COLOR_ALERT
                        Write-Log "KIT" "Retry app=$($apps[$item].Name) id=$($apps[$item].ID)"
                        $res = Invoke-SmartInstall -AppID $apps[$item].ID -AppName $apps[$item].Name
                    }
                    Write-Log "KIT" "Install app=$($apps[$item].Name) result=$res"
                    $results += "[ $res ] $($apps[$item].Name)"
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
        Write-Host " [A] PERFIL ACTUAL" -ForegroundColor $COLOR_PRIMARY
        Write-Host " [B] TODOS LOS PERFILES LOCALES" -ForegroundColor $COLOR_PRIMARY
        Write-Host " [C] EXPORTAR INVENTARIO DE APPS Y DRIVERS" -ForegroundColor $COLOR_PRIMARY
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $choice = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","X")
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

# --- OPTIMIZADOR DE TEMPORALES ---

# --- OPTIMIZADOR DE TEMPORALES ---
function Invoke-TempOptimizer {
    while($true){
        Show-MainTitle
        Write-Host "`n OPTIMIZACION DE ARCHIVOS TEMPORALES" -ForegroundColor $COLOR_MENU
        Write-Host " [A] LIMPIEZA PROFUNDA ``(TODO`)`n [B] SOLO TEMPORALES DE USUARIO`n [C] SOLO TEMPORALES DEL SISTEMA"
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $o = (Read-Host "`n ``> SELECCIONE").ToUpper()
        if($o -eq "X"){break}
        $targets = @()
        if($o -eq "A"){ $targets = @("$env:TEMP", "C:\Windows\Temp") }
        elseif($o -eq "B"){ $targets = @("$env:TEMP") }
        elseif($o -eq "C"){ $targets = @("C:\Windows\Temp") }
        else {
            Write-Host "`n OPCION NO VALIDA. INTENTA NUEVAMENTE." -ForegroundColor $COLOR_DANGER
            Start-Sleep -Seconds 1
            continue
        }

        if($targets.Count -gt 0){
            $demoMode = (Read-Host " MODO DEMO (S=solo mostrar, N=ejecutar)").ToUpper()
            $isDemo = ($demoMode -eq "S")

            Write-Log "TEMP" "Inicio optimizer. DemoMode=$isDemo Targets=$($targets -join ';')"
            Write-Host "`n ELIMINANDO ARCHIVOS..." -ForegroundColor $COLOR_PRIMARY
            $failCount = 0
            foreach ($target in $targets) {
                if (Test-Path $target) {
                    $items = Get-ChildItem -Path $target -Force -ErrorAction SilentlyContinue
                    $cnt = if($items){$items.Count}else{0}
                    Write-Host ("  - {0} => {1} elementos" -f $target, $cnt)
                    Write-Log "TEMP" "Target=$target Elements=$cnt DemoMode=$isDemo"

                    if(-not $isDemo){
                        foreach($it in $items){
                            try {
                                Remove-Item $it.FullName -Recurse -Force -ErrorAction Stop
                            } catch {
                                $failCount++
                                Write-Log "TEMP" ("Remove failed path={0} err={1}" -f $it.FullName, $_.Exception.Message)
                            }
                        }
                    }
                }
            }
            if(-not $isDemo){
                if($failCount -gt 0){
                    Write-Host "`n [!] LIMPIEZA COMPLETADA CON ERRORES. No se pudieron borrar: $failCount elementos (en uso/permisos)." -ForegroundColor $COLOR_ALERT
                } else {
                    Write-Host "`n LIMPIEZA COMPLETADA" -ForegroundColor $COLOR_PRIMARY
                }
            } else {
                Write-Host "`n DEMO: no se borro ningun archivo" -ForegroundColor $COLOR_ALERT
            }
            Write-Log "TEMP" "Fin optimizer. DemoMode=$isDemo FailCount=$failCount"
            Start-Sleep -Seconds 1
        }
    }
}

# --- GESTION DE PAQUETES (WINGET/CHOCO) ---
function Invoke-WingetMenu {
    while($true){
        Show-MainTitle
        Write-Host ([Environment]::NewLine + ' GESTION DE PAQUETES (WINGET & CHOCOLATEY)') -ForegroundColor $COLOR_MENU
        Write-Host " [A] WINGET: ACTUALIZAR TODO             [D] CHOCO: INSTALAR CHOCOLATEY"
        Write-Host " [B] WINGET: LISTAR DISPONIBLES          [E] CHOCO: ACTUALIZAR TODO"
        Write-Host " [C] WINGET: REPARAR CLIENTE             [F] CHOCO: BUSCAR PAQUETE"
        Write-Host ' [G] INSTALAR POR NOMBRE (AUTO-SEARCH)'
        Write-Host ' [H] INSTALAR WINGET (APP INSTALLER)'
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
        $hasChoco  = [bool](Get-Command choco -ErrorAction SilentlyContinue)
        Write-Host "`n ESTADO:" -ForegroundColor Gray
        Write-Host ("  - winget: {0}" -f ($(if($hasWinget){"OK"}else{"NO"}))) -ForegroundColor $COLOR_MENU
        Write-Host ("  - choco : {0}" -f ($(if($hasChoco){"OK"}else{"NO"}))) -ForegroundColor $COLOR_MENU

        $o = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","E","F","G","H","X")
        if($o -eq "X"){break}
        
        if($o -eq "A"){
            if(-not $hasWinget){ Write-Host "`n [!] winget no está disponible." -ForegroundColor $COLOR_DANGER; Pause-Enter " ENTER"; continue }
            Write-Host "`n ACTUALIZANDO VIA WINGET..." -ForegroundColor $COLOR_PRIMARY
            $out = winget upgrade --all --accept-package-agreements --accept-source-agreements 2>&1
            Write-Log "PKG" ("winget upgrade all exit={0}" -f $LASTEXITCODE)
            Pause-Enter "`n FIN. ENTER"
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

        Write-Host "`n ACCIONES DE MONITOREO" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_MENU
        Write-Host " [K] KILL: FINALIZAR PROCESO      [R] REFRESCAR / ACTUALIZAR DATOS" -ForegroundColor $COLOR_MENU
        Write-Host " [T] TIEMPO REFRESCO (MS)         [Q] SALIR" -ForegroundColor $COLOR_MENU
        
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER AL MENU PRINCIPAL" -ForegroundColor $COLOR_DANGER

        Write-Host "`n (Auto refresco: $refreshMs ms)" -ForegroundColor Gray
        $action = Read-MenuOption "`n ``> SELECCIONE (ENTER=auto)" -Valid @("K","R","T","Q","X")
        if(-not $action){
            Start-Sleep -Milliseconds $refreshMs
            continue
        }
        if ($action -eq "X") { break }
        if ($action -eq "Q") { break }
        if ($action -eq "K") {
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
        }
        if ($action -eq "T") {
            $v = Read-Host " NUEVO INTERVALO (MS) (ej 1000)"
            if($v -match "^\\d+$"){
                $refreshMs = [int]$v
                Write-Log "MONITOR" "RefreshMs set to $refreshMs"
            }
        }
    }
}

# --- CONTROL DE DEFENDER ---
function Invoke-DefenderControl {
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

function Invoke-AutoFlow {
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
# --- MENU PRINCIPAL ---
while ($true) {
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
        Write-Host '    [P]  WINDOWS DEFENDER TOTAL   [Q]  AUTO-FLOW (EXPRESS)' -ForegroundColor Green
    } else {
        Write-Host "    [A] BACKUP TOTAL`n    [B] RESTORE TOTAL`n    [C] GESTION DRIVERS`n    [D] PURGA Y FORMATEO`n    [E] OPTIMIZAR TEMP"
        Write-Host "    [F] WIN UTIL TITUS`n    [G] MASSGRAVE ACT`n    [H] GESTION PAQUETES PRO`n    [I] KIT POST FORMAT`n    [J] GESTION USUARIOS"
        Write-Host ('    [K] SOPORTE TECNICO PRO' + "`n    [L] BYPASS WINDOWS 11`n    [M] RED Y REPARACION`n    [N] MANTENIM DISCO`n    [O] MONITOR EN VIVO " + '(PRO)')
        Write-Host "    [P] WINDOWS DEFENDER TOTAL"
        Write-Host '    [Q]  AUTO-FLOW (MANTENIMIENTO EXPRESS)' -ForegroundColor Green
    }

    Write-Host "`n CONFIGURACION Y VISTA" -ForegroundColor Gray
    Write-Host "  -----------------------------------------------------------------------------" -ForegroundColor $COLOR_MENU
    Write-Host '    [R] REFRESCAR MENU            [V] CAMBIAR VISTA (V)' -ForegroundColor $COLOR_MENU
    Write-Host "    [S] CAMBIAR CLAVE             [X] SALIR DEL SCRIPT" -ForegroundColor $COLOR_DANGER

    $opt = (Read-Host "`n ``> OPCION").ToUpper()
    switch ($opt) {
        "R" { continue }
        "V" { $Global:MenuHorizontal = !$Global:MenuHorizontal; continue }
        "Q" { Invoke-AutoFlow }
        "A" { Invoke-Engine "BACKUP" "RESPALDO" }
        "B" { Invoke-Engine "RESTORE" "RESTAURACION" }
        "C" { Invoke-DriverManagement }
        "D" { 
            while($true){
                Show-MainTitle
                Write-Host "`n OPERACION CRITICA" -ForegroundColor $COLOR_DANGER
                Write-Host " [A] PURGAR PERFIL`n [B] FORMATEAR USB"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $o = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","X")
                if($o -eq "X"){ break }

                if($o -eq "B"){
                    if(-not (Require-Admin "formatear una unidad")){ continue }
                    if(-not (Confirm-Critical "FORMATEAR USB" "FORMAT")){ continue }
                    $vols = Select-RemovableVolumes
                    if($vols -and $vols.Count -gt 0){
                        Write-Host "`n UNIDADES REMOVIBLES DETECTADAS:" -ForegroundColor $COLOR_PRIMARY
                        $vols | ForEach-Object {
                            $size = if($_.Size){ Format-Bytes ([Int64]$_.Size) } else { "?" }
                            $free = if($_.FreeSpace){ Format-Bytes ([Int64]$_.FreeSpace) } else { "?" }
                            Write-Host ("  - {0}\\  Label: {1}  Size: {2}  Free: {3}" -f $_.DeviceID, $_.VolumeName, $size, $free) -ForegroundColor $COLOR_MENU
                        }
                    } else {
                        Write-Host "`n [!] No se detectaron unidades removibles via Win32_LogicalDisk." -ForegroundColor $COLOR_ALERT
                    }

                    $l = Read-Host " LETRA DE UNIDAD A FORMATEAR (EJ: E)"
                    if($l){
                        Write-Log "FORMAT" "Format-Volume DriveLetter=$l"
                        Format-Volume -DriveLetter $l -FileSystem NTFS -Force
                    }
                    Pause-Enter " HECHO. ENTER"
                    continue
                }

                if($o -eq "A"){
                    if(-not (Confirm-Critical "PURGAR PERFIL (ELIMINAR DATOS DE USUARIO ACTUAL)" "BORRAR")){ continue }
                    $profileRoot = $env:USERPROFILE
                    Write-Host " [+] Purga del perfil en: $profileRoot" -ForegroundColor $COLOR_PRIMARY

                    $demoMode = Read-MenuOption " MODO DEMO (S=solo mostrar, N=ejecutar)" -Valid @("S","N")
                    $isDemo = ($demoMode -eq "S")

                    $scriptPath = $PSCommandPath
                    Write-Log "PURGA" "Inicio. DemoMode=$isDemo ProfileRoot=$profileRoot"
                    foreach($rel in $USER_FOLDER_NAMES){
                        $fullPath = Join-Path $profileRoot $rel
                        if(Test-Path $fullPath){
                            $items = Get-ChildItem -LiteralPath $fullPath -Force -ErrorAction SilentlyContinue
                            $cnt = if($items){$items.Count}else{0}
                            Write-Host ("  - {0} => {1} elementos" -f $rel, $cnt)
                            Write-Log "PURGA" "Target=$fullPath Elements=$cnt DemoMode=$isDemo"

                            if(-not $isDemo){
                                $items | ForEach-Object {
                                    if($scriptPath -and ($_.FullName -ieq $scriptPath)){
                                        Write-Host "    (Excluido: script actual)" -ForegroundColor $COLOR_ALERT
                                        Write-Log "PURGA" "Excluded current script path=$scriptPath"
                                        return
                                    }
                                    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                                }
                            }
                        }
                    }
                    Write-Log "PURGA" "Fin. ProfileRoot=$profileRoot"
                    Pause-Enter " HECHO. ENTER"
                }
            }
        }
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
        "G" { 
            $url = "https://get.activated.win"
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
        "H" { Invoke-WingetMenu }
        "I" { Invoke-KitPostFormat }
        "J" { 
            while($true){ 
                Show-MainTitle; Write-Host "`n GESTION USUARIOS" -ForegroundColor $COLOR_MENU
                Write-Host " [A] LISTAR USUARIOS`n [B] CREAR LOCAL ADMIN`n [C] ELIMINAR USUARIO"
                Write-Host " [D] ACTIVAR SUPER ADMIN`n [F] CAMBIAR PASSWORD"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $u = Read-MenuOption ([Environment]::NewLine + ' >') -Valid @("A","B","C","D","F","X")
                if(-not $u){ continue }
                if($u -eq "X"){break}

                if(-not (Require-Admin "gestión de usuarios")){ continue }

                if($u -eq "A"){
                    net user
                    Pause-Enter " ENTER"
                }
                if($u -eq "B"){
                    if(-not (Confirm-Critical "CREAR USUARIO LOCAL ADMIN" "APLICAR")){ continue }
                    $n = (Read-Host " NOMBRE").Trim()
                    if($n){
                        net user "$n" /add
                        net localgroup administrators "$n" /add
                        Write-Log "USER" "Created admin user=$n"
                    }
                    Pause-Enter " OK"
                }
                if($u -eq "C"){
                    $n = (Read-Host " NOMBRE").Trim()
                    if($n -and ($n.ToLower() -ne $env:USERNAME.ToLower())){
                        if(-not (Confirm-Critical "ELIMINAR USUARIO '$n'" "BORRAR")){ continue }
                        net user "$n" /delete
                        Write-Log "USER" "Deleted user=$n"
                    } else {
                        Write-Host "`n [!] No se puede eliminar el usuario actual ($env:USERNAME)." -ForegroundColor $COLOR_DANGER
                    }
                    Pause-Enter " OK"
                }
                if($u -eq "D"){
                    if(-not (Confirm-Critical "ACTIVAR CUENTA ADMINISTRATOR (SUPER ADMIN)" "APLICAR")){ continue }
                    net user administrator /active:yes
                    Write-Log "USER" "Activated built-in administrator"
                    Pause-Enter " OK"
                }
                if($u -eq "F"){
                    $n = (Read-Host " USUARIO").Trim()
                    $p = Read-Host " CLAVE"
                    if($n -and $p){
                        if(-not (Confirm-Critical "CAMBIAR PASSWORD DE '$n'" "APLICAR")){ continue }
                        net user "$n" $p
                        Write-Log "USER" "Password changed for user=$n"
                    }
                    Pause-Enter " OK"
                }
            }
        }
        "K" { 
            while($true){ Show-MainTitle; Write-Host "`n SOPORTE TECNICO PRO" -ForegroundColor $COLOR_MENU
            Write-Host " [A] SALUD DISCO`n [B] REPARAR SISTEMA`n [C] CLAVE BIOS - Recupera la licencia original del equipo.`n [D] SINCRONIZAR HORA"
            Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
            $s = Read-MenuOption ([Environment]::NewLine + ' >') -Valid @("A","B","C","D","X")
            if(-not $s){ continue }
            if($s -eq "X"){break}
            if($s -eq "A"){
                Get-PhysicalDisk | Format-Table
                Write-Log "SUPPORT" "Disk health queried"
                Pause-Enter " ENTER"
            }
            if($s -eq "B"){
                if(-not (Require-Admin "reparar sistema (SFC/DISM)")){ continue }
                if(-not (Confirm-Critical "REPARAR SISTEMA (SFC + DISM)" "APLICAR")){ continue }
                $outFile = Join-Path $PSScriptRoot ("support_repair_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".txt")
                Write-Host "`n [+] Ejecutando SFC..." -ForegroundColor $COLOR_MENU
                $sfcOut = (sfc /scannow 2>&1 | Out-String)
                Write-Host "`n [+] Ejecutando DISM..." -ForegroundColor $COLOR_MENU
                $dismOut = (dism /online /cleanup-image /restorehealth 2>&1 | Out-String)
                ($sfcOut + "`n`n--- DISM ---`n`n" + $dismOut) | Out-File -FilePath $outFile -Encoding utf8 -Force
                Write-Log "SUPPORT" "Repair ran. OutputFile=$outFile"
                Write-Host "`n [+] Salida guardada en: $outFile" -ForegroundColor $COLOR_PRIMARY
                Pause-Enter " OK"
            }
            if($s -eq "C"){
                $key = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
                Write-Host $key
                Write-Log "SUPPORT" "OA3 key queried"
                Pause-Enter " OK"
            } 
            if($s -eq "D"){ 
                net stop w32time 
                w32tm /config /syncfromflags:manual /manualpeerlist:"time.windows.com" 
                net start w32time 
                $syncResult = w32tm /resync 2>&1 
                if ($LASTEXITCODE -eq 0) { 
                    Write-Host "`n [+] SINCRONIZACION EXITOSA" -ForegroundColor $COLOR_PRIMARY 
                    Write-Host "`n ESTADO DE SINCRONIZACION:" -ForegroundColor $COLOR_ALERT 
                    w32tm /query /source | ForEach-Object { Write-Host (' > ' + $_) } 
                    w32tm /query /status | ForEach-Object { Write-Host (' > ' + $_) } 
                } else { 
                    Write-Host "`n [!] ERROR AL SINCRONIZAR:" -ForegroundColor $COLOR_DANGER 
                    $syncResult | ForEach-Object { Write-Host (' > ' + $_) } 
                } 
                Write-Log "SUPPORT" ("Time sync exit={0}" -f $LASTEXITCODE)
                Pause-Enter " OK" 
            } }
        }
        "L" { 
            while($true){ Show-MainTitle; Write-Host "`n BYPASS WINDOWS 11" -ForegroundColor $COLOR_ALERT
            Write-Host " [A] BYPASS HARDWARE   - Omitir TPM, SecureBoot y chequeos de RAM para continuar la instalación" -ForegroundColor $COLOR_MENU
            Write-Host " [B] BYPASS INTERNET  - Evitar la necesidad de conexión a Internet durante la instalación" -ForegroundColor $COLOR_MENU
            Write-Host " [C] VER ESTADO ACTUAL (REGISTRO)" -ForegroundColor $COLOR_MENU
            Write-Host " [D] REVERTIR BYPASS HARDWARE" -ForegroundColor $COLOR_MENU
            Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
            $b = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","X")
            if(-not $b){ continue }
            if($b -eq "X"){break}
            $reg="HKLM:\System\Setup\LabConfig"
            if($b -eq "A"){
                if(-not (Require-Admin "aplicar bypass Windows 11")){ continue }
                if(-not (Confirm-Critical "BYPASS HARDWARE (LabConfig)" "APLICAR")){ continue }
                Write-Host "`n [+] Aplicando bypass de hardware..." -ForegroundColor $COLOR_PRIMARY
                if(!(Test-Path $reg)){New-Item $reg -Force | Out-Null}
                "BypassTPMCheck","BypassSecureBootCheck","BypassRAMCheck" | ForEach-Object {New-ItemProperty $reg $_ -Value 1 -PropertyType DWord -Force | Out-Null}
                Write-Log "BYPASS" "Applied hardware bypass LabConfig"
                Pause-Enter " OK"
            }
            if($b -eq "B"){
                Write-Host "`n [+] Aplicando bypass de Internet..." -ForegroundColor $COLOR_PRIMARY
                & $env:SystemRoot\System32\oobe\bypassnro.cmd
                Write-Log "BYPASS" "Ran bypassnro.cmd"
                Pause-Enter " OK"
            }
            if($b -eq "C"){
                Show-MainTitle
                Write-Host "`n ESTADO LabConfig:" -ForegroundColor $COLOR_ALERT
                if(Test-Path $reg){
                    Get-ItemProperty $reg -ErrorAction SilentlyContinue | Select-Object BypassTPMCheck,BypassSecureBootCheck,BypassRAMCheck | Format-List
                } else {
                    Write-Host " (No existe)" -ForegroundColor $COLOR_MENU
                }
                Pause-Enter " ENTER"
            }
            if($b -eq "D"){
                if(-not (Require-Admin "revertir bypass Windows 11")){ continue }
                if(-not (Confirm-Critical "REVERTIR BYPASS HARDWARE (LabConfig)" "APLICAR")){ continue }
                if(Test-Path $reg){
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
                Write-Host " [D] PING MONITOR"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $m = Read-MenuOption "`n ``> SELECCIONE" -Valid @("A","B","C","D","E","F","G","X")
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
                }
                if($o -eq "B"){
                    if(-not (Confirm-Critical "OPTIMIZAR SSD (TRIM) EN DISCO C:" "APLICAR")){ continue }
                    Optimize-Volume -DriveLetter C -ReTrim -Verbose
                    Pause-Enter " OK"
                }
                if($o -eq "C"){
                    if(-not (Confirm-Critical "LIMPIEZA DISM (STARTCOMPONENTCLEANUP)" "APLICAR")){ continue }
                    dism /online /Cleanup-Image /StartComponentCleanup
                    Pause-Enter " OK"
                }
            }
        }
        "O" { Show-LiveMonitor }
        "P" { Invoke-DefenderControl }
        "S" { 
            $nk1 = Read-Host ' > NUEVA CLAVE'
            if(-not $nk1){ Pause-Enter " CANCELADO. ENTER"; break }
            $nk2 = Read-Host ' > REPITA NUEVA CLAVE'
            if($nk1 -ne $nk2){
                Write-Host "`n [!] NO COINCIDE." -ForegroundColor $COLOR_DANGER
                Write-Log "SEC" "MasterPass change failed (mismatch)"
                Pause-Enter " ENTER"
                break
            }
            if(-not (Confirm-Critical "CAMBIAR CLAVE MAESTRA" "APLICAR")){ break }
            $nk1 | Out-File $CONFIG_FILE -Encoding ascii -Force
            $Global:MasterPass = $nk1
            Write-Log "SEC" "MasterPass changed"
            Pause-Enter " OK"
        }
        "X" { exit }
    }
}
