package core

import (
"fmt"
"os"
"os/exec"
"syscall"
"unsafe"
)

var (
modshell32                    = syscall.NewLazyDLL("shell32.dll")
procIsUserAnAdmin             = modshell32.NewProc("IsUserAnAdmin")
procShellExecuteW             = modshell32.NewProc("ShellExecuteW")
modkernel32                   = syscall.NewLazyDLL("kernel32.dll")
procGetStdHandle              = modkernel32.NewProc("GetStdHandle")
procGetConsoleScreenBufferInfo = modkernel32.NewProc("GetConsoleScreenBufferInfo")
procFillConsoleOutputCharacterW = modkernel32.NewProc("FillConsoleOutputCharacterW")
procFillConsoleOutputAttribute = modkernel32.NewProc("FillConsoleOutputAttribute")
procSetConsoleCursorPosition  = modkernel32.NewProc("SetConsoleCursorPosition")
)

type coord struct {
x int16
y int16
}

type smallRect struct {
left   int16
top    int16
right  int16
bottom int16
}

type consoleScreenBufferInfo struct {
dwSize              coord
dwCursorPosition    coord
wAttributes         uint16
srWindow            smallRect
dwMaximumWindowSize coord
}

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
ret, _, _ := procShellExecuteW.Call(0, uintptr(unsafe.Pointer(verbPtr)), uintptr(unsafe.Pointer(filePtr)), 0, 0, uintptr(showCmd))
if ret > 32 {
os.Exit(0)
}
fmt.Println("\n\033[31m[!] Requiere privilegios de Administrador.\033[0m")
PauseEnter("")
os.Exit(1)
}

// ClearScreen limpia el búfer completo de Windows Console API y purga scrollback ANSI
func ClearScreen() {
const stdOutputHandle = ^uintptr(10) // STD_OUTPUT_HANDLE (-11)
handle, _, _ := procGetStdHandle.Call(stdOutputHandle)

var csbi consoleScreenBufferInfo
ret, _, _ := procGetConsoleScreenBufferInfo.Call(handle, uintptr(unsafe.Pointer(&csbi)))
if ret != 0 {
cellCount := uint32(csbi.dwSize.x) * uint32(csbi.dwSize.y)
var written uint32
homeCoords := uintptr(0)
procFillConsoleOutputCharacterW.Call(handle, uintptr(' '), uintptr(cellCount), homeCoords, uintptr(unsafe.Pointer(&written)))
procFillConsoleOutputAttribute.Call(handle, uintptr(csbi.wAttributes), uintptr(cellCount), homeCoords, uintptr(unsafe.Pointer(&written)))
procSetConsoleCursorPosition.Call(handle, homeCoords)
}
fmt.Print("\033[H\033[2J\033[3J")
}

func ShowBanner() {
	ClearScreen()
fmt.Print("\033[36m")
fmt.Println("╔═════════════════════════════════════════════════════════════════════════════════╗")
fmt.Println("║ ╔═════════════════════════════════════════════════════════════════════════════╗ ║")
fmt.Println("║ ║                                                                             ║ ║")
fmt.Println("║ ║   ████████╗███████╗ ██████╗██╗  ██╗    ███████╗██╗      ██████╗ ██╗    ██╗  ║ ║")
fmt.Println("║ ║   ╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██║     ██╔═══██╗██║    ██║  ║ ║")
fmt.Println("║ ║      ██║   █████╗  ██║     ███████║    █████╗  ██║     ██║   ██║██║ █╗ ██║  ║ ║")
fmt.Println("║ ║      ██║   ██╔══╝  ██║     ██╔══██║    ██╔══╝  ██║     ██║   ██║██║███╗██║  ║ ║")
fmt.Println("║ ║      ██║   ███████╗╚██████╗██║  ██║    ██║     ███████╗╚██████╔╝╚███╔███╔╝  ║ ║")
fmt.Println("║ ║      ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝   ║ ║")
fmt.Println("║ ║                                                                             ║ ║")
fmt.Println("║ ║                              GO EDITION v7.0                                ║ ║")
fmt.Println("║ ║                SOLUCIONES IT - LUIS FERNANDO GARCIA ENCISO                  ║ ║")
fmt.Println("║ ║                                                                             ║ ║")
fmt.Println("║ ╚═════════════════════════════════════════════════════════════════════════════╝ ║")
fmt.Println("╚═════════════════════════════════════════════════════════════════════════════════╝")
fmt.Print("\033[0m")
}

func RunPowerShellCmd(cmdStr string) (string, error) {
cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmdStr)
out, err := cmd.CombinedOutput()
return string(out), err
}