# ============================================================
# TECHFLOW SUITE PRO - MAINTENANCE MODULE (CLON COMPLETO)
# ============================================================

$COLOR_PRIMARY = $Global:COLOR_PRIMARY
$COLOR_ALERT   = $Global:COLOR_ALERT
$COLOR_DANGER  = $Global:COLOR_DANGER
$COLOR_MENU    = $Global:COLOR_MENU
$COLOR_WARNING = $Global:COLOR_WARNING

# BASE DE DATOS DE URLs PARA INSTALACIÓN AUTOMÁTICA
$Global:KnownApps = @{
    "mipony"          = @{ Url = "https://www.mipony.net/downloads/MiPony_Installer.exe"; Args = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"; FileName = "MiPony_Installer.exe" }
    "jdownloader"     = @{ Url = "http://installer.jdownloader.org/JD2Setup.exe"; Args = "/S"; FileName = "JD2Setup.exe" }
    "idm"             = @{ Url = "https://mirror2.internetdownloadmanager.com/idman642build25.exe"; Args = "/silent /norestart"; FileName = "idman.exe" }
    "fdm"             = @{ Url = "https://web.archive.org/web/20260404211342/https://files2.freedownloadmanager.org/6/latest/fdm_x64_setup.exe"; Args = "/S"; FileName = "FDM.exe" }
    "brave"           = @{ Url = "https://referrals.brave.com/latest/BraveBrowserSetup.exe"; Args = "/silent /install"; FileName = "BraveSetup.exe" }
    "opera"           = @{ Url = "https://download.opera.com/download/get/?partner=www&opsys=Windows&product=Opera&os=windows"; Args = "/silent"; FileName = "OperaSetup.exe" }
    "thorium"         = @{ Url = "https://github.com/Alex313031/Thorium-Win/releases/download/M138.0.7204.303/thorium_SSE4_mini_installer.exe"; Args = "/S"; FileName = "thorium_SSE4_mini_installer.exe" }
    "optichromium"    = @{ Url = "https://web.archive.org/web/20251214035701/https://download2267.mediafire.com/tlkp1arhg5rgjizzzrn4LWBEAW8DF7OevEORrGYyXM_b8flLvHxieRXodkUwcKzshLuNIOfjLpoogm_ucrhIaNLw9PUp9e8ku9T-_5oWsbIsS5eDWVK_H9NY-I1c8_3sBnPCHGGLqlvqark32R5oWjUlWUGJahcvkbvWixYDIiB7OQ/lc6hskmnsd98lmp/OptiChromium+V6.zip"; Args = ""; FileName = "OptiChromium.7z"; IsZip = $true }
    "chrome87"        = @{ Url = "https://web.archive.org/web/20240325002543/https://download1654.mediafire.com/7lraot2efkdgBS4DYgJbfgSnb-_bGT8TNIFi3i4rNjYZPA3eK9MadHsu5lxhH_7VnireWQFor0hamy84G0GNRRNlFWS3jGj-vcIpZ_KI-SFT5WhEJGxkrrDbVLvjanuhJ2k_7rwmxFBH1Er4oACUnIavHfHkM6uQzamuB_Fs9z_5lc8/l1fub61m4ltwx5u/Chrome+87+Flash+34+Portable.7z"; Args = ""; FileName = "Chrome87Portable.7z"; IsZip = $true }
    "filmora"         = @{ Url = "https://web.archive.org/web/20260413052259/https://download2264.mediafire.com/37gqnsr4c47goss47w7nURN9yZfA1IofJdWtZ7ZmX8dZ2dF865Haz7g4mVCZH0aenvncdSZ8qIt6egUVhwoideK6STrLemBeUkxWaPOElFdAFQEoL9uurzjNnBXxSDyhVWjJgkqIlk9a-OOXNyYqBsCdteOdmP-PMFH05DzsvkKLowg/7l97whv5gos05qg/Wondershare+Filmora+14.7z"; Args = ""; FileName = "Filmora14.7z"; IsZip = $true }
    "photoshop"       = @{ Url = "https://web.archive.org/web/20240325004539/https://download2390.mediafire.com/r2f51m86gzygrVa8Ai00uR6C7XSk8dwFCNpOF4VrvowDX34LvAZK0elRq8_lZTCuVOzT70lSgw29LFxFNNPx1JHielU0UPPr2QzDttB6FxgZrlKh0XmvNyXlRHnaYyK0xhlItIcVihWGXp869v4X-9CLt8cq7oMPPfNfC5wv8T7rcA/wpysvclp68cq6p3/Photoshop+CS6.rar"; Args = ""; FileName = "PhotoshopCS6.7z"; IsZip = $true }
    "office"          = @{ Url = "https://web.archive.org/web/20260413001802/https://download2445.mediafire.com/p7l3iqn220agfCPalOg-_DGhIBFvvOgt6GZcZHvnrgMmaA9G0WFSzoP5JlSGL82rS7lGI1UnWyrqeYaRn6jVdfEmgGltBnk5OZHtVM3yKITEh-hVM1BXsS2qlfpvbwnzsxEqrpFBuY5TmdEAEUhQPJHClNkcp1rsGRTcDZnoTTwQTg/jcqeb11nhj4hs31/Office+Professional+2016.7z"; Args = ""; FileName = "Office2016.7z"; IsZip = $true }
    "gtasa"           = @{ Url = "https://web.archive.org/web/20260413030332/https://download2340.mediafire.com/t3ju4zhngkrgnGKwGQ3HRrY4as2Yz1CbFb__bAxSnjIGvP9Lc5D_y2eN58WPRBqsAYJ52a3toM71-yJ79P3qpEevLvQ5LHElfMnIajCIiXMUwbDWkpLN5WCu8uJlBC5VAA-NOwKuzRhvDPMZNt9CwdbZiCyjaw49jIBd0BbGYQXF3A/bxhtk77nslso4oq/GTA+San+Andreas+CANAIMA+Mod.7z"; Args = ""; FileName = "GTASA.7z"; IsZip = $true }
    "cs16"            = @{ Url = "https://web.archive.org/web/20260413025540/https://download2291.mediafire.com/n7x022f9127g6iEQMf3RJg2rvc6qBLo175VJmRcsUTmHJhGbVU3jkxREHWtpTf8TJjTy3o1hzBNaNd_ldgsWhM6sSHHJDaVOuCbmEB-WvnPtMu-Ubmkmr_eSt1MeslBcS5OSLXh2E2bjJlQ_j-dpzriScwW4viTDgBmt_tpVxtO13g/ag28b7eumf10go2/Counter+Strike+1.6+Opti-Client+V2.7z"; Args = ""; FileName = "CS16.7z"; IsZip = $true }
    "pvz"             = @{ Url = "https://web.archive.org/web/20260413021646/https://download2354.mediafire.com/bl2h9mx7yclgtRzBnjJSY4fG7CIPMIr9cu3__jh1bumZbyHuKCxu6LIsbJ8CXjJXZVYoHb67e5ddtK76UpXpJBEnqOgwFBthxNZqbTYLJGnC0V3T8zoU5HcraUyG3jgH6u3VAEGOt1ZyZ616c_EKmuEy6k3e_qj9rcIW2sIECkrU2aA/yswh4afgrs0jo9f/Plantas+VS+Zombies+GOTY.7z"; Args = ""; FileName = "PVZ.7z"; IsZip = $true }
    "rufus"           = @{ Url = "https://github.com/pbatard/rufus/releases/download/v4.6/rufus-4.6.exe"; Args = ""; FileName = "rufus.exe" }
}

function Install-AutoApp {
    param([string]$AppName)
    Show-MainTitle
    Write-Host "`n 🚀 INSTALACIÓN AUTOMÁTICA: $AppName" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    
    $appKey = $AppName.ToLower().Trim()
    $found = $false; $appData = $null
    
    foreach ($key in $Global:KnownApps.Keys) {
        if ($appKey -eq $key -or $appKey -like "*$key*" -or $key -like "*$appKey*") {
            $found = $true; $appData = $Global:KnownApps[$key]; break
        }
    }
    
    if (-not $found) {
        Write-Host " ❌ No se encontró '$AppName' en la base de datos." -ForegroundColor $COLOR_DANGER
        Pause-Enter; return $false
    }
    
    $tempPath = "$env:TEMP\$($appData.FileName)"
    Write-Host " ⏳ Descargando: $($appData.Url)..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $appData.Url -OutFile $tempPath -UseBasicParsing -ErrorAction Stop
        Write-Host " ✅ Descarga completada." -ForegroundColor Green
    } catch {
        Write-Host " ❌ Error al descargar: $($_.Exception.Message)" -ForegroundColor Red
        Pause-Enter; return $false
    }
    
    if ($appData.IsZip) {
        $extractPath = "$env:TEMP\$($AppName)_extracted"
        if (-not (Test-Path $extractPath)) { New-Item $extractPath -ItemType Directory -Force | Out-Null }
        Expand-Archive -Path $tempPath -DestinationPath $extractPath -Force
        Write-Host " ✅ Extracción completada en: $extractPath" -ForegroundColor Green
        Start-Process "explorer.exe" $extractPath
        Pause-Enter; return $true
    }
    
    Write-Host " ⏳ Ejecutando instalador..." -ForegroundColor Yellow
    Start-Process -FilePath $tempPath -ArgumentList $appData.Args -Wait -ErrorAction SilentlyContinue
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    Write-Host " ✅ Proceso completado." -ForegroundColor Green
    Pause-Enter; return $true
}

