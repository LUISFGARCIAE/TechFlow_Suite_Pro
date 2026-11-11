package apps

import (
	"archive/zip"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"techflow/pkg/core"
)

type AppItem struct {
	Num   int
	Name  string
	ID    string
	Choco string
}

type Category struct {
	ID   string
	Name string
	Apps []AppItem
}

type DirectApp struct {
	URL      string
	Args     string
	FileName string
	IsZip    bool
	IsManual bool
}

var knownApps = map[string]DirectApp{
	"mipony":          {URL: "https://www.mipony.net/downloads/MiPony_Installer.exe", Args: "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART", FileName: "MiPony_Installer.exe"},
	"jdownloader":     {URL: "http://installer.jdownloader.org/JD2Setup.exe", Args: "/S", FileName: "JD2Setup.exe"},
	"idm":             {URL: "https://mirror2.internetdownloadmanager.com/idman642build25.exe", Args: "/silent /norestart", FileName: "idman.exe"},
	"brave":           {URL: "https://referrals.brave.com/latest/BraveBrowserSetup.exe", Args: "/silent /install", FileName: "BraveSetup.exe"},
	"rufus":           {URL: "https://github.com/pbatard/rufus/releases/download/v4.6/rufus-4.6.exe", Args: "", FileName: "rufus.exe"},
	"ventoy":          {URL: "https://github.com/ventoy/Ventoy/releases/download/v1.0.99/ventoy-1.0.99-windows.zip", Args: "", FileName: "ventoy.zip", IsZip: true},
	"wireshark":       {URL: "https://www.wireshark.org/download/Wireshark-win64-4.2.6.exe", Args: "/S", FileName: "Wireshark.exe"},
	"ccleaner":        {URL: "https://download.ccleaner.com/ccsetup661.exe", Args: "/S", FileName: "ccsetup.exe"},
	"bleachbit":       {URL: "https://download.bleachbit.org/BleachBit-4.6.0-setup.exe", Args: "/S", FileName: "BleachBit.exe"},
	"crystaldiskinfo": {URL: "https://download946.mediafire.com/kot16wrlgk6gUv4J9-Qe83nbmCsWkws0z2rwz0zTWZulEw3GO9_znwBR8Qhy4EvTqh-KZyj2jI0gbFJRCkYorI0Jpn_tRuEUPQX_0BhpcNdAuECjrbhuEcmaWq66gX8rNNDKPTe0_06pUpVovt94xTl-TZrCLEKH245Pi-8l-mUk2g/uhmhcl9whgu3f83/CrystalDiskInfo9_8_0.zip", Args: "", FileName: "CrystalDiskInfo.zip", IsZip: true},
	"vlc":             {URL: "https://mirror.fcix.net/videolan-ftp/vlc/3.0.23/win32/vlc-3.0.23-win32.exe", Args: "/S", FileName: "VLC.exe"},
	"davinci":         {URL: "https://www.blackmagicdesign.com/products/davinciresolve", Args: "", FileName: "DaVinci_Resolve.exe", IsManual: true},
}

