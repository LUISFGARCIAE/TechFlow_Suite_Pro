package maintenance

import (
"bufio"
"fmt"
"os"
"os/exec"
"path/filepath"
"strings"
"techflow/pkg/core"
"techflow/pkg/office"
)

// clearScreen limpia la consola nativamente
func clearScreen() {
cmd := exec.Command("cmd", "/c", "cls")
cmd.Stdout = os.Stdout
_ = cmd.Run()
}

// printOfficeBanner imprime el banner principal de TechFlow adaptado al módulo de Office
func printOfficeBanner() {
clearScreen()
fmt.Println("\033[36m╔══════════════════════════════════════════════════════════════════════════════════╗")
fmt.Println("║                                                                                  ║")
fmt.Println("║    ████████╗███████╗ ██████╗██╗  ██╗    ███████╗██╗     ██████╗ ██╗    ██╗       ║")
fmt.Println("║    ╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██║     ██╔═══██╗██║    ██║       ║")
fmt.Println("║       ██║   █████╗  ██║     ███████║    █████╗  ██║     ██║   ██║██║ █╗ ██║       ║")
fmt.Println("║       ██║   ██╔══╝  ██║     ██╔══██║    ██╔══╝  ██║     ██║   ██║██║███╗██║       ║")
fmt.Println("║       ██║   ███████╗╚██████╗██║  ██║    ██║     ███████╗╚██████╔╝╚███╔███╔╝       ║")
fmt.Println("║       ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝        ║")
fmt.Println("║                                                                                  ║")
fmt.Println("║                   📦 CENTRO DE DESPLIEGUE Y ACTIVACIÓN OFFICE                    ║")
fmt.Println("║                   SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                    ║")
fmt.Println("║                                                                                  ║")
fmt.Println("╚══════════════════════════════════════════════════════════════════════════════════╝\033[0m")
fmt.Println("")
}

// ShowOfficeActivationHub unifica el despliegue de Office y la herramienta de activacion
func ShowOfficeActivationHub() {
reader := bufio.NewReader(os.Stdin)

for {
printOfficeBanner()

fmt.Println("  \033[33m[1]\033[0m 🚀 Instalar Office 365 ProPlus (Oficial ODT x64)")
fmt.Println("  \033[33m[2]\033[0m 📦 Instalar Office 2021 LTSC Pro Plus (Oficial ODT x64)")
fmt.Println("  \033[33m[3]\033[0m 🌐 Enlaces Descarga Offline Directa (.IMG Oficial CDN)")
fmt.Println("  \033[33m[4]\033[0m 📋 Consultar Licencias Instaladas de Office (ospp.vbs)")
fmt.Println("  \033[33m[5]\033[0m 🔑 Ejecutar Utilidad de Activación Integrada")
fmt.Println("  \033[31m[X]\033[0m ↩️  Volver al Menú Principal")
fmt.Println("\033[36m-----------------------------------------------------------------------------\033[0m")
fmt.Print("  👉 Selecciona una opción: ")

input, _ := reader.ReadString('\n')
choice := strings.TrimSpace(strings.ToUpper(input))

if choice == "X" {
break
}

switch choice {
case "1":
desplegarOffice("O365ProPlusRetail")
case "2":
desplegarOffice("ProPlus2021Volume")
case "3":
mostrarEnlacesCDN()
case "4":
consultarLicenciasLocales()
case "5":
InvokeMassGraveIntegrated()
default:
fmt.Println("\n  \033[31m[!] Opción no válida.\033[0m")
}

if choice != "X" {
core.PauseEnter("\nPresiona ENTER para continuar...")
}
}
}

func desplegarOffice(edition string) {
tempDir := filepath.Join(os.TempDir(), "OfficeDeploy")
_ = os.MkdirAll(tempDir, 0755)

odtExe := filepath.Join(tempDir, "odt_setup.exe")
fmt.Println("\n  \033[36m[*] Obteniendo herramienta oficial ODT de Microsoft...\033[0m")
if err := office.DescargarODT(odtExe); err != nil {
fmt.Printf("  \033[31m[X] Error de descarga: %v\033[0m\n", err)
return
}

fmt.Println("  \033[36m[*] Extrayendo archivos de configuración...\033[0m")
_ = exec.Command(odtExe, "/quiet", fmt.Sprintf("/extract:%s", tempDir)).Run()

setupExe := filepath.Join(tempDir, "setup.exe")
cfg := office.OfficeConfig{Edition: edition, Arch: "64", Lang: "es-es"}
xmlFile, err := office.GenerarXMLConfig(tempDir, cfg)
if err != nil {
fmt.Printf("  \033[31m[X] Error al generar XML: %v\033[0m\n", err)
return
}

fmt.Println("  \033[32m[*] Ejecutando instalación oficial de Microsoft Office...\033[0m")
if err := office.EjecutarInstalacionODT(setupExe, xmlFile); err != nil {
fmt.Printf("  \033[31m[X] Error durante la instalación: %v\033[0m\n", err)
} else {
fmt.Println("  \033[32m[✔] Instalación completada exitosamente.\033[0m")
}
}

func mostrarEnlacesCDN() {
fmt.Println("\n\033[36m--- Enlaces Oficiales CDN de Microsoft (Descarga Directa) ---\033[0m")
fmt.Println("  • Office Pro Plus 2021 Retail (Español):")
fmt.Println("    https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/ProPlus2021Retail.img")
fmt.Println("  • Office Hogar y Empresas 2021 (Español):")
fmt.Println("    https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/HomeBusiness2021Retail.img")
}

func consultarLicenciasLocales() {
fmt.Println("\n  \033[36m[*] Consultando estado de licencias Office instaladas...\033[0m")
paths := []string{
`C:\Program Files\Microsoft Office\Office16\OSPP.VBS`,
`C:\Program Files (x86)\Microsoft Office\Office16\OSPP.VBS`,
}
found := false
for _, p := range paths {
if _, err := os.Stat(p); err == nil {
cmd := exec.Command("cscript", "//nologo", p, "/dstatus")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
found = true
break
}
}
if !found {
fmt.Println("  \033[33m[!] No se encontró OSPP.VBS en este equipo.\033[0m")
}
}