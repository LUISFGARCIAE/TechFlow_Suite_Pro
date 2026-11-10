package core

import (
"bufio"
"fmt"
"os"
"strings"
)

// ReadMenuOption espera la entrada del usuario y requiere presionar ENTER obligatoriamente.
func ReadMenuOption(prompt string, validOptions []string, defaultValue string) string {
reader := bufio.NewReader(os.Stdin)
for {
fmt.Print(prompt + " ")
input, err := reader.ReadString('\n')
if err != nil {
return defaultValue
}

clean := strings.ToUpper(strings.TrimSpace(input))

if clean == "" {
if defaultValue != "" {
return strings.ToUpper(defaultValue)
}
// Si el usuario da ENTER en blanco sin default, se limpia y se vuelve a solicitar sin saltos
continue
}

if len(validOptions) > 0 {
for _, opt := range validOptions {
if clean == strings.ToUpper(opt) {
return clean
}
}
fmt.Printf(" \033[33m[!] Opción '%s' no válida. Permitidas: %s\033[0m\n", clean, strings.Join(validOptions, ", "))
} else {
return clean
}
}
}

func PauseEnter(msg string) {
if msg == "" {
msg = "Presiona ENTER para continuar..."
}
fmt.Printf("\n\033[90m%s\033[0m", msg)
reader := bufio.NewReader(os.Stdin)
_, _ = reader.ReadString('\n')
}
