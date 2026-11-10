package backup

import (
"fmt"
"os"
"os/exec"
"path/filepath"
"strconv"
"strings"
"techflow/pkg/core"
)

var userFolderNames = []string{
"Desktop", "Documents", "Pictures", "Videos", "Music", "Downloads", "Favorites", "Contacts",
}

type DriveInfo struct {
Letter string
Label  string
Type   string
FreeGB string
}

func scanDrives() []DriveInfo {
psCmd := `
Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.DriveType -in 'Fixed','Removable' } | ForEach-Object {
$label = if ($_.FileSystemLabel) { $_.FileSystemLabel } else { "SinEtiqueta" }
$free = [math]::Round($_.SizeRemaining / 1GB, 1)
Write-Host "$($_.DriveLetter):|$label|$($_.DriveType)|$free"
}
`
out, _ := core.RunPowerShellCmd(psCmd)
lines := strings.Split(strings.TrimSpace(out), "\n")
var drives []DriveInfo

for _, line := range lines {
parts := strings.Split(strings.TrimSpace(line), "|")
if len(parts) >= 4 {
drives = append(drives, DriveInfo{
Letter: parts[0],
Label:  parts[1],
Type:   parts[2],
FreeGB: parts[3],
})
}
}
return drives
}

func selectDrive(title string) string {
core.ShowBanner()
fmt.Printf("\n \033[36m📂 %s\033[0m\n", title)
fmt.Println(" ═══════════════════════════════════════════════════════════════════")

drives := scanDrives()
if len(drives) == 0 {
fmt.Println(" \033[31m[✘] No se detectaron unidades disponibles.\033[0m")
core.PauseEnter("")
return ""
}

validLetters := []string{"X"}
for _, d := range drives {
fmt.Printf("   [%s]  %-15s  %-12s  Libre: %s GB\n", d.Letter, d.Label, d.Type, d.FreeGB)
validLetters = append(validLetters, strings.TrimSuffix(d.Letter, ":"))
}

fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println(" \033[31m[X] CANCELAR\033[0m")

sel := core.ReadMenuOption("\n > SELECCIONE UNA UNIDAD (Letra):", validLetters, "")
if sel == "X" {
return ""
}
return sel + `:\BACKOPs`
}

func getNextBackupDir(basePath string) string {
_ = os.MkdirAll(basePath, 0755)
for i := 1; i <= 99; i++ {
candidate := filepath.Join(basePath, fmt.Sprintf("BACKOP_%02d", i))
if _, err := os.Stat(candidate); os.IsNotExist(err) {
_ = os.MkdirAll(candidate, 0755)
return candidate
}
}
return filepath.Join(basePath, "BACKOP_99")
}

