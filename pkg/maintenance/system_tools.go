package maintenance

import (
"bufio"
"fmt"
"os"
"os/exec"
"path/filepath"
"strconv"
"strings"
"time"
"techflow/pkg/apps"
"techflow/pkg/core"
)

func InvokeWinUtilTitus() {
core.ShowBanner()
fmt.Println("\n \033[36m🛠️ CHRIS TITUS TECH WINDOWS UTILITY\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" Se descargara y ejecutara la utilidad oficial de Chris Titus Tech.")

confirm := core.ReadMenuOption("\n ¿Desea continuar? (S/N):", []string{"S", "N"}, "N")
if confirm != "S" {
return
}

fmt.Println("\n\033[32m[+] Ejecutando irm https://christitus.com/win | iex ...\033[0m")
cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm https://christitus.com/win | iex")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
cmd.Stdin = os.Stdin
_ = cmd.Run()
core.PauseEnter("")
}

func InvokeUserManagement() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m👥 GESTION DE USUARIOS\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" 👤 Usuarios locales")
fmt.Println("  📋 [A] LISTAR USUARIOS")
fmt.Println("  ➕ [B] CREAR LOCAL ADMIN")
fmt.Println("  ❌ [C] ELIMINAR USUARIO")
		fmt.Println()
fmt.Println(" 👑 Super Administrador")
fmt.Println("  ✅ [D] ACTIVAR SUPER ADMIN (net user administrador /active:yes)")
fmt.Println("  ⛔ [E] DESACTIVAR SUPER ADMIN (net user administrador /active:no)")
fmt.Println("  🔑 [F] CAMBIAR PASSWORD")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"A", "B", "C", "D", "E", "F", "X"}, "")
if opt == "X" {
break
}

switch opt {
case "A":
core.ShowBanner()
fmt.Println("\n\033[32m[+] Lista de usuarios del sistema:\033[0m")
out, _ := core.RunPowerShellCmd("net user")
fmt.Println(out)
core.PauseEnter("")
case "B":
name := core.ReadMenuOption("\n Nombre del nuevo usuario Administrador:", nil, "")
if name != "" {
core.RunPowerShellCmd(fmt.Sprintf(`net user "%s" /add; net localgroup administrators "%s" /add`, name, name))
fmt.Printf("\n \033[32m[✔] Usuario admin '%s' creado con exito.\033[0m\n", name)
core.PauseEnter("")
}
case "C":
name := core.ReadMenuOption("\n Nombre del usuario a eliminar:", nil, "")
if name != "" {
confirm := core.ReadMenuOption(fmt.Sprintf(" ¿CONFIRMA eliminar a '%s'? (S/N):", name), []string{"S", "N"}, "N")
if confirm == "S" {
core.RunPowerShellCmd(fmt.Sprintf(`net user "%s" /delete`, name))
fmt.Printf("\n \033[32m[✔] Usuario '%s' eliminado.\033[0m\n", name)
core.PauseEnter("")
}
}
case "D":
fmt.Println("\n\033[32m[+] Activando cuenta de Super Administrador integrada...\033[0m")
core.RunPowerShellCmd("net user administrador /active:yes; net user administrator /active:yes")
fmt.Println(" \033[32m[✔] Cuenta de Administrador activada.\033[0m")
core.PauseEnter("")
case "E":
fmt.Println("\n\033[33m[+] Desactivando cuenta de Super Administrador integrada...\033[0m")
core.RunPowerShellCmd("net user administrador /active:no; net user administrator /active:no")
fmt.Println(" \033[32m[✔] Cuenta de Administrador desactivada.\033[0m")
core.PauseEnter("")
case "F":
name := core.ReadMenuOption("\n Ingrese el nombre del usuario:", nil, "")
pass := core.ReadMenuOption(" Ingrese la nueva clave:", nil, "")
if name != "" && pass != "" {
core.RunPowerShellCmd(fmt.Sprintf(`net user "%s" "%s"`, name, pass))
fmt.Println("\n \033[32m[✔] Contraseña actualizada correctamente.\033[0m")
core.PauseEnter("")
}
}
}
}

func InvokeNetworkRepair() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m🌐 RED Y REPARACIÓN DE CONECTIVIDAD\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" 🔄 [1] LIMPIAR CACHE DNS (ipconfig /flushdns)")
fmt.Println(" 🛠️ [2] REINICIAR WINSOCK Y PROTOCOLO TCP/IP")
fmt.Println(" ⚡ [3] LIBERAR Y RENOVAR DIRECCION IP")
fmt.Println(" 📡 [4] TEST DE CONECTIVIDAD (PING A CLOUDFLARE 1.1.1.1)")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"1", "2", "3", "4", "X"}, "")
if opt == "X" {
break
}