var categories = []Category{
	{ID: "1", Name: "🌐 NAVEGADORES", Apps: []AppItem{
		{Num: 1, Name: "Google Chrome", ID: "Google.Chrome", Choco: "googlechrome"},
		{Num: 2, Name: "Mozilla Firefox", ID: "Mozilla.Firefox", Choco: "firefox"},
		{Num: 3, Name: "Brave Browser", ID: "Brave.Brave", Choco: "brave"},
		{Num: 4, Name: "Microsoft Edge", ID: "Microsoft.Edge", Choco: "microsoft-edge"},
		{Num: 5, Name: "Opera", ID: "Opera.Opera", Choco: "opera"},
		{Num: 6, Name: "Vivaldi", ID: "Vivaldi.Vivaldi", Choco: "vivaldi"},
		{Num: 7, Name: "Tor Browser", ID: "TorProject.TorBrowser", Choco: "tor-browser"},
		{Num: 8, Name: "Opera GX", ID: "Opera.OperaGX", Choco: "opera-gx"},
	}},
	{ID: "2", Name: "💬 COMUNICACIÓN", Apps: []AppItem{
		{Num: 21, Name: "Discord", ID: "Discord.Discord", Choco: "discord"},
		{Num: 22, Name: "Telegram Desktop", ID: "Telegram.TelegramDesktop", Choco: "telegram"},
		{Num: 23, Name: "Signal Desktop", ID: "OpenWhisperSystems.Signal", Choco: "signal"},
		{Num: 24, Name: "Zoom", ID: "Zoom.Zoom", Choco: "zoom"},
		{Num: 25, Name: "Microsoft Teams", ID: "Microsoft.Teams", Choco: "teams"},
		{Num: 26, Name: "Slack", ID: "SlackTechnologies.Slack", Choco: "slack"},
		{Num: 27, Name: "WhatsApp Desktop", ID: "WhatsApp.WhatsApp", Choco: "whatsapp"},
		{Num: 28, Name: "Thunderbird", ID: "Mozilla.Thunderbird", Choco: "thunderbird"},
	}},
	{ID: "3", Name: "🛠️ UTILIDADES", Apps: []AppItem{
		{Num: 41, Name: "7-Zip", ID: "7zip.7zip", Choco: "7zip"},
		{Num: 42, Name: "WinRAR", ID: "RARLab.WinRAR", Choco: "winrar"},
		{Num: 43, Name: "PowerToys", ID: "Microsoft.PowerToys", Choco: "powertoys"},
		{Num: 44, Name: "Everything", ID: "voidtools.Everything", Choco: "everything"},
		{Num: 45, Name: "BleachBit", ID: "BleachBit.BleachBit", Choco: "bleachbit"},
		{Num: 46, Name: "Revo Uninstaller", ID: "RevoUninstaller.RevoUninstaller", Choco: "revo-uninstaller"},
		{Num: 47, Name: "Bitwarden", ID: "Bitwarden.Bitwarden", Choco: "bitwarden"},
		{Num: 48, Name: "Malwarebytes", ID: "Malwarebytes.Malwarebytes", Choco: "malwarebytes"},
		{Num: 49, Name: "CPU-Z", ID: "CPUID.CPU-Z", Choco: "cpuz"},
		{Num: 50, Name: "GPU-Z", ID: "TechPowerUp.GPU-Z", Choco: "gpuz"},
		{Num: 51, Name: "HWMonitor", ID: "CPUID.HWMonitor", Choco: "hwmonitor"},
		{Num: 52, Name: "HWiNFO", ID: "REALiX.HWiNFO", Choco: "hwinfo"},
		{Num: 53, Name: "Notepad++", ID: "Notepad++.Notepad++", Choco: "notepadplusplus"},
		{Num: 54, Name: "WizTree", ID: "WizTree.WizTree", Choco: "wiztree"},
	}},
	{ID:  "4", Name: "💻 DESARROLLO", Apps: []AppItem{
		{Num: 61, Name: "VS Code", ID: "Microsoft.VisualStudioCode", Choco: "vscode"},
		{Num: 62, Name: "Git", ID: "Git.Git", Choco: "git"},
		{Num: 63, Name: "GitHub Desktop", ID: "GitHub.GitHubDesktop", Choco: "github-desktop"},
		{Num: 64, Name: "Docker Desktop", ID: "Docker.DockerDesktop", Choco: "docker-desktop"},
		{Num: 65, Name: "Node.js", ID: "OpenJS.NodeJS", Choco: "nodejs"},
		{Num: 66, Name: "Python 3", ID: "Python.Python.3", Choco: "python"},
		{Num: 67, Name: "PuTTY", ID: "PuTTY.PuTTY", Choco: "putty"},
		{Num: 68, Name: "FileZilla Client", ID: "FileZilla.Client", Choco: "filezilla"},
		{Num: 69, Name: "DBeaver", ID: "DBeaver.DBeaver", Choco: "dbeaver"},
	}},
	{ID: "5", Name: "🎬 MULTIMEDIA", Apps: []AppItem{
		{Num: 81, Name: "VLC Media Player", ID: "VideoLAN.VLC", Choco: "vlc"},
		{Num: 82, Name: "GIMP", ID: "GIMP.GIMP", Choco: "gimp"},
		{Num: 83, Name: "Audacity", ID: "Audacity.Audacity", Choco: "audacity"},
		{Num: 84, Name: "Blender", ID: "BlenderFoundation.Blender", Choco: "blender"},
		{Num: 85, Name: "HandBrake", ID: "HandBrake.HandBrake", Choco: "handbrake"},
		{Num: 86, Name: "OBS Studio", ID: "OBSProject.OBSStudio", Choco: "obs-studio"},
		{Num: 87, Name: "Spotify", ID: "Spotify.Spotify", Choco: "spotify"},
		{Num: 88, Name: "K-Lite Codec Pack", ID: "CodecGuide.K-LiteCodecPack.Basic", Choco: "k-litecodecpackbasic"},
	}},
	{ID: "6", Name: "📄 OFIMÁTICA", Apps: []AppItem{
		{Num: 101, Name: "LibreOffice", ID: "TheDocumentFoundation.LibreOffice", Choco: "libreoffice"},
		{Num: 102, Name: "Adobe Acrobat Reader", ID: "Adobe.Acrobat.Reader.64-bit", Choco: "adobereader"},
		{Num: 103, Name: "Notion", ID: "Notion.Notion", Choco: "notion"},
		{Num: 104, Name: "Obsidian", ID: "Obsidian.Obsidian", Choco: "obsidian"},
		{Num: 105, Name: "Foxit PDF Reader", ID: "Foxit.FoxitReader", Choco: "foxitreader"},
		{Num: 106, Name: "SumatraPDF", ID: "SumatraPDF.SumatraPDF", Choco: "sumatrapdf"},
	}},
	{ID: "7", Name: "🌐 REDES Y TERMINAL", Apps: []AppItem{
		{Num: 121, Name: "Wireshark", ID: "WiresharkFoundation.Wireshark", Choco: "wireshark"},
		{Num: 122, Name: "Advanced IP Scanner", ID: "Famatech.AdvancedIPScanner", Choco: "advanced-ip-scanner"},
		{Num: 123, Name: "Windows Terminal", ID: "Microsoft.WindowsTerminal", Choco: "microsoft-windows-terminal"},
		{Num: 124, Name: "AnyDesk", ID: "AnyDesk.AnyDesk", Choco: "anydesk"},
		{Num: 125, Name: "RustDesk", ID: "RustDesk.RustDesk", Choco: "rustdesk"},
		{Num: 126, Name: "TeamViewer", ID: "TeamViewer.TeamViewer", Choco: "teamviewer"},
	}},
	{ID: "8", Name: "🎮 JUEGOS", Apps: []AppItem{
		{Num: 141, Name: "Steam", ID: "Valve.Steam", Choco: "steam"},
		{Num: 142, Name: "Epic Games Launcher", ID: "EpicGames.EpicGamesLauncher", Choco: "epicgameslauncher"},
		{Num: 143, Name: "EA Desktop", ID: "ElectronicArts.EADesktop", Choco: "ea-app"},
		{Num: 144, Name: "GOG Galaxy", ID: "GOG.Galaxy", Choco: "goggalaxy"},
		{Num: 145, Name: "Parsec", ID: "Parsec.Parsec", Choco: "parsec"},
	}},
	{ID: "9", Name: "🖥️ VIRTUALIZACIÓN", Apps: []AppItem{
		{Num: 161, Name: "VirtualBox", ID: "Oracle.VirtualBox", Choco: "virtualbox"},
		{Num: 162, Name: "VMware Workstation Player", ID: "VMware.WorkstationPlayer", Choco: "vmware-workstation-player"},
		{Num: 163, Name: "Raspberry Pi Imager", ID: "RaspberryPiFoundation.RaspberryPiImager", Choco: "raspberry-pi-imager"},
		{Num: 164, Name: "WSL", ID: "Microsoft.WSL", Choco: "wsl"},
	}},
	{ID: "10", Name: "💾 RESPALDOS", Apps: []AppItem{
		{Num: 181, Name: "Duplicati", ID: "Duplicati.Duplicati", Choco: "duplicati"},
		{Num: 182, Name: "Nextcloud", ID: "Nextcloud.NextcloudDesktop", Choco: "nextcloud-client"},
		{Num: 183, Name: "Google Drive", ID: "Google.Drive", Choco: "googledrive"},
		{Num: 184, Name: "Syncthing", ID: "SyncThing.SyncThing", Choco: "syncthing"},
	}},
	{ID: "11", Name: "🔒 VPN", Apps: []AppItem{
		{Num: 201, Name: "ProtonVPN", ID: "ProtonTechnologies.ProtonVPN", Choco: "protonvpn"},
		{Num: 202, Name: "Tailscale", ID: "Tailscale.Tailscale", Choco: "tailscale"},
		{Num: 203, Name: "ZeroTier One", ID: "ZeroTier.ZeroTier", Choco: "zerotier-one"},
		{Num: 204, Name: "WireGuard", ID: "WireGuard.WireGuard", Choco: "wireguard"},
	}},
	{ID: "12", Name: "📊 MONITOR", Apps: []AppItem{
		{Num: 221, Name: "Core Temp", ID: "CoreTemp.CoreTemp", Choco: "coretemp"},
		{Num: 222, Name: "CrystalDiskInfo", ID: "CrystalDiskInfo.CrystalDiskInfo", Choco: "crystaldiskinfo"},
		{Num: 223, Name: "CrystalDiskMark", ID: "CrystalDiskMark.CrystalDiskMark", Choco: "crystaldiskmark"},
		{Num: 224, Name: "Process Explorer", ID: "Microsoft.Sysinternals.ProcessExplorer", Choco: "procexp"},
		{Num: 225, Name: "Autoruns", ID: "Microsoft.Sysinternals.Autoruns", Choco: "autoruns"},
	}},
	{ID: "13", Name: "📝 NOTAS", Apps: []AppItem{
		{Num: 241, Name: "Simplenote", ID: "Simplenote.Simplenote", Choco: "simplenote"},
		{Num: 242, Name: "Joplin", ID: "Joplin.Joplin", Choco: "joplin"},
		{Num: 243, Name: "Logseq", ID: "Logseq.Logseq", Choco: "logseq"},
	}},
	{ID: "14", Name: "⚡ UTILIDADES AVANZADAS", Apps: []AppItem{
		{Num: 261, Name: "Bulk Rename Utility", ID: "BulkRenameUtility.BulkRenameUtility", Choco: "bulkrenameutility"},
		{Num: 262, Name: "AutoHotkey", ID: "AutoHotkey.AutoHotkey", Choco: "autohotkey"},
		{Num: 263, Name: "Fastfetch", ID: "Fastfetch.Fastfetch", Choco: "fastfetch"},
		{Num: 264, Name: "qBittorrent", ID: "qBittorrent.qBittorrent", Choco: "qbittorrent"},
	}},
	{ID: "15", Name: "📦 CLIENTES", Apps: []AppItem{
		{Num: 281, Name: "LocalSend", ID: "LocalSend.LocalSend", Choco: "localsend"},
		{Num: 282, Name: "Motrix", ID: "Motrix.Motrix", Choco: "motrix"},
		{Num: 283, Name: "KDE Connect", ID: "KDE.KDEConnect", Choco: "kdeconnect-kde"},
	}},
	{ID: "16", Name: "🧹 LIMPIEZA", Apps: []AppItem{
		{Num: 301, Name: "TreeSize Free", ID: "JAMSoftware.TreeSize.Free", Choco: "treesizefree"},
		{Num: 302, Name: "BleachBit", ID: "BleachBit.BleachBit", Choco: "bleachbit"},
		{Num: 303, Name: "Wise Disk Cleaner", ID: "WiseCleaner.WiseDiskCleaner", Choco: "wise-disk-cleaner"},
	}},
	{ID: "17", Name: "🎨 PERSONALIZACIÓN", Apps: []AppItem{
		{Num: 321, Name: "f.lux", ID: "f.lux.f.lux", Choco: "flux"},
		{Num: 322, Name: "Ditto", ID: "Ditto.Ditto", Choco: "ditto"},
		{Num: 323, Name: "TranslucentTB", ID: "TranslucentTB.TranslucentTB", Choco: "translucenttb"},
		{Num: 324, Name: "Rainmeter", ID: "Rainmeter.Rainmeter", Choco: "rainmeter"},
	}},
	{ID: "18", Name: "🤖 INTELIGENCIA ARTIFICIAL", Apps: []AppItem{
		{Num: 341, Name: "LM Studio", ID: "LMStudio.LMStudio", Choco: "lmstudio"},
		{Num: 342, Name: "Ollama", ID: "Ollama.Ollama", Choco: "ollama"},
		{Num: 343, Name: "GPT4All", ID: "Nomic.GPT4All", Choco: "gpt4all"},
		{Num: 344, Name: "Upscayl", ID: "Upscayl.Upscayl", Choco: "upscayl"},
	}},
	{ID: "19", Name: "🔐 SEGURIDAD AVANZADA", Apps: []AppItem{
		{Num: 361, Name: "VeraCrypt", ID: "IDRIX.VeraCrypt", Choco: "veracrypt"},
		{Num: 362, Name: "KeePassXC", ID: "KeePassXCTeam.KeePassXC", Choco: "keepassxc"},
		{Num: 363, Name: "Nmap", ID: "Insecure.Nmap", Choco: "nmap"},
	}},
	{ID: "20", Name: "📊 DATA SCIENCE", Apps: []AppItem{
		{Num: 381, Name: "Anaconda", ID: "Anaconda.Anaconda3", Choco: "anaconda3"},
		{Num: 382, Name: "R for Windows", ID: "RProject.R", Choco: "r.project"},
		{Num: 383, Name: "Power BI Desktop", ID: "Microsoft.PowerBIDesktop", Choco: "powerbi"},
	}},
	{ID: "21", Name: "🎬 MEDIA SERVER", Apps: []AppItem{
		{Num: 401, Name: "Plex Media Server", ID: "Plex.PlexMediaServer", Choco: "plexmediaserver"},
		{Num: 402, Name: "Jellyfin Server", ID: "Jellyfin.Server", Choco: "jellyfin"},
	}},
	{ID: "22", Name: "🛠️ HERRAMIENTAS SISTEMA", Apps: []AppItem{
		{Num: 421, Name: "Rufus", ID: "Rufus.Rufus", Choco: "rufus"},
		{Num: 422, Name: "BalenaEtcher", ID: "Balena.Etcher", Choco: "etcher"},
		{Num: 423, Name: "Process Lasso", ID: "Bitsum.ProcessLasso", Choco: "processlasso"},
		{Num: 424, Name: "Cinebench", ID: "Maxon.Cinebench", Choco: "cinebench"},
	}},
}

