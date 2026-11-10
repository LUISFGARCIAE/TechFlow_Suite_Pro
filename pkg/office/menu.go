package office

import (
"bufio"
"fmt"
"os"
"os/exec"
"path/filepath"
"strings"
)

func ShowOfficeMenu() {
reader := bufio.NewReader(os.Stdin)

for {
fmt.Println("\n==================================================")
fmt.Println("  📦 CENTRO DE DESPLIEGUE MICROSOFT OFFICE AIO   ")
fmt.Println("==================================================")
fmt.Println("  [1] Instalar Office 365 ProPlus (Oficial ODT x64)")
fmt.Println("  [2] Instalar Office 2021 LTSC Pro Plus (Oficial ODT x64)")
fmt.Println("  [3] Descargar Imagen Offline Completa (.IMG Oficial CDN)")
fmt.Println("  [4] Ver estado de licenciamiento de Office (vbs)")
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
desplegarViaODT("O365ProPlusRetail", "64", "es-es")
case "2":
desplegarViaODT("ProPlus2021Volume", "64", "es-es")
case "3":
mostrarEnlacesCDN()
case "4":
consultarLicenciamientoOffice()
default:
fmt.Println("  [!] Opción no válida.")
}
}
}

func desplegarViaODT(edition, arch, lang string) {
tempDir := filepath.Join(os.TempDir(), "OfficeDeploy")
_ = os.MkdirAll(tempDir, 0755)

odtExe := filepath.Join(tempDir, "odt_setup.exe")
fmt.Println("\n  [*] Obteniendo herramienta oficial de despliegue de Microsoft (ODT)...")
if err := DescargarODT(odtExe); err != nil {
fmt.Printf("  [X] Error al descargar ODT: %v\n", err)
return
}

fmt.Println("  [*] Extrayendo archivos de despliegue...")
_ = exec.Command(odtExe, "/quiet", fmt.Sprintf("/extract:%s", tempDir)).Run()

setupExe := filepath.Join(tempDir, "setup.exe")
cfg := OfficeConfig{Edition: edition, Arch: arch, Lang: lang}
xmlFile, err := GenerarXMLConfig(tempDir, cfg)
if err != nil {
fmt.Printf("  [X] Error al generar configuración: %v\n", err)
return
}

fmt.Println("  [*] Ejecutando instalación oficial de Microsoft Office...")
if err := EjecutarInstalacionODT(setupExe, xmlFile); err != nil {
fmt.Printf("  [X] Error durante la instalación: %v\n", err)
} else {
fmt.Println("  [✔] Instalación completada exitosamente.")
}
}

func mostrarEnlacesCDN() {
fmt.Println("\n--- Enlaces Oficiales CDN de Microsoft (Descarga Directa) ---")
fmt.Println("  • Office Pro Plus 2021 Retail (Español):")
fmt.Println("    https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/ProPlus2021Retail.img")
fmt.Println("  • Office Hogar y Empresas 2021 (Español):")
fmt.Println("    https://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/es-es/HomeBusiness2021Retail.img")
}

func consultarLicenciamientoOffice() {
fmt.Println("\n  [*] Consultando estado de licencias de Office registradas...")
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
fmt.Println("  [!] No se encontró OSPP.VBS en las rutas predeterminadas de Office 16.")
}
}