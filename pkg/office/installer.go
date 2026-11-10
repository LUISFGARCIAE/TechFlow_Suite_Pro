package office

import (
"fmt"
"io"
"net/http"
"os"
"os/exec"
"path/filepath"
)

type OfficeConfig struct {
Edition string
Arch    string
Lang    string
}

func GenerarXMLConfig(destDir string, cfg OfficeConfig) (string, error) {
xmlContent := fmt.Sprintf(`<Configuration>
  <Add OfficeClientEdition="%s" Channel="Current">
    <Product ID="%s">
      <Language ID="%s" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
</Configuration>`, cfg.Arch, cfg.Edition, cfg.Lang)

xmlPath := filepath.Join(destDir, "configuration.xml")
err := os.WriteFile(xmlPath, []byte(xmlContent), 0644)
return xmlPath, err
}

func DescargarODT(destPath string) error {
odtURL := "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17328-20162.exe"
resp, err := http.Get(odtURL)
if err != nil {
return err
}
defer resp.Body.Close()

out, err := os.Create(destPath)
if err != nil {
return err
}
defer out.Close()

_, err = io.Copy(out, resp.Body)
return err
}

func EjecutarInstalacionODT(setupExe string, xmlPath string) error {
cmd := exec.Command(setupExe, "/configure", xmlPath)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
cmd.Stdin = os.Stdin
return cmd.Run()
}