function Remove-LockedFileSafely {
    param([Parameter(Mandatory=$true)][string]$Path, [switch]$ForceDelete)
    try {
        if (-not (Test-Path $Path)) { return $true }
        Remove-Item $Path -Recurse -Force -ErrorAction Stop
        return $true
    } catch {
        if ($ForceDelete) {
            try {
                cmd /c "del /f /q `"$Path`"" 2>&1 | Out-Null
                $pendingDir = "$env:TEMP\_pending_delete_"
                if (-not (Test-Path $pendingDir)) { New-Item $pendingDir -ItemType Directory -Force | Out-Null }
                $destName = [System.IO.Path]::GetFileName($Path) + "_" + (Get-Date -Format "yyyyMMddHHmmss")
                Move-Item $Path (Join-Path $pendingDir $destName) -Force -ErrorAction SilentlyContinue
                return $false
            } catch { return $false }
        }
        return $false
    }
}

function Invoke-TempOptimizer {
    while($true){
        Show-MainTitle
        Write-Host "`n 🗂️ GESTIÓN DE ALMACENAMIENTO Y LIMPIEZA" -ForegroundColor $COLOR_MENU
        Write-Host " ---------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " 🔧 [1] TODO (Mantenimiento Integral)" -ForegroundColor Gray
        Write-Host " 🗑️ [2] Papelera de Reciclaje" -ForegroundColor $COLOR_MENU
        Write-Host " 🧹 [3] Temporales de Usuario" -ForegroundColor $COLOR_MENU
        Write-Host " ⚙️ [4] Temporales del Sistema" -ForegroundColor $COLOR_MENU
        Write-Host " 🧽 [5] LIMPIEZA AVANZADA (BleachBit) - App gráfica" -ForegroundColor $COLOR_MENU
        Write-Host "`n ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $o = (Read-Host "`n > SELECCIONE").Trim().ToUpper()
        if($o -eq "X"){ break }
        
        $targets = @(); $clearTrash = $false
        switch ($o) {
            "1" { $targets = @("$env:TEMP", "C:\Windows\Temp"); $clearTrash = $true }
            "2" { $clearTrash = $true }
            "3" { $targets = @("$env:TEMP") }
            "4" { $targets = @("C:\Windows\Temp") }
            "5" {
                $installed = Get-Command bleachbit -ErrorAction SilentlyContinue
                if (-not $installed) {
                    Write-Host "`n [+] Instalando BleachBit..." -ForegroundColor Yellow
                    winget install BleachBit.BleachBit --silent
                }
                Write-Host "`n [+] Abre BleachBit manualmente desde el menú inicio." -ForegroundColor Yellow
                Pause-Enter " ENTER después de cerrar BleachBit"
                continue
            }
        }

        $isDemo = ((Read-Host " ¿Ejecutar en MODO DEMO? (S/N)").ToUpper() -eq "S")

        if ($clearTrash -and -not $isDemo) {
            Write-Host "`n [*] Vaciando Papelera..." -ForegroundColor $COLOR_WARNING
            Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host " [+] Papelera limpia." -ForegroundColor $COLOR_PRIMARY
        }

        if ($targets.Count -gt 0) {
            Write-Host "`n [*] Eliminando temporales..." -ForegroundColor $COLOR_WARNING
            $failCount = 0; $pendingCount = 0
            $excludedPatterns = @("*cpuz*", "*hwmonitor*", "*gpuz*", "*aida64*", "*msiafterburner*")
            
            foreach ($target in $targets) {
                if (Test-Path $target) {
                    $items = Get-ChildItem -Path "$target\*" -Force -Recurse -ErrorAction SilentlyContinue
                    $filteredItems = @()
                    foreach ($it in $items) {
                        $excluded = $false
                        foreach ($pattern in $excludedPatterns) {
                            if ($it.Name -like $pattern) { $excluded = $true; break }
                        }
                        if (-not $excluded) { $filteredItems += $it }
                    }
                    if (-not $isDemo) {
                        foreach ($it in $filteredItems) {
                            try {
                                if (Test-Path $it.FullName) {
                                    if (-not (Remove-LockedFileSafely -Path $it.FullName -ForceDelete)) { $pendingCount++ }
                                }
                            } catch { $failCount++ }
                        }
                    }
                }
            }
            if ($pendingCount -gt 0) { Write-Host "  [!] $pendingCount archivos programados para eliminación al reinicio." -ForegroundColor DarkGray }
        }

        if (-not $isDemo) {
            Write-Host "`n [+] PROCESO FINALIZADO." -ForegroundColor $COLOR_PRIMARY
        } else {
            Write-Host "`n [DEMO] No se realizaron cambios." -ForegroundColor $COLOR_WARNING
        }
        Pause-Enter "para volver"
    }
}

