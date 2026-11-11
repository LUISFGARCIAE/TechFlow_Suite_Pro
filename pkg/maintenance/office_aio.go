package maintenance

import (
"fmt"
"os/exec"
"strings"
"techflow/pkg/core"
)

func ShowOfficeAIO() {
for {
core.ClearScreen()
core.ShowBanner()
fmt.Println("\n\033[32m📑 CENTRO DE DESPLIEGUE Y ACTIVACIÓN DE MICROSOFT OFFICE\033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1]\033[0m 🚀 Instalar Office 365 ProPlus (Oficial ODT x64)")
fmt.Println("  \033[36m[2]\033[0m 📦 Instalar Office 2021 LTSC Pro Plus (Oficial ODT x64)")
fmt.Println("  \033[36m[3]\033[0m 🌐 Enlaces Descarga Offline Directa (.IMG Oficial CDN)")
fmt.Println("  \033[36m[4]\033[0m 📋 Consultar Licencias Instaladas de Office (ospp.vbs)")
fmt.Println("")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X]\033[0m ↩️  Volver al Menú Principal")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Print("  \033[32m👉 Selecciona una opción:\033[0m ")

var opt string
fmt.Scanln(&opt)
opt = strings.ToUpper(strings.TrimSpace(opt))

switch opt {
case "1":
fmt.Println("\n\033[36m[*] Iniciando instalación desatendida de Microsoft 365...\033[0m")
core.PauseEnter("")
case "2":
fmt.Println("\n\033[36m[*] Iniciando instalación desatendida de Office 2021 LTSC...\033[0m")
core.PauseEnter("")
case "3":
fmt.Println("\n\033[36m[*] Enlaces oficiales CDN de Microsoft Office:\033[0m")
fmt.Println("    - Office 2021 Pro Plus x64: https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/ProPlus2021Retail.img")
core.PauseEnter("")
case "4":
fmt.Println("\n\033[36m[*] Verificando estado de activación mediante ospp.vbs...\033[0m")
cmd := exec.Command("cscript", "C:\\Program Files\\Microsoft Office\\Office16\\OSPP.VBS", "/dstatus")
out, err := cmd.CombinedOutput()
if err != nil {
cmd32 := exec.Command("cscript", "C:\\Program Files (x86)\\Microsoft Office\\Office16\\OSPP.VBS", "/dstatus")
out, _ = cmd32.CombinedOutput()
}
fmt.Println(string(out))
core.PauseEnter("")
case "X":
return
}
}
}