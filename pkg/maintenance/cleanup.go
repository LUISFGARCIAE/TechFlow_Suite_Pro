package maintenance

import (
"fmt"
"os"
"os/exec"
"path/filepath"
"strings"
"techflow/pkg/core"
)

var excludedPatterns = []string{
"cpuz", "hwmonitor", "gpuz", "aida64", "msiafterburner",
}

func isExcluded(name string) bool {
lower := strings.ToLower(name)
for _, pattern := range excludedPatterns {
if strings.Contains(lower, pattern) {
return true
}
}
return false
}

func cleanDirectory(dirPath string, isDemo bool) (int, int) {
if _, err := os.Stat(dirPath); os.IsNotExist(err) {
return 0, 0
}

entries, err := os.ReadDir(dirPath)
if err != nil {
return 0, 0
}

failCount := 0
deletedCount := 0

for _, entry := range entries {
name := entry.Name()
if isExcluded(name) {
fmt.Printf("    \033[90m[EXCLUIDO] %s (en uso por hardware monitor)\033[0m\n", name)
continue
}

fullPath := filepath.Join(dirPath, name)
if isDemo {
fmt.Printf("    \033[33m[DEMO] Se eliminaria: %s\033[0m\n", fullPath)
continue
}

err := os.RemoveAll(fullPath)
if err != nil {
failCount++
} else {
deletedCount++
}
}
return deletedCount, failCount
}

func runDiskPartScript(scriptContent string) {
tmpFile := filepath.Join(os.Getenv("TEMP"), "tf_diskpart.txt")
err := os.WriteFile(tmpFile, []byte(scriptContent), 0644)
if err != nil {
fmt.Printf(" \033[31m[✘] Error al crear script temporal: %v\033[0m\n", err)
return
}
defer os.Remove(tmpFile)

cmd := exec.Command("diskpart", "/s", tmpFile)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
}

// InvokeSimpleDiskPart replica la gestión completa de DiskPart simplificado
func InvokeSimpleDiskPart() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m🛠️ DISKPART SIMPLIFICADO - GESTIÓN DE DISCOS Y PARTICIONES\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println(" 📋 INFORMACIÓN BÁSICA:")
fmt.Println("   [1] LISTAR DISCOS (ver unidades conectadas)")
fmt.Println("   [2] VER DETALLES DE UN DISCO (tamaño, particiones)")
fmt.Println("   [3] VER VOLÚMENES (particiones con letras asignadas)")
fmt.Println("\n 🔧 OPERACIONES SEGURAS:")
fmt.Println("   [4] ASIGNAR LETRA DE UNIDAD")
fmt.Println("   [5] EXTENDER PARTICIÓN (aprovechar espacio libre)")
fmt.Println("   [6] REDUCIR PARTICIÓN (shrink - liberar espacio)")
fmt.Println("   [7] VERIFICAR PARTICIÓN (chkdsk)")
fmt.Println("   [8] OCULTAR / REVELAR PARTICIÓN")
fmt.Println("\n ⚠️ OPERACIONES CRÍTICAS (DESTRUCCIÓN / MODIFICACIÓN DE DATOS):")
fmt.Println("   [9]  LIMPIAR DISCO COMPLETO (clean - borra todo)")
fmt.Println("   [10] FORMATEAR COMO FAT32")
fmt.Println("   [11] FORMATEAR COMO NTFS")
fmt.Println("   [12] ACTIVAR PARTICIÓN (marcar como activa/booteable)")
fmt.Println("   [13] CONVERTIR MBR -> GPT")
fmt.Println("   [14] CONVERTIR GPT -> MBR")
fmt.Println("   [15] ELIMINAR PARTICIÓN")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m═══════════════════════════════════════════════════════════════════\033[0m")
fmt.Println(" \033[31m[X] VOLVER AL MENÚ DE DIAGNÓSTICO\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{
"1", "2", "3", "4", "5", "6", "7", "8",
"9", "10", "11", "12", "13", "14", "15", "X",
}, "")

if opt == "X" {
break
}