func InvokeSmartInstall(appID string, appName string, chocoID string) bool {
	fmt.Printf("\n \033[36m[!] INSTALANDO: %s...\033[0m\n", appName)
	fmt.Println(" \033[32m[+] Intentando con winget...\033[0m")

	cmdWinget := exec.Command("winget", "install", "--id", appID, "--exact", "--accept-package-agreements", "--accept-source-agreements", "--silent")
	cmdWinget.Stdout = os.Stdout
	cmdWinget.Stderr = os.Stderr
	if err := cmdWinget.Run(); err == nil {
		fmt.Printf(" \033[32m[✔] %s instalado correctamente con Winget.\033[0m\n", appName)
		return true
	}

	if chocoID != "" {
		fmt.Printf(" \033[33m[+] Intentando con Chocolatey: %s...\033[0m\n", chocoID)
		cmdChoco := exec.Command("choco", "install", chocoID, "-y", "--no-progress")
		cmdChoco.Stdout = os.Stdout
		cmdChoco.Stderr = os.Stderr
		if err := cmdChoco.Run(); err == nil {
			fmt.Printf(" \033[32m[✔] %s instalado correctamente con Chocolatey.\033[0m\n", appName)
			return true
		}
	}

	fmt.Printf(" \033[31m[✘] Fallo la instalacion de %s.\033[0m\n", appName)
	return false
}

