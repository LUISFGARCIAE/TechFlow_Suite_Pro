package core

import (
"syscall"
"time"
)

var (
kernel32             = syscall.NewLazyDLL("kernel32.dll")
user32               = syscall.NewLazyDLL("user32.dll")
procGetConsoleWindow = kernel32.NewProc("GetConsoleWindow")
procShowWindow       = user32.NewProc("ShowWindow")
procSetForeground    = user32.NewProc("SetForegroundWindow")
procBringWindowToTop = user32.NewProc("BringWindowToTop")
)

const (
swShowNormal = 1
swRestore    = 9
swShow       = 5
)

// ForceForegroundWindow asegura que la consola no se minimice y retenga el foco
func ForceForegroundWindow() {
// Pequeña pausa de 100ms para permitir que el subsistema de video de Windows cree la ventana
time.Sleep(100 * time.Millisecond)
hwnd, _, _ := procGetConsoleWindow.Call()
if hwnd != 0 {
procShowWindow.Call(hwnd, uintptr(swRestore))
procShowWindow.Call(hwnd, uintptr(swShow))
procBringWindowToTop.Call(hwnd)
procSetForeground.Call(hwnd)
}
}