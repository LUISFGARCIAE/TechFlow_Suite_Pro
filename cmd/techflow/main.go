package main

import (
"fmt"
"os"
"os/user"
"strings"
"time"
"techflow/pkg/apps"
"techflow/pkg/backup"
"techflow/pkg/core"
"techflow/pkg/devtools"
"techflow/pkg/hardware"
"techflow/pkg/maintenance"
"techflow/pkg/media"
)

var menuHorizontal = true

func getUsername() string {
u, err := user.Current()
if err != nil {
return os.Getenv("USERNAME")
}
parts := strings.Split(u.Username, "\\")
return parts[len(parts)-1]
}

func showMainMenu() {
core.ShowBanner()

horaActual := time.Now().Format("15:04:05")
vistaStr := "HORIZONTAL"
if !menuHorizontal {
vistaStr = "VERTICAL"
}
userName := getUsername()

fmt.Printf("\n \033[32m✅ SISTEMA OK | 👤 USUARIO %s | 🖥️ VISTA %s | ⏰ HORA: %s\033[0m\n", userName, vistaStr, horaActual)
fmt.Println(" \033[90m-----------------------------------------------------------------------------\033[0m")

if menuHorizontal {
fmt.Println(" \033[32m   💾 [A]  BACKUP TOTAL             🧹 [E]  OPTIMIZAR TEMP           📦 [I]  KIT POST FORMAT\033[0m")
fmt.Println(" \033[32m   📀 [B]  RESTORE TOTAL            🛠️ [F]  WIN UTIL TITUS           👥 [J]  GESTION USUARIOS\033[0m")
fmt.Println(" \033[32m   🔧 [C]  GESTION DRIVERS          🔑 [G]  MICROSOFT OFFICE AIO     🛠️ [K]  SOPORTE TECNICO PRO\033[0m")
fmt.Println(" \033[32m   🧹 [D]  PURGA Y FORMATEO         📦 [H]  GESTION PAQUETES PRO     🚀 [L]  BYPASS WINDOWS 11\033[0m")
fmt.Println(" \033[32m   🌐 [M]  RED Y REPARACION         💾 [N]  MANTENIM DISCO           📊 [O]  MONITOR EN VIVO (PRO)\033[0m")
fmt.Println(" \033[32m   🛡️ [P]  WINDOWS DEFENDER TOTAL   ⚡ [Q]  AUTO-FLOW (EXPRESS)      🛠️ [U]  SYSINTERNALS KIT\033[0m")
fmt.Println(" \033[32m   🖥️ [T]  ESCRITORIO REMOTO        🔐 [Y]  GENERADOR CONTRASEÑAS    🎵 [Z]  CENTRO DESCARGAS (yt-dlp)\033[0m")
} else {
fmt.Println(" \033[32m   💾 [A] BACKUP TOTAL\033[0m")
fmt.Println(" \033[32m   📀 [B] RESTORE TOTAL\033[0m")
fmt.Println(" \033[32m   🔧 [C] GESTION DRIVERS\033[0m")
fmt.Println(" \033[32m   🧹 [D] PURGA Y FORMATEO\033[0m")
fmt.Println(" \033[32m   🧹 [E] OPTIMIZAR TEMP\033[0m")
fmt.Println(" \033[32m   🛠️ [F] WIN UTIL TITUS\033[0m")
fmt.Println(" \033[32m   🔑 [G] MICROSOFT OFFICE AIO\033[0m")
fmt.Println(" \033[32m   📦 [H] GESTION PAQUETES PRO\033[0m")
fmt.Println(" \033[32m   📦 [I] KIT POST FORMAT\033[0m")
fmt.Println(" \033[32m   👥 [J] GESTION USUARIOS\033[0m")
fmt.Println(" \033[32m   🛠️ [K] SOPORTE TECNICO PRO\033[0m")
fmt.Println(" \033[32m   🚀 [L] BYPASS WINDOWS 11\033[0m")
fmt.Println(" \033[32m   🌐 [M] RED Y REPARACION\033[0m")
fmt.Println(" \033[32m   💾 [N] MANTENIM DISCO\033[0m")
fmt.Println(" \033[32m   📊 [O] MONITOR EN VIVO (PRO)\033[0m")
fmt.Println(" \033[32m   🛡️ [P] WINDOWS DEFENDER TOTAL\033[0m")
fmt.Println(" \033[32m   ⚡ [Q] AUTO-FLOW (MANTENIMIENTO EXPRESS)\033[0m")
fmt.Println(" \033[32m   🖥️ [T] ESCRITORIO REMOTO\033[0m")
fmt.Println(" \033[32m   🛠️ [U] SYSINTERNALS KIT (11 herramientas)\033[0m")
fmt.Println(" \033[32m   🔐 [Y] GENERADOR CONTRASEÑAS\033[0m")
fmt.Println(" \033[32m   🎵 [Z] CENTRO DESCARGAS (yt-dlp)\033[0m")
}

fmt.Println("\n \033[90m⚙️ CONFIGURACION Y VISTA\033[0m")
fmt.Println(" \033[36m -----------------------------------------------------------------------------\033[0m")
fmt.Println(" \033[36m   🔄 [R] REFRESCAR MENU            🖥️ [V] CAMBIAR VISTA (V)\033[0m")
fmt.Println(" \033[31m   ❌ [X] SALIR DEL SCRIPT\033[0m")
}

