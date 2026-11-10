package hardware

import (
"fmt"
"os/exec"
"strings"
"techflow/pkg/core"
)

func ShowBatteryHealth() {
core.ShowBanner()
fmt.Println("\n \033[36m===== SALUD DE BATERIA =====\033[0m")

psQuery := `
$b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
if (-not $b) { "NO_BATTERY"; exit }
$status = $b.BatteryStatus
$charge = $b.EstimatedChargeRemaining
Write-Host "STATUS:$status|CHARGE:$charge"
`
out, _ := core.RunPowerShellCmd(psQuery)
out = strings.TrimSpace(out)

if strings.Contains(out, "NO_BATTERY") || out == "" {
fmt.Println(" \033[33m[!] No se detecto bateria en este equipo (Equipo de escritorio).\033[0m")
core.PauseEnter("")
return
}

fmt.Printf(" [+] Estado reportado: %s\n", out)
fmt.Println("\n \033[33m[+] Generando reporte detallado de Windows (powercfg /batteryreport)...\033[0m")

reportCmd := exec.Command("powercfg", "/batteryreport", "/output", "BatteryReport.html")
if err := reportCmd.Run(); err == nil {
fmt.Println(" \033[32m[✔] Reporte generado: BatteryReport.html en el directorio actual.\033[0m")
opt := core.ReadMenuOption(" Desea abrir el reporte en el navegador? (S/N):", []string{"S", "N"}, "N")
if opt == "S" {
_ = exec.Command("cmd", "/c", "start", "BatteryReport.html").Start()
}
} else {
fmt.Println(" \033[31m[✘] Error al ejecutar powercfg.\033[0m")
}

core.PauseEnter("")
}

func ShowTemperatures() {
core.ShowBanner()
fmt.Println("\n \033[36m[*] TEMPERATURAS Y ESTADO DE DISCOS\033[0m")
fmt.Println(" ===================================================================")

psCmd := `
Write-Host "--- SENSORES CPU ---" -ForegroundColor Cyan
$temps = Get-CimInstance -Namespace root/WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
if ($temps) {
foreach ($t in $temps) {
$c = [math]::Round(($t.CurrentTemperature - 2732) / 10, 1)
Write-Host " Sensor: $c C" -ForegroundColor Yellow
}
} else {
Write-Host " No se detectaron zonas termicas ACPI estandares." -ForegroundColor DarkGray
}

Write-Host "` + "`n" + `--- ESTADO DE DISCOS ---" -ForegroundColor Cyan
Get-PhysicalDisk -ErrorAction SilentlyContinue | Format-Table -AutoSize FriendlyName, MediaType, HealthStatus
`
out, _ := core.RunPowerShellCmd(psCmd)
fmt.Println(out)

core.PauseEnter("")
}

func ShowSystemInfo() {
core.ShowBanner()
fmt.Println("\n \033[36m===== INFORME TECNICO DE HARDWARE =====\033[0m")

psCmd := `
$cs = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
$cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$mem = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum

Write-Host "EQUIPO      : $env:COMPUTERNAME" -ForegroundColor Green
Write-Host "MODELO      : $($cs.Name)" -ForegroundColor Green
Write-Host "PROCESADOR  : $($cpu.Name.Trim())" -ForegroundColor Green
Write-Host "RAM TOTAL   : $([math]::Round($mem.Sum / 1GB, 2)) GB" -ForegroundColor Green
Write-Host "SISTEMA     : $($os.Caption) ($($os.OSArchitecture))" -ForegroundColor Green
Write-Host "BUILD       : $($os.BuildNumber)" -ForegroundColor Green
`
out, _ := core.RunPowerShellCmd(psCmd)
fmt.Println(out)

core.PauseEnter("")
}