function Invoke-AutoFlow {
    Show-MainTitle
    Write-Host "`n 🚀 [!] PERFIL: MANTENIMIENTO EXPRESS (AUTO-FLOW)" -ForegroundColor $COLOR_ALERT
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray
    Write-Host " 🧹 1. Elimina Apps basura (Netflix, Disney, etc.)"
    Write-Host " 🗑️ 2. Limpia archivos temporales del sistema."
    Write-Host " 📦 3. Instala Apps (Chrome, Sumatra, WinRAR, 7-Zip, VLC, WhatsApp, VCRedist)"
    Write-Host " ---------------------------------------------------" -ForegroundColor Gray
    Write-Host "`n [ENTER] COMENZAR  |  [X] VOLVER AL MENU" -ForegroundColor $COLOR_PRIMARY

    $decision = Read-Host
    if ($decision.ToUpper() -eq "X") { return }

    Write-Host "`n [>] Eliminando Bloatware..." -ForegroundColor $COLOR_MENU
    $bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*")
    foreach($b in $bloat){ Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue }

    Write-Host "`n [>] Limpiando sistema..." -ForegroundColor Cyan
    @("$env:TEMP\*", "C:\Windows\Temp\*") | ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host "`n [>] Instalando paquetería esencial..." -ForegroundColor $COLOR_MENU
    $basico = @(
        @{Name="Google Chrome"; ID="Google.Chrome"}, @{Name="Sumatra PDF"; ID="SumatraPDF.SumatraPDF"},
        @{Name="WinRAR"; ID="RARLab.WinRAR"}, @{Name="7-Zip"; ID="7zip.7zip"},
        @{Name="VLC Media Player"; ID="VideoLAN.VLC"}, @{Name="WhatsApp Desktop"; ID="WhatsApp.WhatsApp"},
        @{Name="Microsoft VCRedist"; ID="Microsoft.VCRedist"}
    )
    foreach($app in $basico){
        Invoke-SmartInstall -AppID $app.ID -AppName $app.Name | Out-Null
    }
    Write-Host "`n [OK] AUTO-FLOW FINALIZADO." -ForegroundColor Green
    Pause-Enter
}

