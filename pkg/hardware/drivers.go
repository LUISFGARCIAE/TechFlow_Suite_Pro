package hardware

import (
"fmt"
"os"
"os/exec"
"path/filepath"
"strings"
"techflow/pkg/core"
)

func ExportDrivers(destinationDir string) error {
if destinationDir == "" {
destinationDir = "C:\\Drivers_Backup"
}
_ = os.MkdirAll(destinationDir, 0755)
fmt.Printf("\n  \033[36m[*] Exportando drivers OEM instalados hacia %s...\033[0m\n", destinationDir)
cmd := exec.Command("dism", "/online", "/export-driver", fmt.Sprintf("/destination:%s", destinationDir))
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
return cmd.Run()
}

func RestoreDrivers(sourceDir string) error {
absPath, err := filepath.Abs(sourceDir)
if err != nil {
return err
}
fmt.Printf("\n  \033[36m[*] Inyectando controladores recursivamente desde %s...\033[0m\n", absPath)
cmd := exec.Command("pnputil", "/add-driver", filepath.Join(absPath, "*.inf"), "/subdirs", "/install")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
return cmd.Run()
}

func InvokeDriverManagement() {
for {
core.ClearScreen()
core.ShowBanner()
fmt.Println("\n\033[32m💾 GESTIÓN AVANZADA DE CONTROLADORES / DRIVERS\033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1]\033[0m 💾 RESPALDAR DRIVERS INSTALADOS (Exportar a C:\\Drivers_Backup)")
fmt.Println("  \033[36m[2]\033[0m 📥 RESTAURAR DRIVERS DESDE CARPETA (Inyección recursiva vía pnputil)")
fmt.Println("")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X]\033[0m ❌ VOLVER AL MENÚ PRINCIPAL")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Print("  \033[32m>\033[0m SELECCIONE UNA OPCIÓN: ")

var opt string
fmt.Scanln(&opt)
opt = strings.ToUpper(strings.TrimSpace(opt))

switch opt {
case "1":
_ = ExportDrivers("C:\\Drivers_Backup")
core.PauseEnter("")
case "2":
fmt.Print("\n  Ruta del directorio de drivers [Default: C:\\Drivers_Backup]: ")
var path string
fmt.Scanln(&path)
path = strings.TrimSpace(path)
if path == "" {
path = "C:\\Drivers_Backup"
}
_ = RestoreDrivers(path)
core.PauseEnter("")
case "X":
return
}
}
}