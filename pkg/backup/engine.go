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

var expressFolderNames = []string{
"Desktop", "Documents", "Favorites",
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
fmt.Printf("\n  \033[44;37m 📂 %s \033[0m\n", title)
fmt.Println("  \033[36m═══════════════════════════════════════════════════════════════════════════\033[0m")

drives := scanDrives()
if len(drives) == 0 {
fmt.Println("  \033[31m[✘] No se detectaron unidades disponibles.\033[0m")
core.PauseEnter("")
return ""
}

validLetters := []string{"X"}
for _, d := range drives {
fmt.Printf("    \033[36m[%s]\033[0m  %-16s  %-12s  Libre: \033[32m%s GB\033[0m\n", d.Letter, d.Label, d.Type, d.FreeGB)
validLetters = append(validLetters, strings.TrimSuffix(d.Letter, ":"))
}

fmt.Println("  \033[36m═══════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[31m[X] CANCELAR\033[0m")

sel := core.ReadMenuOption("\n  \033[32m> SELECCIONE UNA UNIDAD (Letra):\033[0m", validLetters, "")
if sel == "" || sel == "X" {
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

func estimateFoldersSize(profile string, folders []string) string {
var paths []string
for _, f := range folders {
p := filepath.Join(profile, f)
if _, err := os.Stat(p); err == nil {
paths = append(paths, fmt.Sprintf("'%s'", p))
}
}
if len(paths) == 0 {
return "0 MB"
}
ps := fmt.Sprintf(`$bytes = (Get-ChildItem -Path @(%s) -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; if ($bytes -ge 1GB) { "{0:N2} GB" -f ($bytes/1GB) } else { "{0:N1} MB" -f ($bytes/1MB) }`, strings.Join(paths, ","))
out, _ := core.RunPowerShellCmd(ps)
return strings.TrimSpace(out)
}

func backupFolders(sourceProfile string, targetRoot string, folders []string) {
userName := filepath.Base(sourceProfile)
destPath := filepath.Join(targetRoot, userName)
_ = os.MkdirAll(destPath, 0755)

estSize := estimateFoldersSize(sourceProfile, folders)
fmt.Printf("\n  \033[36m[+] Respaldando usuario: %s (Peso estimado: %s)\033[0m\n", userName, estSize)

for _, folder := range folders {
src := filepath.Join(sourceProfile, folder)
if _, err := os.Stat(src); os.IsNotExist(err) {
continue
}
dst := filepath.Join(destPath, folder)
fmt.Printf("    -> Copiando %s...\n", folder)

cmd := exec.Command("robocopy", src, dst, "/E", "/MT:16", "/R:2", "/W:3", "/XJ", "/NP", "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/XF", "pagefile.sys", "hiberfil.sys", "swapfile.sys")
_ = cmd.Run()
}
}

// BackupProfile mantiene compatibilidad con llamadas externas
func BackupProfile(sourceProfile string, targetRoot string) {
backupFolders(sourceProfile, targetRoot, userFolderNames)
}

// InvokeBackup replica [A] BACKUP TOTAL
func InvokeBackup() {
for {
core.ShowBanner()
fmt.Println("\n  \033[44;37m 💾 BACKUP TOTAL - SELECCIONA EL TIPO DE RESPALDO \033[0m")
fmt.Println("  \033[36m═══════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[A] PERFIL ACTUAL COMPLETO     \033[0m - Respaldar todas las carpetas del usuario activo")
fmt.Println("  \033[36m[B] TODOS LOS PERFILES         \033[0m - Respaldar todos los usuarios locales del equipo")
fmt.Println("  \033[36m[C] EXPORTAR INVENTARIO        \033[0m - Lista de programas instalados y drivers OEM")
fmt.Println("  \033[36m[D] BACKUP EXPRESS (TRABAJO)   \033[0m - Solo Escritorio, Documentos y Favoritos")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
fmt.Println("  \033[36m═══════════════════════════════════════════════════════════════════════════\033[0m")

opt := core.ReadMenuOption("\n  \033[32m> SELECCIONE:\033[0m", []string{"A", "B", "C", "D", "X"}, "")
if opt == "" {
continue
}
if opt == "X" {
break
}

baseDir := selectDrive("SELECCIONAR DESTINO DE BACKUP")
if baseDir == "" {
continue
}

backupTarget := getNextBackupDir(baseDir)
fmt.Printf("\n  \033[32m[+] Destino preparado: %s\033[0m\n", backupTarget)

switch opt {
case "A":
userProfile := os.Getenv("USERPROFILE")
BackupProfile(userProfile, backupTarget)
fmt.Printf("\n  \033[32m[✔] Respaldo completado con éxito en: %s\033[0m\n", backupTarget)
core.PauseEnter("")
case "B":
usersBase := filepath.Join(os.Getenv("SystemDrive")+`\`, "Users")
entries, _ := os.ReadDir(usersBase)
excludedUsers := map[string]bool{"Public": true, "Default": true, "Default User": true, "All Users": true}

for _, e := range entries {
if e.IsDir() && !excludedUsers[e.Name()] {
BackupProfile(filepath.Join(usersBase, e.Name()), backupTarget)
}
}
fmt.Printf("\n  \033[32m[✔] Respaldo de todos los perfiles completado en: %s\033[0m\n", backupTarget)
core.PauseEnter("")
case "C":
fmt.Println("\n  \033[33m[+] Exportando lista de programas instalados y controladores...\033[0m")
appsFile := filepath.Join(backupTarget, "Programas_Instalados.txt")
driversDir := filepath.Join(backupTarget, "Drivers")
_ = os.MkdirAll(driversDir, 0755)

_, _ = core.RunPowerShellCmd(fmt.Sprintf(`Get-Package | Format-Table Name, Version | Out-File -FilePath "%s" -Encoding utf8`, appsFile))
_, _ = core.RunPowerShellCmd(fmt.Sprintf(`Export-WindowsDriver -Online -Destination "%s"`, driversDir))

fmt.Printf("\n  \033[32m[✔] Inventario de programas y drivers guardado en: %s\033[0m\n", backupTarget)
core.PauseEnter("")
case "D":
userProfile := os.Getenv("USERPROFILE")
backupFolders(userProfile, backupTarget, expressFolderNames)
fmt.Printf("\n  \033[32m[✔] Respaldo express completado en: %s\033[0m\n", backupTarget)
core.PauseEnter("")
}
}
}

// InvokeRestore replica [B] RESTORE TOTAL escaneando todas las unidades conectadas
func InvokeRestore() {
core.ShowBanner()
fmt.Println("\n  \033[44;37m 📀 RESTORE TOTAL - RESTAURACIÓN DE PERFILES \033[0m")
fmt.Println("  \033[36m═══════════════════════════════════════════════════════════════════════════\033[0m")

psCmd := `
$roots = Get-Volume | Where-Object { $_.DriveLetter -ne $null } | ForEach-Object { "$($_.DriveLetter):\BACKOPs" }
Get-ChildItem -Path $roots -Directory -Recurse -ErrorAction SilentlyContinue |
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
fmt.Println("  \033[31m[✘] No se encontraron carpetas de respaldo (BACKOP_XX) en ninguna unidad.\033[0m")
core.PauseEnter("")
return
}

fmt.Println("  Respaldos encontrados en unidades conectadas:")
var validOpts []string
for i, b := range validBackups {
fmt.Printf("    \033[36m[%d]\033[0m %s\n", i+1, b)
validOpts = append(validOpts, strconv.Itoa(i+1))
}
validOpts = append(validOpts, "X")

sel := core.ReadMenuOption("\n  \033[32m> SELECCIONE EL RESPALDO A RESTAURAR (o X):\033[0m", validOpts, "")
if sel == "" || sel == "X" {
return
}

idx, _ := strconv.Atoi(sel)
chosenBackup := validBackups[idx-1]

targetRoot := filepath.Join(os.Getenv("SystemDrive")+`\`, "Users")
fmt.Printf("\n  \033[33m[!] Restaurando datos desde: %s\033[0m\n", chosenBackup)
fmt.Printf("      Destino base: %s\n", targetRoot)

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
fmt.Printf("    -> Restaurando %s/%s...\n", profileName, f.Name())
cmd := exec.Command("robocopy", srcFolder, dstFolder, "/E", "/MT:8", "/R:1", "/W:2", "/NP", "/NFL", "/NDL", "/NJH", "/NJS")
_ = cmd.Run()
}
}
}

fmt.Println("\n  \033[32m[✔] Proceso de restauración finalizado con éxito.\033[0m")
core.PauseEnter("")
}