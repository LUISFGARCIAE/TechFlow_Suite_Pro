package core

import (
"encoding/json"
"fmt"
"net/http"
"os"
"os/exec"
"path/filepath"
"strings"
"time"
)

const CurrentVersion = "6.0"
const RepoOwner = "LUISFGARCIAE"
const RepoName = "TechFlow_Suite_Pro"

type GithubRelease struct {
TagName string `json:"tag_name"`
Assets  []struct {
Name               string `json:"name"`
BrowserDownloadURL string `json:"browser_download_url"`
} `json:"assets"`
}

func checkCommandWorking(command string, args ...string) bool {
cmd := exec.Command(command, args...)
err := cmd.Run()
return err == nil
}

func checkAndRepairWinget() bool {
if checkCommandWorking("winget", "--version") {
return true
}
fmt.Println("   \033[33m🔧 Reparando motor WINGET...\033[0m")
psRepair := `
$ProgressPreference = 'SilentlyContinue'
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
}
if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -ErrorAction SilentlyContinue | Out-Null
}
Import-Module Microsoft.WinGet.Client -ErrorAction SilentlyContinue
Repair-WinGetPackageManager -AllUsers -ErrorAction SilentlyContinue | Out-Null
`
_, _ = RunPowerShellCmd(psRepair)
return checkCommandWorking("winget", "--version")
}

func checkAndRepairChoco() bool {
if checkCommandWorking("choco", "--version") {
return true
}
fmt.Println("   \033[33m🔧 Instalando CHOCOLATEY...\033[0m")
psChoco := `
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
$script = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
Invoke-Expression $script
`
_, _ = RunPowerShellCmd(psChoco)
return checkCommandWorking("choco", "--version")
}