func downloadFile(url, dest string) error {
	out, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer out.Close()

	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("error HTTP: %d", resp.StatusCode)
	}

	_, err = io.Copy(out, resp.Body)
	return err
}

func unzipArchive(src, dest string) error {
	r, err := zip.OpenReader(src)
	if err != nil {
		return err
	}
	defer r.Close()

	_ = os.MkdirAll(dest, 0755)
	for _, f := range r.File {
		fpath := filepath.Join(dest, f.Name)
		if f.FileInfo().IsDir() {
			_ = os.MkdirAll(fpath, f.Mode())
			continue
		}
		if err := os.MkdirAll(filepath.Dir(fpath), 0755); err != nil {
			return err
		}
		outFile, err := os.OpenFile(fpath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
		if err != nil {
			return err
		}
		rc, err := f.Open()
		if err != nil {
			outFile.Close()
			return err
		}
		_, err = io.Copy(outFile, rc)
		outFile.Close()
		rc.Close()
		if err != nil {
			return err
		}
	}
	return nil
}

func installAutoApp(name string) {
	key := strings.ToLower(strings.TrimSpace(name))
	appData, exists := knownApps[key]
	if !exists {
		fmt.Printf("\n \033[31m[✘] No se encontro '%s' en la base de datos automatica.\033[0m\n", name)
		fmt.Println(" Programas disponibles:")
		for k := range knownApps {
			fmt.Printf("   • %s\n", k)
		}
		core.PauseEnter("")
		return
	}

	if appData.IsManual {
		fmt.Printf("\n \033[33m[!] Requiere descarga manual desde: %s\033[0m\n", appData.URL)
		_ = exec.Command("cmd", "/c", "start", appData.URL).Start()
		core.PauseEnter("ENTER tras descargar")
		return
	}

	tmpDest := filepath.Join(os.Getenv("TEMP"), appData.FileName)
	fmt.Printf("\n\033[33m[+] Descargando instalador desde: %s...\033[0m\n", appData.URL)
	if err := downloadFile(appData.URL, tmpDest); err != nil {
		fmt.Printf(" \033[31m[✘] Error al descargar: %v\033[0m\n", err)
		core.PauseEnter("")
		return
	}

	if appData.IsZip {
		extDir := filepath.Join(os.Getenv("TEMP"), key+"_extraido")
		_ = os.MkdirAll(extDir, 0755)
		fmt.Println(" \033[32m[+] Extrayendo paquete ZIP...\033[0m")
		_ = unzipArchive(tmpDest, extDir)
		_ = exec.Command("explorer.exe", extDir).Start()
		fmt.Printf(" \033[32m[✔] Extraido en: %s\033[0m\n", extDir)
		core.PauseEnter("")
		return
	}

	fmt.Println(" \033[32m[+] Ejecutando instalacion silenciosa...\033[0m")
	var cmd *exec.Cmd
	if appData.Args != "" {
		args := strings.Fields(appData.Args)
		cmd = exec.Command(tmpDest, args...)
	} else {
		cmd = exec.Command(tmpDest)
	}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	_ = cmd.Run()
	_ = os.Remove(tmpDest)
	fmt.Println(" \033[32m[✔] Proceso de instalacion finalizado.\033[0m")
	core.PauseEnter("")
}

func invokeUninstallMenu() {
	for {
		core.ShowBanner()
		fmt.Println("\n \033[31m🗑️ DESINSTALACIÓN DE PROGRAMAS\033[0m")
		fmt.Println(" -----------------------------------------------------------------------------")
		fmt.Println(" 🖥️ [1] PANEL DE CONTROL (appwiz.cpl) - Administrador nativo de Windows")
		fmt.Println(" ⚡ [2] WINGET UNINSTALL             - Desinstalacion directa por comando")
		fmt.Println(" 🔧 [3] REVO UNINSTALLER            - Descargar / Abrir Revo")
		fmt.Println(" 🧹 [4] BULK CRAP UNINSTALLER (BCU) - Descargar / Abrir BCUninstaller")
		fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
		fmt.Println(" \033[31m-------------------\033[0m")
		fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

		opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"1", "2", "3", "4", "X"}, "")
		if opt == "X" {
			break
		}

		switch opt {
		case "1":
			_ = exec.Command("control", "appwiz.cpl").Start()
			core.PauseEnter("ENTER tras cerrar Panel de Control")
		case "2":
			core.ShowBanner()
			fmt.Println("\n\033[33m[+] Lista de programas detectados por Winget:\033[0m")
			cmdList := exec.Command("winget", "list")
			cmdList.Stdout = os.Stdout
			cmdList.Stderr = os.Stderr
			_ = cmdList.Run()

			name := core.ReadMenuOption("\n Escriba el nombre o ID exacto del programa a desinstalar:", nil, "")
			if name != "" {
				fmt.Printf("\n\033[33m[+] Desinstalando %s...\033[0m\n", name)
				cmd := exec.Command("winget", "uninstall", name, "--silent")
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				_ = cmd.Run()
				fmt.Println(" \033[32m[✔] Proceso de desinstalacion completado.\033[0m")
			}
			core.PauseEnter("")
		case "3":
			if _, err := exec.LookPath("revo"); err != nil {
				InvokeSmartInstall("RevoUninstaller.RevoUninstaller", "Revo Uninstaller", "revo-uninstaller")
			}
			_ = exec.Command("revo").Start()
			core.PauseEnter("ENTER tras cerrar Revo")
		case "4":
			if _, err := exec.LookPath("bcuninstaller"); err != nil {
				InvokeSmartInstall("Klocman.BulkCrapUninstaller", "Bulk Crap Uninstaller", "bulk-crap-uninstaller")
			}
			_ = exec.Command("bcuninstaller").Start()
			core.PauseEnter("ENTER tras cerrar BCUninstaller")
		}
	}
}

