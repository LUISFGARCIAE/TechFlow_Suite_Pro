package office

import (
"bufio"
"fmt"
"os"
"os/exec"
"path/filepath"
"strings"
"techflow/pkg/core"
)

func ShowOfficeMenu() {
reader := bufio.NewReader(os.Stdin)

for {
core.ClearScreen()
core.ShowBanner()
fmt.Println("\n\033[44;37m 📦 CENTRO DE DESPLIEGUE Y ACTIVACIÓN MICROSOFT OFFICE AIO \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[36m[1] OFFICE 365 PROPLUS     \033[0m - Despliegue oficial ODT canal Retail x64")
fmt.Println("  \033[36m[2] OFFICE 2021 LTSC VL    \033[0m - Licenciamiento por volumen corporativo")
fmt.Println("  \033[36m[3] DESCARGA OFFLINE CDN   \033[0m - Enlaces directos de instaladores (.IMG)")
fmt.Println("  \033[36m[4] CONSULTAR LICENCIAS    \033[0m - Diagnóstico de activación (ospp.vbs)")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[31m[X] VOLVER                 \033[0m - Regresar al Menú Principal")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Print("  \033[32m> SELECCIONE:\033[0m ")

input, _ := reader.ReadString('\n')
choice := strings.TrimSpace(strings.ToUpper(input))

if choice == "X" {
core.ClearScreen()
return
}

switch choice {
case "1":
desplegarViaODT("O365ProPlusRetail", "64", "es-es")
core.PauseEnter("")
case "2":
desplegarViaODT("ProPlus2021Volume", "64", "es-es")
core.PauseEnter("")
case "3":
mostrarEnlacesCDN()
core.PauseEnter("")
case "4":
consultarLicenciamientoOffice()
core.PauseEnter("")
}
}
}

func desplegarViaODT(edition, arch, lang string) {
tempDir := filepath.Join(os.Getenv("TEMP"), "OfficeSetup")
_ = os.MkdirAll(tempDir, 0755)

fmt.Printf("\n  \033[36m[*] Preparando instalación de %s (%s-bit, %s)...\033[0m\n", edition, arch, lang)
setupExe := filepath.Join(tempDir, "setup.exe")

if _, err := os.Stat(setupExe); os.IsNotExist(err) {
fmt.Println("  \033[36m[*] Descargando Office Deployment Tool (ODT)...\033[0m")
err := DescargarODT(setupExe)
if err != nil {
fmt.Printf("  \033[31m[!] Error al descargar ODT: %v\033[0m\n", err)
return
}
}

cfg := OfficeConfig{
Edition:  edition,
Arch:     arch,
Lang:     lang,
}

xmlPath, err := GenerarXMLConfig(tempDir, cfg)
if err != nil {
fmt.Printf("  \033[31m[!] Error al generar configuración XML: %v\033[0m\n", err)
return
}

fmt.Println("  \033[32m[*] Ejecutando instalación oficial de Microsoft...\033[0m")
if err := EjecutarInstalacionODT(setupExe, xmlPath); err != nil {
fmt.Printf("  \033[31m[!] Proceso finalizado con advertencia: %v\033[0m\n", err)
} else {
fmt.Println("  \033[32m[✔] Proceso de instalación finalizado.\033[0m")
}
}

func mostrarEnlacesCDN() {
fmt.Println("\n\033[36m════════════════════ ENLACES OFICIALES CDN (MICROSOFT) ════════════════════\033[0m")
fmt.Println("  - Office 2021 Pro Plus (x86/x64 Spanish):")
fmt.Println("    \033[32mhttps://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/ProPlus2021Retail.img\033[0m")
fmt.Println("  - Office 2019 Pro Plus (x86/x64 Spanish):")
fmt.Println("    \033[32mhttps://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/ProPlus2019Retail.img\033[0m")
fmt.Println("\033[36m───────────────────────────────────────────────────────────────────────────\033[0m")
}

func consultarLicenciamientoOffice() {
fmt.Println("\n  \033[36m[*] Consultando estado de activación mediante ospp.vbs...\033[0m\n")
paths := []string{
`C:\Program Files\Microsoft Office\Office16\OSPP.VBS`,
`C:\Program Files (x86)\Microsoft Office\Office16\OSPP.VBS`,
}

found := false
for _, p := range paths {
if _, err := os.Stat(p); err == nil {
found = true
cmd := exec.Command("cscript", p, "/dstatus")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
break
}
}

if !found {
fmt.Println("  \033[33m[!] No se localizó OSPP.VBS en las rutas estándar de Office 2016/2019/2021/365.\033[0m")
}
}