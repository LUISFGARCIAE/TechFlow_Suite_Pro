package maintenance

import (
"fmt"
"os"
"os/exec"
"path/filepath"
"techflow/pkg/core"
)

func runCLI(name string, args ...string) {
cmd := exec.Command(name, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
}

// ShowDiagnosticMenu corresponde a [D] PURGA Y FORMATEO / INTEGRIDAD
func ShowDiagnosticMenu() {
validKeys := []string{"1", "2", "3", "4", "5", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 🩺 HERRAMIENTAS DE INTEGRIDAD Y REPARACIÓN DEL SISTEMA \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] REPARAR IMAGEN WINDOWS     \033[0m - Restaurar almacén de componentes (DISM)")
fmt.Println("  \033[36m[2] INTEGRIDAD DE ARCHIVOS     \033[0m - Escanear y reparar sistema (SFC /scannow)")
fmt.Println("  \033[36m[3] REINICIAR PILA DE RED      \033[0m - Reset Winsock, TCP/IP y FlushDNS")
fmt.Println("  \033[36m[4] SINCRONIZAR HORA NTP       \033[0m - Forzar reloj oficial de Windows (w32tm)")
fmt.Println("  \033[36m[5] CHECKDISK EN LÍNEA (C:)    \033[0m - Auditar errores de disco sin reiniciar")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
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
fmt.Println("\n  \033[36m[*] Ejecutando DISM /Online /Cleanup-Image /RestoreHealth...\033[0m")
runCLI("dism", "/online", "/cleanup-image", "/restorehealth")
core.PauseEnter("")
case "2":
fmt.Println("\n  \033[36m[*] Ejecutando SFC /scannow...\033[0m")
runCLI("sfc", "/scannow")
core.PauseEnter("")
case "3":
fmt.Println("\n  \033[36m[*] Restableciendo sockets, IP y limpiando caché DNS...\033[0m")
runCLI("netsh", "winsock", "reset")
runCLI("netsh", "int", "ip", "reset")
runCLI("ipconfig", "/flushdns")
fmt.Println("\n  \033[32m[✔] Conectividad y adaptadores de red restablecidos.\033[0m")
core.PauseEnter("")
case "4":
fmt.Println("\n  \033[36m[*] Forzando sincronización con servidor de hora oficial...\033[0m")
runCLI("w32tm", "/resync")
core.PauseEnter("")
case "5":
fmt.Println("\n  \033[36m[*] Ejecutando CHKDSK C: /scan (auditoría en línea sin reinicio)...\033[0m\n")
runCLI("chkdsk", "C:", "/scan")
core.PauseEnter("")
}
}
}

// InvokeBypassWin11 corresponde a [L] BYPASS WINDOWS 11
func InvokeBypassWin11() {
validKeys := []string{"1", "2", "3", "4", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 🚀 BYPASS WINDOWS 11 - REQUISITOS Y CONFIGURACIÓN OOBE \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] BYPASS TPM / RAM / CPU     \033[0m - Parchear registro LabConfig y AllowUpgrades")
fmt.Println("  \033[36m[2] BYPASS CUENTA MICROSOFT    \033[0m - Habilitar creación de cuenta local (OOBE)")
fmt.Println("  \033[36m[3] RESTAURAR MENÚ CLÁSICO W10 \033[0m - Quitar menú contextual colapsado de Win11")
fmt.Println("  \033[36m[4] VERIFICAR COMPATIBILIDAD   \033[0m - Auditar estado de TPM, SecureBoot y UEFI")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
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
fmt.Println("\n  \033[36m[*] Aplicando claves de registro LabConfig (TPM, SecureBoot, RAM, CPU)...\033[0m")
ps := `
New-Item -Path "HKLM:\SYSTEM\Setup\LabConfig" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassTPMCheck" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassSecureBootCheck" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassRAMCheck" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassCPUCheck" -Value 1 -PropertyType DWord -Force | Out-Null
New-Item -Path "HKLM:\SYSTEM\Setup\MoSetup" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -PropertyType DWord -Force | Out-Null
`
_, _ = core.RunPowerShellCmd(ps)
fmt.Println("  \033[32m[✔] Bypass de hardware aplicado correctamente.\033[0m")
core.PauseEnter("")
case "2":
fmt.Println("\n  \033[36m[*] Habilitando modo BypassNRO para cuentas locales sin red...\033[0m")
_, _ = core.RunPowerShellCmd(`New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "BypassNRO" -Value 1 -PropertyType DWord -Force | Out-Null`)
fmt.Println("  \033[32m[✔] BypassNRO configurado.\033[0m")
core.PauseEnter("")
case "3":
fmt.Println("\n  \033[36m[*] Restaurando menú contextual clásico de Windows 10...\033[0m")
_, _ = core.RunPowerShellCmd(`reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve`)
fmt.Println("  \033[32m[✔] Menú clásico aplicado (reinicia el Explorador para ver cambios).\033[0m")
core.PauseEnter("")
case "4":
fmt.Println("\n  \033[36m[*] Auditando TPM y arranque seguro...\033[0m\n")
out, _ := core.RunPowerShellCmd("Get-Tpm | Select-Object TpmPresent, TpmReady, TpmEnabled | Format-List; Confirm-SecureBootUEFI")
fmt.Println(out)
core.PauseEnter("")
}
}
}

