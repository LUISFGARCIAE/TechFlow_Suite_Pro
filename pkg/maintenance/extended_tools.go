package maintenance

import (
"fmt"
"os/exec"
"techflow/pkg/core"
"techflow/pkg/office"
)

// ShowOfficeActivationHub conecta el submenú de Office con el menú existente
func ShowOfficeActivationHub() {
core.ShowBanner()
office.ShowOfficeMenu()
}

// InvokeWinUtilTitus lanza el kit de optimización WinUtil
func InvokeWinUtilTitus() {
core.ShowBanner()
fmt.Println("\n\033[44;37m ⚙️  WINUTIL TITUS - OPTIMIZADOR GLOBAL DEL SISTEMA \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  [*] Iniciando utilidad externa de optimización Windows...")
cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm https://christitus.com/win | iex")
cmd.Stdout = exec.Command("cmd").Stdout
_ = cmd.Start()
core.PauseEnter("Presione ENTER para regresar...")
}

// InvokeUserManagement submenú para administración de cuentas de usuario
func InvokeUserManagement() {
validKeys := []string{"1", "2", "3", "4", "X"}

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 👤 GESTIÓN DE USUARIOS - ADMINISTRACIÓN DE CUENTAS \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] USUARIOS Y GRUPOS          \033[0m - Administrador gráfico local (lusrmgr.msc)")
fmt.Println("  \033[36m[2] CONTROL DE ACCESO          \033[0m - Cuentas y auto-login (netplwiz)")
fmt.Println("  \033[36m[3] HABILITAR ADMINISTRADOR    \033[0m - Activar cuenta Administrador integrada")
fmt.Println("  \033[36m[4] AUDITORÍA CUENTAS LOCALES  \033[0m - Listar usuarios, estado y último acceso")
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
_ = exec.Command("lusrmgr.msc").Start()
case "2":
_ = exec.Command("netplwiz").Start()
case "3":
fmt.Println("\n  \033[36m[*] Activando cuenta integrada Administrator / Administrador...\033[0m")
_, err := core.RunPowerShellCmd("Get-LocalUser | Where-Object { $_.SID -like '*-500' } | Enable-LocalUser")
if err != nil {
fmt.Printf("  \033[31m[!] Error al habilitar cuenta: %v\033[0m\n", err)
} else {
fmt.Println("  \033[32m[✔] Cuenta de Administrador integrada habilitada.\033[0m")
}
core.PauseEnter("")
case "4":
fmt.Println("\n  \033[36m[*] Consultando cuentas locales del equipo...\033[0m\n")
out, _ := core.RunPowerShellCmd("Get-LocalUser | Select-Object Name, Enabled, PasswordRequired, LastLogon | Format-Table -AutoSize")
fmt.Println(out)
core.PauseEnter("")
}
}
}