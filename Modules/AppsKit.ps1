# ============================================================
# TECHFLOW SUITE PRO - APPS KIT MODULE (CATÁLOGO COMPLETO V6)
# ============================================================

$COLOR_PRIMARY = $Global:COLOR_PRIMARY
$COLOR_ALERT   = $Global:COLOR_ALERT
$COLOR_DANGER  = $Global:COLOR_DANGER
$COLOR_MENU    = $Global:COLOR_MENU

function Invoke-SmartInstall ($AppID, $AppName) {
    Write-Host "`n [+] Instalando: $AppName ($AppID)..." -ForegroundColor $COLOR_MENU
    
    $chocoMapping = @{
        "Google.Chrome"="googlechrome"; "Mozilla.Firefox"="firefox"; "Opera.Opera"="opera"
        "Discord.Discord"="discord"; "Telegram.TelegramDesktop"="telegram"; "Zoom.Zoom"="zoom"
        "Microsoft.Teams"="teams"; "SlackTechnologies.Slack"="slack"; "WhatsApp.WhatsApp"="whatsapp"
        "7zip.7zip"="7zip"; "RARLab.WinRAR"="winrar"; "Microsoft.PowerToys"="powertoys"
        "voidtools.Everything"="everything"; "BleachBit.BleachBit"="bleachbit"; "RevoUninstaller.RevoUninstaller"="revo"
        "Bitwarden.Bitwarden"="bitwarden"; "Malwarebytes.Malwarebytes"="malwarebytes"; "CPUID.CPU-Z"="cpuz"
        "TechPowerUp.GPU-Z"="gpuz"; "CPUID.HWMonitor"="hwmonitor"; "REALiX.HWiNFO"="hwinfo"
        "Notepad++.Notepad++"="notepadplusplus"; "Microsoft.VisualStudioCode"="vscode"; "Git.Git"="git"
        "GitHub.GitHubDesktop"="github-desktop"; "Docker.DockerDesktop"="docker-desktop"; "OpenJS.NodeJS"="nodejs"
        "Python.Python.3"="python"; "PuTTY.PuTTY"="putty"; "WinSCP.WinSCP"="winscp"; "FileZilla.Client"="filezilla"
        "GIMP.GIMP"="gimp"; "Inkscape.Inkscape"="inkscape"; "BlenderFoundation.Blender"="blender"
        "VideoLAN.VLC"="vlc"; "OBSProject.OBSStudio"="obs-studio"; "Spotify.Spotify"="spotify"
        "TheDocumentFoundation.LibreOffice"="libreoffice"; "Obsidian.Obsidian"="obsidian"; "Notion.Notion"="notion"
        "Adobe.Acrobat.Reader.64-bit"="adobereader"; "WiresharkFoundation.Wireshark"="wireshark"; "AnyDesk.AnyDesk"="anydesk"
        "RustDesk.RustDesk"="rustdesk"; "TeamViewer.TeamViewer"="teamviewer"; "Valve.Steam"="steam"
    }

    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "   → Intentando con Winget..." -ForegroundColor DarkGray
        winget install --id $AppID --exact --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Instalado correctamente con Winget" -ForegroundColor Green
            return "OK"
        }
    }

    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        $cName = if ($chocoMapping.ContainsKey($AppID)) { $chocoMapping[$AppID] } else { $AppID.Split('.')[-1].ToLower() }
        Write-Host "   → Intentando con Chocolatey ($cName)..." -ForegroundColor DarkGray
        choco install $cName -y --no-progress 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Instalado correctamente con Chocolatey" -ForegroundColor Green
            return "OK"
        }
    }

    Write-Host "   ❌ Falló la instalación automatizada." -ForegroundColor Red
    return "ERROR"
}

