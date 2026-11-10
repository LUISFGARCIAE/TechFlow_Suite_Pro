package hardware

import (
"fmt"
"os"
"path/filepath"
"techflow/pkg/core"
)

// InvokeDriverManagement replica [C] GESTION DRIVERS
func InvokeDriverManagement() {
for {
core.ShowBanner()
fmt.Println("\n \033[36m🔧 GESTION DE DRIVERS PRO\033[0m")
fmt.Println(" -----------------------------------------------------------------------------")
fmt.Println(" 💾 [A] EXPORTAR DRIVERS (BACKUP LOCAL EN CARPETA)")
fmt.Println(" 🔄 [B] RE-INSTALAR DRIVERS (DESDE BACKUP)")
fmt.Println(" 🔍 [C] BUSCAR EN SERVIDORES OFICIALES (WINDOWS UPDATE)")
fmt.Println(" 🆔 [D] VER IDENTIFICADORES DE HARDWARE (SIN DRIVER)")
fmt.Println("\n \033[90m⌨️ CONTROL\033[0m")
fmt.Println(" \033[31m-------------------\033[0m")
fmt.Println(" \033[31m❌ [X] VOLVER\033[0m")

opt := core.ReadMenuOption("\n > SELECCIONE:", []string{"A", "B", "C", "D", "X"}, "")
if opt == "X" {
break
}

backupDir := filepath.Join(os.Getenv("SystemDrive")+`\`, "Drivers_"+os.Getenv("COMPUTERNAME"))

switch opt {
case "A":
fmt.Printf("\n\033[33m[+] Exportando controladores a %s...\033[0m\n", backupDir)
_ = os.MkdirAll(backupDir, 0755)
psCmd := fmt.Sprintf(`Export-WindowsDriver -Online -Destination "%s"`, backupDir)
core.RunPowerShellCmd(psCmd)
fmt.Printf(" \033[32m[✔] Drivers exportados en: %s\033[0m\n", backupDir)
core.PauseEnter("")

case "B":
if _, err := os.Stat(backupDir); os.IsNotExist(err) {
fmt.Println(" \033[31m[✘] No se encontro la carpeta de backup de drivers.\033[0m")
core.PauseEnter("")
continue
}
fmt.Println("\n\033[32m[+] Reinstalando drivers mediante pnputil...\033[0m")
psCmd := fmt.Sprintf(`Get-ChildItem "%s\*.inf" -Recurse | ForEach-Object { pnputil /add-driver $_.FullName /install }`, backupDir)
core.RunPowerShellCmd(psCmd)
fmt.Println(" \033[32m[✔] Proceso de reinstalacion finalizado.\033[0m")
core.PauseEnter("")

case "C":
fmt.Println("\n\033[33m[+] Conectando con Microsoft Update para buscar drivers...\033[0m")
psCmd := `
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
}
if (!(Get-Module -ListAvailable PSWindowsUpdate)) {
Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser | Out-Null
}
Import-Module PSWindowsUpdate
Get-WindowsUpdate -Category "Drivers" -Install -AcceptAll -IgnoreReboot
`
core.RunPowerShellCmd(psCmd)
fmt.Println(" \033[32m[✔] Busqueda y carga de drivers finalizada.\033[0m")
core.PauseEnter("")

case "D":
core.ShowBanner()
fmt.Println("\n\033[33m[!] DISPOSITIVOS CON ERROR O SIN CONTROLADOR:\033[0m")
psCmd := `Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } | Format-Table -AutoSize Name, Status, DeviceID`
out, _ := core.RunPowerShellCmd(psCmd)
if out == "" {
fmt.Println(" \033[32m[✔] No se detectaron problemas de hardware (Todo OK).\033[0m")
} else {
fmt.Println(out)
}
core.PauseEnter("")
}
}
}