func showCategoryApps(cat Category) {
	core.ShowBanner()
	fmt.Printf("\n \033[36m📂 %s (%d aplicaciones)\033[0m\n", cat.Name, len(cat.Apps))
	fmt.Println(" ═══════════════════════════════════════════════════════════════════")

	for i := 0; i < len(cat.Apps); i += 2 {
		line := fmt.Sprintf("   [%3d] %-28s", cat.Apps[i].Num, cat.Apps[i].Name)
		if i+1 < len(cat.Apps) {
			line += fmt.Sprintf("   [%3d] %-28s", cat.Apps[i+1].Num, cat.Apps[i+1].Name)
		}
		fmt.Println(line)
	}

	fmt.Println("\n ═══════════════════════════════════════════════════════════════════")
	fmt.Println(" \033[33m💡 Escribe el numero de la app, 'TODO' para todas, o 'X' para volver\033[0m")

	input := core.ReadMenuOption("\n > SELECCIONE:", nil, "")
	if strings.ToUpper(input) == "X" || input == "" {
		return
	}

	if strings.ToUpper(input) == "TODO" {
		for _, app := range cat.Apps {
			InvokeSmartInstall(app.ID, app.Name, app.Choco)
		}
		core.PauseEnter("")
		return
	}

	num, err := strconv.Atoi(input)
	if err == nil {
		for _, app := range cat.Apps {
			if app.Num == num {
				InvokeSmartInstall(app.ID, app.Name, app.Choco)
				core.PauseEnter("")
				return
			}
		}
	}
	fmt.Println(" \033[31m[!] Opcion no valida.\033[0m")
	core.PauseEnter("")
}