function Invoke-KitPostFormat {
    $categorias = @{
        "1" = @{ Nombre = "🌐 NAVEGADORES"; Apps = @(
            @{Num=1; Nombre="Google Chrome"; ID="Google.Chrome"}, @{Num=2; Nombre="Mozilla Firefox"; ID="Mozilla.Firefox"},
            @{Num=3; Nombre="Brave Browser"; ID="Brave.Brave"}, @{Num=4; Nombre="Microsoft Edge"; ID="Microsoft.Edge"},
            @{Num=5; Nombre="Opera"; ID="Opera.Opera"}, @{Num=6; Nombre="Vivaldi"; ID="Vivaldi.Vivaldi"},
            @{Num=7; Nombre="Arc Browser"; ID="Arc.Arc"}, @{Num=8; Nombre="Tor Browser"; ID="TorProject.TorBrowser"},
            @{Num=9; Nombre="Firefox Developer"; ID="Mozilla.Firefox.DeveloperEdition"}, @{Num=10; Nombre="Chromium"; ID="Chromium.Chromium"},
            @{Num=11; Nombre="DuckDuckGO"; ID="DuckDuckGo.DesktopBrowser"}, @{Num=12; Nombre="Opera GX"; ID="Opera.OperaGX"},
            @{Num=13; Nombre="Pale Moon"; ID="PaleMoon.PaleMoon"}, @{Num=14; Nombre="Waterfox"; ID="Waterfox.Waterfox"},
            @{Num=15; Nombre="LibreWolf"; ID="LibreWolf.LibreWolf"}, @{Num=16; Nombre="Falkon"; ID="Falkon.Falkon"},
            @{Num=17; Nombre="Midori"; ID="Midori.Midori"}, @{Num=18; Nombre="SeaMonkey"; ID="SeaMonkey.SeaMonkey"},
            @{Num=19; Nombre="Ungoogled Chromium"; ID="UngoogledChromium.UngoogledChromium"}, @{Num=20; Nombre="Slimjet"; ID="Slimjet.Slimjet"}
        )}
        "2" = @{ Nombre = "💬 COMUNICACIÓN"; Apps = @(
            @{Num=21; Nombre="Discord"; ID="Discord.Discord"}, @{Num=22; Nombre="Telegram Desktop"; ID="Telegram.TelegramDesktop"},
            @{Num=23; Nombre="Signal Desktop"; ID="OpenWhisperSystems.Signal"}, @{Num=24; Nombre="Zoom"; ID="Zoom.Zoom"},
            @{Num=25; Nombre="Microsoft Teams"; ID="Microsoft.Teams"}, @{Num=26; Nombre="Slack"; ID="SlackTechnologies.Slack"},
            @{Num=27; Nombre="WhatsApp Desktop"; ID="9NKSQGP7F2NH"}, @{Num=28; Nombre="Element (Matrix)"; ID="Element.Element"},
            @{Num=29; Nombre="Thunderbird"; ID="Mozilla.Thunderbird"}, @{Num=30; Nombre="BlueMail"; ID="BlueMail.BlueMail"},
            @{Num=31; Nombre="Skype"; ID="Microsoft.Skype"}, @{Num=32; Nombre="Google Meet"; ID="Google.Meet"},
            @{Num=33; Nombre="Webex"; ID="Cisco.Webex"}, @{Num=34; Nombre="Jitsi Meet"; ID="Jitsi.JitsiMeet"},
            @{Num=35; Nombre="Mattermost"; ID="Mattermost.Mattermost"}, @{Num=36; Nombre="Rocket.Chat"; ID="RocketChat.RocketChat"},
            @{Num=37; Nombre="Flock"; ID="Flock.Flock"}, @{Num=38; Nombre="Keybase"; ID="Keybase.Keybase"},
            @{Num=39; Nombre="Wire"; ID="Wire.Wire"}, @{Num=40; Nombre="Tox"; ID="Tox.Tox"}
        )}
        "3" = @{ Nombre = "🛠️ UTILIDADES"; Apps = @(
            @{Num=41; Nombre="7-Zip"; ID="7zip.7zip"}, @{Num=42; Nombre="WinRAR"; ID="RARLab.WinRAR"},
            @{Num=43; Nombre="Microsoft PowerToys"; ID="Microsoft.PowerToys"}, @{Num=44; Nombre="Everything Search"; ID="voidtools.Everything"},
            @{Num=45; Nombre="BleachBit"; ID="BleachBit.BleachBit"}, @{Num=46; Nombre="Revo Uninstaller"; ID="RevoUninstaller.RevoUninstaller"},
            @{Num=47; Nombre="Bitwarden"; ID="Bitwarden.Bitwarden"}, @{Num=48; Nombre="Malwarebytes"; ID="Malwarebytes.Malwarebytes"},
            @{Num=49; Nombre="CPU-Z"; ID="CPUID.CPU-Z"}, @{Num=50; Nombre="GPU-Z"; ID="TechPowerUp.GPU-Z"},
            @{Num=51; Nombre="HWMonitor"; ID="CPUID.HWMonitor"}, @{Num=52; Nombre="HWINFO"; ID="REALiX.HWiNFO"},
            @{Num=53; Nombre="MSI Afterburner"; ID="Guru3D.Afterburner"}, @{Num=54; Nombre="PeaZip"; ID="PeaZip.PeaZip"},
            @{Num=55; Nombre="Notepad++"; ID="Notepad++.Notepad++"}, @{Num=56; Nombre="Greenshot"; ID="Greenshot.Greenshot"},
            @{Num=57; Nombre="ShareX"; ID="ShareX.ShareX"}, @{Num=58; Nombre="Windirstat"; ID="Windirstat.Windirstat"},
            @{Num=59; Nombre="WizTree"; ID="WizTree.WizTree"}, @{Num=60; Nombre="TreeSize Free"; ID="TreeSize.TreeSize"}
        )}
        "4" = @{ Nombre = "💻 DESARROLLO"; Apps = @(
            @{Num=61; Nombre="Visual Studio Code"; ID="Microsoft.VisualStudioCode"}, @{Num=62; Nombre="Git"; ID="Git.Git"},
            @{Num=63; Nombre="GitHub Desktop"; ID="GitHub.GitHubDesktop"}, @{Num=64; Nombre="Docker Desktop"; ID="Docker.DockerDesktop"},
            @{Num=65; Nombre="CMake"; ID="Kitware.CMake"}, @{Num=66; Nombre="Node.js"; ID="OpenJS.NodeJS"},
            @{Num=67; Nombre="Python 3"; ID="Python.Python.3"}, @{Num=68; Nombre="PuTTY"; ID="PuTTY.PuTTY"},
            @{Num=69; Nombre="WinSCP"; ID="WinSCP.WinSCP"}, @{Num=70; Nombre="FileZilla Client"; ID="FileZilla.Client"},
            @{Num=71; Nombre="Sublime Text"; ID="SublimeHQ.SublimeText.4"}, @{Num=72; Nombre="Neovim"; ID="Neovim.Neovim"},
            @{Num=73; Nombre="IntelliJ IDEA"; ID="JetBrains.IntelliJIDEA.Community"}, @{Num=74; Nombre="PyCharm Community"; ID="JetBrains.PyCharm.Community"},
            @{Num=75; Nombre="Postman"; ID="Postman.Postman"}, @{Num=76; Nombre="Insomnia"; ID="Insomnia.Insomnia"},
            @{Num=77; Nombre="Azure Data Studio"; ID="Microsoft.AzureDataStudio"}, @{Num=78; Nombre="DBeaver"; ID="DBeaver.DBeaver"},
            @{Num=79; Nombre="Fork"; ID="GitFork.Fork"}, @{Num=80; Nombre="Android Studio"; ID="Google.AndroidStudio"}
        )}
        "5" = @{ Nombre = "🎬 MULTIMEDIA"; Apps = @(
            @{Num=81; Nombre="GIMP"; ID="GIMP.GIMP"}, @{Num=82; Nombre="Inkscape"; ID="Inkscape.Inkscape"},
            @{Num=83; Nombre="Krita"; ID="KritaFoundation.Krita"}, @{Num=84; Nombre="Blender"; ID="BlenderFoundation.Blender"},
            @{Num=85; Nombre="Paint.NET"; ID="dotPDN.PaintDotNet"}, @{Num=86; Nombre="HandBrake"; ID="HandBrake.HandBrake"},
            @{Num=87; Nombre="VLC Media Player"; ID="VideoLAN.VLC"}, @{Num=88; Nombre="Audacity"; ID="Audacity.Audacity"},
            @{Num=89; Nombre="Calibre"; ID="Calibre.Calibre"}, @{Num=90; Nombre="K-Lite Codec Basic"; ID="CodecGuide.K-LiteCodecPack.Basic"},
            @{Num=91; Nombre="Spotify"; ID="Spotify.Spotify"}, @{Num=92; Nombre="DaVinci Resolve"; ID="BlackmagicDesign.DaVinciResolve"},
            @{Num=93; Nombre="Shotcut"; ID="Shotcut.Shotcut"}, @{Num=94; Nombre="OpenShot"; ID="OpenShot.OpenShot"},
            @{Num=95; Nombre="LMMS"; ID="LMMS.LMMS"}, @{Num=96; Nombre="Darktable"; ID="Darktable.Darktable"},
            @{Num=97; Nombre="RawTherapee"; ID="RawTherapee.RawTherapee"}, @{Num=98; Nombre="Kdenlive"; ID="Kdenlive.Kdenlive"},
            @{Num=99; Nombre="OBS Studio"; ID="OBSProject.OBSStudio"}, @{Num=100; Nombre="Stremio"; ID="Stremio.Stremio"}
        )}
        "6" = @{ Nombre = "📄 OFIMÁTICA"; Apps = @(
            @{Num=101; Nombre="LibreOffice"; ID="TheDocumentFoundation.LibreOffice"}, @{Num=102; Nombre="Microsoft 365 ODT"; ID="Microsoft.OfficeDeploymentTool"},
            @{Num=103; Nombre="Notion"; ID="Notion.Notion"}, @{Num=104; Nombre="Obsidian"; ID="Obsidian.Obsidian"},
            @{Num=105; Nombre="Zotero"; ID="Zotero.Zotero"}, @{Num=106; Nombre="Adobe Acrobat Reader"; ID="Adobe.Acrobat.Reader.64-bit"},
            @{Num=107; Nombre="Foxit PDF Reader"; ID="Foxit.FoxitReader"}, @{Num=108; Nombre="SumatraPDF"; ID="SumatraPDF.SumatraPDF"},
            @{Num=109; Nombre="PDF24 Creator"; ID="PDF24.PDF24"}, @{Num=110; Nombre="Typora Editor"; ID="Typora.Typora"},
            @{Num=111; Nombre="OnlyOffice"; ID="ONLYOFFICE.DesktopEditors"}, @{Num=112; Nombre="WPS Office"; ID="WPS.WPSOffice"},
            @{Num=113; Nombre="FreeOffice"; ID="SoftMaker.FreeOffice"}, @{Num=114; Nombre="Evernote"; ID="Evernote.Evernote"},
            @{Num=115; Nombre="Joplin"; ID="Joplin.Joplin"}, @{Num=116; Nombre="Anytype"; ID="Anytype.Anytype"},
            @{Num=117; Nombre="Zoho Workplace"; ID="Zoho.ZohoWorkplace"}, @{Num=118; Nombre="Calligra"; ID="Calligra.Calligra"},
            @{Num=119; Nombre="Apache OpenOffice"; ID="Apache.OpenOffice"}, @{Num=120; Nombre="Google Drive Desktop"; ID="Google.Drive"}
        )}
        "7" = @{ Nombre = "🌐 REDES Y TERMINAL"; Apps = @(
            @{Num=121; Nombre="Wireshark"; ID="WiresharkFoundation.Wireshark"}, @{Num=122; Nombre="Nmap"; ID="Nmap.Nmap"},
            @{Num=123; Nombre="Advanced IP Scanner"; ID="Famatech.AdvancedIPScanner"}, @{Num=124; Nombre="MobaXterm"; ID="Mobatek.MobaXterm"},
            @{Num=125; Nombre="Alacritty"; ID="Alacritty.Alacritty"}, @{Num=126; Nombre="Windows Terminal"; ID="Microsoft.WindowsTerminal"},
            @{Num=127; Nombre="AnyDesk"; ID="AnyDesk.AnyDesk"}, @{Num=128; Nombre="RustDesk"; ID="RustDesk.RustDesk"},
            @{Num=129; Nombre="TeamViewer"; ID="TeamViewer.TeamViewer"}, @{Num=130; Nombre="Angry IP Scanner"; ID="AngryIPScanner.AngryIPScanner"},
            @{Num=131; Nombre="NetScan"; ID="NetScan.NetScan"}, @{Num=132; Nombre="Termius"; ID="Termius.Termius"},
            @{Num=133; Nombre="Tabby"; ID="Eugeny.Tabby"}, @{Num=134; Nombre="Hyper"; ID="Hyper.Hyper"},
            @{Num=135; Nombre="Flipper"; ID="Flipper.Flipper"}, @{Num=136; Nombre="MRemoteNG"; ID="MRemoteNG.MRemoteNG"},
            @{Num=137; Nombre="KiTTY"; ID="KiTTY.KiTTY"}, @{Num=138; Nombre="Royal TS"; ID="RoyalApps.RoyalTS"},
            @{Num=139; Nombre="WinSCP"; ID="WinSCP.WinSCP"}, @{Num=140; Nombre="FileZilla Client"; ID="FileZilla.Client"}
        )}
        "8" = @{ Nombre = "🎮 JUEGOS"; Apps = @(
            @{Num=141; Nombre="Steam"; ID="Valve.Steam"}, @{Num=142; Nombre="Epic Games Launcher"; ID="EpicGames.EpicGamesLauncher"},
            @{Num=143; Nombre="EA Desktop"; ID="ElectronicArts.EADesktop"}, @{Num=144; Nombre="Ubisoft Connect"; ID="Ubisoft.Connect"},
            @{Num=145; Nombre="GOG Galaxy"; ID="GOG.Galaxy"}, @{Num=146; Nombre="Parsec"; ID="Parsec.Parsec"},
            @{Num=147; Nombre="PlayStation Remote"; ID="Sony.PlayStationRemotePlay"}, @{Num=148; Nombre="Xbox App"; ID="Microsoft.Xbox"},
            @{Num=149; Nombre="Battle.net"; ID="Blizzard.BattleNet"}, @{Num=150; Nombre="Riot Games"; ID="RiotGames.RiotClient"},
            @{Num=151; Nombre="Amazon Games"; ID="Amazon.Games"}, @{Num=152; Nombre="Itch.io"; ID="Itch.Itch"},
            @{Num=153; Nombre="Modrinth"; ID="Modrinth.Modrinth"}, @{Num=154; Nombre="CurseForge"; ID="Overwolf.CurseForge"},
            @{Num=155; Nombre="Playnite"; ID="Playnite.Playnite"}, @{Num=156; Nombre="Lutris"; ID="Lutris.Lutris"},
            @{Num=157; Nombre="Heroic Games Launcher"; ID="HeroicGamesLauncher.HeroicGamesLauncher"}, @{Num=158; Nombre="Greenlight"; ID="Greenlight.Greenlight"},
            @{Num=159; Nombre="NVIDIA GeForce Now"; ID="NVIDIA.GeForceNow"}, @{Num=160; Nombre="Boosteroid"; ID="Boosteroid.Boosteroid"}
        )}
        "9" = @{ Nombre = "🖥️ VIRTUALIZACIÓN"; Apps = @(
            @{Num=161; Nombre="VirtualBox"; ID="Oracle.VirtualBox"}, @{Num=162; Nombre="VMware Player"; ID="VMware.WorkstationPlayer"},
            @{Num=163; Nombre="Raspberry Pi Imager"; ID="RaspberryPiFoundation.RaspberryPiImager"}, @{Num=164; Nombre="WSL"; ID="Microsoft.WSL"},
            @{Num=165; Nombre="PowerShell 7"; ID="Microsoft.PowerShell"}, @{Num=166; Nombre="QEMU"; ID="QEMU.QEMU"},
            @{Num=167; Nombre="Podman"; ID="RedHat.Podman"}, @{Num=168; Nombre="Vagrant"; ID="HashiCorp.Vagrant"},
            @{Num=169; Nombre="Multipass"; ID="Canonical.Multipass"}, @{Num=170; Nombre="Lima"; ID="Lima.Lima"},
            @{Num=171; Nombre="UTM"; ID="UTM.UTM"}, @{Num=172; Nombre="Minikube"; ID="Kubernetes.Minikube"},
            @{Num=173; Nombre="Docker Desktop"; ID="Docker.DockerDesktop"}, @{Num=174; Nombre="Rancher Desktop"; ID="Rancher.RancherDesktop"},
            @{Num=175; Nombre="Colima"; ID="Colima.Colima"}, @{Num=176; Nombre="Kind"; ID="Kubernetes.Kind"},
            @{Num=177; Nombre="Proxmox VE"; ID="Proxmox.ProxmoxVE"}, @{Num=178; Nombre="XCP-ng Center"; ID="XCPng.XCPngCenter"},
            @{Num=179; Nombre="Hyper-V Manager"; ID="Microsoft.HyperVManager"}, @{Num=180; Nombre="Windows Sandbox"; ID="Microsoft.WindowsSandbox"}
        )}
        "10" = @{ Nombre = "💾 RESPALDOS"; Apps = @(
            @{Num=181; Nombre="Duplicati"; ID="Duplicati.Duplicati"}, @{Num=182; Nombre="Nextcloud Desktop"; ID="Nextcloud.NextcloudDesktop"},
            @{Num=183; Nombre="Google Drive"; ID="Google.Drive"}, @{Num=184; Nombre="Dropbox"; ID="Dropbox.Dropbox"},
            @{Num=185; Nombre="SyncThing"; ID="SyncThing.SyncThing"}, @{Num=186; Nombre="Resilio Sync"; ID="Resilio.ResilioSync"},
            @{Num=187; Nombre="Rclone"; ID="Rclone.Rclone"}, @{Num=188; Nombre="Proton Drive"; ID="ProtonTechnologies.ProtonDrive"},
            @{Num=189; Nombre="OneDrive"; ID="Microsoft.OneDrive"}, @{Num=190; Nombre="Mega"; ID="Mega.Mega"},
            @{Num=191; Nombre="pCloud"; ID="pCloud.pCloud"}, @{Num=192; Nombre="FreeFileSync"; ID="FreeFileSync.FreeFileSync"},
            @{Num=193; Nombre="Duplicacy"; ID="Duplicacy.Duplicacy"}, @{Num=194; Nombre="Kopia"; ID="Kopia.Kopia"},
            @{Num=195; Nombre="BorgBackup"; ID="BorgBackup.BorgBackup"}, @{Num=196; Nombre="Restic"; ID="Restic.Restic"},
            @{Num=197; Nombre="UrBackup"; ID="UrBackup.UrBackup"}, @{Num=198; Nombre="BackupPC"; ID="BackupPC.BackupPC"},
            @{Num=199; Nombre="Cobian Backup"; ID="CobianSoft.CobianBackup"}, @{Num=200; Nombre="EaseUS Todo Backup"; ID="EaseUS.TodoBackup"}
        )}
        "11" = @{ Nombre = "🔒 VPN"; Apps = @(
            @{Num=201; Nombre="ProtonVPN"; ID="ProtonTechnologies.ProtonVPN"}, @{Num=202; Nombre="Windscribe VPN"; ID="Windscribe.Windscribe"},
            @{Num=203; Nombre="OpenVPN"; ID="OpenVPNTechnologies.OpenVPN"}, @{Num=204; Nombre="Mullvad VPN"; ID="Mullvad.MullvadVPN"},
            @{Num=205; Nombre="NordVPN"; ID="NordSecurity.NordVPN"}, @{Num=206; Nombre="Tailscale"; ID="Tailscale.Tailscale"},
            @{Num=207; Nombre="ZeroTier"; ID="ZeroTier.ZeroTier"}, @{Num=208; Nombre="WireGuard"; ID="WireGuard.WireGuard"},
            @{Num=209; Nombre="VyprVPN"; ID="VyprVPN.VyprVPN"}, @{Num=210; Nombre="Hide.me"; ID="HideMe.HideMe"},
            @{Num=211; Nombre="IPVanish"; ID="IPVanish.IPVanish"}, @{Num=212; Nombre="PureVPN"; ID="PureVPN.PureVPN"},
            @{Num=213; Nombre="PrivateVPN"; ID="PrivateVPN.PrivateVPN"}, @{Num=214; Nombre="TunnelBear"; ID="TunnelBear.TunnelBear"},
            @{Num=215; Nombre="Surfshark"; ID="Surfshark.Surfshark"}, @{Num=216; Nombre="CyberGhost"; ID="CyberGhost.CyberGhost"},
            @{Num=217; Nombre="ExpressVPN"; ID="ExpressVPN.ExpressVPN"}, @{Num=218; Nombre="AtlasVPN"; ID="AtlasVPN.AtlasVPN"},
            @{Num=219; Nombre="Hotspot Shield"; ID="AnchorFree.HotspotShield"}, @{Num=220; Nombre="PIA VPN"; ID="PrivateInternetAccess.PIA"}
        )}
        "12" = @{ Nombre = "📊 MONITOR"; Apps = @(
            @{Num=221; Nombre="OpenHardwareMonitor"; ID="OpenHardwareMonitor.OpenHardwareMonitor"}, @{Num=222; Nombre="Core Temp"; ID="CoreTemp.CoreTemp"},
            @{Num=223; Nombre="CrystalDiskInfo"; ID="CrystalDiskInfo.CrystalDiskInfo"}, @{Num=224; Nombre="CrystalDiskMark"; ID="CrystalDiskMark.CrystalDiskMark"},
            @{Num=225; Nombre="HWiNFO64"; ID="REALiX.HWiNFO"}, @{Num=226; Nombre="Process Explorer"; ID="Microsoft.Sysinternals.ProcessExplorer"},
            @{Num=227; Nombre="Process Monitor"; ID="Microsoft.Sysinternals.ProcessMonitor"}, @{Num=228; Nombre="RAMMap"; ID="Microsoft.Sysinternals.RAMMap"},
            @{Num=229; Nombre="VMMap"; ID="Microsoft.Sysinternals.VMMap"}, @{Num=230; Nombre="TCPView"; ID="Microsoft.Sysinternals.TCPView"},
            @{Num=231; Nombre="Disk2VHD"; ID="Microsoft.Sysinternals.Disk2VHD"}, @{Num=232; Nombre="Autoruns"; ID="Microsoft.Sysinternals.Autoruns"},
            @{Num=233; Nombre="BgInfo"; ID="Microsoft.Sysinternals.BgInfo"}, @{Num=234; Nombre="PsTools"; ID="Microsoft.Sysinternals.PsTools"},
            @{Num=235; Nombre="Sysmon"; ID="Microsoft.Sysinternals.Sysmon"}, @{Num=236; Nombre="WinObj"; ID="Microsoft.Sysinternals.WinObj"},
            @{Num=237; Nombre="ZoomIt"; ID="Microsoft.Sysinternals.ZoomIt"}, @{Num=238; Nombre="Performance Monitor"; ID="Microsoft.PerformanceMonitor"},
            @{Num=239; Nombre="Resource Monitor"; ID="Microsoft.ResourceMonitor"}, @{Num=240; Nombre="Task Manager"; ID="Microsoft.TaskManager"}
        )}
        "13" = @{ Nombre = "📝 NOTAS"; Apps = @(
            @{Num=241; Nombre="Simplenote"; ID="Simplenote.Simplenote"}, @{Num=242; Nombre="Joplin"; ID="Joplin.Joplin"},
            @{Num=243; Nombre="Obsidian"; ID="Obsidian.Obsidian"}, @{Num=244; Nombre="Notion"; ID="Notion.Notion"},
            @{Num=245; Nombre="Standard Notes"; ID="StandardNotes.StandardNotes"}, @{Num=246; Nombre="CherryTree"; ID="CherryTree.CherryTree"},
            @{Num=247; Nombre="Zim Wiki"; ID="Zim.Zim"}, @{Num=248; Nombre="QOwnNotes"; ID="QOwnNotes.QOwnNotes"},
            @{Num=249; Nombre="Trilium Notes"; ID="TriliumNotes.TriliumNotes"}, @{Num=250; Nombre="BoostNote"; ID="BoostNote.BoostNote"},
            @{Num=251; Nombre="Zettlr"; ID="Zettlr.Zettlr"}, @{Num=252; Nombre="Mark Text"; ID="MarkText.MarkText"},
            @{Num=253; Nombre="Typora"; ID="Typora.Typora"}, @{Num=254; Nombre="Ghostwriter"; ID="Ghostwriter.Ghostwriter"},
            @{Num=255; Nombre="Remarkable"; ID="Remarkable.Remarkable"}, @{Num=256; Nombre="Logseq"; ID="Logseq.Logseq"},
            @{Num=257; Nombre="Dendron"; ID="Dendron.Dendron"}, @{Num=258; Nombre="Foam"; ID="Foam.Foam"},
            @{Num=259; Nombre="Notable"; ID="Notable.Notable"}, @{Num=260; Nombre="Evernote"; ID="Evernote.Evernote"}
        )}
        "14" = @{ Nombre = "⚡ UTILIDADES AVANZADAS"; Apps = @(
            @{Num=261; Nombre="Bulk Rename Utility"; ID="BulkRenameUtility.BulkRenameUtility"}, @{Num=262; Nombre="AutoHotkey"; ID="AutoHotkey.AutoHotkey"},
            @{Num=263; Nombre="Espanso Text Expander"; ID="Espanso.Espanso"}, @{Num=264; Nombre="Gsudo"; ID="Gsudo.Gsudo"},
            @{Num=265; Nombre="Nushell"; ID="Nushell.Nushell"}, @{Num=266; Nombre="Fastfetch"; ID="Fastfetch.Fastfetch"},
            @{Num=267; Nombre="Monitorian"; ID="Monitorian.Monitorian"}, @{Num=268; Nombre="qBittorrent"; ID="qBittorrent.qBittorrent"},
            @{Num=269; Nombre="TeraBox"; ID="Baidu.TeraBox"}, @{Num=270; Nombre="Power Automate Desktop"; ID="Microsoft.PowerAutomateDesktop"},
            @{Num=271; Nombre="Cheat Engine"; ID="CheatEngine.CheatEngine"}, @{Num=272; Nombre="dnSpy"; ID="dnSpy.dnSpy"},
            @{Num=273; Nombre="Process Hacker"; ID="ProcessHacker.ProcessHacker"}, @{Num=274; Nombre="x64dbg"; ID="x64dbg.x64dbg"},
            @{Num=275; Nombre="Sysinternals Suite"; ID="Microsoft.Sysinternals"}, @{Num=276; Nombre="Windows ADK"; ID="Microsoft.WindowsADK"},
            @{Num=277; Nombre="Windows PE"; ID="Microsoft.WindowsPE"}, @{Num=278; Nombre="WinDbg"; ID="Microsoft.WinDbg"},
            @{Num=279; Nombre="Registry Workshop"; ID="RegistryWorkshop.RegistryWorkshop"}, @{Num=280; Nombre="OllyDbg"; ID="OllyDbg.OllyDbg"}
        )}
        "15" = @{ Nombre = "📦 CLIENTES Y DESCARGAS"; Apps = @(
            @{Num=281; Nombre="Motrix Manager"; ID="Motrix.Motrix"}, @{Num=282; Nombre="LocalSend"; ID="LocalSend.LocalSend"},
            @{Num=283; Nombre="KDE Connect"; ID="KDE.KDEConnect"}, @{Num=284; Nombre="croc transfer"; ID="Schollz.croc"},
            @{Num=285; Nombre="Transmission"; ID="Transmission.Transmission"}, @{Num=286; Nombre="Deluge"; ID="DelugeTeam.Deluge"},
            @{Num=287; Nombre="Aria2"; ID="Aria2.Aria2"}, @{Num=288; Nombre="JDownloader"; ID="JDownloader.JDownloader"},
            @{Num=289; Nombre="IDM"; ID="InternetDownloadManager.IDM"}, @{Num=290; Nombre="EagleGet"; ID="EagleGet.EagleGet"},
            @{Num=291; Nombre="XDM"; ID="XtremeDownloadManager.XDM"}, @{Num=292; Nombre="Free Download Manager"; ID="FreeDownloadManager.FDM"},
            @{Num=293; Nombre="uGet"; ID="uGet.uGet"}, @{Num=294; Nombre="Persepolis"; ID="Persepolis.Persepolis"},
            @{Num=295; Nombre="Neat Download Manager"; ID="NeatDownloadManager.NDM"}, @{Num=296; Nombre="DownThemAll"; ID="DownThemAll.DownThemAll"},
            @{Num=297; Nombre="Wget"; ID="Wget.Wget"}, @{Num=298; Nombre="Curl"; ID="Curl.Curl"},
            @{Num=299; Nombre="HTTPie"; ID="HTTPie.HTTPie"}, @{Num=300; Nombre="Postman Client"; ID="Postman.Postman"}
        )}
        "16" = @{ Nombre = "🧹 LIMPIEZA Y DISCO"; Apps = @(
            @{Num=301; Nombre="TreeSize Free"; ID="TreeSize.TreeSize"}, @{Num=302; Nombre="WizTree"; ID="WizTree.WizTree"},
            @{Num=303; Nombre="DiskGenius"; ID="DiskGenius.DiskGenius"}, @{Num=304; Nombre="BleachBit"; ID="BleachBit.BleachBit"},
            @{Num=305; Nombre="CCleaner"; ID="Piriform.CCleaner"}, @{Num=306; Nombre="PrivaZer"; ID="Goversoft.PrivaZer"},
            @{Num=307; Nombre="Glary Utilities"; ID="Glarysoft.GlaryUtilities"}, @{Num=308; Nombre="Wise Disk Cleaner"; ID="WiseCleaner.WiseDiskCleaner"},
            @{Num=309; Nombre="System Ninja"; ID="SystemNinja.SystemNinja"}, @{Num=310; Nombre="Clean Master"; ID="CleanMaster.CleanMaster"},
            @{Num=311; Nombre="Advanced SystemCare"; ID="IObit.AdvancedSystemCare"}, @{Num=312; Nombre="Ashampoo WinOptimizer"; ID="Ashampoo.WinOptimizer"},
            @{Num=313; Nombre="Auslogics Defrag"; ID="Auslogics.DiskDefrag"}, @{Num=314; Nombre="Defraggler"; ID="Piriform.Defraggler"},
            @{Num=315; Nombre="MyDefrag"; ID="MyDefrag.MyDefrag"}, @{Num=316; Nombre="O&O Defrag"; ID="OODefrag.OODefrag"},
            @{Num=317; Nombre="UltraDefrag"; ID="UltraDefrag.UltraDefrag"}, @{Num=318; Nombre="Windows Disk Cleanup"; ID="Microsoft.DiskCleanup"},
            @{Num=319; Nombre="Storage Sense"; ID="Microsoft.StorageSense"}, @{Num=320; Nombre="Revo Portable"; ID="RevoUninstaller.RevoUninstaller"}
        )}
        "17" = @{ Nombre = "🎨 PERSONALIZACIÓN"; Apps = @(
            @{Num=321; Nombre="f.lux"; ID="f.lux.f.lux"}, @{Num=322; Nombre="Ditto Clipboard"; ID="Ditto.Ditto"},
            @{Num=323; Nombre="CopyQ"; ID="CopyQ.CopyQ"}, @{Num=324; Nombre="Wallpaper Engine"; ID="WallpaperEngine.WallpaperEngine"},
            @{Num=325; Nombre="Lively Wallpaper"; ID="LivelyWallpaper.LivelyWallpaper"}, @{Num=326; Nombre="TranslucentTB"; ID="TranslucentTB.TranslucentTB"},
            @{Num=327; Nombre="WindowBlinds"; ID="Stardock.WindowBlinds"}, @{Num=328; Nombre="Start11"; ID="Stardock.Start11"},
            @{Num=329; Nombre="Fences"; ID="Stardock.Fences"}, @{Num=330; Nombre="Groupy"; ID="Stardock.Groupy"},
            @{Num=331; Nombre="ObjectDock"; ID="Stardock.ObjectDock"}, @{Num=332; Nombre="Rainmeter"; ID="Rainmeter.Rainmeter"},
            @{Num=333; Nombre="RocketDock"; ID="RocketDock.RocketDock"}, @{Num=334; Nombre="Nexus Dock"; ID="Winstep.NexusDock"},
            @{Num=335; Nombre="TaskbarX"; ID="TaskbarX.TaskbarX"}, @{Num=336; Nombre="StartAllBack"; ID="StartAllBack.StartAllBack"},
            @{Num=337; Nombre="Open-Shell"; ID="OpenShell.OpenShell"}, @{Num=338; Nombre="Classic Shell"; ID="ClassicShell.ClassicShell"},
            @{Num=339; Nombre="Winaero Tweaker"; ID="Winaero.WinaeroTweaker"}, @{Num=340; Nombre="Ultimate Windows Tweaker"; ID="UltimateWindowsTweaker.UWT"}
        )}
        "18" = @{ Nombre = "🤖 INTELIGENCIA ARTIFICIAL"; Apps = @(
            @{Num=341; Nombre="LM Studio"; ID="LMStudio.LMStudio"}, @{Num=342; Nombre="Ollama"; ID="Ollama.Ollama"},
            @{Num=343; Nombre="GPT4All"; ID="GPT4All.GPT4All"}, @{Num=344; Nombre="Upscayl"; ID="Upscayl.Upscayl"},
            @{Num=345; Nombre="Continue AI"; ID="Continue.continue"}, @{Num=346; Nombre="Cody AI"; ID="Sourcegraph.cody"},
            @{Num=347; Nombre="TabNine"; ID="TabNine.tabnine"}, @{Num=348; Nombre="Codeium"; ID="Codeium.Codeium"},
            @{Num=349; Nombre="Whisper Desktop"; ID="Const-me.Whisper"}, @{Num=350; Nombre="ChatGPT Desktop"; ID="ChatGPT.ChatGPT"},
            @{Num=351; Nombre="Claude Desktop"; ID="Anthropic.Claude"}, @{Num=352; Nombre="Perplexity AI"; ID="Perplexity.Perplexity"},
            @{Num=353; Nombre="KoboldCP"; ID="KoboldAI.KoboldCP"}, @{Num=354; Nombre="Automatic1111"; ID="AUTOMATIC1111.StableDiffusion"},
            @{Num=355; Nombre="ComfyUI"; ID="ComfyUI.ComfyUI"}, @{Num=356; Nombre="InvokeAI"; ID="InvokeAI.InvokeAI"},
            @{Num=357; Nombre="Fooocus"; ID="Fooocus.Fooocus"}, @{Num=358; Nombre="EasyDiffusion"; ID="EasyDiffusion.EasyDiffusion"},
            @{Num=359; Nombre="TextGen WebUI"; ID="Oobabooga.TextGeneration"}, @{Num=360; Nombre="Jan AI"; ID="Jan.Jan"}
        )}
        "19" = @{ Nombre = "🔐 SEGURIDAD AVANZADA"; Apps = @(
            @{Num=361; Nombre="VeraCrypt"; ID="IDRIX.VeraCrypt"}, @{Num=362; Nombre="KeePassXC"; ID="KeePassXCTeam.KeePassXC"},
            @{Num=363; Nombre="ProtonMail Bridge"; ID="ProtonTechnologies.ProtonMailBridge"}, @{Num=364; Nombre="Sysinternals"; ID="Microsoft.Sysinternals"},
            @{Num=365; Nombre="Process Hacker"; ID="ProcessHacker.ProcessHacker"}, @{Num=366; Nombre="Autoruns"; ID="Microsoft.Autoruns"},
            @{Num=367; Nombre="TCPView"; ID="Microsoft.TCPView"}, @{Num=368; Nombre="Wireshark"; ID="WiresharkFoundation.Wireshark"},
            @{Num=369; Nombre="Nmap"; ID="Nmap.Nmap"}, @{Num=370; Nombre="Burp Suite"; ID="PortSwigger.BurpSuite"},
            @{Num=371; Nombre="Nikto"; ID="Nikto.Nikto"}, @{Num=372; Nombre="SQLmap"; ID="SQLmap.SQLmap"},
            @{Num=373; Nombre="Hydra"; ID="Hydra.Hydra"}, @{Num=374; Nombre="John the Ripper"; ID="JohnTheRipper.John"},
            @{Num=375; Nombre="HashCat"; ID="HashCat.HashCat"}, @{Num=376; Nombre="AirCrack-ng"; ID="AirCrackNG.AirCrackNG"},
            @{Num=377; Nombre="Kismet"; ID="Kismet.Kismet"}, @{Num=378; Nombre="Reaver"; ID="Reaver.Reaver"},
            @{Num=379; Nombre="OpenSSL"; ID="OpenSSL.OpenSSL"}, @{Num=380; Nombre="Metasploit"; ID="Rapid7.Metasploit"}
        )}
        "20" = @{ Nombre = "📊 DATA SCIENCE"; Apps = @(
            @{Num=381; Nombre="Anaconda"; ID="Anaconda.Anaconda3"}, @{Num=382; Nombre="Miniconda"; ID="Anaconda.Miniconda3"},
            @{Num=383; Nombre="R for Windows"; ID="RProject.R"}, @{Num=384; Nombre="RStudio"; ID="RStudio.RStudio"},
            @{Num=385; Nombre="Julia"; ID="JuliaComputing.Julia"}, @{Num=386; Nombre="Tableau Public"; ID="Tableau.TableauPublic"},
            @{Num=387; Nombre="Power BI Desktop"; ID="Microsoft.PowerBIDesktop"}, @{Num=388; Nombre="QGIS"; ID="QGIS.QGIS"},
            @{Num=389; Nombre="Orange"; ID="Orange.Orange"}, @{Num=390; Nombre="KNIME"; ID="KNIME.KNIME"},
            @{Num=391; Nombre="Weka"; ID="Weka.Weka"}, @{Num=392; Nombre="RapidMiner"; ID="RapidMiner.RapidMiner"},
            @{Num=393; Nombre="DataGrip"; ID="JetBrains.DataGrip"}, @{Num=394; Nombre="DBeaver"; ID="DBeaver.DBeaver"},
            @{Num=395; Nombre="HeidiSQL"; ID="HeidiSQL.HeidiSQL"}, @{Num=396; Nombre="MongoDB Compass"; ID="MongoDB.Compass"},
            @{Num=397; Nombre="PostgreSQL"; ID="PostgreSQL.PostgreSQL"}, @{Num=398; Nombre="MySQL Workbench"; ID="Oracle.MySQLWorkbench"},
            @{Num=399; Nombre="Azure Data Studio"; ID="Microsoft.AzureDataStudio"}, @{Num=400; Nombre="DVC"; ID="Iterative.DVC"}
        )}
        "21" = @{ Nombre = "🎬 MEDIA SERVER"; Apps = @(
            @{Num=401; Nombre="Plex Server"; ID="Plex.Plex"}, @{Num=402; Nombre="Jellyfin Server"; ID="Jellyfin.Server"},
            @{Num=403; Nombre="Emby Server"; ID="Emby.Emby"}, @{Num=404; Nombre="Sonarr"; ID="Sonarr.Sonarr"},
            @{Num=405; Nombre="Radarr"; ID="Radarr.Radarr"}, @{Num=406; Nombre="Prowlarr"; ID="Prowlarr.Prowlarr"},
            @{Num=407; Nombre="Overseerr"; ID="Overseerr.Overseerr"}, @{Num=408; Nombre="Tautulli"; ID="Tautulli.Tautulli"},
            @{Num=409; Nombre="Jackett"; ID="Jackett.Jackett"}, @{Num=410; Nombre="Bazarr"; ID="Bazarr.Bazarr"},
            @{Num=411; Nombre="Lidarr"; ID="Lidarr.Lidarr"}, @{Num=412; Nombre="Readarr"; ID="Readarr.Readarr"},
            @{Num=413; Nombre="Mylar3"; ID="Mylar3.Mylar3"}, @{Num=414; Nombre="NZBGet"; ID="NZBGet.NZBGet"},
            @{Num=415; Nombre="SABnzbd"; ID="SABnzbd.SABnzbd"}, @{Num=416; Nombre="qBittorrent"; ID="qBittorrent.qBittorrent"},
            @{Num=417; Nombre="Transmission"; ID="Transmission.Transmission"}, @{Num=418; Nombre="Deluge"; ID="DelugeTeam.Deluge"},
            @{Num=419; Nombre="Tdarr"; ID="Tdarr.Tdarr"}, @{Num=420; Nombre="FileFlows"; ID="FileFlows.FileFlows"}
        )}
        "22" = @{ Nombre = "🛠️ HERRAMIENTAS SISTEMA"; Apps = @(
            @{Num=421; Nombre="Process Lasso"; ID="Bitsum.ProcessLasso"}, @{Num=422; Nombre="Macrium Reflect"; ID="Macrium.MacriumReflect"},
            @{Num=423; Nombre="Veeam Agent"; ID="Veeam.VeeamAgent"}, @{Num=424; Nombre="Rufus"; ID="Rufus.Rufus"},
            @{Num=425; Nombre="Ventoy"; ID="Ventoy.Ventoy"}, @{Num=426; Nombre="BalenaEtcher"; ID="Balena.Etcher"},
            @{Num=427; Nombre="Clonezilla"; ID="Clonezilla.Clonezilla"}, @{Num=428; Nombre="Hiren BootCD"; ID="HirensBootCD.HirensBootCD"},
            @{Num=429; Nombre="Medicat USB"; ID="Medicat.MedicatUSB"}, @{Num=430; Nombre="GParted Live"; ID="GParted.GPartedLive"},
            @{Num=431; Nombre="HDDScan"; ID="HDDScan.HDDScan"}, @{Num=432; Nombre="MemTest86"; ID="PassMark.MemTest86"},
            @{Num=433; Nombre="Prime95"; ID="Prime95.Prime95"}, @{Num=434; Nombre="FurMark"; ID="FurMark.FurMark"},
            @{Num=435; Nombre="Cinebench"; ID="Maxon.Cinebench"}, @{Num=436; Nombre="Geekbench"; ID="PrimateLabs.Geekbench"},
            @{Num=437; Nombre="3DMark"; ID="UL.3DMark"}, @{Num=438; Nombre="PassMark"; ID="PassMark.PassMark"},
            @{Num=439; Nombre="OCCT"; ID="OCCT.OCCT"}, @{Num=440; Nombre="HWMonitor"; ID="CPUID.HWMonitor"}
        )}
    }

    function Show-CategoryApps($CatId) {
        $cat = $categorias[$CatId]
        Clear-Host; Show-MainTitle
        Write-Host "`n 📂 $($cat.Nombre) - $($cat.Apps.Count) aplicaciones" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        
        $cols = 2
        for ($i = 0; $i -lt $cat.Apps.Count; $i += $cols) {
            $row = "   "
            for ($j = 0; $j -lt $cols; $j++) {
                if (($i + $j) -lt $cat.Apps.Count) {
                    $app = $cat.Apps[$i + $j]
                    $nameStr = if ($app.Nombre.Length -gt 28) { $app.Nombre.Substring(0, 25) + "..." } else { $app.Nombre }
                    $row += "[$($app.Num.ToString().PadLeft(3))] $($nameStr.PadRight(33))"
                }
            }
            Write-Host $row -ForegroundColor White
        }
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 💡 Ingresa números separados por coma (ej: 1,3,5), rango (1-5), o 'TODO'" -ForegroundColor $COLOR_ALERT
        Write-Host " ❌ [X] Volver  |  🔍 [B] Buscar en todas las categorías" -ForegroundColor $COLOR_DANGER
        
        $inputVal = Read-Host "`n > SELECCIONE"
        if ($inputVal.ToUpper() -eq "X") { return $null }
        if ($inputVal.ToUpper() -eq "B") { return "BUSCAR" }
        if ($inputVal.ToUpper() -eq "TODO") { return ($cat.Apps | ForEach-Object { $_.Num.ToString() }) }
        
        $selection = @()
        foreach ($part in ($inputVal -split ',')) {
            $part = $part.Trim()
            if ($part -match '^(\d+)-(\d+)$') {
                for ($k = [int]$matches[1]; $k -le [int]$matches[2]; $k++) { $selection += $k.ToString() }
            } elseif ($part -match '^\d+$') {
                $selection += $part
            }
        }
        return ($selection | Where-Object { $_ -in ($cat.Apps | ForEach-Object { $_.Num.ToString() }) })
    }

    function Search-AllApps($term) {
        Clear-Host; Show-MainTitle
        Write-Host "`n 🔍 RESULTADOS PARA: '$term'" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        $results = @()
        foreach ($c in $categorias.Values) {
            foreach ($a in $c.Apps) {
                if ($a.Nombre -like "*$term*") { $results += $a }
            }
        }
        if ($results.Count -eq 0) {
            Write-Host " ❌ No se encontraron aplicaciones." -ForegroundColor Red
            Read-Host "ENTER para continuar..."; return $null
        }
        foreach ($res in $results) {
            Write-Host "   [$($res.Num.ToString().PadLeft(3))] $($res.Nombre)" -ForegroundColor White
        }
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        $inputVal = Read-Host "`n > Ingrese números a instalar separados por coma (o X para cancelar)"
        if ($inputVal.ToUpper() -eq "X") { return $null }
        return ($inputVal -split ',' | ForEach-Object { $_.Trim() })
    }

    while ($true) {
        Clear-Host; Show-MainTitle
        Write-Host "`n 📦 KIT POST FORMAT (440 APPS DISPONIBLES)" -ForegroundColor $COLOR_PRIMARY
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        
        $catList = $categorias.Keys | Sort-Object { [int]$_ }
        for ($i = 0; $i -lt $catList.Count; $i += 2) {
            $c1 = $catList[$i]
            $line = " [$($c1.PadLeft(2))] $($categorias[$c1].Nombre.PadRight(30))"
            if (($i + 1) -lt $catList.Count) {
                $c2 = $catList[$i + 1]
                $line += " [$($c2.PadLeft(2))] $($categorias[$c2].Nombre.PadRight(30))"
            }
            Write-Host $line -ForegroundColor $COLOR_MENU
        }

        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🎮 [P] PERFILES PREDEFINIDOS (Gaming, Dev, IA, Básicos, etc.)" -ForegroundColor Cyan
        Write-Host " 🔄 [U] ACTUALIZAR SOFTWARE  |  🧹 [0] LIMPIAR BLOATWARE NATIVO" -ForegroundColor Yellow
        Write-Host " 🔍 [B] BUSCAR APP (Nombre)  |  ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $opt = (Read-Host "`n > SELECCIONE CATEGORÍA (1-22), P, U, 0, B, X").Trim().ToUpper()
        if ($opt -eq "X") { break }

        $selection = @()
        if ($opt -eq "0") {
            Write-Host "`n [!] Eliminando aplicaciones basura de Windows..." -ForegroundColor Yellow
            @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*") | ForEach-Object {
                Get-AppxPackage $_ -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            }
            Write-Host " ✅ Limpieza de bloatware finalizada." -ForegroundColor Green
            Read-Host "ENTER"; continue
        } elseif ($opt -eq "U") {
            Write-Host "`n 🔄 Actualizando todas las aplicaciones vía Winget..." -ForegroundColor Yellow
            winget upgrade --all --accept-package-agreements --accept-source-agreements
            Read-Host "ENTER"; continue
        } elseif ($opt -eq "B") {
            $term = Read-Host "`n 🔍 Ingrese nombre de la aplicación"
            $selection = Search-AllApps $term
        } elseif ($opt -eq "P") {
            Clear-Host; Show-MainTitle
            Write-Host "`n 🎮 PERFILES DE INSTALACIÓN RÁPIDA" -ForegroundColor Cyan
            Write-Host " [1] Gaming  | [2] Básico  | [3] IA/ML  | [4] Seguridad | [5] Data Science"
            Write-Host " [6] Media   | [7] Dev     | [8] Office | [9] Redes     | [10] Personalización"
            $pOpt = Read-Host "`n > Seleccione perfil (1-10)"
            $selection = switch ($pOpt) {
                "1" { "141","21","99","41","142" }
                "2" { "1","41","87","127","25","27" }
                "3" { "341","342","345","348","343" }
                "4" { "361","362","201","121" }
                "5" { "381","384","78","387" }
                "6" { "401","404","405","402","268" }
                "7" { "61","62","64","66","67","75" }
                "8" { "101","106","103","104" }
                "9" { "121","122","127","129","126" }
                "10"{ "321","322","324","304" }
            }
        } elseif ($categorias.ContainsKey($opt)) {
            $selection = Show-CategoryApps $opt
            if ($selection -eq "BUSCAR") {
                $term = Read-Host "`n 🔍 Ingrese nombre de la aplicación"
                $selection = Search-AllApps $term
            }
        }

        if ($selection -and $selection.Count -gt 0) {
            Write-Host "`n =================================================================" -ForegroundColor Cyan
            Write-Host " 🚀 PROCESANDO INSTALACIONES SELECCIONADAS ($($selection.Count) apps)" -ForegroundColor Cyan
            Write-Host " =================================================================" -ForegroundColor Cyan
            foreach ($num in $selection) {
                foreach ($c in $categorias.Values) {
                    $found = $c.Apps | Where-Object { $_.Num -eq [int]$num }
                    if ($found) {
                        Invoke-SmartInstall $found.ID $found.Nombre | Out-Null
                        break
                    }
                }
            }
            Write-Host "`n ✅ Todas las instalaciones han finalizado." -ForegroundColor Green
            Read-Host "ENTER para volver al menú...";
        }
    }
}

