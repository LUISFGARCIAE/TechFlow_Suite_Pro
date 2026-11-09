# ============================================================
# TECHFLOW SUITE PRO - AI REPO SCANNER & CONTEXT GENERATOR
# ============================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$targetPath = "C:\TechFlow_Suite_Pro_v6"
$outputDump = "$targetPath\DevTools\AI_CONTEXT_DUMP.txt"

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           TECHFLOW AI SCANNER - GENERADOR DE CONTEXTO            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n[*] Escaneando estructura y módulos en: $targetPath..." -ForegroundColor Yellow

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("=================================================================")
$null = $sb.AppendLine("TECHFLOW SUITE PRO v6.0 - COMPREHENSIVE AI CONTEXT DUMP")
$null = $sb.AppendLine("FECHA DE CAPTURA : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$null = $sb.AppendLine("RUTA RAIZ        : $targetPath")
$null = $sb.AppendLine("=================================================================`n")

# A. Resumen de Archivos y Hashes SHA256
$null = $sb.AppendLine("--- INVENTARIO DE ARCHIVOS Y HASHES ---")
$files = Get-ChildItem -Path $targetPath -Recurse -File | Where-Object { $_.Name -notmatch "AI_CONTEXT_DUMP" }
foreach ($f in $files) {
    $relPath = $f.FullName.Replace($targetPath, "").TrimStart("\")
    $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
    $lines = (Get-Content $f.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    $null = $sb.AppendLine(("[{0,-35}] | {1,5} Líneas | SHA256: {2}" -f $relPath, $lines, $hash))
}
$null = $sb.AppendLine("")

# B. Mapa de Funciones Exportadas por Módulo
$null = $sb.AppendLine("--- MAPA DE FUNCIONES POR MODULO ---")
$psFiles = Get-ChildItem -Path $targetPath -Recurse -Filter "*.ps1"
foreach ($ps in $psFiles) {
    $rel = $ps.FullName.Replace($targetPath, "").TrimStart("\")
    $null = $sb.AppendLine("[$rel]")
    $content = Get-Content $ps.FullName -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    $funcDefinitions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    
    if ($funcDefinitions.Count -gt 0) {
        foreach ($fn in $funcDefinitions) {
            $null = $sb.AppendLine("  ├─ Function: $($fn.Name)")
        }
    } else {
        $null = $sb.AppendLine("  └─ (Script ejecutable raíz / Sin declaraciones de función)")
    }
    $null = $sb.AppendLine("")
}

# C. Integrar Prompt Master
$promptPath = "$targetPath\DevTools\AI_PROMPT_MASTER.md"
if (Test-Path $promptPath) {
    $null = $sb.AppendLine("--- DIRECTIVAS DEL PROYECTO (AI_PROMPT_MASTER.md) ---")
    $null = $sb.AppendLine((Get-Content $promptPath -Raw))
    $null = $sb.AppendLine("")
}

# D. Guardar y Copiar al Portapapeles
$finalText = $sb.ToString()
Set-Content -Path $outputDump -Value $finalText -Encoding UTF8

try {
    Set-Clipboard -Value $finalText
    $clipOk = $true
} catch {
    $clipOk = $false
}

Write-Host "✅ Escaneo finalizado con éxito." -ForegroundColor Green
Write-Host "📁 Archivo generado: $outputDump" -ForegroundColor White
if ($clipOk) {
    Write-Host "📋 ¡TODO EL CONTEXTO FUE COPIADO AL PORTAPAPELES!" -ForegroundColor Yellow
    Write-Host "   (Solo abre cualquier chat con una IA y presiona Ctrl + V)" -ForegroundColor Gray
} else {
    Write-Host "ℹ️ Puedes copiar el contenido desde: $outputDump" -ForegroundColor Gray
}
Write-Host ""
pause

