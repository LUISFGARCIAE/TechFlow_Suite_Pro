package hardware

import (
"fmt"
"os/exec"
"strings"
"syscall"
"unsafe"
"techflow/pkg/core"
)

var (
kernel32              = syscall.NewLazyDLL("kernel32.dll")
procGlobalMemoryStatus = kernel32.NewProc("GlobalMemoryStatusEx")
procGetSystemPower     = kernel32.NewProc("GetSystemPowerStatus")
)

type memorystatusex struct {
dwLength                uint32
dwMemoryLoad            uint32
ullTotalPhys            uint64
ullAvailPhys            uint64
ullTotalPageFile        uint64
ullAvailPageFile        uint64
ullTotalVirtual         uint64
ullAvailVirtual         uint64
ullAvailExtendedVirtual uint64
}

type systemPowerStatus struct {
ACLineStatus        byte
BatteryFlag         byte
BatteryLifePercent  byte
SystemStatusFlag    byte
BatteryLifeTime     uint32
BatteryFullLifeTime uint32
}

func ShowSystemInfo() {
core.ClearScreen()
core.ShowBanner()
fmt.Println("\n\033[32m📊 INFORMACIÓN DEL SISTEMA Y RENDIMIENTO DE HARDWARE\033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

var mem memorystatusex
mem.dwLength = uint32(unsafe.Sizeof(mem))
r1, _, _ := procGlobalMemoryStatus.Call(uintptr(unsafe.Pointer(&mem)))
if r1 != 0 {
totalGB := float64(mem.ullTotalPhys) / (1024 * 1024 * 1024)
availGB := float64(mem.ullAvailPhys) / (1024 * 1024 * 1024)
usedGB := totalGB - availGB
fmt.Printf("  \033[36m[MEMORIA RAM]\033[0m    🧠 Total: \033[32m%.2f GB\033[0m | En uso: \033[33m%.2f GB\033[0m | Libre: \033[32m%.2f GB\033[0m (Carga: %d%%)\n",
totalGB, usedGB, availGB, mem.dwMemoryLoad)
}

cmdCPU := exec.Command("wmic", "cpu", "get", "name,NumberOfCores,NumberOfLogicalProcessors", "/format:list")
outCPU, err := cmdCPU.Output()
if err == nil {
lines := strings.Split(string(outCPU), "\n")
var name, cores, threads string
for _, line := range lines {
line = strings.TrimSpace(line)
if strings.HasPrefix(line, "Name=") {
name = strings.TrimPrefix(line, "Name=")
} else if strings.HasPrefix(line, "NumberOfCores=") {
cores = strings.TrimPrefix(line, "NumberOfCores=")
} else if strings.HasPrefix(line, "NumberOfLogicalProcessors=") {
threads = strings.TrimPrefix(line, "NumberOfLogicalProcessors=")
}
}
if name != "" {
fmt.Printf("  \033[36m[PROCESADOR]\033[0m     ⚡ %s (\033[32m%s núcleos\033[0m / \033[32m%s hilos\033[0m)\n", name, cores, threads)
}
}

fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
core.PauseEnter("")
}

func ShowBatteryHealth() {
core.ClearScreen()
core.ShowBanner()
fmt.Println("\n\033[32m🔋 ESTADO DE LA BATERÍA Y ALIMENTACIÓN ACPI\033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

var power systemPowerStatus
r, _, _ := procGetSystemPower.Call(uintptr(unsafe.Pointer(&power)))
if r != 0 {
acStatus := "⚡ Desconectado (Modo Batería)"
if power.ACLineStatus == 1 {
acStatus = "🔌 Conectado a la Corriente Eléctrica"
}

if power.BatteryFlag == 128 || power.BatteryLifePercent == 255 {
fmt.Printf("  \033[36m[ALIMENTACIÓN]\033[0m   %s\n", acStatus)
fmt.Println("  \033[33m[DETECCIÓN]\033[0m      🖥️ Equipo de escritorio o sin módulo de batería ACPI presente.")
} else {
fmt.Printf("  \033[36m[ALIMENTACIÓN]\033[0m   %s\n", acStatus)
fmt.Printf("  \033[36m[NIVEL CARGA]\033[0m    🔋 \033[32m%d%%\033[0m de capacidad disponible\n", power.BatteryLifePercent)
}
}

fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
core.PauseEnter("")
}

func ShowTemperatures() {
core.ClearScreen()
core.ShowBanner()
fmt.Println("\n\033[32m🌡️ MONITOREO TÉRMICO DE SENSORES ACPI / WMI\033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

out, err := core.RunPowerShellCmd("Get-WmiObject -Namespace root/wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | ForEach-Object { [math]::Round(($_.CurrentTemperature - 2732) / 10, 1) }")
tempStr := strings.TrimSpace(out)
if err == nil && tempStr != "" {
temps := strings.Split(tempStr, "\n")
for idx, t := range temps {
t = strings.TrimSpace(t)
if t != "" {
fmt.Printf("  \033[36m[SENSOR %d]\033[0m       🌡️ Temperatura actual: \033[32m%s °C\033[0m\n", idx+1, t)
}
}
} else {
fmt.Println("  \033[33m[AVISO]\033[0m          Sensores térmicos OEM reservados o no expuestos por la BIOS del equipo.")
}

fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
core.PauseEnter("")
}