func runPresetProfile(perfil string) {
	var appList []AppItem

	switch perfil {
	case "1":
		appList = []AppItem{
			{Name: "Steam", ID: "Valve.Steam", Choco: "steam"},
			{Name: "Discord", ID: "Discord.Discord", Choco: "discord"},
			{Name: "OBS Studio", ID: "OBSProject.OBSStudio", Choco: "obs-studio"},
			{Name: "7-Zip", ID: "7zip.7zip", Choco: "7zip"},
			{Name: "Epic Games", ID: "EpicGames.EpicGamesLauncher", Choco: "epicgameslauncher"},
		}
	case "2":
		appList = []AppItem{
			{Name: "Google Chrome", ID: "Google.Chrome", Choco: "googlechrome"},
			{Name: "7-Zip", ID: "7zip.7zip", Choco: "7zip"},
			{Name: "VLC Media Player", ID: "VideoLAN.VLC", Choco: "vlc"},
			{Name: "AnyDesk", ID: "AnyDesk.AnyDesk", Choco: "anydesk"},
			{Name: "Microsoft Teams", ID: "Microsoft.Teams", Choco: "teams"},
		}
	case "3":
		appList = []AppItem{
			{Name: "VS Code", ID: "Microsoft.VisualStudioCode", Choco: "vscode"},
			{Name: "Git", ID: "Git.Git", Choco: "git"},
			{Name: "Docker Desktop", ID: "Docker.DockerDesktop", Choco: "docker-desktop"},
			{Name: "Node.js", ID: "OpenJS.NodeJS", Choco: "nodejs"},
			{Name: "Python 3", ID: "Python.Python.3", Choco: "python"},
		}
	case "4":
		appList = []AppItem{
			{Name: "LibreOffice", ID: "TheDocumentFoundation.LibreOffice", Choco: "libreoffice"},
			{Name: "Adobe Acrobat Reader", ID: "Adobe.Acrobat.Reader.64-bit", Choco: "adobereader"},
			{Name: "Notion", ID: "Notion.Notion", Choco: "notion"},
			{Name: "Obsidian", ID: "Obsidian.Obsidian", Choco: "obsidian"},
		}
	}

	successCount := 0
	for i, app := range appList {
		pct := int(float64(i+1) / float64(len(appList)) * 100)
		fmt.Printf("\n\033[36m[%d/%d - %d%%] Procesando %s...\033[0m\n", i+1, len(appList), pct, app.Name)
		if InvokeSmartInstall(app.ID, app.Name, app.Choco) {
			successCount++
		}
	}

	fmt.Printf("\n\033[32m═══════════════════════════════════════════════════════════════\033[0m\n")
	fmt.Printf(" ✅ Exitosas: %d  |  ❌ Fallidas: %d\n", successCount, len(appList)-successCount)
	fmt.Printf("\033[32m═══════════════════════════════════════════════════════════════\033[0m\n")
	core.PauseEnter("")
}