func showSubmenuK() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m🛠️ SOPORTE TECNICO PRO\033[0m")
fmt.Println(" 💾 [A] SALUD DISCO")
fmt.Println(" 🔧 [B] REPARAR SISTEMA (SFC + DISM)")
fmt.Println(" 🔑 [C] CLAVE BIOS - Recupera la licencia original del equipo.")
fmt.Println(" ⏰ [D] SINCRONIZAR HORA")
fmt.Println(" 🔋 [F] SALUD DE BATERIA")
fmt.Println(" 🌡️ [T] TEMPERATURAS CPU/GPU - Monitoreo en tiempo real")
fmt.Println(" ℹ️ [G] INFO TECNICA COMPLETA (HW/SW)")
fmt.Println(" ⚡ [Z] MODO DIOS - Todos los accesos de configuracion")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n >", []string{"A", "B", "C", "D", "F", "T", "G", "Z", "X"}, "")
if opt == "X" {
break
}

switch opt {
case "A":
hardware.ShowTemperatures()
case "B":
fmt.Println("\n\033[32m[+] Ejecutando reparacion de sistema...\033[0m")
core.RunPowerShellCmd("sfc /scannow; dism /online /cleanup-image /restorehealth")
core.PauseEnter("")
case "C":
out, _ := core.RunPowerShellCmd("(Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey")
fmt.Printf("\n\033[32m[+] Clave BIOS encontrada: %s\033[0m\n", out)
core.PauseEnter("")
case "D":
fmt.Println("\n\033[32m[+] Sincronizando hora con servidor oficial...\033[0m")
core.RunPowerShellCmd("net stop w32time; net start w32time; w32tm /resync /force")
core.PauseEnter("")
case "F":
hardware.ShowBatteryHealth()
case "T":
hardware.ShowTemperatures()
case "G":
hardware.ShowSystemInfo()
case "Z":
core.RunPowerShellCmd("Start-Process 'explorer.exe' 'shell:::{ED7BA470-8E54-465E-825C-99712043E01C}'")
core.PauseEnter("ENTER para volver")
}
}
}

func main() {
core.EnsureAdmin()
core.RunStartupSequence()

validKeys := []string{
"A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
"K", "L", "M", "N", "O", "P", "Q", "T", "U", "Y",
"Z", "R", "V", "X",
}

for {
showMainMenu()

// Requiere confirmación explícita con ENTER
opt := core.ReadMenuOption("\n > OPCION:", validKeys, "")
if opt == "" {
continue
}

switch opt {
case "R":
continue
case "V":
menuHorizontal = !menuHorizontal
continue
case "A":
backup.InvokeBackup()
case "B":
backup.InvokeRestore()
case "C":
hardware.InvokeDriverManagement()
case "D":
maintenance.ShowDiagnosticMenu()
case "E":
maintenance.InvokeTempOptimizer()
case "F":
maintenance.InvokeWinUtilTitus()
case "G":
maintenance.InvokeMassGraveIntegrated()
case "H":
apps.InvokeWingetMenu()
case "I":
apps.InvokeKitPostFormat()
case "J":
maintenance.InvokeUserManagement()
case "K":
showSubmenuK()
case "L":
maintenance.InvokeBypassWin11()
case "M":
maintenance.InvokeNetworkRepair()
case "N":
maintenance.InvokeDiskMaintenance()
case "O":
maintenance.ShowLiveMonitor()
case "P":
maintenance.InvokeDefenderControl()
case "Q":
maintenance.InvokeAutoFlow()
case "T":
maintenance.InvokeRemoteDesktop()
case "U":
devtools.InvokeSysinternalsKit()
case "Y":
hardware.InvokePasswordGenerator()
case "Z":
media.InvokeDownloadCenter()
case "X":
os.Exit(0)
}
}
}