// InvokeNetworkRepair corresponde a [M] RED Y REPARACION
func InvokeNetworkRepair() {
validKeys := []string{"1", "2", "3", "4", "5", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 🌐 RED Y REPARACIÓN - CONECTIVIDAD Y DIAGNÓSTICO \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] RESET INTEGRAL DE RED      \033[0m - Winsock, IP, Release/Renew y FlushDNS")
fmt.Println("  \033[36m[2] APLICAR DNS CLOUDFLARE     \033[0m - Configurar 1.1.1.1 / 1.0.0.1 en adaptadores")
fmt.Println("  \033[36m[3] AUDITORÍA IP Y ADAPTADORES \033[0m - Ver IPv4, Puerta de Enlace, MAC y DNS")
fmt.Println("  \033[36m[4] TEST DE LATENCIA (1.1.1.1) \033[0m - Prueba de ping rápido a Cloudflare e Internet")
fmt.Println("  \033[36m[5] VER CLAVES WIFI GUARDADAS  \033[0m - Extraer perfiles WiFi y contraseñas")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
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
fmt.Println("\n  \033[36m[*] Ejecutando limpieza y reinicio de pila TCP/IP...\033[0m")
runCLI("ipconfig", "/flushdns")
runCLI("netsh", "winsock", "reset")
runCLI("netsh", "int", "ip", "reset")
runCLI("ipconfig", "/release")
runCLI("ipconfig", "/renew")
fmt.Println("\n  \033[32m[✔] Pila de red restaurada.\033[0m")
core.PauseEnter("")
case "2":
fmt.Println("\n  \033[36m[*] Configurando DNS Cloudflare (1.1.1.1 / 1.0.0.1) en interfaces activas...\033[0m")
_, _ = core.RunPowerShellCmd(`Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Set-DnsClientServerAddress -ServerAddresses ("1.1.1.1","1.0.0.1")`)
runCLI("ipconfig", "/flushdns")
fmt.Println("  \033[32m[✔] DNS 1.1.1.1 asignado correctamente.\033[0m")
core.PauseEnter("")
case "3":
fmt.Println("\n  \033[36m[*] Estado de interfaces activas:\033[0m\n")
out, _ := core.RunPowerShellCmd(`Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-List`)
fmt.Println(out)
core.PauseEnter("")
case "4":
fmt.Println("\n  \033[36m[*] Probando conectividad y latencia hacia 1.1.1.1...\033[0m\n")
runCLI("ping", "-n", "4", "1.1.1.1")
core.PauseEnter("")
case "5":
fmt.Println("\n  \033[36m[*] Perfiles Wi-Fi y claves almacenadas en el equipo:\033[0m\n")
ps := `
$profiles = netsh wlan show profiles | Select-String ":\s+(.+)$" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
foreach ($p in $profiles) {
    $key = (netsh wlan show profile name="$p" key=clear | Select-String "Contenido de la clave|Key Content") -replace '.*:\s*', ''
    [PSCustomObject]@{ Red_SSID = $p; Clave = if ($key) { $key } else { "(Sin clave / Abierta)" } }
} | Format-Table -AutoSize
`
out, _ := core.RunPowerShellCmd(ps)
fmt.Println(out)
core.PauseEnter("")
}
}
}

// InvokeDiskMaintenance corresponde a [N] MANTENIM DISCO
func InvokeDiskMaintenance() {
validKeys := []string{"1", "2", "3", "4", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 💾 MANTENIMIENTO Y SALUD DE DISCOS (SSD / HDD) \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] SALUD S.M.A.R.T. Y DESGASTE\033[0m - Auditar temperatura, errores y estado físico")
fmt.Println("  \033[36m[2] OPTIMIZAR SSD (RETRIM)     \033[0m - Ejecutar TRIM en unidades de estado sólido")
fmt.Println("  \033[36m[3] AUDITORÍA DE PARTICIONES   \033[0m - Ver volúmenes, formato, tamaño y espacio libre")
fmt.Println("  \033[36m[4] ADMINISTRACIÓN DE DISCOS   \033[0m - Abrir consola gráfica (diskmgmt.msc)")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
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
fmt.Println("\n  \033[36m[*] Consultando telemetría física de almacenamiento...\033[0m\n")
out, _ := core.RunPowerShellCmd(`Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus, @{N='SizeGB';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize`)
fmt.Println(out)
core.PauseEnter("")
case "2":
fmt.Println("\n  \033[36m[*] Ejecutando ReTrim / Optimización en unidad C:...\033[0m\n")
out, _ := core.RunPowerShellCmd(`Optimize-Volume -DriveLetter C -ReTrim -Verbose`)
fmt.Println(out)
fmt.Println("  \033[32m[✔] Optimización de unidad completada.\033[0m")
core.PauseEnter("")
case "3":
fmt.Println("\n  \033[36m[*] Volúmenes y particiones montadas:\033[0m\n")
out, _ := core.RunPowerShellCmd(`Get-Volume | Where-Object { $_.DriveLetter } | Select-Object DriveLetter, FileSystemLabel, FileSystem, DriveType, @{N='LibreGB';E={[math]::Round($_.SizeRemaining/1GB,1)}}, @{N='TotalGB';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize`)
fmt.Println(out)
core.PauseEnter("")
case "4":
_ = exec.Command("diskmgmt.msc").Start()
}
}
}