func checkGithubUpdates(exeFolder, exeName string) {
fmt.Println("\n \033[90m🔍 [1/3] VERIFICANDO ACTUALIZACIONES...\033[0m")
apiURL := fmt.Sprintf("https://api.github.com/repos/%s/%s/releases/latest", RepoOwner, RepoName)

client := &http.Client{Timeout: 5 * time.Second}
resp, err := client.Get(apiURL)
if err != nil || resp.StatusCode != http.StatusOK {
fmt.Println("   \033[33m⚠️ No se pudo conectar con el servidor de actualizaciones.\033[0m")
return
}
defer resp.Body.Close()

var rel GithubRelease
if err := json.NewDecoder(resp.Body).Decode(&rel); err != nil {
fmt.Println("   \033[33m⚠️ Error al verificar respuesta de versión.\033[0m")
return
}

latestVer := strings.TrimPrefix(rel.TagName, "v")
if latestVer != "" && latestVer != CurrentVersion {
fmt.Println(" \033[33m═══════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("   \033[33m🚀 ¡NUEVA VERSIÓN DISPONIBLE!\033[0m")
fmt.Printf("   \033[36m📦 Actual: v%s  ➜  Nueva: v%s\033[0m\n", CurrentVersion, latestVer)
fmt.Println(" \033[33m═══════════════════════════════════════════════════════════════════\033[0m")

updateOpt := ReadMenuOption("   ❓ ¿Deseas actualizar ahora? (S/N):", []string{"S", "N"}, "N")
if updateOpt == "S" {
var downloadURL string
for _, asset := range rel.Assets {
if strings.HasSuffix(strings.ToLower(asset.Name), ".exe") {
downloadURL = asset.BrowserDownloadURL
break
}
}

if downloadURL == "" {
fmt.Println("   \033[31m❌ ERROR: No se encontró ejecutable en la release.\033[0m")
PauseEnter("Presiona ENTER para continuar...")
return
}

fmt.Println("   \033[33m⏳ Descargando nueva versión...\033[0m")
newExePath := filepath.Join(exeFolder, "TechFlow_NUEVO.exe")
psDownload := fmt.Sprintf(`Invoke-WebRequest -Uri "%s" -OutFile "%s" -UseBasicParsing`, downloadURL, newExePath)
_, err := RunPowerShellCmd(psDownload)
if err == nil {
batFile := filepath.Join(exeFolder, "actualizar.bat")
batContent := fmt.Sprintf(`@echo off
cd /d "%s"
timeout /t 2 /nobreak > nul
taskkill /f /im "%s" > nul 2>&1
timeout /t 2 /nobreak > nul
del /f /q "%s" > nul 2>&1
timeout /t 1 /nobreak > nul
copy /y "TechFlow_NUEVO.exe" "%s" > nul
timeout /t 1 /nobreak > nul
start "" "%s"
del /f /q "TechFlow_NUEVO.exe" > nul 2>&1
del /f /q "%%~f0" > nul 2>&1
exit
`, exeFolder, exeName, exeName, exeName, exeName)

_ = os.WriteFile(batFile, []byte(batContent), 0644)
fmt.Println("   \033[33m🔄 Aplicando parche de actualización...\033[0m")
_ = exec.Command("cmd", "/c", "start", "/min", batFile).Start()
time.Sleep(2 * time.Second)
os.Exit(0)
}
}
} else {
fmt.Printf("   \033[32m✅ Versión al día (v%s).\033[0m\n", CurrentVersion)
}
}

func ensureDefenderExclusion(exeFolder, exeName string) {
fmt.Println(" \033[90m🔍 [2/3] OPTIMIZANDO PROTECCIÓN DEFENDER...\033[0m")
psCmd := fmt.Sprintf(`
$current = Get-MpPreference -ErrorAction SilentlyContinue
$pathEx = $current.ExclusionPath -contains '%s'
$procEx = $current.ExclusionProcess -contains '%s'
if (-not ($pathEx -and $procEx)) {
Add-MpPreference -ExclusionPath '%s' -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess '%s' -ErrorAction SilentlyContinue
Write-Host "ADDED"
} else {
Write-Host "ALREADY"
}
`, exeFolder, exeName, exeFolder, exeName)

out, _ := RunPowerShellCmd(psCmd)
if strings.Contains(out, "ADDED") {
fmt.Println("   \033[32m✅ TechFlow añadido a exclusiones de seguridad.\033[0m")
} else {
fmt.Println("   \033[32m🛡️ El programa ya cuenta con protección total.\033[0m")
}
}

func cleanStartupLeftovers(exeFolder string) {
fmt.Println(" \033[90m🔍 [3/3] LIMPIANDO TEMPORALES DE INICIO...\033[0m")
_ = os.Remove(filepath.Join(exeFolder, "TechFlow_NUEVO.exe"))
_ = os.Remove(filepath.Join(exeFolder, "actualizar.bat"))

// Limpiar backups residuales
files, _ := filepath.Glob(filepath.Join(exeFolder, "TechFlow_Backup*.exe"))
for _, f := range files {
_ = os.Remove(f)
}
fmt.Println("   \033[32m✨ Entorno de ejecución limpio.\033[0m")
}

// RunStartupSequence ejecuta la pantalla previa idéntica al PS1 original
func RunStartupSequence() {
ClearScreen()

exePath, _ := os.Executable()
exeFolder := filepath.Dir(exePath)
exeName := filepath.Base(exePath)

fmt.Println("\n \033[36m📦 ESTADO DE REPOSITORIOS DE SOFTWARE\033[0m")
fmt.Println(" \033[90m═══════════════════════════════════════════════════════════════════\033[0m")

wingetOk := checkAndRepairWinget()
if wingetOk {
fmt.Println("   \033[32m✅ WINGET      : DISPONIBLE 🧊\033[0m")
} else {
fmt.Println("   \033[33m⚠️ WINGET      : NO DISPONIBLE (Uso de URLs manuales)\033[0m")
}

chocoOk := checkAndRepairChoco()
if chocoOk {
fmt.Println("   \033[32m✅ CHOCOLATEY  : DISPONIBLE 🍫\033[0m")
} else {
fmt.Println("   \033[33m⚠️ CHOCOLATEY  : NO DISPONIBLE\033[0m")
}

fmt.Println(" \033[90m═══════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("   \033[90m💡 RECOMENDACIÓN: Los repositorios permiten instalaciones silenciosas.\033[0m")
time.Sleep(1 * time.Second)

checkGithubUpdates(exeFolder, exeName)
ensureDefenderExclusion(exeFolder, exeName)
cleanStartupLeftovers(exeFolder)

fmt.Println("\n   \033[32m🚀 Cargando menú principal...\033[0m")
time.Sleep(1500 * time.Millisecond)
}