// InvokeKitPostFormat replica de forma 1 a 1 el menú con 22 categorías, desinstalación y catálogo directo
func InvokeKitPostFormat() {
	for {
		core.ShowBanner()
		fmt.Println("\n \033[32m📦 KIT POST FORMAT - INSTALACION INTELIGENTE\033[0m")
		fmt.Println(" \033[90m═══════════════════════════════════════════════════════════════════\033[0m")

menuLineas := []string{
"  \033[36m[01]\033[0m 🌐 NAVEGADORES                 \033[36m[02]\033[0m 💬 COMUNICACIÓN",
"  \033[36m[03]\033[0m 🛠️ UTILIDADES                  \033[36m[04]\033[0m 💻 DESARROLLO",
"  \033[36m[05]\033[0m 🎬 MULTIMEDIA                  \033[36m[06]\033[0m 📄 OFIMÁTICA",
"  \033[36m[07]\033[0m 🌐 REDES Y TERMINAL            \033[36m[08]\033[0m 🎮 JUEGOS",
"  \033[36m[09]\033[0m 🖥️ VIRTUALIZACIÓN              \033[36m[10]\033[0m 💾 RESPALDOS",
"  \033[36m[11]\033[0m 🔒 VPN                         \033[36m[12]\033[0m 📊 MONITOR",
"  \033[36m[13]\033[0m 📝 NOTAS                       \033[36m[14]\033[0m ⚡ UTILIDADES AVANZADAS",
"  \033[36m[15]\033[0m 📦 CLIENTES                    \033[36m[16]\033[0m 🧹 LIMPIEZA",
"  \033[36m[17]\033[0m 🎨 PERSONALIZACIÓN             \033[36m[18]\033[0m 🤖 INTELIGENCIA ARTIFICIAL",
"  \033[36m[19]\033[0m 🔐 SEGURIDAD AVANZADA          \033[36m[20]\033[0m 📈 DATA SCIENCE",
"  \033[36m[21]\033[0m 🎥 MEDIA SERVER                \033[36m[22]\033[0m 🔧 HERRAMIENTAS SISTEMA",
}
for _, m := range menuLineas {
fmt.Println(m)
}

		fmt.Println("\n \033[90m═══════════════════════════════════════════════════════════════════\033[0m")
		fmt.Println(" 🎮 [P] PERFILES PREDEFINIDOS (Gaming, Basico, Dev, Ofimatica)")
		fmt.Println(" 🔄 [U] ACTUALIZAR TODO EL SOFTWARE")
		fmt.Println(" 🗑️ [R] DESINSTALAR PROGRAMAS (appwiz, winget, revo, bcu)")
		fmt.Println(" 🧹 [0] LIMPIEZA DE BLOATWARE (CandyCrush, Netflix, TikTok, etc.)")
		fmt.Println(" 🔍 [B] BUSCAR APP (por nombre)")
		fmt.Println(" 🚀 [M] INSTALACIÓN AUTOMÁTICA (Base de datos URLs directas)")
		fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
		fmt.Println(" \033[31m-------------------\033[0m")
		fmt.Println(" \033[31m❌ [X] VOLVER AL MENÚ PRINCIPAL\033[0m")

		validOpts := []string{"P", "U", "R", "0", "B", "M", "X"}
		for _, cat := range categories {
			validOpts = append(validOpts, cat.ID)
		}

		opt := core.ReadMenuOption("\n > SELECCIONE (categoria 1-22, P, U, R, 0, B, M, X):", validOpts, "")
		if opt == "X" {
			break
		}

		switch opt {
		case "0":
			fmt.Println("\n\033[33m[!] Eliminando Bloatware de Windows...\033[0m")
			psBloat := `
$bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*", "*Facebook*", "*Spotify*")
foreach($b in $bloat){ Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue }
`
			core.RunPowerShellCmd(psBloat)
			fmt.Println(" \033[32m[✔] Bloatware eliminado.\033[0m")
			core.PauseEnter("")
		case "P":
			for {
				core.ShowBanner()
				fmt.Println("\n \033[36m🎮 PERFILES PREDEFINIDOS\033[0m")
				fmt.Println(" 🎮 [1] PERFIL GAMING (Steam, Discord, OBS, 7-Zip, Epic)")
				fmt.Println(" 🛠️ [2] PERFIL BASICO (Chrome, 7-Zip, VLC, AnyDesk, Teams)")
				fmt.Println(" 💻 [3] PERFIL DESARROLLADOR (VSCode, Git, Docker, Node, Python)")
				fmt.Println(" 📄 [4] PERFIL OFIMATICA (LibreOffice, Adobe Reader, Notion, Obsidian)")
				fmt.Println("\n \033[31m❌ [X] VOLVER\033[0m")

				p := core.ReadMenuOption("\n > SELECCIONE PERFIL:", []string{"1", "2", "3", "4", "X"}, "")
				if p == "X" {
					break
				}
				runPresetProfile(p)
			}
		case "U":
			cmd := exec.Command("winget", "upgrade", "--all", "--accept-package-agreements", "--accept-source-agreements")
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			_ = cmd.Run()
			core.PauseEnter("")
		case "R":
			invokeUninstallMenu()
		case "B":
			term := core.ReadMenuOption("\n Ingrese el nombre de la app a buscar:", nil, "")
			if term != "" {
				cmd := exec.Command("winget", "search", term)
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				_ = cmd.Run()

				installID := core.ReadMenuOption("\n Ingrese el ID exacto a instalar (o ENTER para cancelar):", nil, "")
				if installID != "" {
					InvokeSmartInstall(installID, installID, "")
				}
			}
			core.PauseEnter("")
		case "M":
			appName := core.ReadMenuOption("\n Ingrese el nombre del programa (ej: mipony, jdownloader, rufus, brave):", nil, "")
			if appName != "" {
				installAutoApp(appName)
			}
		default:
			for _, cat := range categories {
				if cat.ID == opt {
					showCategoryApps(cat)
					break
				}
			}
		}
	}
}

