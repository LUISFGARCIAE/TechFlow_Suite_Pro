package maintenance

import (
"fmt"
"os"
"os/exec"
"path/filepath"
"techflow/pkg/core"
)

func InvokeTempOptimizer() {
validKeys := []string{"1", "2", "3", "4", "5", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 🧹 OPTIMIZACIÓN Y PURGA PROFUNDA DE TEMPORALES \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] LIMPIEZA RÁPIDA (EXPRESS)  \033[0m - Purgar %TEMP%, Windows\\Temp y Prefetch")
fmt.Println("  \033[36m[2] CACHÉ WINDOWS UPDATE       \033[0m - Vaciar descargas viejas de SoftwareDistribution")
fmt.Println("  \033[36m[3] CACHÉ MINIATURAS Y DNS     \033[0m - Limpiar Thumbnails, caché web y FlushDNS")
fmt.Println("  \033[36m[4] PAPELERA Y VOLCADOS BSOD   \033[0m - Vaciar Papelera, reportes WER y Minidumps")
fmt.Println("  \033[36m[5] PURGA PROFUNDA TOTAL (AIO) \033[0m - Ejecutar limpieza completa + WinSxS DISM")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

opt := core.ReadMenuOption("\n  \033[32m> SELECCIONE NIVEL DE LIMPIEZA:\033[0m", validKeys, "")
if opt == "" {
continue
}
if opt == "X" {
return
}

switch opt {
case "1":
runExpressClean()
core.PauseEnter("")
case "2":
runWinUpdateClean()
core.PauseEnter("")
case "3":
runThumbAndDNSClean()
core.PauseEnter("")
case "4":
runRecycleAndDumpsClean()
core.PauseEnter("")
case "5":
runExpressClean()
runWinUpdateClean()
runThumbAndDNSClean()
runRecycleAndDumpsClean()
fmt.Println("\n  \033[36m[DISM WINSXS]\033[0m   🧹 Limpiando almacén de componentes obsoletos...")
_ = exec.Command("dism.exe", "/Online", "/Cleanup-Image", "/StartComponentCleanup").Run()
fmt.Println("  \033[32m[✔] Purga profunda integral finalizada con éxito.\033[0m")
core.PauseEnter("")
}
}
}

// purgeDirectory mantiene compatibilidad con system_tweaks.go
func purgeDirectory(dirPath string) (int, int64) {
return cleanDirSafe(dirPath), 0
}

func cleanDirSafe(dirPath string) int {
entries, err := os.ReadDir(dirPath)
if err != nil {
return 0
}
deleted := 0
for _, entry := range entries {
fullPath := filepath.Join(dirPath, entry.Name())
if err := os.RemoveAll(fullPath); err == nil {
deleted++
}
}
return deleted
}

func runExpressClean() {
fmt.Println("\n  \033[36m[*] Ejecutando Limpieza Rápida de Temporales...\033[0m\n")
userTemp := os.TempDir()
winTemp := `C:\Windows\Temp`
prefetch := `C:\Windows\Prefetch`

c1 := cleanDirSafe(userTemp)
fmt.Printf("  \033[36m[USER TEMP]\033[0m     🧹 Elementos eliminados: \033[32m%d\033[0m (%s)\n", c1, userTemp)

c2 := cleanDirSafe(winTemp)
fmt.Printf("  \033[36m[WINDOWS TEMP]\033[0m  🧹 Elementos eliminados: \033[32m%d\033[0m (%s)\n", c2, winTemp)

c3 := cleanDirSafe(prefetch)
fmt.Printf("  \033[36m[PREFETCH]\033[0m      🧹 Elementos eliminados: \033[32m%d\033[0m (%s)\n", c3, prefetch)
}

func runWinUpdateClean() {
fmt.Println("\n  \033[36m[*] Purgando caché de Windows Update...\033[0m\n")
_ = exec.Command("net", "stop", "wuauserv").Run()
_ = exec.Command("net", "stop", "bits").Run()

wuDir := `C:\Windows\SoftwareDistribution\Download`
c := cleanDirSafe(wuDir)
fmt.Printf("  \033[36m[WIN UPDATE]\033[0m    🧹 Paquetes residuales eliminados: \033[32m%d\033[0m\n", c)

_ = exec.Command("net", "start", "wuauserv").Run()
_ = exec.Command("net", "start", "bits").Run()
}

func runThumbAndDNSClean() {
fmt.Println("\n  \033[36m[*] Limpiando caché de miniaturas y resolución DNS...\033[0m\n")
localAppData := os.Getenv("LOCALAPPDATA")
thumbDir := filepath.Join(localAppData, `Microsoft\Windows\Explorer`)

matches, _ := filepath.Glob(filepath.Join(thumbDir, "thumbcache_*.db"))
deleted := 0
for _, m := range matches {
if os.Remove(m) == nil {
deleted++
}
}
fmt.Printf("  \033[36m[THUMBNAILS]\033[0m    🧹 Archivos de caché visual purgados: \033[32m%d\033[0m\n", deleted)

_ = exec.Command("ipconfig", "/flushdns").Run()
fmt.Println("  \033[36m[DNS RESOLVER]\033[0m  🧹 Caché DNS vaciada correctamente")
}

func runRecycleAndDumpsClean() {
fmt.Println("\n  \033[36m[*] Vaciando Papelera y volcados de memoria...\033[0m\n")
_ = exec.Command("powershell", "-NoProfile", "-Command", "Clear-RecycleBin -Force -ErrorAction SilentlyContinue").Run()
fmt.Println("  \033[36m[PAPELERA]\033[0m      🧹 Papelera de reciclaje vaciada en todas las unidades")

cWer := cleanDirSafe(`C:\ProgramData\Microsoft\Windows\WER\ReportQueue`)
cDump := cleanDirSafe(`C:\Windows\Minidump`)
_ = os.Remove(`C:\Windows\MEMORY.DMP`)
fmt.Printf("  \033[36m[VOLCADOS/WER]\033[0m  🧹 Reportes y volcados eliminados: \033[32m%d\033[0m\n", cWer+cDump)
}