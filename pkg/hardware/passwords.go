package hardware

import (
"crypto/rand"
"fmt"
"math/big"
"strings"
"techflow/pkg/core"
)

const (
charsetUpper   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
charsetLower   = "abcdefghijklmnopqrstuvwxyz"
charsetDigits  = "0123456789"
charsetSpecial = "!@#$%&*_-+="
)

func GenerateSecurePassword(length int) (string, error) {
if length < 8 {
length = 16
}
allChars := charsetUpper + charsetLower + charsetDigits + charsetSpecial
res := make([]byte, length)

for i := 0; i < length; i++ {
num, err := rand.Int(rand.Reader, big.NewInt(int64(len(allChars))))
if err != nil {
return "", err
}
res[i] = allChars[num.Int64()]
}
return string(res), nil
}

func InvokePasswordGenerator() {
for {
core.ClearScreen()
core.ShowBanner()
fmt.Println("\n\033[32m🔑 GENERADOR CRIPTOGRÁFICO DE CONTRASEÑAS SEGURAS\033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[90mContraseñas de alta entropía generadas con crypto/rand (16 caracteres):\033[0m\n")

for i := 1; i <= 4; i++ {
pwd, _ := GenerateSecurePassword(16)
fmt.Printf("    \033[36m[%d]\033[0m 🔐 \033[32m%s\033[0m\n", i, pwd)
}

fmt.Println("")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[36m[R]\033[0m 🔄 REGENERAR NUEVAS CONTRASEÑAS")
fmt.Println("  \033[31m[X]\033[0m ❌ VOLVER AL MENÚ PRINCIPAL")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Print("  \033[32m>\033[0m SELECCIONE UNA OPCIÓN: ")

var opt string
fmt.Scanln(&opt)
opt = strings.ToUpper(strings.TrimSpace(opt))

if opt == "X" {
return
}
}
}