function Invoke-MassGraveIntegrated {
    Show-MainTitle
    Write-Host "`n 🔑 ACTIVACIÓN DE WINDOWS / OFFICE (MASSGRAVE)" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    if (-not (Confirm-Critical "EJECUTAR MASSGRAVE" "ACTIVAR")) { return }
    
    $rtpDesactivado = $false; $procesosExcluidos = @(); $rutasExcluidas = @()
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        $rtpDesactivado = $true
        
        $conectividad = "direct"
        try { $null = Invoke-WebRequest -Uri "https://get.activated.win" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop }
        catch { $conectividad = "doh" }

        $cmd = if ($conectividad -eq "doh") { "iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)" } else { "irm https://get.activated.win | iex" }
        
        $tempScript = "$env:TEMP\tf_mg.ps1"
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $cmd" | Out-File $tempScript -Encoding UTF8
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs -Wait
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    } finally {
        if ($rtpDesactivado) { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue }
    }
    Pause-Enter " ENTER CUANDO TERMINE"
}

function Repair-Defender {
    Show-MainTitle
    Write-Host "`n 🔧 REPARACIÓN DE WINDOWS DEFENDER" -ForegroundColor $COLOR_MENU
    if (-not (Require-Admin "reparar Defender")) { return }
    
    $policiesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    $blockingPolicies = @("DisableAntiSpyware", "DisableRealtimeMonitoring", "DisableBehaviorMonitoring", "DisableOnAccessProtection", "DisableScanOnRealtimeEnable")
    if (Test-Path $policiesPath) { foreach ($policy in $blockingPolicies) { Remove-ItemProperty -Path $policiesPath -Name $policy -ErrorAction SilentlyContinue } }

    @("WinDefend", "WdNisSvc", "Sense") | ForEach-Object {
        Set-Service -Name $_ -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $_ -ErrorAction SilentlyContinue
    }
    Start-Process "mpcmdrun.exe" -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host "`n ✅ REPARACIÓN COMPLETADA" -ForegroundColor Green
    Pause-Enter " ENTER"
}