func InvokeWingetMenu() {
	for {
		core.ShowBanner()
		fmt.Println("\n \033[36m📦 GESTION DE PAQUETES (WINGET & CHOCOLATEY)\033[0m")
		fmt.Println(" \033[36m 🔄 [A] WINGET: ACTUALIZAR TODO             🍫 [D] CHOCO: ACTUALIZAR TODO\033[0m")
		fmt.Println(" \033[36m 📋 [B] WINGET: LISTAR DISPONIBLES          📋 [E] CHOCO: LISTAR DISPONIBLES\033[0m")
		fmt.Println(" \033[36m 🔍 [S] WINGET: BUSCAR PAQUETE              🔍 [F] CHOCO: BUSCAR PAQUETE\033[0m")
		fmt.Println(" \033[36m 📥 [G] WINGET: INSTALAR POR ID EXACTO      🍫 [H] CHOCO: INSTALAR CHOCOLATEY\033[0m")
		fmt.Println(" \033[36m 🔧 [C] WINGET: REPARAR CLIENTE\033[0m")
		fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
		fmt.Println(" \033[31m-------------------\033[0m")
		fmt.Println(" \033[31m[X] VOLVER\033[0m")

		opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"A", "B", "C", "S", "D", "E", "F", "G", "H", "X"}, "")
		if opt == "X" {
			break
		}

		switch opt {
		case "A":
			cmd := exec.Command("winget", "upgrade", "--all", "--accept-package-agreements", "--accept-source-agreements")
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			_ = cmd.Run()
			core.PauseEnter("")
		case "B":
			cmd := exec.Command("winget", "upgrade")
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			_ = cmd.Run()
			core.PauseEnter("")
		case "S":
			term := core.ReadMenuOption("\n Ingrese el nombre a buscar:", nil, "")
			if term != "" {
				cmd := exec.Command("winget", "search", term)
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				_ = cmd.Run()
			}
			core.PauseEnter("")
		case "G":
			pkgID := core.ReadMenuOption("\n Ingrese ID exacto del paquete:", nil, "")
			if pkgID != "" {
				InvokeSmartInstall(pkgID, pkgID, "")
			}
			core.PauseEnter("")
		case "D":
			cmd := exec.Command("choco", "upgrade", "all", "-y", "--no-progress")
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			_ = cmd.Run()
			core.PauseEnter("")
		case "E":
			cmd := exec.Command("choco", "outdated")
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			_ = cmd.Run()
			core.PauseEnter("")
		case "F":
			term := core.ReadMenuOption("\n Nombre del programa a buscar en Chocolatey:", nil, "")
			if term != "" {
				cmd := exec.Command("choco", "search", term, "--limit-output")
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				_ = cmd.Run()
			}
			core.PauseEnter("")
		case "H":
			core.RunPowerShellCmd("Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))")
			core.PauseEnter("")
		case "C":
			core.RunPowerShellCmd("Repair-WinGetPackageManager -AllUsers -ErrorAction SilentlyContinue")
			core.PauseEnter("")
		}
	}
}
