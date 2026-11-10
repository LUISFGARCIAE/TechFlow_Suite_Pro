package maintenance

import (
"fmt"
"os"
"os/exec"
"techflow/pkg/core"
)

// InvokeBypassWin11 replica [L] BYPASS WINDOWS 11
func InvokeBypassWin11() {
for {
core.ShowBanner()
fmt.Println("\n \033[33m🚀 BYPASS WINDOWS 11\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" 🔓 [A] BYPASS HARDWARE   - Omitir TPM, SecureBoot y chequeos de RAM")
fmt.Println(" 🌐 [B] BYPASS INTERNET   - Evitar conexion a Internet durante instalacion (OOBE)")
fmt.Println(" 📊 [C] VER ESTADO ACTUAL - Comprobar claves de registro en LabConfig")
fmt.Println(" 🔄 [D] REVERTIR BYPASS   - Restaurar validaciones por defecto de Windows")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"A", "B", "C", "D", "X"}, "")
if opt == "X" {
break
}

switch opt {
case "A":
fmt.Println("\n\033[32m[+] Aplicando Bypass de Hardware en LabConfig...\033[0m")
psCmd := `
$reg = "HKLM:\System\Setup\LabConfig"
if (-not (Test-Path $reg)) { New-Item $reg -Force | Out-Null }
"BypassTPMCheck","BypassSecureBootCheck","BypassRAMCheck" | ForEach-Object {
New-ItemProperty -Path $reg -Name $_ -Value 1 -PropertyType DWord -Force | Out-Null
}
Write-Host " [✔] Claves aplicadas correctamente en HKLM:\System\Setup\LabConfig" -ForegroundColor Green
`
core.RunPowerShellCmd(psCmd)
core.PauseEnter("")

case "B":
fmt.Println("\n\033[33m[+] Ejecutando bypass de conexion OOBE...\033[0m")
psCmd := `
$cmd = "$env:SystemRoot\System32\oobe\bypassnro.cmd"
if (Test-Path $cmd) {
& $cmd
} else {
Write-Host " [!] El archivo bypassnro.cmd no existe fuera del instalador de Windows." -ForegroundColor Red
}
`
core.RunPowerShellCmd(psCmd)
core.PauseEnter("")

case "C":
core.ShowBanner()
fmt.Println("\n\033[36m📊 ESTADO REGISTRO LabConfig:\033[0m")
psCmd := `
$reg = "HKLM:\System\Setup\LabConfig"
if (Test-Path $reg) {
Get-ItemProperty $reg -ErrorAction SilentlyContinue | Select-Object BypassTPMCheck, BypassSecureBootCheck, BypassRAMCheck | Format-List
} else {
Write-Host " Clave no configurada (No existe HKLM:\System\Setup\LabConfig)" -ForegroundColor Yellow
}
`
out, _ := core.RunPowerShellCmd(psCmd)
fmt.Println(out)
core.PauseEnter("")

case "D":
fmt.Println("\n\033[33m[+] Revirtiendo Bypass de Hardware...\033[0m")
psCmd := `
$reg = "HKLM:\System\Setup\LabConfig"
if (Test-Path $reg) {
"BypassTPMCheck","BypassSecureBootCheck","BypassRAMCheck" | ForEach-Object {
Remove-ItemProperty -Path $reg -Name $_ -ErrorAction SilentlyContinue
}
Write-Host " [✔] Validaciones restauradas a estado original." -ForegroundColor Green
}
`
core.RunPowerShellCmd(psCmd)
core.PauseEnter("")
}
}
}

// InvokeDefenderControl replica [P] WINDOWS DEFENDER TOTAL
func InvokeDefenderControl() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m🛡️ CONTROL TOTAL DE WINDOWS DEFENDER\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println(" ✅ [1] ACTIVAR DEFENDER   - Restaurar proteccion en tiempo real")
fmt.Println(" 🔧 [2] REPARAR DEFENDER   - Eliminar GPO conflictivas y reactivar servicios")
fmt.Println(" ⚡ [R] ESCANEO RAPIDO     - Revision rapida con MpCmdRun")
fmt.Println(" 🔍 [C] ESCANEO COMPLETO   - Revision exhaustiva del sistema")
fmt.Println(" 🔄 [U] ACTUALIZAR FIRMAS  - Descargar ultimas definiciones")
fmt.Println(" 📋 [V] VER AMENAZAS       - Registro historico de detecciones")
fmt.Println(" ⚠️ [4] DESACTIVAR         - Pausar proteccion (Solo entornos de prueba)")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"1", "2", "R", "C", "U", "V", "4", "X"}, "")
if opt == "X" {
break
}

