$CONFIG_FILE = "$PSScriptRoot\suite_config.dat"
$COLOR_PRIMARY = "Green"; $COLOR_ALERT = "Yellow"; $COLOR_DANGER = "Red"; $COLOR_MENU = "Cyan"
$Global:MenuHorizontal = $true

if (!(Test-Path $CONFIG_FILE)) { "ADMIN2026" | Out-File $CONFIG_FILE -Encoding ascii -Force }
$Global:MasterPass = (Get-Content $CONFIG_FILE -Raw).Trim()
$USER_FOLDERS = @("$HOME\Desktop", "$HOME\Documents", "$HOME\Pictures", "$HOME\Videos", "$HOME\Music", "$HOME\Downloads")

function Show-MainTitle {
    Clear-Host
    Write-Host " #############################################################################" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #                                                                           #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #          T E C H F L O W   S U I T E   -   P R O   E D I T I O N          #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #                  SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO              #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #                                     V.4.0                                 #" -ForegroundColor $COLOR_PRIMARY
    Write-Host " #############################################################################" -ForegroundColor $COLOR_PRIMARY
}

# --- MOTOR DE INSTALACION HIBRIDA INTELIGENTE ---
function Invoke-SmartInstall ($AppID, $AppName) {
    Write-Host "`n [!] INSTALANDO: $AppName..." -ForegroundColor $COLOR_MENU
    
    # Intento con Winget usando el ID exacto
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
        # ... (Se pueden seguir llenando hasta 100 con la misma estructura)
    }

    while($true){
        Show-MainTitle
        Write-Host "`n KIT POST FORMAT - INSTALACION INTELIGENTE" -ForegroundColor $COLOR_PRIMARY
        Write-Host " [0] LIMPIEZA DE BLOATWARE (CandyCrush, Netflix, etc.)" -ForegroundColor $COLOR_ALERT
        Write-Host " [1] PERFIL BASICO (Chrome, 7Zip, VLC, AnyDesk, Zoom)"
        Write-Host " [2] PERFIL GAMING (Steam, Discord, VLC, DirectX)"
        Write-Host " [3] SELECCION MANUAL (Listado Completo)"
        Write-Host " [4] ACTUALIZAR TODO EL SOFTWARE"
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $opt = (Read-Host "`n > SELECCIONE").ToUpper()
        if($opt -eq "X"){break}
        
        $selection = @()
        switch ($opt) {
            "0" {
                Write-Host "`n [!] Eliminando Bloatware..." -ForegroundColor $COLOR_ALERT
                $bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*")
                foreach($b in $bloat){ Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue }
                Read-Host " OK. ENTER"
            }
            "1" { $selection = "1","16","36","56","29" }
            "2" { $selection = "71","28","36","94" }
            "3" {
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
                $manual = Read-Host "`n > INGRESE NUMEROS SEPARADOS POR COMA"
                $selection = $manual.Split(",").Trim()
            }
            "4" { winget upgrade --all --silent; Read-Host " OK. ENTER"; continue }
        }

        if($selection.Count -gt 0){
            $results = @()
            foreach($item in $selection){
                if($apps.ContainsKey($item)){
                    $res = Invoke-SmartInstall -AppID $apps[$item].ID -AppName $apps[$item].Name
                    $results += "[ $res ] $($apps[$item].Name)"
                }
            }
            Show-MainTitle
            Write-Host "`n RESUMEN DE INSTALACION:" -ForegroundColor $COLOR_ALERT
            $results | ForEach-Object { Write-Host " $_" }
            Read-Host "`n PRESIONE ENTER"
        }
    }
}


