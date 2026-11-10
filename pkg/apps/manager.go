package apps

import (
"bufio"
"fmt"
"os"
"os/exec"
"strings"
"sync"
"techflow/pkg/core"
)

type SoftwarePackage struct {
ID          string
Name        string
Category    string
IsInstalled bool
}

// Catálogo base de software esencial para técnicos y desarrollo
var catalog = []SoftwarePackage{
{ID: "Google.Chrome", Name: "Google Chrome", Category: "Navegadores"},
{ID: "Mozilla.Firefox", Name: "Mozilla Firefox", Category: "Navegadores"},
{ID: "Brave.Brave", Name: "Brave Browser", Category: "Navegadores"},
{ID: "7zip.7zip", Name: "7-Zip Compresor", Category: "Utilidades"},
{ID: "RARLab.WinRAR", Name: "WinRAR", Category: "Utilidades"},
{ID: "VideoLAN.VLC", Name: "VLC Media Player", Category: "Multimedia"},
{ID: "Notepad++.Notepad++", Name: "Notepad++ Editor", Category: "Desarrollo"},
{ID: "Microsoft.VisualStudioCode", Name: "Visual Studio Code", Category: "Desarrollo"},
{ID: "Git.Git", Name: "Git CLI para Windows", Category: "Desarrollo"},
{ID: "AnyDeskSoftwareGmbH.AnyDesk", Name: "AnyDesk Soporte Remoto", Category: "Soporte"},
{ID: "TeamViewer.TeamViewer", Name: "TeamViewer", Category: "Soporte"},
{ID: "BleachBit.BleachBit", Name: "BleachBit Limpiador", Category: "Mantenimiento"},
}

// checkPackageStatus verifica si un paquete específico ya está en el sistema
func checkPackageStatus(pkg *SoftwarePackage, wg *sync.WaitGroup, sem chan struct{}) {
defer wg.Done()
sem <- struct{}{}        // Adquiere cupo en el worker pool
defer func() { <-sem }() // Libera cupo

cmd := exec.Command("winget", "list", "--id", pkg.ID, "--exact", "--accept-source-agreements")
err := cmd.Run()
if err == nil {
pkg.IsInstalled = true
} else {
pkg.IsInstalled = false
}
}

// RefreshCatalogStatus consulta el estado de todos los paquetes usando Goroutines en paralelo
func RefreshCatalogStatus() {
var wg sync.WaitGroup
// Limitamos la concurrencia a 5 hilos simultáneos para no saturar la base de datos de WinGet
sem := make(chan struct{}, 5)

fmt.Println("\n\033[36m[*] Escaneando catálogo de software concurrentemente (Goroutines)... \033[0m")

for i := range catalog {
wg.Add(1)
go checkPackageStatus(&catalog[i], &wg, sem)
}

wg.Wait()
fmt.Println("\033[32m[✔] Escaneo concurrente completado.\033[0m")
}