function Repair-Winget {
    Write-Host "`n [+] Restableciendo orígenes de Winget..." -ForegroundColor Yellow
    winget source reset --force
    winget source update
    Write-Host " ✅ Orígenes de Winget actualizados y reparados." -ForegroundColor Green
    Pause-Enter
}

function Repair-Chocolatey {
    Write-Host "`n [+] Verificando / reinstalando Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    try {
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host " ✅ Chocolatey reparado y operativo." -ForegroundColor Green
    } catch {
        Write-Host " ❌ Error al contactar repositorio Chocolatey." -ForegroundColor Red
    }
    Pause-Enter
}

function Invoke-WingetMenu {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 📦 GESTIÓN AVANZADA DE PAQUETES (WINGET / CHOCO)" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🔄 [A] ACTUALIZAR TODO           - Actualiza todas las apps instaladas (Winget)"
        Write-Host " 🔍 [B] BUSCAR PAQUETE EN LÍNEA   - Busca programas en los repositorios oficiales"
        Write-Host " 🛠️ [C] REPARAR MOTOR WINGET      - Restablece las fuentes y caché de fuentes"
        Write-Host " 🍫 [D] REPARAR / INSTALAR CHOCO  - Restaura el entorno de Chocolatey"
        Write-Host " 📋 [E] LISTAR PAQUETES ACTIVOS   - Muestra programas administrables por consola"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $opt = Read-MenuOption "`n > SELECCIONE" -Valid @("A","B","C","D","E","X")
        if ($opt -eq "X") { break }

        switch ($opt) {
            "A" { winget upgrade --all --accept-package-agreements --accept-source-agreements; Pause-Enter }
            "B" {
                $q = Read-Host "`n Nombre del programa a buscar"
                if ($q) { winget search $q }
                Pause-Enter
            }
            "C" { Repair-Winget }
            "D" { Repair-Chocolatey }
            "E" { winget list | Out-GridView -Title "Aplicaciones Administrables"; Pause-Enter }
        }
    }
}