# --- MOTOR DE RESPALDO Y RESTAURACION ---
function Invoke-Engine ($Mode, $Msg) {
    Show-MainTitle
    $DriveLetter = if ($PSScriptRoot -and $PSScriptRoot.Length -ge 2) { $PSScriptRoot.Substring(0,2) } else { "C:" }
    Write-Host "`n SELECCION DE UNIDAD PARA $Msg" -ForegroundColor $COLOR_ALERT
    Write-Host " [A] UNIDAD ACTUAL $DriveLetter"
    Write-Host " [B] OTRA UNIDAD"
    Write-Host "`n CONTROL" -ForegroundColor Gray 
    Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
    Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
    $p = (Read-Host "`n > SELECCIONE").ToUpper()
    if ($p -eq "X") { return }
    $Base = if ($p -eq "B") { 
        $l = (Read-Host " LETRA DE UNIDAD EJ D").Substring(0,1).ToUpper(); "$($l):\$env:USERNAME" 
    } else { "$DriveLetter\Backups\$env:USERNAME" }
    foreach ($f in $USER_FOLDERS) {
        $name = Split-Path $f -Leaf
        $BackupPath = "$Base\$name"
        Show-MainTitle ; Write-Host "`n PROCESANDO $Msg - $name" -ForegroundColor $COLOR_MENU
        if ($Mode -eq "BACKUP") {
            if (Test-Path $f) {
                if (!(Test-Path $BackupPath)) { New-Item $BackupPath -ItemType Directory -Force | Out-Null }
                robocopy "$f" "$BackupPath" /E /MT:16 /R:0 /W:0 /XJ /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
            }
        } 
        elseif ($Mode -eq "RESTORE") {
            if (Test-Path $BackupPath) {
                if (!(Test-Path $f)) { New-Item $f -ItemType Directory -Force | Out-Null }
                robocopy "$BackupPath" "$f" /E /MT:16 /R:0 /W:0 /XJ /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
            }
        }
    }
    Read-Host "`n PROCESO FINALIZADO. ENTER PARA VOLVER"
}

# --- OPTIMIZADOR DE TEMPORALES ---
function Invoke-TempOptimizer {
    while($true){
        Show-MainTitle
        Write-Host "`n OPTIMIZACION DE ARCHIVOS TEMPORALES" -ForegroundColor $COLOR_MENU
        Write-Host " [A] LIMPIEZA PROFUNDA (TODO)`n [B] SOLO TEMPORALES DE USUARIO`n [C] SOLO TEMPORALES DEL SISTEMA"
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $o = (Read-Host "`n > SELECCIONE").ToUpper()
        if($o -eq "X"){break}
        $targets = @()
        if($o -eq "A"){ $targets = @("$env:TEMP\*", "C:\Windows\Temp\*") }
        elseif($o -eq "B"){ $targets = @("$env:TEMP\*") }
        elseif($o -eq "C"){ $targets = @("C:\Windows\Temp\*") }
        if($targets.Count -gt 0){
            Write-Host "`n ELIMINANDO ARCHIVOS..." -ForegroundColor $COLOR_PRIMARY
            $targets | ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }
            Write-Host "`n LIMPIEZA COMPLETADA" -ForegroundColor $COLOR_PRIMARY; Start-Sleep -Seconds 1
        }
    }
}

