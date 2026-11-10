package core

import (
"fmt"
"io"
"net/http"
"os"
"os/exec"
"path/filepath"
)

// ApplySelfUpdate descarga el nuevo binario y reemplaza el actual en caliente
func ApplySelfUpdate(downloadURL string) error {
exePath, err := os.Executable()
if err != nil {
return err
}
realExePath, err := filepath.EvalSymlinks(exePath)
if err != nil {
realExePath = exePath
}

exeDir := filepath.Dir(realExePath)
newExePath := filepath.Join(exeDir, "TechFlow_Pro.exe.new")
oldExePath := filepath.Join(exeDir, "TechFlow_Pro.exe.old")

resp, err := http.Get(downloadURL)
if err != nil {
return fmt.Errorf("error al descargar actualización: %w", err)
}
defer resp.Body.Close()

out, err := os.Create(newExePath)
if err != nil {
return fmt.Errorf("no se pudo crear archivo temporal: %w", err)
}
_, err = io.Copy(out, resp.Body)
out.Close()
if err != nil {
return fmt.Errorf("error al escribir binario: %w", err)
}

_ = os.Remove(oldExePath)

if err := os.Rename(realExePath, oldExePath); err != nil {
return fmt.Errorf("fallo al desplazar binario actual: %w", err)
}

if err := os.Rename(newExePath, realExePath); err != nil {
_ = os.Rename(oldExePath, realExePath)
return fmt.Errorf("fallo al posicionar nuevo binario: %w", err)
}

cmd := exec.Command(realExePath)
if err := cmd.Start(); err != nil {
return fmt.Errorf("error al arrancar la nueva versión: %w", err)
}

os.Exit(0)
return nil
}

// CleanOldBinary elimina residuos de TechFlow_Pro.exe.old tras reiniciar
func CleanOldBinary() {
exePath, err := os.Executable()
if err != nil {
return
}
realExePath, err := filepath.EvalSymlinks(exePath)
if err != nil {
realExePath = exePath
}
oldFile := filepath.Join(filepath.Dir(realExePath), "TechFlow_Pro.exe.old")
if _, err := os.Stat(oldFile); err == nil {
_ = os.Remove(oldFile)
}
}