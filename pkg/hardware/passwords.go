package hardware

import (
"crypto/rand"
"fmt"
"math/big"
"os/exec"
"strconv"
"techflow/pkg/core"
)

const charset = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%^&*()_+-=[]{}|;:,.<>?"

func GeneratePassword(length int) string {
b := make([]byte, length)
maxIdx := big.NewInt(int64(len(charset)))
for i := range b {
idx, _ := rand.Int(rand.Reader, maxIdx)
b[i] = charset[idx.Int64()]
}
return string(b)
}

func CopyToClipboard(text string) {
cmd := exec.Command("powershell", "-NoProfile", "-Command", fmt.Sprintf("Set-Clipboard -Value '%s'", text))
_ = cmd.Run()
}

func InvokePasswordGenerator() {
fmt.Println("\n \033[36m[+] GENERADOR DE CONTRASEÑAS SEGURAS (Go Native)\033[0m")
fmt.Println(" ===================================================================")
fmt.Println(" Longitudes recomendadas: 16 (Estandar), 24 (Alta seguridad), 32 (Critica)")

opt := core.ReadMenuOption("\n Longitud deseada (o ENTER para 16):", nil, "16")
length, err := strconv.Atoi(opt)
if err != nil || length < 4 {
length = 16
}

fmt.Printf("\n \033[32m[+] CONTRASEÑAS GENERADAS (%d CARACTERES):\033[0m\n", length)
fmt.Println(" -------------------------------------------------------------")

firstPwd := ""
for i := 1; i <= 5; i++ {
pwd := GeneratePassword(length)
if i == 1 {
firstPwd = pwd
}
fmt.Printf(" [%d]  \033[36m%s\033[0m\n", i, pwd)
}

CopyToClipboard(firstPwd)
fmt.Println(" -------------------------------------------------------------")
fmt.Println(" \033[32m[OK] La contraseña [1] ha sido copiada al portapapeles.\033[0m")
core.PauseEnter("")
}
