package core

import (
"fmt"
"os"
"os/exec"
"syscall"
"unsafe"
)

var (
modshell32       = syscall.NewLazyDLL("shell32.dll")
procIsUserAnAdmin = modshell32.NewProc("IsUserAnAdmin")
procShellExecuteW = modshell32.NewProc("ShellExecuteW")
)

func IsAdmin() bool {
ret, _, _ := procIsUserAnAdmin.Call()
return ret != 0
}

func EnsureAdmin() {
if IsAdmin() {
return
}

exePath, err := os.Executable()
if err != nil {
fmt.Println("\033[31m[!] Error al obtener ruta del ejecutable.\033[0m")
PauseEnter("")
os.Exit(1)
}

verbPtr, _ := syscall.UTF16PtrFromString("runas")
filePtr, _ := syscall.UTF16PtrFromString(exePath)
showCmd := int32(1)

ret, _, _ := procShellExecuteW.Call(
0,
uintptr(unsafe.Pointer(verbPtr)),
uintptr(unsafe.Pointer(filePtr)),
0,
0,
uintptr(showCmd),
)

if ret > 32 {
os.Exit(0)
}

fmt.Println("\n\033[31m[!] Requiere privilegios de Administrador.\033[0m")
PauseEnter("")
os.Exit(1)
}

// ClearScreen ejecuta cls directamente sobre la consola activa
func ClearScreen() {
c := exec.Command("cmd", "/c", "cls")
c.Stdout = os.Stdout
c.Stderr = os.Stderr
_ = c.Run()
}

func ShowBanner() {
ClearScreen()
banner := `
 ╔══════════════════════════════════════════════════════════════════════════════════╗
 ║                                                                                  ║
 ║    ████████╗███████╗ ██████╗██╗  ██╗    ███████╗██╗      ██████╗ ██╗    ██╗      ║
 ║    ╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██║     ██╔═══██╗██║    ██║      ║
 ║       ██║   █████╗  ██║     ███████║    █████╗  ██║     ██║   ██║██║ █╗ ██║      ║
 ║       ██║   ██╔══╝  ██║     ██╔══██║    ██╔══╝  ██║     ██║   ██║██║███╗██║      ║
 ║       ██║   ███████╗╚██████╗██║  ██║    ██║     ███████╗╚██████╔╝╚███╔███╔╝      ║
 ║       ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝       ║
 ║                                                                                  ║
 ║                                 GO EDITION v7.0                                  ║
 ║                    SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                   ║
 ║                                                                                  ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝`
fmt.Println("\033[36m" + banner + "\033[0m")
}

func RunPowerShellCmd(cmdStr string) (string, error) {
cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmdStr)
out, err := cmd.CombinedOutput()
return string(out), err
}