# --- GESTION DE PAQUETES (WINGET/CHOCO) ---
function Invoke-WingetMenu {
    while($true){
        Show-MainTitle
        Write-Host "`n GESTION DE PAQUETES (WINGET & CHOCOLATEY)" -ForegroundColor $COLOR_MENU
        Write-Host " [A] WINGET: ACTUALIZAR TODO             [D] CHOCO: INSTALAR CHOCOLATEY"
        Write-Host " [B] WINGET: LISTAR DISPONIBLES          [E] CHOCO: ACTUALIZAR TODO"
        Write-Host " [C] WINGET: REPARAR CLIENTE             [F] CHOCO: BUSCAR PAQUETE"
        Write-Host " [G] INSTALAR POR NOMBRE (AUTO-SEARCH)"
        Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
        $o = (Read-Host "`n > SELECCIONE").ToUpper()
        if($o -eq "X"){break}
        
        if($o -eq "A"){
            Write-Host "`n ACTUALIZANDO VIA WINGET..." -ForegroundColor $COLOR_PRIMARY
            winget upgrade --all --accept-package-agreements --accept-source-agreements
            Read-Host "`n FIN. ENTER"
        }
        if($o -eq "B"){ winget upgrade; Read-Host "`n ENTER" }
        if($o -eq "C"){
            Write-Host "`n RE-INSTALANDO CLIENTE WINGET..." -ForegroundColor $COLOR_ALERT
            $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $dest = "$env:TEMP\winget.msixbundle"
            Invoke-WebRequest -Uri $url -OutFile $dest
            Add-AppxPackage -Path $dest
            Read-Host "`n CLIENTE ACTUALIZADO. ENTER"
        }
        if($o -eq "D"){
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Read-Host "`n INSTALACION FINALIZADA. ENTER"
        }
        if($o -eq "E"){
            if(Get-Command choco -ErrorAction SilentlyContinue){ choco upgrade all -y }
            else { Write-Host " CHOCO NO INSTALADO" -ForegroundColor $COLOR_DANGER }
            Read-Host " ENTER"
        }
        if($o -eq "F"){
            $p = Read-Host " NOMBRE DEL PROGRAMA A BUSCAR EN CHOCO"
            if($p){ choco search $p }
            Read-Host "`n ENTER"
        }
        if($o -eq "G"){
            $app = (Read-Host "`n > ESCRIBA EL NOMBRE DE LA APP A INSTALAR").Trim()
            if($app){ Invoke-SmartInstall -AppID $app -AppName $app }
            Read-Host "`n PROCESO TERMINADO. ENTER"
        }
    }
}