switch opt {
case "1":
fmt.Println("\n\033[32m[+] Discos conectados:\033[0m")
runDiskPartScript("list disk\nexit\n")
core.PauseEnter("")
case "2":
dNum := core.ReadMenuOption(" Ingrese número de disco:", nil, "")
if dNum != "" {
runDiskPartScript(fmt.Sprintf("select disk %s\ndetail disk\nexit\n", dNum))
}
core.PauseEnter("")
case "3":
fmt.Println("\n\033[32m[+] Volúmenes del sistema:\033[0m")
runDiskPartScript("list volume\nexit\n")
core.PauseEnter("")
case "4":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición:", nil, "")
letra := core.ReadMenuOption(" Letra a asignar (ej: E):", nil, "")
if dNum != "" && pNum != "" && letra != "" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nassign letter=%s\nexit\n", dNum, pNum, letra))
fmt.Println(" \033[32m[✔] Operación completada.\033[0m")
}
core.PauseEnter("")
case "5":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición:", nil, "")
sz := core.ReadMenuOption(" Tamaño a extender en MB (ENTER para máximo disponible):", nil, "")
if dNum != "" && pNum != "" {
if sz != "" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nextend size=%s\nexit\n", dNum, pNum, sz))
} else {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nextend\nexit\n", dNum, pNum))
}
fmt.Println(" \033[32m[✔] Partición extendida.\033[0m")
}
core.PauseEnter("")
case "6":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición:", nil, "")
sz := core.ReadMenuOption(" Tamaño a reducir en MB:", nil, "")
if dNum != "" && pNum != "" && sz != "" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nshrink desired=%s\nexit\n", dNum, pNum, sz))
fmt.Println(" \033[32m[✔] Partición reducida.\033[0m")
}
core.PauseEnter("")
case "7":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición:", nil, "")
if dNum != "" && pNum != "" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nchkdsk /f\nexit\n", dNum, pNum))
}
core.PauseEnter("")
case "8":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición:", nil, "")
act := core.ReadMenuOption(" ¿Ocultar (H) o Revelar (R)?:", []string{"H", "R"}, "H")
if dNum != "" && pNum != "" {
if act == "H" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nremove letter=\nexit\n", dNum, pNum))
} else {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nassign\nexit\n", dNum, pNum))
}
fmt.Println(" \033[32m[✔] Estado de letra modificado.\033[0m")
}
core.PauseEnter("")
case "9":
dNum := core.ReadMenuOption(" \033[31mNúmero de disco a LIMPIAR TOTALMENTE:\033[0m", nil, "")
if dNum != "" {
confirm := core.ReadMenuOption(fmt.Sprintf(" \033[31m¿CONFIRMA BORRAR TODO EL DISCO %s? Escriba 'BORRAR':\033[0m", dNum), nil, "")
if strings.ToUpper(confirm) == "BORRAR" {
runDiskPartScript(fmt.Sprintf("select disk %s\nclean\ncreate partition primary\nactive\nformat fs=ntfs quick\nassign\nexit\n", dNum))
fmt.Println(" \033[32m[✔] Disco limpiado y formateado en NTFS.\033[0m")
}
}
core.PauseEnter("")
case "10":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición:", nil, "")
if dNum != "" && pNum != "" {
confirm := core.ReadMenuOption(" Confirme formateo FAT32 escribiendo 'FORMATEAR':", nil, "")
if strings.ToUpper(confirm) == "FORMATEAR" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nformat fs=fat32 quick\nexit\n", dNum, pNum))
fmt.Println(" \033[32m[✔] Formateo FAT32 finalizado.\033[0m")
}
}
core.PauseEnter("")
case "11":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición:", nil, "")
if dNum != "" && pNum != "" {
confirm := core.ReadMenuOption(" Confirme formateo NTFS escribiendo 'FORMATEAR':", nil, "")
if strings.ToUpper(confirm) == "FORMATEAR" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nformat fs=ntfs quick\nexit\n", dNum, pNum))
fmt.Println(" \033[32m[✔] Formateo NTFS finalizado.\033[0m")
}
}
core.PauseEnter("")
case "12":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición a activar:", nil, "")
if dNum != "" && pNum != "" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\nactive\nexit\n", dNum, pNum))
fmt.Println(" \033[32m[✔] Partición marcada como activa.\033[0m")
}
core.PauseEnter("")
case "13":
dNum := core.ReadMenuOption(" Número de disco a convertir a GPT:", nil, "")
if dNum != "" {
confirm := core.ReadMenuOption(" Confirme conversión escribiendo 'CONVERTIR':", nil, "")
if strings.ToUpper(confirm) == "CONVERTIR" {
runDiskPartScript(fmt.Sprintf("select disk %s\nclean\nconvert gpt\nexit\n", dNum))
fmt.Println(" \033[32m[✔] Disco convertido a GPT.\033[0m")
}
}
core.PauseEnter("")
case "14":
dNum := core.ReadMenuOption(" Número de disco a convertir a MBR:", nil, "")
if dNum != "" {
confirm := core.ReadMenuOption(" Confirme conversión escribiendo 'CONVERTIR':", nil, "")
if strings.ToUpper(confirm) == "CONVERTIR" {
runDiskPartScript(fmt.Sprintf("select disk %s\nclean\nconvert mbr\nexit\n", dNum))
fmt.Println(" \033[32m[✔] Disco convertido a MBR.\033[0m")
}
}
core.PauseEnter("")
case "15":
dNum := core.ReadMenuOption(" Número de disco:", nil, "")
pNum := core.ReadMenuOption(" Número de partición a eliminar:", nil, "")
if dNum != "" && pNum != "" {
confirm := core.ReadMenuOption(" Confirme eliminación escribiendo 'BORRAR':", nil, "")
if strings.ToUpper(confirm) == "BORRAR" {
runDiskPartScript(fmt.Sprintf("select disk %s\nselect partition %s\ndelete partition\nexit\n", dNum, pNum))
fmt.Println(" \033[32m[✔] Partición eliminada.\033[0m")
}
}
core.PauseEnter("")
}
}
}