switch opt {
case "1":
fmt.Println("\n\033[33m[+] Vaciando cache de resolucion DNS...\033[0m")
cmd := exec.Command("ipconfig", "/flushdns")
cmd.Stdout = os.Stdout
_ = cmd.Run()
core.PauseEnter("")
case "2":
fmt.Println("\n\033[33m[+] Restableciendo catálogo de Winsock e interfaz IPv4...\033[0m")
_ = exec.Command("netsh", "winsock", "reset").Run()
_ = exec.Command("netsh", "int", "ip", "reset").Run()
fmt.Println(" \033[32m[✔] Winsock e IP restablecidos. Reinicio recomendado.\033[0m")
core.PauseEnter("")
case "3":
fmt.Println("\n\033[33m[+] Renovando configuracion DHCP...\033[0m")
_ = exec.Command("ipconfig", "/release").Run()
cmd := exec.Command("ipconfig", "/renew")
cmd.Stdout = os.Stdout
_ = cmd.Run()
core.PauseEnter("")
case "4":
fmt.Println("\n\033[32m[+] Realizando ping continuo a 1.1.1.1...\033[0m")
cmd := exec.Command("ping", "1.1.1.1", "-n", "4")
cmd.Stdout = os.Stdout
_ = cmd.Run()
core.PauseEnter("")
}
}
}

func InvokeDiskMaintenance() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m💾 MANTENIMIENTO DE DISCO Y PARTICIONES\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" 🔍 [1] VERIFICAR Y REPARAR UNIDAD C: (CHKDSK)")
fmt.Println(" 🧽 [2] OPTIMIZAR Y DESFRAGMENTAR UNIDADES (DEFRAG)")
fmt.Println(" 📊 [3] VER INFORMACION S.M.A.R.T. Y ESTADO FISICO")
fmt.Println(" 🛠️ [4] ABRIR GESTION DE DISCOS GRAFICO (diskmgmt.msc)")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"1", "2", "3", "4", "X"}, "")
if opt == "X" {
break
}

switch opt {
case "1":
fmt.Println("\n\033[33m[+] Ejecutando CHKDSK C: en modo solo lectura...\033[0m")
cmd := exec.Command("chkdsk", "C:")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
core.PauseEnter("")
case "2":
fmt.Println("\n\033[32m[+] Optimizando volumenes de almacenamiento...\033[0m")
cmd := exec.Command("defrag", "C:", "/O", "/U")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
core.PauseEnter("")
case "3":
core.ShowBanner()
fmt.Println("\n\033[36m📊 ESTADO FISICO DE DISCOS:\033[0m")
out, _ := core.RunPowerShellCmd("Get-PhysicalDisk | Format-Table -AutoSize DeviceId, FriendlyName, MediaType, HealthStatus, Size")
fmt.Println(out)
core.PauseEnter("")
case "4":
_ = exec.Command("diskmgmt.msc").Start()
core.PauseEnter("ENTER para volver")
}
}
}

func ShowLiveMonitor() {
reader := bufio.NewReader(os.Stdin)
for {
core.ShowBanner()
fmt.Println("\n \033[36m📊 MONITOR EN VIVO Y GESTIÓN DE TAREAS\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")

psCmd := `
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
Write-Host " CPU: $cpu % | RAM LIBRE: $freeGB GB de $totalGB GB" -ForegroundColor Green
Write-Host "` + "`n" + `TOP PROCESOS (POR CONSUMO DE MEMORIA):" -ForegroundColor Cyan
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 8 | Format-Table -AutoSize Id, ProcessName, @{Name="Memoria (MB)"; Expression={[math]::Round($_.WorkingSet/1MB,1)}}
`
out, _ := core.RunPowerShellCmd(psCmd)
fmt.Println(out)

fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" [K] Finalizar proceso (PID)     [P] Process Lasso (App)")
fmt.Println(" [E] Everything Search (App)     [R] Refrescar     [X] Salir")
fmt.Print("\n > Acción: ")

input, _ := reader.ReadString('\n')
action := strings.ToUpper(strings.TrimSpace(input))

if action == "X" {
break
} else if action == "K" {
fmt.Print(" Ingrese PID a finalizar: ")
pidStr, _ := reader.ReadString('\n')
pidStr = strings.TrimSpace(pidStr)
if pid, err := strconv.Atoi(pidStr); err == nil {
core.RunPowerShellCmd(fmt.Sprintf("Stop-Process -Id %d -Force", pid))
fmt.Printf("\033[32m[✔] Proceso %d finalizado.\033[0m\n", pid)
time.Sleep(1 * time.Second)
}
} else if action == "P" {
if _, err := exec.LookPath("processlasso"); err != nil {
apps.InvokeSmartInstall("Bitsum.ProcessLasso", "Process Lasso", "processlasso")
}
_ = exec.Command("processlasso").Start()
} else if action == "E" {
if _, err := exec.LookPath("everything"); err != nil {
apps.InvokeSmartInstall("voidtools.Everything", "Everything", "everything")
}
_ = exec.Command("everything").Start()
}
}
}

