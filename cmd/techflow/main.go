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
fmt.Println("\n  \033[44;37m 🛠️  SOPORTE TÉCNICO PRO - DIAGNÓSTICO Y REPARACIÓN \033[0m")
fmt.Println("  \033[36m═══════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[A] SALUD FÍSICA DISCOS        \033[0m - Telemetría S.M.A.R.T. y estado NVMe/SSD/HDD")
fmt.Println("  \033[36m[B] REPARAR SISTEMA (SFC+DISM) \033[0m - Reparación profunda de imagen y archivos")
fmt.Println("  \033[36m[C] CLAVE LICENCIA BIOS (OEM)  \033[0m - Recuperar clave original embebida en placa")
fmt.Println("  \033[36m[D] SINCRONIZAR RELOJ OFICIAL  \033[0m - Forzar servicio w32time NTP")
fmt.Println("  \033[36m[E] REINICIAR A BIOS / UEFI    \033[0m - Reinicio directo al firmware sin teclas")
fmt.Println("  \033[36m[F] SALUD DE BATERÍA           \033[0m - Capacidad de diseño vs carga completa")
fmt.Println("  \033[36m[G] INFO TÉCNICA COMPLETA      \033[0m - Inventario detallado de Hardware y Software")
fmt.Println("  \033[36m[H] VISOR EVENTOS CRÍTICOS     \033[0m - Últimos 10 errores graves / BSOD del sistema")
fmt.Println("  \033[36m[I] CHECKDISK EN LÍNEA (C:)    \033[0m - Auditar errores de disco sin reiniciar")
fmt.Println("  \033[36m[J] RESET PILA DE RED Y DNS    \033[0m - Restablecer Winsock, TCP/IP y FlushDNS")
fmt.Println("  \033[36m[T] TEMPERATURAS Y SENSORES    \033[0m - Lectura térmica de CPU y placa")
fmt.Println("  \033[36m[Z] MODO DIOS (GOD MODE)       \033[0m - Panel maestro con +200 ajustes de Windows")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
fmt.Println("  \033[36m═══════════════════════════════════════════════════════════════════════════\033[0m")

opt := core.ReadMenuOption("\n  \033[32m> SELECCIONE:\033[0m", []string{"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "T", "Z", "X"}, "")
if opt == "" {
continue
}
if opt == "X" {
break
}

switch opt {
case "A":
fmt.Println("\n  \033[36m[*] Consultando salud física de unidades...\033[0m\n")
out, _ := core.RunPowerShellCmd(`Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, @{N='SizeGB';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize`)
fmt.Println(out)
core.PauseEnter("")
case "B":
fmt.Println("\n  \033[32m[+] Ejecutando reparación integral SFC + DISM...\033[0m")
_, _ = core.RunPowerShellCmd("dism /online /cleanup-image /restorehealth; sfc /scannow")
core.PauseEnter("")
case "C":
out, _ := core.RunPowerShellCmd("(Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey")
fmt.Printf("\n  \033[32m[+] Clave BIOS OEM encontrada: %s\033[0m\n", out)
core.PauseEnter("")
case "D":
fmt.Println("\n  \033[32m[+] Sincronizando hora con servidor oficial...\033[0m")
_, _ = core.RunPowerShellCmd("net stop w32time; net start w32time; w32tm /resync /force")
core.PauseEnter("")
case "E":
confirm := core.ReadMenuOption("  ¿Reiniciar ahora mismo directamente hacia BIOS/UEFI? (S/N):", []string{"S", "N"}, "N")
if confirm == "S" {
_, _ = core.RunPowerShellCmd("shutdown /r /fw /t 0")
}
case "F":
hardware.ShowBatteryHealth()
case "G":
hardware.ShowSystemInfo()
case "H":
fmt.Println("\n  \033[36m[*] Últimos 10 eventos críticos o errores graves del sistema:\033[0m\n")
out, _ := core.RunPowerShellCmd(`Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName, @{N='Mensaje';E={($_.Message -split "\r?\n")[0]}} | Format-Table -AutoSize`)
fmt.Println(out)
core.PauseEnter("")
case "I":
fmt.Println("\n  \033[36m[*] Ejecutando CHKDSK C: /scan (auditoría en línea)...\033[0m\n")
out, _ := core.RunPowerShellCmd("chkdsk C: /scan")
fmt.Println(out)
core.PauseEnter("")
case "J":
fmt.Println("\n  \033[36m[*] Restableciendo Winsock, IP y caché DNS...\033[0m")
_, _ = core.RunPowerShellCmd("netsh winsock reset; netsh int ip reset; ipconfig /flushdns")
fmt.Println("  \033[32m[✔] Pila de red restablecida.\033[0m")
core.PauseEnter("")
case "T":
hardware.ShowTemperatures()
case "Z":
_, _ = core.RunPowerShellCmd("Start-Process 'explorer.exe' 'shell:::{ED7BA470-8E54-465E-825C-99712043E01C}'")
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
maintenance.ShowOfficeActivationHub()
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