function Invoke-DefenderControl {
    while($true){
        Show-MainTitle
        Write-Host "`n 🛡️ CONTROL TOTAL DE WINDOWS DEFENDER" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ✅ [1] ACTIVAR DEFENDER"
        Write-Host " 🔧 [2] REPARAR DEFENDER (Elimina GPO y restaura servicios)"
        Write-Host " 🦠 [3] ESCANEO DE MALWARE"
        Write-Host " ⚠️ [4] DESACTIVAR DEFENDER (NO RECOMENDADO)"
        Write-Host "`n ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $o = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","X")
        if($o -eq "X"){ break }
        
        if($o -eq "1"){
            if(Require-Admin "activar Defender" -and (Confirm-Critical "ACTIVAR DEFENDER" "APLICAR")){
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
                Write-Host " ✅ Activado." -ForegroundColor Green; Pause-Enter
            }
        }
        if($o -eq "2"){ Repair-Defender }
        if($o -eq "3"){
            Write-Host "`n [R] Rápido | [C] Completo | [U] Actualizar | [V] Ver Amenazas"
            $s = (Read-Host " >").ToUpper()
            $exe = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
            switch ($s) {
                "R" { Start-Process $exe -ArgumentList "-Scan -ScanType 1" -NoNewWindow -Wait }
                "C" { Start-Process $exe -ArgumentList "-Scan -ScanType 2" -NoNewWindow -Wait }
                "U" { Start-Process $exe -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait }
                "V" { Get-MpThreat | Format-Table -AutoSize }
            }
            Pause-Enter
        }
        if($o -eq "4"){
            if(Require-Admin "desactivar Defender" -and (Confirm-Critical "DESACTIVAR DEFENDER" "DESACTIVAR")){
                Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
                Write-Host " ✅ Desactivado." -ForegroundColor Red; Pause-Enter
            }
        }
    }
}

