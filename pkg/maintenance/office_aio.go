package maintenance

import (
"bufio"
"fmt"
"os"
"os/exec"
"path/filepath"
"strings"
"techflow/pkg/office"
)

// ShowOfficeActivationHub unifica el despliegue de Office y la herramienta de activacion
func ShowOfficeActivationHub() {
reader := bufio.NewReader(os.Stdin)

for {
fmt.Println("\n==================================================")
fmt.Println("  📦 CENTRO DE DESPLIEGUE Y ACTIVACIÓN (OFFICE/WIN)")
fmt.Println("==================================================")
fmt.Println("  [1] Instalar Office 365 ProPlus (Oficial ODT x64)")
fmt.Println("  [2] Instalar Office 2021 LTSC Pro Plus (Oficial ODT x64)")
fmt.Println("  [3] Enlaces Descarga Offline Directa (.IMG Oficial)")
fmt.Println("  [4] Consultar licencias instaladas (ospp.vbs)")
fmt.Println("  [5] Ejecutar Utilidad de Activación Integrada")
fmt.Println("  [X] Volver al Menú Principal")
fmt.Println("==================================================")
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
fmt.Println("\n--- Enlaces Oficiales CDN de Microsoft (Descarga Directa) ---")
fmt.Println("  • Office Pro Plus 2021 Retail (Español):")
fmt.Println("    https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/ProPlus2021Retail.img")
fmt.Println("  • Office Hogar y Empresas 2021 (Español):")
fmt.Println("    https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/HomeBusiness2021Retail.img")
case "4":
consultarLicenciasLocales()
case "5":
InvokeMassGraveIntegrated()
default:
fmt.Println("  [!] Opción no válida.")
}
}
}

func desplegarOffice(edition string) {
tempDir := filepath.Join(os.TempDir(), "OfficeDeploy")
_ = os.MkdirAll(tempDir, 0755)

odtExe := filepath.Join(tempDir, "odt_setup.exe")
fmt.Println("\n  [*] Obteniendo herramienta oficial ODT de Microsoft...")
if err := office.DescargarODT(odtExe); err != nil {
fmt.Printf("  [X] Error de descarga: %v\n", err)
return
}

fmt.Println("  [*] Extrayendo archivos de configuración...")
_ = exec.Command(odtExe, "/quiet", fmt.Sprintf("/extract:%s", tempDir)).Run()

setupExe := filepath.Join(tempDir, "setup.exe")
cfg := office.OfficeConfig{Edition: edition, Arch: "64", Lang: "es-es"}
xmlFile, err := office.GenerarXMLConfig(tempDir, cfg)
if err != nil {
fmt.Printf("  [X] Error al generar XML: %v\n", err)
return
}

fmt.Println("  [*] Ejecutando instalación oficial de Microsoft Office...")
if err := office.EjecutarInstalacionODT(setupExe, xmlFile); err != nil {
fmt.Printf("  [X] Error durante la instalación: %v\n", err)
} else {
fmt.Println("  [✔] Instalación completada.")
}
}

func consultarLicenciasLocales() {
fmt.Println("\n  [*] Consultando estado de licencias Office...")
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
fmt.Println("  [!] No se encontró OSPP.VBS en el equipo.")
}
}