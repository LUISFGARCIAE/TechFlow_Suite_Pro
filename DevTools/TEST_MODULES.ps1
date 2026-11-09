[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$base = "C:\TechFlow_Suite_Pro_v6"
Clear-Host
Write-Host "🔍 COMPROBANDO INTEGRIDAD SINTÁCTICA DEL PROYECTO..." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray

$files = Get-ChildItem -Path $base -Recurse -Filter "*.ps1" | Where-Object { $_.Name -notmatch "AI_SCANNER|TEST_MODULES" }
$hayErrores = $false

foreach ($f in $files) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors)
    
    $rel = $f.FullName.Replace($base, "").TrimStart("\")
    if ($errors.Count -eq 0) {
        Write-Host "  ✅ [OK]     $rel" -ForegroundColor Green
    } else {
        $hayErrores = $true
        Write-Host "  ❌ [ERROR]  $rel ($($errors.Count) incidencias sintácticas)" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "       └─ Línea $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Yellow
        }
    }
}

Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
if (-not $hayErrores) {
    Write-Host "✅ Todos los módulos están libres de errores sintácticos." -ForegroundColor Green
} else {
    Write-Host "⚠️ Se detectaron errores que deben corregirse antes de compilar o ejecutar." -ForegroundColor Red
}
pause