function Invoke-Win11Bypass {
    while($true){ 
        Show-MainTitle
        Write-Host "`n 🚀 BYPASS WINDOWS 11" -ForegroundColor $COLOR_ALERT
        Write-Host " 🔓 [A] BYPASS HARDWARE (TPM, SecureBoot, RAM)"
        Write-Host " 🌐 [B] BYPASS INTERNET (OOBE)"
        Write-Host " 📊 [C] VER ESTADO ACTUAL"
        Write-Host " 🔄 [D] REVERTIR BYPASS"
        Write-Host "`n ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER

        $b = Read-MenuOption "`n > SELECCIONE" -Valid @("A","B","C","D","X")
        if ($b -eq "X") { break }
        $reg = "HKLM:\System\Setup\LabConfig"

        if ($b -eq "A") {
            if (Require-Admin "bypass" -and (Confirm-Critical "BYPASS HARDWARE" "APLICAR")) {
                if (-not (Test-Path $reg)) { New-Item $reg -Force | Out-Null }
                "BypassTPMCheck","BypassSecureBootCheck","BypassRAMCheck" | ForEach-Object {
                    New-ItemProperty -Path $reg -Name $_ -Value 1 -PropertyType DWord -Force | Out-Null
                }
                Write-Host " ✅ Bypass aplicado." -ForegroundColor Green; Pause-Enter
            }
        }
        if ($b -eq "B") {
            if (Test-Path "$env:SystemRoot\System32\oobe\bypassnro.cmd") { & "$env:SystemRoot\System32\oobe\bypassnro.cmd" }
            Pause-Enter
        }
        if ($b -eq "C") {
            if (Test-Path $reg) { Get-ItemProperty $reg | Format-List Bypass* } else { Write-Host "No configurado." }
            Pause-Enter
        }
        if ($b -eq "D") {
            if (Require-Admin "revertir" -and (Confirm-Critical "REVERTIR" "APLICAR")) {
                Remove-Item $reg -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host " ✅ Revertido." -ForegroundColor Green; Pause-Enter
            }
        }
    }
}

function Invoke-WinUtilTitus {
    $url = "https://christitus.com/win"
    Show-MainTitle
    Write-Host "`n [!] Se ejecutará: $url" -ForegroundColor $COLOR_ALERT
    if ((Read-Host "¿Continuar? (S/N)").ToUpper() -eq "S") {
        irm $url | iex
        Pause-Enter
    }
}

function Invoke-OfficeAIO {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 🔑 MICROSOFT OFFICE AIO (DESPLIEGUE Y ACTIVACIÓN)" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 📦 [1] INSTALAR MICROSOFT 365 (Oficial vía ODT)"
        Write-Host " 💾 [2] DESCARGAR OFFICE 2016 PRO (Instalador autónomo)"
        Write-Host " 📄 [3] INSTALAR LIBREOFFICE (Alternativa 100% gratuita)"
        Write-Host " 🔑 [4] ACTIVAR OFFICE / WINDOWS (Script Oficial MassGrave)"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $sub = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","X")
        if ($sub -eq "X") { break }

        switch ($sub) {
            "1" {
                Write-Host "`n [+] Descargando herramienta oficial de despliegue (ODT)..." -ForegroundColor Yellow
                winget install Microsoft.OfficeDeploymentTool --silent --accept-package-agreements
                Write-Host " ✅ ODT descargado. Configúralo desde C:\Program Files\OfficeDeploymentTool" -ForegroundColor Green
                Pause-Enter
            }
            "2" {
                Install-AutoApp "office"
            }
            "3" {
                Write-Host "`n [+] Instalando LibreOffice..." -ForegroundColor Yellow
                winget install TheDocumentFoundation.LibreOffice --silent --accept-package-agreements
                Write-Host " ✅ LibreOffice instalado." -ForegroundColor Green
                Pause-Enter
            }
            "4" {
                Invoke-MassGraveIntegrated
            }
        }
    }
}
