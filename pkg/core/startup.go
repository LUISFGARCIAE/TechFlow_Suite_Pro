package core

// RunStartupSequence orquesta la inicialización sin disparar subventanas que roben foco
func RunStartupSequence() bool {
CleanOldBinary()
ForceForegroundWindow()
return IsAdmin()
}

// CheckStartup mantiene compatibilidad
func CheckStartup() bool {
return RunStartupSequence()
}