// ShowDiagnosticMenu replica [D] PURGA Y FORMATEO con todas las opciones originales
func ShowDiagnosticMenu() {
for {
core.ShowBanner()
fmt.Println("\n \033[31m🧹 PURGA Y FORMATEO - LIMPIEZA AVANZADA\033[0m")
fmt.Println(" ---------------------------------------------------------------------------")
fmt.Println(" 🗑️ [1] LIMPIAR ARCHIVOS TEMPORALES PROFUNDO")
fmt.Println(" 🧽 [2] LIMPIAR CACHÉ DE WINDOWS (WinSxS Component Cleanup)")
fmt.Println(" 🔄 [3] ELIMINAR RESTOS DE ACTUALIZACIONES ANTIGUAS (SPSuperseded)")
fmt.Println(" 📊 [4] ANALIZAR Y LIMPIAR DISCO (cleanmgr nativo)")
fmt.Println(" ⚡ [5] FORMATEO RÁPIDO DE UNIDAD USB (DiskPart FAT32)")
fmt.Println(" 💿 [6] CREAR USB BOOTEABLE (Abrir Rufus)")
fmt.Println(" 🛠️ [8] DISKPART SIMPLIFICADO - Gestión fácil de discos/USB")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"1", "2", "3", "4", "5", "6", "8", "X"}, "")
if opt == "X" {
break
}

switch opt {
case "1":
fmt.Println("\n\033[33m[+] Limpieza profunda de temporales...\033[0m")
cleanDirectory(os.Getenv("TEMP"), false)
cleanDirectory(filepath.Join(os.Getenv("SystemRoot"), "Temp"), false)
fmt.Println(" \033[32m[✔] Completado.\033[0m")
core.PauseEnter("")
case "2":
fmt.Println("\n\033[33m[+] Ejecutando DISM StartComponentCleanup...\033[0m")
cmd := exec.Command("dism", "/online", "/Cleanup-Image", "/StartComponentCleanup", "/ResetBase")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
fmt.Println("\n \033[32m[✔] Limpieza de WinSxS finalizada.\033[0m")
core.PauseEnter("")
case "3":
fmt.Println("\n\033[33m[+] Eliminando versiones obsoletas de Windows (SPSuperseded)...\033[0m")
cmd := exec.Command("dism", "/online", "/Cleanup-Image", "/SPSuperseded")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
fmt.Println("\n \033[32m[✔] Paquetes residuales eliminados.\033[0m")
core.PauseEnter("")
case "4":
fmt.Println("\n\033[33m[+] Abriendo Liberador de espacio en disco (cleanmgr)...\033[0m")
_ = exec.Command("cleanmgr.exe").Start()
core.PauseEnter("ENTER después de cerrar")
case "5":
letra := core.ReadMenuOption("\n LETRA DE LA UNIDAD USB (ej: D, sin dos puntos):", nil, "")
if letra != "" {
confirm := core.ReadMenuOption(fmt.Sprintf(" ¿CONFIRMA formatear la unidad %s:? Escriba 'FORMATEAR':", letra), nil, "")
if strings.ToUpper(confirm) == "FORMATEAR" {
fmt.Println("\n\033[33m[+] Formateando unidad...\033[0m")
cmd := exec.Command("cmd", "/c", fmt.Sprintf("format %s: /FS:FAT32 /Q /Y", letra))
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
fmt.Println(" \033[32m[✔] Formateo completado.\033[0m")
}
}
core.PauseEnter("")
case "6":
fmt.Println("\n\033[36m[+] Abriendo página de descarga oficial de Rufus...\033[0m")
_ = exec.Command("cmd", "/c", "start", "https://rufus.ie/es/").Start()
core.PauseEnter("")
case "8":
InvokeSimpleDiskPart()
}
}
}