// BackupProfile ejecuta Robocopy sobre las carpetas del perfil indicado
func BackupProfile(sourceProfile string, targetRoot string) {
userName := filepath.Base(sourceProfile)
destPath := filepath.Join(targetRoot, userName)
_ = os.MkdirAll(destPath, 0755)

fmt.Printf("\n\033[36m[+] Iniciando respaldo para usuario: %s\033[0m\n", userName)

for _, folder := range userFolderNames {
src := filepath.Join(sourceProfile, folder)
if _, err := os.Stat(src); os.IsNotExist(err) {
continue
}
dst := filepath.Join(destPath, folder)
fmt.Printf("  -> Copiando %s...\n", folder)

cmd := exec.Command("robocopy", src, dst, "/E", "/MT:16", "/R:2", "/W:3", "/XJ", "/NP", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/XF", "pagefile.sys", "hiberfil.sys", "swapfile.sys")
_ = cmd.Run()
}
}

// InvokeBackup replica [A] BACKUP TOTAL
func InvokeBackup() {
for {
core.ShowBanner()
fmt.Println("\n \033[32m💾 BACKUP TOTAL - SELECCIONA EL TIPO DE RESPALDO\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println(" 👤 [A] PERFIL ACTUAL           - Respaldar usuario activo")
fmt.Println(" 👥 [B] TODOS LOS PERFILES      - Respaldar todos los usuarios locales")
fmt.Println(" 📊 [C] EXPORTAR INVENTARIO     - Lista de programas instalados y drivers")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"A", "B", "C", "X"}, "")
if opt == "X" {
break
}

baseDir := selectDrive("SELECCIONAR DESTINO DE BACKUP")
if baseDir == "" {
continue
}

backupTarget := getNextBackupDir(baseDir)
fmt.Printf("\n \033[32m[+] Destino preparado: %s\033[0m\n", backupTarget)

switch opt {
case "A":
userProfile := os.Getenv("USERPROFILE")
BackupProfile(userProfile, backupTarget)
fmt.Printf("\n\033[32m[✔] Respaldo completado con exito en: %s\033[0m\n", backupTarget)
core.PauseEnter("")
case "B":
usersBase := filepath.Join(os.Getenv("SystemDrive") + `\`, "Users")
entries, _ := os.ReadDir(usersBase)
excludedUsers := map[string]bool{"Public": true, "Default": true, "Default User": true, "All Users": true}

for _, e := range entries {
if e.IsDir() && !excludedUsers[e.Name()] {
BackupProfile(filepath.Join(usersBase, e.Name()), backupTarget)
}
}
fmt.Printf("\n\033[32m[✔] Respaldo de todos los perfiles completado en: %s\033[0m\n", backupTarget)
core.PauseEnter("")
case "C":
fmt.Println("\n\033[33m[+] Exportando lista de programas instalados y controladores...\033[0m")
appsFile := filepath.Join(backupTarget, "Programas_Instalados.txt")
driversDir := filepath.Join(backupTarget, "Drivers")
_ = os.MkdirAll(driversDir, 0755)

core.RunPowerShellCmd(fmt.Sprintf(`Get-Package | Format-Table Name, Version | Out-File -FilePath "%s" -Encoding utf8`, appsFile))
core.RunPowerShellCmd(fmt.Sprintf(`Export-WindowsDriver -Online -Destination "%s"`, driversDir))

fmt.Printf("\n\033[32m[✔] Inventario de programas y drivers guardado en: %s\033[0m\n", backupTarget)
core.PauseEnter("")
}
}
}

// InvokeRestore replica [B] RESTORE TOTAL
func InvokeRestore() {
core.ShowBanner()
fmt.Println("\n \033[36m📀 RESTORE TOTAL - RESTAURACIÓN DE PERFILES\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")

psCmd := `
Get-ChildItem -Path @("C:\BACKOPs", "D:\BACKOPs", "E:\BACKOPs") -Directory -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.Name -match "^BACKOP_\d+" } | ForEach-Object { $_.FullName }
`
out, _ := core.RunPowerShellCmd(psCmd)
backups := strings.Split(strings.TrimSpace(out), "\n")

var validBackups []string
for _, b := range backups {
clean := strings.TrimSpace(b)
if clean != "" {
validBackups = append(validBackups, clean)
}
}

if len(validBackups) == 0 {
fmt.Println(" \033[31m[✘] No se encontraron carpetas de respaldo (BACKOP_XX) en las unidades locales.\033[0m")
core.PauseEnter("")
return
}

fmt.Println(" Respaldos encontrados:")
var validOpts []string
for i, b := range validBackups {
fmt.Printf("   [%d] %s\n", i+1, b)
validOpts = append(validOpts, strconv.Itoa(i+1))
}
validOpts = append(validOpts, "X")

sel := core.ReadMenuOption("\n > SELECCIONE EL RESPALDO A RESTAURAR (o X):", validOpts, "")
if sel == "X" {
return
}

idx, _ := strconv.Atoi(sel)
chosenBackup := validBackups[idx-1]

targetRoot := filepath.Join(os.Getenv("SystemDrive")+`\`, "Users")
fmt.Printf("\n\033[33m[!] Restaurando datos desde: %s\033[0m\n", chosenBackup)
fmt.Printf("    Destino base: %s\n", targetRoot)

entries, _ := os.ReadDir(chosenBackup)
for _, entry := range entries {
if !entry.IsDir() || strings.EqualFold(entry.Name(), "Drivers") {
continue
}
profileName := entry.Name()
srcProfile := filepath.Join(chosenBackup, profileName)
dstProfile := filepath.Join(targetRoot, profileName)
_ = os.MkdirAll(dstProfile, 0755)

folders, _ := os.ReadDir(srcProfile)
for _, f := range folders {
if f.IsDir() {
srcFolder := filepath.Join(srcProfile, f.Name())
dstFolder := filepath.Join(dstProfile, f.Name())
fmt.Printf("  -> Restaurando %s/%s...\n", profileName, f.Name())
cmd := exec.Command("robocopy", srcFolder, dstFolder, "/E", "/MT:8", "/R:1", "/W:2", "/NP", "/NFL", "/NDL", "/NJH", "/NJS")
_ = cmd.Run()
}
}
}

fmt.Println("\n \033[32m[✔] Proceso de restauracion finalizado con exito.\033[0m")
core.PauseEnter("")
}