# --- MONITOR DE SISTEMA PRO ---
function Show-LiveMonitor {
    while ($true) {
        Show-MainTitle
        Write-Host "`n [O] MONITOR DE SISTEMA Y GESTION DE TAREAS" -ForegroundColor $COLOR_MENU
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
        
        $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        $mem = Get-CimInstance Win32_OperatingSystem | Select-Object @{Name="Free";Expression={"{0:N2}" -f ($_.FreePhysicalMemory / 1MB)}}, @{Name="Total";Expression={"{0:N2}" -f ($_.TotalVisibleMemorySize / 1MB)}}
        
        Write-Host " ESTADO ACTUAL:" -ForegroundColor $COLOR_ALERT
        Write-Host " >> CPU: $cpu %" -ForegroundColor $COLOR_PRIMARY
        Write-Host " >> RAM LIBRE: $($mem.Free) GB / $($mem.Total) GB" -ForegroundColor $COLOR_PRIMARY
        
        Write-Host "`n TOP 10 PROCESOS (ORDENADOS POR CONSUMO DE RAM):" -ForegroundColor $COLOR_ALERT
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor Gray
        
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | ForEach-Object {
            $memMB = "{0:N2}" -f ($_.WorkingSet / 1MB)
            $procName = $_.ProcessName
            if($procName.Length -gt 25) { $procName = $procName.Substring(0,22) + "..." }
            Write-Host " [ID: $($_.Id.ToString().PadRight(6))]  $($procName.PadRight(25)) | Uso: $memMB MB"
        }

        Write-Host "`n ACCIONES DE MONITOREO" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_MENU
        Write-Host " [K] KILL: FINALIZAR PROCESO      [R] REFRESCAR / ACTUALIZAR DATOS" -ForegroundColor $COLOR_MENU
        
        Write-Host "`n CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " [X] VOLVER AL MENU PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $action = (Read-Host "`n > SELECCIONE").ToUpper()
        if ($action -eq "X") { break }
        if ($action -eq "K") {
            $target = Read-Host " INGRESE NOMBRE O ID DEL PROCESO"
            if ($target) {
                try {
                    if ($target -match "^\d+$") { Stop-Process -Id $target -Force -ErrorAction Stop }
                    else { Stop-Process -Name $target -Force -ErrorAction Stop }
                    Write-Host "`n [+] PROCESO FINALIZADO EXITOSAMENTE." -ForegroundColor $COLOR_PRIMARY
                } catch {
                    Write-Host "`n [!] ERROR: NO SE PUDO CERRAR EL PROCESO." -ForegroundColor $COLOR_DANGER
                }
                Start-Sleep -Seconds 2
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
        $o = (Read-Host "`n > SELECCIONE").ToUpper()
        if($o -eq "X"){break}
        if($o -eq "A"){
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f | Out-Null
            Write-Host " REINICIE PARA APLICAR CAMBIOS" -ForegroundColor Green; Read-Host " ENTER"
        }
        if($o -eq "B"){
            $regReal = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
            if (!(Test-Path $regReal)) { New-Item $regReal -Force | Out-Null }
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f | Out-Null
            reg add $regReal /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f | Out-Null
            Write-Host " DEFENDER DESACTIVADO" -ForegroundColor Green; Read-Host " ENTER"
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
        Write-Host "    [A]  BACKUP TOTAL             [E]  OPTIMIZAR TEMP           [I]  KIT POST FORMAT"
        Write-Host "    [B]  RESTORE TOTAL            [F]  WIN UTIL TITUS           [J]  GESTION USUARIOS"
        Write-Host "    [C]  GESTION DRIVERS          [G]  MASSGRAVE ACT            [K]  SOPORTE TECNICO PRO"
        Write-Host "    [D]  PURGA Y FORMATEO         [H]  GESTION PAQUETES PRO     [L]  BYPASS WINDOWS 11"
        Write-Host "    [M]  RED Y REPARACION         [N]  MANTENIM DISCO           [O]  MONITOR EN VIVO (PRO)"
        Write-Host "    [P]  WINDOWS DEFENDER TOTAL"
    } else {
        Write-Host "    [A] BACKUP TOTAL`n    [B] RESTORE TOTAL`n    [C] GESTION DRIVERS`n    [D] PURGA Y FORMATEO`n    [E] OPTIMIZAR TEMP"
        Write-Host "    [F] WIN UTIL TITUS`n    [G] MASSGRAVE ACT`n    [H] GESTION PAQUETES PRO`n    [I] KIT POST FORMAT`n    [J] GESTION USUARIOS"
        Write-Host "    [K] SOPORTE TECNICO PRO`n    [L] BYPASS WINDOWS 11`n    [M] RED Y REPARACION`n    [N] MANTENIM DISCO`n    [O] MONITOR EN VIVO (PRO)"
        Write-Host "    [P] WINDOWS DEFENDER TOTAL"
    }

    Write-Host "`n CONFIGURACION Y VISTA" -ForegroundColor Gray
    Write-Host "  -----------------------------------------------------------------------------" -ForegroundColor $COLOR_MENU
    Write-Host "    [R] REFRESCAR MENU            [V] CAMBIAR VISTA (V)" -ForegroundColor $COLOR_MENU
    Write-Host "    [S] CAMBIAR CLAVE             [X] SALIR DEL SCRIPT" -ForegroundColor $COLOR_DANGER

    $opt = (Read-Host "`n > OPCION").ToUpper()
    switch ($opt) {
        "R" { continue }
        "V" { $Global:MenuHorizontal = !$Global:MenuHorizontal; continue }
        "A" { Invoke-Engine "BACKUP" "RESPALDO" }
        "B" { Invoke-Engine "RESTORE" "RESTAURACION" }
        "C" { 
            while($true){ Show-MainTitle; Write-Host "`n GESTION DE DRIVERS" -ForegroundColor $COLOR_MENU
            Write-Host " [A] EXPORTAR DRIVERS`n [B] INSTALAR DRIVERS"
            Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
            $o=(Read-Host "`n > SELECCIONE").ToUpper(); if($o -eq "X"){break}
            if($o -eq "A"){$p="$PSScriptRoot\Drivers_$env:COMPUTERNAME"; New-Item $p -ItemType Directory -Force | Out-Null; Export-WindowsDriver -Online -Destination $p; Read-Host " OK"}
            if($o -eq "B"){$path = "$PSScriptRoot\Drivers_$env:COMPUTERNAME"; Get-ChildItem "$path\*.inf" -Recurse | ForEach-Object {pnputil /add-driver $_.FullName /install}; Read-Host " OK"} }
        }
        "D" { 
            while($true){ Show-MainTitle; Write-Host "`n OPERACION CRITICA" -ForegroundColor $COLOR_DANGER
            Write-Host " [A] PURGAR PERFIL`n [B] FORMATEAR USB"
            Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
            $o=(Read-Host "`n > SELECCIONE").ToUpper(); if($o -eq "X"){break}
            $pin=Get-Random -Min 1000 -Max 9999; Write-Host "`n PIN DE SEGURIDAD $pin" -BackgroundColor Red -ForegroundColor White
            if((Read-Host " INGRESE PIN PARA CONFIRMAR") -eq $pin.ToString()){
                if($o -eq "B"){$l=(Read-Host " LETRA DE UNIDAD"); Format-Volume -DriveLetter $l -FileSystem NTFS -Force}
                if($o -eq "A"){$USER_FOLDERS | ForEach-Object {if(Test-Path $_){Remove-Item "$_\*" -Recurse -Force -ErrorAction SilentlyContinue}}}
                Read-Host " HECHO ENTER"
            } }
        }
        "E" { Invoke-TempOptimizer }
        "F" { Show-MainTitle; Invoke-WebRequest -UseBasicParsing https://christitus.com/win | Invoke-Expression }
        "G" { Show-MainTitle; Invoke-WebRequest -UseBasicParsing https://get.activated.win | Invoke-Expression }
        "H" { Invoke-WingetMenu }
        "I" { Invoke-KitPostFormat }
        "J" { 
            while($true){ 
                Show-MainTitle; Write-Host "`n GESTION USUARIOS" -ForegroundColor $COLOR_MENU
                Write-Host " [A] LISTAR USUARIOS`n [B] CREAR LOCAL ADMIN`n [C] ELIMINAR USUARIO"
                Write-Host " [D] ACTIVAR SUPER ADMIN`n [F] CAMBIAR PASSWORD"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $u=(Read-Host "`n >").ToUpper(); if($u -eq "X"){break}
                if($u -eq "A"){net user ; Read-Host " ENTER"}
                if($u -eq "B"){$n=Read-Host " NOMBRE"; net user "$n" /add; net localgroup administrators "$n" /add; Read-Host " OK"}
                if($u -eq "C"){$n=Read-Host " NOMBRE"; net user "$n" /delete; Read-Host " OK"}
                if($u -eq "D"){net user administrator /active:yes; Read-Host " OK"}
                if($u -eq "F"){$n=Read-Host " USUARIO"; $p=Read-Host " CLAVE"; if($n -and $p){net user "$n" $p}; Read-Host " OK"}
            }
        }
        "K" { 
            while($true){ Show-MainTitle; Write-Host "`n SOPORTE TECNICO PRO" -ForegroundColor $COLOR_MENU
            Write-Host " [A] SALUD DISCO`n [B] REPARAR SISTEMA`n [C] CLAVE BIOS`n [D] SINCRONIZAR HORA"
            Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
            $s=(Read-Host "`n >").ToUpper(); if($s -eq "X"){break}
            if($s -eq "A"){Get-PhysicalDisk | Format-Table; Read-Host " ENTER"}
            if($s -eq "B"){sfc /scannow; dism /online /cleanup-image /restorehealth; Read-Host " OK"}
            if($s -eq "C"){(Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey; Read-Host " OK"} 
            if($s -eq "D"){net stop w32time; w32tm /config /syncfromflags:manual /manualpeerlist:"time.windows.com"; net start w32time; w32tm /resync; Read-Host " OK"} }
        }
        "L" { 
            while($true){ Show-MainTitle; Write-Host "`n BYPASS WINDOWS 11" -ForegroundColor $COLOR_ALERT
            Write-Host " [A] BYPASS HARDWARE`n [B] BYPASS INTERNET"
            Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
            $b=(Read-Host "`n > SELECCIONE").ToUpper(); if($b -eq "X"){break}
            if($b -eq "A"){$reg="HKLM:\System\Setup\LabConfig"; if(!(Test-Path $reg)){New-Item $reg -Force}; "BypassTPMCheck","BypassSecureBootCheck","BypassRAMCheck" | ForEach-Object {New-ItemProperty $reg $_ -Value 1 -PropertyType DWord -Force}; Read-Host " OK"}
            if($b -eq "B"){& $env:SystemRoot\System32\oobe\bypassnro.cmd} }
        }
        "M" {  
            while($true){ 
                Show-MainTitle; Write-Host "`n RED Y REPARACION" -ForegroundColor $COLOR_MENU
                Write-Host " [A] RESETEAR RED           [F] TRAZA DE RUTA (TRACERT)"
                Write-Host " [B] REPARAR UPDATE         [G] TEST VELOCIDAD (FAST.COM)"
                Write-Host " [C] VER IP                 [E] VER CLAVES WI FI"
                Write-Host " [D] PING MONITOR"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $m=(Read-Host "`n > SELECCIONE").ToUpper(); if($m -eq "X"){break}
                if($m -eq "A"){netsh winsock reset; netsh int ip reset; ipconfig /flushdns; Read-Host " OK"}
                if($m -eq "B"){"wuauserv","bits" | ForEach-Object {Stop-Service $_ -Force}; Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force; "wuauserv","bits" | ForEach-Object {Start-Service $_}; Read-Host " OK"}
                if($m -eq "C"){Get-NetIPAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -notmatch 'Loopback' | Format-Table; Read-Host " ENTER"}
                if($m -eq "D"){
                    $target = Read-Host "> IP O DOMINIO (DEFECTO 8.8.8.8)"; if(!$target){$target="8.8.8.8"}
                    while($true){Test-Connection $target -Count 1; if([console]::KeyAvailable){break}; Start-Sleep -Seconds 1}
                } 
                if($m -eq "E"){
                    Show-MainTitle; Write-Host "`n CLAVES WI FI" -ForegroundColor $COLOR_PRIMARY
                    $profiles = netsh wlan show profiles | Select-String "\:(.+)$" | ForEach-Object {$_.Matches.Groups[1].Value.Trim()}
                    foreach($name in $profiles){
                        $passLine = (netsh wlan show profile name="$name" key=clear) | Select-String "Contenido de la clave|Key Content"
                        if($passLine){ $pass = $passLine.ToString().Split(":")[1].Trim(); Write-Host " RED $name | CLAVE $pass" -ForegroundColor $COLOR_PRIMARY }
                    }
                    Read-Host "`n ENTER PARA VOLVER"
                }
                if($m -eq "F"){ $target=Read-Host " DOMINIO"; tracert $target; Read-Host " ENTER"}
                if($m -eq "G"){ Start-Process "https://fast.com"; Read-Host " OK"}
            }
        }
        "N" { 
            while($true){ 
                Show-MainTitle; Write-Host "`n MANTENIMIENTO DE DISCOS" -ForegroundColor $COLOR_MENU
                Write-Host " [A] DESFRAGMENTAR HDD`n [B] OPTIMIZAR SSD`n [C] LIMPIEZA DISM"
                Write-Host "`n CONTROL" -ForegroundColor Gray ; Write-Host " -------------------" -ForegroundColor $COLOR_DANGER ; Write-Host " [X] VOLVER" -ForegroundColor $COLOR_DANGER
                $o=(Read-Host "`n >").ToUpper(); if($o -eq "X"){break}
                if($o -eq "A"){defrag C: /O; Read-Host " OK"}
                if($o -eq "B"){Optimize-Volume -DriveLetter C -ReTrim -Verbose; Read-Host " OK"}
                if($o -eq "C"){dism /online /Cleanup-Image /StartComponentCleanup; Read-Host " OK"}
            }
        }
        "O" { Show-LiveMonitor }
        "P" { Invoke-DefenderControl }
        "S" { $nk=Read-Host "> NUEVA CLAVE"; if($nk){$nk | Out-File $CONFIG_FILE -Force; $Global:MasterPass=$nk}; Read-Host " OK" }
        "X" { exit }
    }
}