mpCmd := os.Getenv("ProgramFiles") + `\Windows Defender\MpCmdRun.exe`

switch opt {
case "1":
fmt.Println("\n\033[32m[+] Habilitando proteccion de Windows Defender...\033[0m")
psCmd := `
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
Write-Host " [✔] Windows Defender activo." -ForegroundColor Green
`
core.RunPowerShellCmd(psCmd)
core.PauseEnter("")

case "2":
fmt.Println("\n\033[33m[+] Reparando politicas y servicios de Defender...\033[0m")
psCmd := `
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
Remove-ItemProperty -Path $path -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "$path\Real-Time Protection" -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
Set-Service -Name "WinDefend" -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name "WinDefend" -ErrorAction SilentlyContinue
Write-Host " [✔] Servicios y politicas de Windows Defender restaurados." -ForegroundColor Green
`
core.RunPowerShellCmd(psCmd)
core.PauseEnter("")

case "R":
fmt.Println("\n\033[33m[+] Ejecutando escaneo rapido...\033[0m")
cmd := exec.Command(mpCmd, "-Scan", "-ScanType", "1")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
core.PauseEnter("")

case "C":
fmt.Println("\n\033[33m[+] Ejecutando escaneo completo...\033[0m")
cmd := exec.Command(mpCmd, "-Scan", "-ScanType", "2")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
core.PauseEnter("")

case "U":
fmt.Println("\n\033[32m[+] Actualizando definiciones de firmas...\033[0m")
cmd := exec.Command(mpCmd, "-SignatureUpdate")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
core.PauseEnter("")

case "V":
core.ShowBanner()
fmt.Println("\n\033[36m📋 AMENAZAS ENCONTRADAS:\033[0m")
psCmd := `
$threats = Get-MpThreat -ErrorAction SilentlyContinue
if ($threats) {
$threats | Format-Table -AutoSize ThreatID, Name, Severity, Status
} else {
Write-Host " [✔] Sin amenazas registradas en el historial." -ForegroundColor Green
}
`
out, _ := core.RunPowerShellCmd(psCmd)
fmt.Println(out)
core.PauseEnter("")

case "4":
confirm := core.ReadMenuOption("\n ¿Desea pausar la proteccion en tiempo real? (S/N):", []string{"S", "N"}, "N")
if confirm == "S" {
psCmd := `
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Write-Host " [!] Proteccion en tiempo real pausada." -ForegroundColor Yellow
`
core.RunPowerShellCmd(psCmd)
}
core.PauseEnter("")
}
}
}

// InvokeMassGraveIntegrated replica [G] MICROSOFT OFFICE AIO
func InvokeMassGraveIntegrated() {
core.ShowBanner()
fmt.Println("\n \033[36m🔑 ACTIVACION DE WINDOWS / OFFICE (MASSGRAVE)\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println(" Este proceso ejecuta la utilidad oficial de activacion MassGrave.")
fmt.Println(" Se pausara temporalmente la proteccion de Defender y se restaurara al salir.")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")

confirm := core.ReadMenuOption("\n ¿Desea continuar con el proceso de activacion? (S/N):", []string{"S", "N"}, "N")
if confirm != "S" {
return
}

fmt.Println("\n\033[33m[+] Preparando exclusion y ejecutando launcher oficial...\033[0m")
psCmd := `
try {
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Comprobar conectividad
$dohOk = $false
try {
$test = Invoke-WebRequest -Uri "https://get.activated.win" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
} catch {
$dohOk = $true
}

if ($dohOk) {
Write-Host " [!] Usando resolucion DNS-over-HTTPS (1.1.1.1)..." -ForegroundColor Yellow
iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
} else {
irm https://get.activated.win | iex
}
} finally {
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
Write-Host "` + "`n" + ` [✔] Proteccion en tiempo real restaurada." -ForegroundColor Green
}
`
cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", psCmd)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
cmd.Stdin = os.Stdin
_ = cmd.Run()

core.PauseEnter("")
}
