[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$base = "C:\TechFlow_Suite_Pro_v6"
$vFile = "$base\DevTools\VERSION.json"

if (-not (Test-Path $vFile)) {
    Write-Host "❌ No se encontró VERSION.json en DevTools" -ForegroundColor Red
    pause; exit
}

$data = Get-Content $vFile -Raw | ConvertFrom-Json
$partes = ($data.version -split '\.')
$major = if ($partes.Count -ge 1 -and $partes[0] -match '^\d+$') { [int]$partes[0] } else { 6 }
$minor = if ($partes.Count -ge 2 -and $partes[1] -match '^\d+$') { [int]$partes[1] } else { 0 }
$patch = if ($partes.Count -ge 3 -and $partes[2] -match '^\d+$') { [int]$partes[2] } else { 0 }

$oldVersionFull = "$major.$minor.$patch"
$oldMajorMinor  = "$major.$minor"

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          TECHFLOW SUITE PRO - GESTOR DE VERSIONES GLOBAL         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n Versión actual: v$oldVersionFull (Rama: v$oldMajorMinor)" -ForegroundColor Yellow
Write-Host " ──────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host " [1] Parche / Fix    (v$major.$minor.$($patch + 1))"
Write-Host " [2] Sub-versión     (v$major.$($minor + 1).0)"
Write-Host " [3] Versión Mayor   (v$($major + 1).0.0)"
Write-Host " [X] Cancelar"

$op = (Read-Host "`n > Seleccione incremento").Trim().ToUpper()
switch ($op) {
    "1" { $patch++ }
    "2" { $minor++; $patch = 0 }
    "3" { $major++; $minor = 0; $patch = 0 }
    default { exit }
}

$newVersionFull = "$major.$minor.$patch"
$newMajorMinor  = "$major.$minor"

Write-Host "`n Nueva versión: v$newVersionFull (Visual: v$newMajorMinor)" -ForegroundColor Green
$changelog = Read-Host " Ingresa el changelog/descripción del cambio"

# 1. Guardar en DevTools\VERSION.json
$data.version = $newVersionFull
if ($changelog) { $data.changelog = $changelog }
$data | ConvertTo-Json -Depth 4 | Set-Content $vFile -Encoding UTF8
Write-Host " [✔] Actualizado: DevTools\VERSION.json" -ForegroundColor Green

# 2. Actualizar TechFlow.ps1 (Banner ASCII y títulos)
$tfPath = "$base\TechFlow.ps1"
if (Test-Path $tfPath) {
    $tfContent = Get-Content $tfPath -Raw -Encoding UTF8
    
    # Marco de 82 caracteres
    $bannerText = "PRO EDITION v$newMajorMinor (MODULAR)"
    $totalWidth = 82
    $leftPad = [math]::Floor(($totalWidth - $bannerText.Length) / 2)
    $rightPad = $totalWidth - $bannerText.Length - $leftPad
    $newLine = " ║" + (" " * $leftPad) + $bannerText + (" " * $rightPad) + "║"
    
    $tfContent = [regex]::Replace($tfContent, ' ║\s*PRO EDITION v[^\n\r]+?\(MODULAR\)\s*║?', $newLine)
    $tfContent = $tfContent -replace 'v\d+\.\d+(\.\d+)?', "v$newMajorMinor"
    Set-Content -Path $tfPath -Value $tfContent -Encoding UTF8
    Write-Host " [✔] TechFlow.ps1: Banner ASCII y textos actualizados a v$newMajorMinor" -ForegroundColor Green
}

# 3. Propagación en todos los archivos de Modules, DevTools y lanzadores
$archivos = Get-ChildItem -Path $base -Recurse -File | Where-Object {
    $_.Extension -in @(".ps1", ".bat", ".md", ".json") -and $_.Name -ne "VERSION.json"
}

Write-Host "`n [*] Propagando cambios transversales en toda la suite..." -ForegroundColor Cyan
foreach ($f in $archivos) {
    $raw = Get-Content $f.FullName -Raw -Encoding UTF8
    $mod = $false

    # Reemplazo de versión semántica (ej: 6.0.0 -> 7.0.0)
    if ($raw -match [regex]::Escape($oldVersionFull)) {
        $raw = $raw -replace [regex]::Escape($oldVersionFull), $newVersionFull
        $mod = $true
    }

    # Reemplazo de versión visual (ej: v6.0 -> v7.0)
    if ($raw -match "(?i)v$([regex]::Escape($oldMajorMinor))") {
        $raw = $raw -replace "(?i)v$([regex]::Escape($oldMajorMinor))", "v$newMajorMinor"
        $mod = $true
    }

    if ($mod) {
        Set-Content -Path $f.FullName -Value $raw -Encoding UTF8
        $rel = $f.FullName.Replace($base, "").TrimStart("\")
        Write-Host "  ├─ Sincronizado: $rel" -ForegroundColor DarkGray
    }
}

Write-Host "`n✅ Versión v$newVersionFull propagada transversalmente en todos los textos." -ForegroundColor Green
pause
