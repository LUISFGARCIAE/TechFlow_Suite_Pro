package core

import (
"bufio"
"fmt"
"os"
"strings"
)

func ReadMenuOption(prompt string, validKeys []string, defaultVal string) string {
reader := bufio.NewReader(os.Stdin)
fmt.Print(prompt + " ")
line, _ := reader.ReadString('\n')
opt := strings.ToUpper(strings.TrimSpace(line))
if opt == "" {
return defaultVal
}
for _, k := range validKeys {
if opt == strings.ToUpper(k) {
return opt
}
}
return ""
}

func PauseEnter(msg string) {
if msg == "" {
msg = "\n  \033[90mPresione ENTER para continuar...\033[0m"
} else {
msg = "\n  \033[90m" + msg + "\033[0m"
}
fmt.Print(msg)
reader := bufio.NewReader(os.Stdin)
_, _ = reader.ReadString('\n')
}