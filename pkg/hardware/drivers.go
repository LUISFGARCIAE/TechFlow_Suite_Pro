package hardware

import (
"fmt"
"os"
"os/exec"
"path/filepath"
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
validKeys := []string{"1", "2", "3", "4", "5", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 💾 GESTIÓN AVANZADA DE CONTROLADORES / DRIVERS \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] RESPALDAR DRIVERS OEM       \033[0m - Exportar todos a C:\\Drivers_Backup (DISM)")
fmt.Println("  \033[36m[2] RESTAURAR DESDE CARPETA     \033[0m - Inyección recursiva de .INF (pnputil)")
fmt.Println("  \033[36m[3] AUDITORÍA DRIVERS TERCEROS  \033[0m - Listar paquetes OEM instalados y versiones")
fmt.Println("  \033[36m[4] HARDWARE CON ERROR / FALLO  \033[0m - Detectar dispositivos PnP con alertas")
fmt.Println("  \033[36m[5] ABRIR ADMIN. DISPOSITIVOS   \033[0m - Lanzar consola gráfica (devmgmt.msc)")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                      \033[0m - Regresar al Menú Principal")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

opt := core.ReadMenuOption("\n  \033[32m> SELECCIONE:\033[0m", validKeys, "")
if opt == "" {
continue
}
if opt == "X" {
return
}

switch opt {
case "1":
if err := ExportDrivers("C:\\Drivers_Backup"); err != nil {
fmt.Printf("\n  \033[31m[!] Error al exportar drivers: %v\033[0m\n", err)
} else {
fmt.Println("\n  \033[32m[✔] Respaldo completado en C:\\Drivers_Backup\033[0m")
}
core.PauseEnter("")
case "2":
if err := RestoreDrivers("C:\\Drivers_Backup"); err != nil {
fmt.Printf("\n  \033[31m[!] Error al restaurar drivers: %v\033[0m\n", err)
} else {
fmt.Println("\n  \033[32m[✔] Controladores inyectados correctamente.\033[0m")
}
core.PauseEnter("")
case "3":
fmt.Println("\n  \033[36m[*] Listando controladores OEM de terceros...\033[0m\n")
out, _ := core.RunPowerShellCmd("Get-WindowsDriver -Online | Select-Object Driver, ProviderName, ClassName, Version | Format-Table -AutoSize")
fmt.Println(out)
core.PauseEnter("")
case "4":
fmt.Println("\n  \033[36m[*] Buscando dispositivos con errores o sin controlador...\033[0m\n")
out, _ := core.RunPowerShellCmd("$err = Get-PnpDevice | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Unknown' }; if ($err) { $err | Select-Object Status, Class, FriendlyName, InstanceId | Format-Table -AutoSize } else { 'Todos los dispositivos PnP operan correctamente (Status: OK).' }")
fmt.Println(out)
core.PauseEnter("")
case "5":
_ = exec.Command("devmgmt.msc").Start()
}
}
}