// InvokeWingetMenu despliega el gestor optimizado
func InvokeWingetMenu() {
RefreshCatalogStatus()
reader := bufio.NewReader(os.Stdin)

for {
clearAppsScreen()
fmt.Println("\033[36m╔══════════════════════════════════════════════════════════════════════════════════╗")
fmt.Println("║                   📦 GESTOR CONCURRENTE DE PAQUETES (WINGET)                    ║")
fmt.Println("║                   SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                    ║")
fmt.Println("╚══════════════════════════════════════════════════════════════════════════════════╝\033[0m\n")

for i, pkg := range catalog {
statusTag := "\033[31m[ No Instalado ]\033[0m"
if pkg.IsInstalled {
statusTag = "\033[32m[ Instalado ]\033[0m"
}
fmt.Printf("  \033[33m[%2d]\033[0m %-26s %-15s %s\n", i+1, pkg.Name, "("+pkg.Category+")", statusTag)
}

fmt.Println("\n  \033[33m[R]\033[0m 🔄 Re-escanear estado de software (Paralelo)")
fmt.Println("  \033[33m[U]\033[0m ⚡ Actualizar todos los paquetes obsoletos (winget upgrade --all)")
fmt.Println("  \033[31m[X]\033[0m ↩️  Volver al Menú Principal")
fmt.Println("\033[36m-----------------------------------------------------------------------------\033[0m")
fmt.Print("  👉 Selecciona número de paquete a instalar o acción: ")

input, _ := reader.ReadString('\n')
choice := strings.TrimSpace(strings.ToUpper(input))

if choice == "X" {
break
}

switch choice {
case "R":
RefreshCatalogStatus()
core.PauseEnter("\nPresiona ENTER para volver al listado...")
case "U":
fmt.Println("\n\033[36m[*] Ejecutando actualización global del sistema...\033[0m")
cmd := exec.Command("winget", "upgrade", "--all", "--include-unknown")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
cmd.Stdin = os.Stdin
_ = cmd.Run()
RefreshCatalogStatus()
core.PauseEnter("\nPresiona ENTER para continuar...")
default:
var index int
_, err := fmt.Sscanf(choice, "%d", &index)
if err == nil && index >= 1 && index <= len(catalog) {
target := catalog[index-1]
fmt.Printf("\n\033[36m[*] Instalando %s (%s)...\033[0m\n", target.Name, target.ID)
cmd := exec.Command("winget", "install", "--id", target.ID, "-e", "--silent", "--accept-package-agreements", "--accept-source-agreements")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
target.IsInstalled = true
catalog[index-1] = target
core.PauseEnter("\nPresiona ENTER para continuar...")
} else {
fmt.Println("\n  \033[31m[!] Opción inválida.\033[0m")
}
}
}
}

// InvokeKitPostFormat permite despliegue desatendido de software estándar
func InvokeKitPostFormat() {
clearAppsScreen()
fmt.Println("\033[36m╔══════════════════════════════════════════════════════════════════════════════════╗")
fmt.Println("║                   ⚡ KIT POST-FORMATEO AUTOMÁTICO DESATENDIDO                   ║")
fmt.Println("║                   SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                    ║")
fmt.Println("╚══════════════════════════════════════════════════════════════════════════════════╝\033[0m\n")

fmt.Println("  Se instalarán en lote: Chrome, 7-Zip, VLC, AnyDesk, Notepad++ y WinRAR.")
reader := bufio.NewReader(os.Stdin)
fmt.Print("\n  ¿Deseas iniciar la instalación automática? (S/N): ")
ans, _ := reader.ReadString('\n')
if strings.TrimSpace(strings.ToUpper(ans)) == "S" {
essentialList := []string{
"Google.Chrome",
"7zip.7zip",
"VideoLAN.VLC",
"AnyDeskSoftwareGmbH.AnyDesk",
"Notepad++.Notepad++",
"RARLab.WinRAR",
}

for _, id := range essentialList {
fmt.Printf("\n\033[36m[*] Desplegando paquete: %s...\033[0m\n", id)
cmd := exec.Command("winget", "install", "--id", id, "-e", "--silent", "--accept-package-agreements", "--accept-source-agreements")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
}
fmt.Println("\n\033[32m[✔] Despliegue de Kit Post-Formateo finalizado.\033[0m")
}
core.PauseEnter("\nPresiona ENTER para regresar...")
}

func clearAppsScreen() {
cmd := exec.Command("cmd", "/c", "cls")
cmd.Stdout = os.Stdout
_ = cmd.Run()
}
// InvokeSmartInstall instala un paquete de WinGet de forma silenciosa y directa
func InvokeSmartInstall(args ...string) {
if len(args) == 0 {
return
}
targetID := args[0]
displayName := targetID
if len(args) > 1 {
displayName = args[1]
}

fmt.Printf("\n\033[36m[*] Instalando %s (%s) desatendidamente...\033[0m\n", displayName, targetID)
cmd := exec.Command("winget", "install", "--id", targetID, "-e", "--silent", "--accept-package-agreements", "--accept-source-agreements")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err != nil {
fmt.Printf("\033[31m[X] Error o cancelación durante la instalación de %s.\033[0m\n", displayName)
} else {
fmt.Printf("\033[32m[✔] %s instalado correctamente.\033[0m\n", displayName)
}
}