func InvokeAutoFlow() {
core.ShowBanner()
fmt.Println("\n \033[33m⚡ AUTO-FLOW: MANTENIMIENTO EXPRESS AUTOMATIZADO\033[0m")
fmt.Println(" ---------------------------------------------------")
fmt.Println(" 🧹 1. Elimina Apps basura (Netflix, Disney, TikTok, etc.)")
fmt.Println(" 🗑️ 2. Limpia archivos temporales del sistema y usuario")
fmt.Println(" 📦 3. Instala Apps esenciales (Chrome, 7-Zip, VLC, WinRAR)")
fmt.Println(" ---------------------------------------------------")

confirm := core.ReadMenuOption("\n ¿Iniciar AUTO-FLOW ahora? (S/N):", []string{"S", "N"}, "N")
if confirm != "S" {
return
}

fmt.Println("\n\033[36m[>] Eliminando Bloatware...\033[0m")
bloatScript := `
$bloat = @("*CandyCrush*", "*Disney*", "*Netflix*", "*TikTok*", "*Instagram*")
foreach($b in $bloat){ Get-AppxPackage $b | Remove-AppxPackage -ErrorAction SilentlyContinue }
`
core.RunPowerShellCmd(bloatScript)

fmt.Println("\033[36m[>] Limpiando archivos temporales...\033[0m")
cleanDirectory(os.Getenv("TEMP"), false)
cleanDirectory(filepath.Join(os.Getenv("SystemRoot"), "Temp"), false)

fmt.Println("\033[36m[>] Desplegando software esencial...\033[0m")
baseApps := []struct {
id, name, choco string
}{
{"Google.Chrome", "Google Chrome", "googlechrome"},
{"7zip.7zip", "7-Zip", "7zip"},
{"VideoLAN.VLC", "VLC Media Player", "vlc"},
{"RARLab.WinRAR", "WinRAR", "winrar"},
}

for _, app := range baseApps {
apps.InvokeSmartInstall(app.id, app.name, app.choco)
}

fmt.Println("\n \033[32m[✔] AUTO-FLOW FINALIZADO CON ÉXITO.\033[0m")
core.PauseEnter("")
}

func InvokeRemoteDesktop() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m🖥️ ESCRITORIO REMOTO Y CONEXIONES\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" 🖥️ [1] ESCRITORIO REMOTO DE WINDOWS (mstsc.exe)")
fmt.Println(" 🚀 [2] ANYDESK (Ejecucion o instalacion)")
fmt.Println(" 🔓 [3] RUSTDESK (Open source)")
fmt.Println(" 👁️ [4] TEAMVIEWER")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"1", "2", "3", "4", "X"}, "")
if opt == "X" {
break
}

switch opt {
case "1":
_ = exec.Command("mstsc.exe").Start()
case "2":
if _, err := exec.LookPath("anydesk"); err != nil {
apps.InvokeSmartInstall("AnyDesk.AnyDesk", "AnyDesk", "anydesk")
}
_ = exec.Command("anydesk").Start()
case "3":
if _, err := exec.LookPath("rustdesk"); err != nil {
apps.InvokeSmartInstall("RustDesk.RustDesk", "RustDesk", "rustdesk")
}
_ = exec.Command("rustdesk").Start()
case "4":
if _, err := exec.LookPath("teamviewer"); err != nil {
apps.InvokeSmartInstall("TeamViewer.TeamViewer", "TeamViewer", "teamviewer")
}
_ = exec.Command("teamviewer").Start()
}
}
}

