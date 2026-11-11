package hardware

import (
"crypto/rand"
"fmt"
"math/big"
"os/exec"
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
if length < 6 {
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

func generateNumericPIN(length int) string {
res := make([]byte, length)
for i := 0; i < length; i++ {
num, _ := rand.Int(rand.Reader, big.NewInt(10))
res[i] = charsetDigits[num.Int64()]
}
return string(res)
}

func copyToClipboard(text string) {
cmd := exec.Command("clip")
cmd.Stdin = strings.NewReader(text)
_ = cmd.Run()
}

func InvokePasswordGenerator() {
validKeys := []string{"1", "2", "3", "4", "5", "6", "7", "R", "X"}
var pwds [4]string
for i := 0; i < 4; i++ {
pwds[i], _ = GenerateSecurePassword(16)
}
statusMsg := ""

for {
core.ShowBanner()
fmt.Println("\n\033[44;37m 🔑 GENERADOR CRIPTOGRÁFICO DE CONTRASEÑAS SEGURAS \033[0m")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("  \033[90mClaves de alta entropía (16 caracteres) — Presiona [1-4] para copiar:\033[0m\n")

for i := 0; i < 4; i++ {
fmt.Printf("    \033[36m[%d]\033[0m 🔐 \033[32m%s\033[0m\n", i+1, pwds[i])
}

fmt.Println("\n  \033[90m⚡ GENERACIÓN AVANZADA (COPIA AUTOMÁTICA AL PORTAPAPELES)\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[36m[5] CLAVE ROBUSTA (24 CHARS)  \033[0m - Generar y copiar clave de 24 caracteres")
fmt.Println("  \033[36m[6] LLAVE MAESTRA (32 CHARS)  \033[0m - Generar y copiar clave máxima de 32 caracteres")
fmt.Println("  \033[36m[7] PIN NUMÉRICO (6 DÍGITOS)  \033[0m - Generar y copiar PIN seguro para Windows/BIOS")
fmt.Println("")
fmt.Println("  \033[90m⌨️  CONTROL\033[0m")
fmt.Println("  \033[90m---------------------------------------------------------------------------\033[0m")
fmt.Println("  \033[36m[R] REGENERAR LOTE            \033[0m - Crear 4 nuevas contraseñas de 16 caracteres")
fmt.Println("  \033[31m[X] VOLVER                    \033[0m - Regresar al Menú Principal")
fmt.Println("\033[36m═════════════════════════════════════════════════════════════════════════════\033[0m")

if statusMsg != "" {
fmt.Printf("  \033[32m%s\033[0m\n", statusMsg)
statusMsg = ""
}

opt := core.ReadMenuOption("\n  \033[32m> SELECCIONE:\033[0m", validKeys, "")
if opt == "" {
continue
}
if opt == "X" {
return
}

switch opt {
case "1", "2", "3", "4":
idx := int(opt[0] - '1')
copyToClipboard(pwds[idx])
statusMsg = fmt.Sprintf("[✔] Contraseña [%s] copiada al portapapeles: %s", opt, pwds[idx])
case "5":
p24, _ := GenerateSecurePassword(24)
copyToClipboard(p24)
statusMsg = fmt.Sprintf("[✔] Clave de 24 caracteres copiada al portapapeles: %s", p24)
case "6":
p32, _ := GenerateSecurePassword(32)
copyToClipboard(p32)
statusMsg = fmt.Sprintf("[✔] Clave maestra de 32 caracteres copiada: %s", p32)
case "7":
pin := generateNumericPIN(6)
copyToClipboard(pin)
statusMsg = fmt.Sprintf("[✔] PIN numérico de 6 dígitos copiado al portapapeles: %s", pin)
case "R":
for i := 0; i < 4; i++ {
pwds[i], _ = GenerateSecurePassword(16)
}
}
}
}