// ShowLiveMonitor corresponde a [O] MONITOR EN VIVO (PRO)
func ShowLiveMonitor() {
validKeys := []string{"R", "T", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 📊 MONITOR EN VIVO (PRO) - TELEMETRÍA Y PROCESOS TOP \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

ps := `
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$os = Get-CimInstance Win32_OperatingSystem
$ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$ramFree = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$ramUsed = [math]::Round($ramTotal - $ramFree, 2)
$uptime = (Get-Date) - $os.LastBootUpTime

Write-Host ("  CPU CARGA ACTUAL : {0}%" -f $cpu) -ForegroundColor Cyan
Write-Host ("  MEMORIA RAM      : {0} GB / {1} GB en uso" -f $ramUsed, $ramTotal) -ForegroundColor Green
Write-Host ("  TIEMPO ACTIVO    : {0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes) -ForegroundColor Yellow
Write-Host ""; Write-Host "  TOP 8 PROCESOS POR CONSUMO DE MEMORIA RAM:" -ForegroundColor White
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 8 Name, Id, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}, @{N='CPU_s';E={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize
`
out, _ := core.RunPowerShellCmd(ps)
fmt.Println(out)
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[36m[R] ACTUALIZAR LECTURA   \033[0m | \033[36m[T] ABRIR TASK MANAGER   \033[0m | \033[31m[X] VOLVER\033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

opt := core.ReadMenuOption("\n  \033[32m> SELECCIONE:\033[0m", validKeys, "R")
if opt == "X" {
return
}
if opt == "T" {
_ = exec.Command("taskmgr.exe").Start()
}
}
}

// InvokeRemoteDesktop corresponde a [T] ESCRITORIO REMOTO (PORTABLE)
func InvokeRemoteDesktop() {
validKeys := []string{"1", "2", "3", "4", "X"}
toolsDir := filepath.Join("C:\\TechFlow_Go", "tools_portable")
_ = os.MkdirAll(toolsDir, 0755)

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 🖥️  ESCRITORIO REMOTO Y SOPORTE (EJECUTABLES PORTABLES) \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] RUSTDESK PORTABLE          \033[0m - Descargar/ejecutar cliente portable sin instalar")
fmt.Println("  \033[36m[2] ANYDESK PORTABLE           \033[0m - Descargar/ejecutar AnyDesk.exe portable")
fmt.Println("  \033[36m[3] ASISTENCIA RÁPIDA WIN      \033[0m - Lanzar Quick Assist nativo de Windows")
fmt.Println("  \033[36m[4] CONEXIÓN RDP (MSTSC)       \033[0m - Abrir cliente de Escritorio Remoto Windows")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                     \033[0m - Regresar al Menú Principal")
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
exePath := filepath.Join(toolsDir, "rustdesk-portable.exe")
if _, err := os.Stat(exePath); os.IsNotExist(err) {
fmt.Println("\n  \033[36m[*] Descargando RustDesk Portable oficial desde GitHub...\033[0m")
ps := fmt.Sprintf(`$rel = Invoke-RestMethod "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"; $asset = $rel.assets | Where-Object { $_.name -like "*x86_64.exe" } | Select-Object -First 1; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "%s"`, exePath)
_, _ = core.RunPowerShellCmd(ps)
}
fmt.Println("  \033[32m[✔] Ejecutando RustDesk Portable...\033[0m")
_ = exec.Command(exePath).Start()
core.PauseEnter("")
case "2":
exePath := filepath.Join(toolsDir, "AnyDesk.exe")
if _, err := os.Stat(exePath); os.IsNotExist(err) {
fmt.Println("\n  \033[36m[*] Descargando AnyDesk Portable oficial...\033[0m")
ps := fmt.Sprintf(`Invoke-WebRequest -Uri "https://download.anydesk.com/AnyDesk.exe" -OutFile "%s"`, exePath)
_, _ = core.RunPowerShellCmd(ps)
}
fmt.Println("  \033[32m[✔] Ejecutando AnyDesk Portable...\033[0m")
_ = exec.Command(exePath).Start()
core.PauseEnter("")
case "3":
_ = exec.Command("quickassist.exe").Start()
case "4":
_ = exec.Command("mstsc.exe").Start()
}
}
}