// InvokeTempOptimizer replica [E] OPTIMIZAR TEMP
func InvokeTempOptimizer() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m🗂️ GESTIÓN DE ALMACENAMIENTO Y LIMPIEZA\033[0m")
fmt.Println(" \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println(" 🔧 [1] TODO (Mantenimiento Integral) -> Limpieza total de basura y residuos.")
fmt.Println(" 🗑️ [2] Papelera de Reciclaje         -> Vacía archivos eliminados de todos los discos.")
fmt.Println(" 🧹 [3] Temporales de Usuario         -> Caché de apps y navegación del perfil actual.")
fmt.Println(" ⚙️ [4] Temporales del Sistema        -> Archivos residuales de Windows y updates.")
fmt.Println(" 🧽 [5] LIMPIEZA AVANZADA (BleachBit) -> App gráfica externa.")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER AL MENÚ PRINCIPAL\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE UNA OPCION:", []string{"1", "2", "3", "4", "5", "X"}, "")
if opt == "X" {
break
}

if opt == "5" {
fmt.Println("\n\033[33m[+] Verificando BleachBit...\033[0m")
_, err := exec.LookPath("bleachbit")
if err != nil {
fmt.Println("\033[33m[+] Instalando BleachBit con Winget...\033[0m")
core.RunPowerShellCmd("winget install BleachBit.BleachBit --silent --accept-package-agreements")
}
_ = exec.Command("bleachbit").Start()
core.PauseEnter("ENTER después de cerrar BleachBit")
continue
}

demoOpt := core.ReadMenuOption(" ¿Ejecutar en MODO DEMO? (S/N):", []string{"S", "N"}, "N")
isDemo := (demoOpt == "S")

userTemp := os.Getenv("TEMP")
winTemp := filepath.Join(os.Getenv("SystemRoot"), "Temp")

if (opt == "1" || opt == "2") && !isDemo {
fmt.Println("\n\033[33m[*] Vaciando Papelera de Reciclaje...\033[0m")
core.RunPowerShellCmd("Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue")
fmt.Println(" \033[32m[+] Papelera limpia.\033[0m")
}

var targets []string
switch opt {
case "1":
targets = []string{userTemp, winTemp}
case "3":
targets = []string{userTemp}
case "4":
targets = []string{winTemp}
}

if len(targets) > 0 {
fmt.Println("\n\033[33m[*] Eliminando archivos temporales...\033[0m")
totalDeleted, totalFailed := 0, 0
for _, target := range targets {
fmt.Printf("  - Procesando: %s...\n", target)
d, f := cleanDirectory(target, isDemo)
totalDeleted += d
totalFailed += f
}

if !isDemo {
fmt.Println("\n \033[32m[+] PROCESO FINALIZADO.\033[0m")
fmt.Printf("     Elementos eliminados: %d\n", totalDeleted)
if totalFailed > 0 {
fmt.Printf("     \033[90m[!] %d elementos en uso no se pudieron borrar.\033[0m\n", totalFailed)
}
} else {
fmt.Println("\n \033[33m[DEMO] Simulación completada. No se aplicaron cambios.\033[0m")
}
}
core.PauseEnter("para volver")
}
}
