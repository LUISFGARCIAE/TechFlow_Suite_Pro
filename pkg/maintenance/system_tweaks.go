package maintenance

import (
"fmt"
"os"
"os/exec"
"techflow/pkg/core"
)

func InvokeDefenderControl() {
validKeys := []string{"1", "2", "3", "4", "5", "6", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 🛡️  GESTIÓN Y CONTROL DE MICROSOFT DEFENDER \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] ANÁLISIS RÁPIDO (QUICK SCAN) \033[0m - Escaneo express de áreas críticas")
fmt.Println("  \033[36m[2] ACTUALIZAR FIRMAS DE VIRUS   \033[0m - Descargar últimas definiciones (MpSignature)")
fmt.Println("  \033[36m[3] SEGURIDAD DE WINDOWS (GUI)   \033[0m - Abrir panel gráfico de Windows Defender")
fmt.Println("  \033[36m[4] ANÁLISIS COMPLETO (FULL)     \033[0m - Escaneo profundo de todas las unidades")
fmt.Println("  \033[36m[5] AGREGAR EXCLUSIÓN DE CARPETA \033[0m - Excluir directorio actual de falsos positivos")
fmt.Println("  \033[36m[6] AUDITORÍA DE PROTECCIÓN      \033[0m - Ver estado de Tiempo Real y Motor AV")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                       \033[0m - Regresar al Menú Principal")
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
fmt.Println("\n  \033[36m[*] Iniciando escaneo rápido con MpCmdRun...\033[0m")
_ = exec.Command("powershell", "-NoProfile", "-Command", "Start-MpScan -ScanType QuickScan").Run()
fmt.Println("  \033[32m[✔] Escaneo rápido completado.\033[0m")
core.PauseEnter("")
case "2":
fmt.Println("\n  \033[36m[*] Actualizando definiciones de seguridad...\033[0m")
_ = exec.Command("powershell", "-NoProfile", "-Command", "Update-MpSignature").Run()
fmt.Println("  \033[32m[✔] Firmas actualizadas correctamente.\033[0m")
core.PauseEnter("")
case "3":
_ = exec.Command("powershell", "-Command", "Start-Process windowsdefender:").Start()
case "4":
fmt.Println("\n  \033[36m[*] Iniciando escaneo completo en segundo plano...\033[0m")
_ = exec.Command("powershell", "-NoProfile", "-Command", "Start-MpScan -ScanType FullScan").Start()
fmt.Println("  \033[32m[✔] Full Scan lanzado en segundo plano.\033[0m")
core.PauseEnter("")
case "5":
cwd, _ := os.Getwd()
fmt.Printf("\n  \033[36m[*] Agregando exclusión en Defender para: %s\033[0m\n", cwd)
_, err := core.RunPowerShellCmd(fmt.Sprintf("Add-MpPreference -ExclusionPath '%s'", cwd))
if err != nil {
fmt.Printf("  \033[31m[!] No se pudo agregar exclusión: %v\033[0m\n", err)
} else {
fmt.Println("  \033[32m[✔] Carpeta excluida exitosamente.\033[0m")
}
core.PauseEnter("")
case "6":
fmt.Println("\n  \033[36m[*] Consultando estado de Microsoft Defender...\033[0m\n")
out, _ := core.RunPowerShellCmd("Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled, IoavProtectionEnabled, AntivirusSignatureVersion | Format-List")
fmt.Println(out)
core.PauseEnter("")
}
}
}

func InvokeAutoFlow() {
core.ShowBanner()
fmt.Println("\n\033[44;37m ⚡ AUTO-FLOW EXPRESS (MANTENIMIENTO DESATENDIDO) \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  Este proceso ejecutará de forma automática y secuencial:")
fmt.Println("    1. Purga de temporales de usuario y Windows")
fmt.Println("    2. Comprobación y reparación rápida de caché DNS")
fmt.Println("    3. Limpieza de miniaturas y volcados residuales")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")

confirm := core.ReadMenuOption("  ¿Desea iniciar Auto-Flow? (S/N):", []string{"S", "N"}, "N")
if confirm == "S" {
fmt.Println("\n  \033[36m[*] [Paso 1/2] Limpiando archivos temporales...\033[0m")
userTemp := os.Getenv("TEMP")
_, _ = purgeDirectory(userTemp)
_, _ = purgeDirectory(`C:\Windows\Temp`)

fmt.Println("  \033[36m[*] [Paso 2/2] Vaciando DNS y caché de red...\033[0m")
_ = exec.Command("ipconfig", "/flushdns").Run()

fmt.Println("\n  \033[32m[✔] Mantenimiento Auto-Flow finalizado con éxito.\033[0m")
core.PauseEnter("")
}
}