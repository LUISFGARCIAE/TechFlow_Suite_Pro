# ============================================================
# TECHFLOW SUITE PRO - BACKUP & RESTORE MODULE (CLON COMPLETO)
# ============================================================

$COLOR_PRIMARY = $Global:COLOR_PRIMARY
$COLOR_ALERT   = $Global:COLOR_ALERT
$COLOR_DANGER  = $Global:COLOR_DANGER
$COLOR_MENU    = $Global:COLOR_MENU
$COLOR_WARNING = $Global:COLOR_WARNING

$USER_FOLDER_NAMES = @("Desktop", "Documents", "Pictures", "Videos", "Music", "Downloads", "Favorites", "Contacts")

function Scan-DriveUnits {
    $units = @()
    try {
        $volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { 
            $_.DriveType -in 'Fixed', 'Removable' -and 
            $_.DriveLetter -ne $null -and
            $_.DriveLetter -ne "" 
        }
        
        if ($volumes -and $volumes.Count -gt 0) {
            $i = 1
            foreach ($vol in $volumes) {
                $driveLetter = $vol.DriveLetter + ":"
                $driveType = if ($vol.DriveType -eq 'Removable') { "USB/Extraíble" } else { "Disco Fijo" }
                $totalGB = [math]::Round($vol.Size / 1GB, 2)
                $freeGB = [math]::Round($vol.SizeRemaining / 1GB, 2)
                $usedGB = [math]::Round(($vol.Size - $vol.SizeRemaining) / 1GB, 2)
                $percentFree = if ($vol.Size -gt 0) { [math]::Round(($vol.SizeRemaining / $vol.Size) * 100, 1) } else { 0 }
                $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "Sin etiqueta" }
                
                $units += [PSCustomObject]@{
                    Index = $i
                    DeviceID = $driveLetter
                    Label = $label
                    Type = $driveType
                    TotalGB = $totalGB
                    UsedGB = $usedGB
                    FreeGB = $freeGB
                    PercentFree = $percentFree
                    Path = $driveLetter + "\"
                }
                $i++
            }
            return $units
        }
    } catch { }
    
    try {
        $disks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | 
                 Where-Object { $_.DriveType -in 2,3 -and $_.DeviceID -ne $null } | 
                 Sort-Object DeviceID
        
        if ($disks -and $disks.Count -gt 0) {
            $i = 1
            foreach ($disk in $disks) {
                $driveType = switch ($disk.DriveType) {
                    2 { "USB/Extraíble" }
                    3 { "Disco Fijo" }
                    default { "Desconocido" }
                }
                $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
                $totalGB = [math]::Round($disk.Size / 1GB, 2)
                $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
                $percentFree = if ($disk.Size -gt 0) { [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1) } else { 0 }
                $label = if ($disk.VolumeName) { $disk.VolumeName } else { "Sin etiqueta" }
                
                $units += [PSCustomObject]@{
                    Index = $i
                    DeviceID = $disk.DeviceID
                    Label = $label
                    Type = $driveType
                    TotalGB = $totalGB
                    UsedGB = $usedGB
                    FreeGB = $freeGB
                    PercentFree = $percentFree
                    Path = $disk.DeviceID + "\"
                }
                $i++
            }
            return $units
        }
    } catch { }
    return $units
}

function Show-DriveSelector {
    param(
        [string]$Title = "SELECCIÓN DE UNIDAD",
        [string]$Action = "seleccionar"
    )
    
    $units = Scan-DriveUnits
    if ($units.Count -eq 0) {
        Write-Host "`n ❌ No se detectaron unidades disponibles." -ForegroundColor $COLOR_DANGER
        return $null
    }
    
    Show-MainTitle
    Write-Host "`n 📂 $Title" -ForegroundColor $COLOR_MENU
    Write-Host $Global:LINEA -ForegroundColor Gray
    Write-Host "   UNIDAD   ETIQUETA         TIPO        TOTAL    LIBRE    USADO"
    Write-Host " ───────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    foreach ($unit in $units) {
        $freeColor = if ($unit.PercentFree -lt 10) { $COLOR_DANGER } 
                     elseif ($unit.PercentFree -lt 25) { $COLOR_ALERT } 
                     else { $COLOR_PRIMARY }
        
        $labelDisplay = $unit.Label.PadRight(15)
        if ($labelDisplay.Length -gt 15) { $labelDisplay = $labelDisplay.Substring(0,12) + "..." }
        
        Write-Host ("   [{0}]  {1}  {2,-12}  {3,8}GB  {4,8}GB  {5,7}GB" -f 
            $unit.DeviceID.PadRight(2),
            $labelDisplay,
            $unit.Type,
            $unit.TotalGB,
            $unit.FreeGB,
            $unit.UsedGB
        ) -ForegroundColor $COLOR_MENU
        
        $barLength = 30
        $filled = [math]::Round($barLength * ($unit.FreeGB / $unit.TotalGB))
        $bar = "█" * $filled + "░" * ($barLength - $filled)
        Write-Host ("      Libre: [{0}] {1}%" -f $bar, $unit.PercentFree) -ForegroundColor $freeColor
        Write-Host ""
    }
    
    Write-Host $Global:LINEA -ForegroundColor Gray
    Write-Host " [X] CANCELAR" -ForegroundColor $COLOR_DANGER
    
    while ($true) {
        $sel = Read-Host "`n > SELECCIONE UNA UNIDAD (LETRA: C, D, E, etc.)"
        if ($sel -eq "X" -or $sel -eq "x") { return $null }
        $sel = $sel.Trim().ToUpper().Replace(":", "")
        
        $found = $null
        foreach ($unit in $units) {
            $unitLetter = $unit.DeviceID.Replace(":", "").Trim()
            if ($unitLetter -eq $sel) {
                $found = $unit
                break
            }
        }
        
        if ($found) {
            Write-Host "`n ✅ UNIDAD SELECCIONADA: $($found.DeviceID) ($($found.Label))" -ForegroundColor Green
            Start-Sleep -Seconds 1
            return $found
        }
        Write-Host "`n ❌ Unidad '$sel' no válida." -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 1
    }
}

function Find-BACKOPsInUnit {
    param([Parameter(Mandatory=$true)][string]$UnitPath)
    $BACKOPs = @()
    Write-Host "   🔍 Escaneando $UnitPath (búsqueda recursiva)..." -ForegroundColor DarkGray
    $searchPath = if ($UnitPath.EndsWith("\")) { $UnitPath } else { $UnitPath + "\" }
    
    try {
        $found = Get-ChildItem -Path $searchPath -Directory -Recurse -ErrorAction Stop | 
                 Where-Object { $_.Name -match "BACKOP" }
        
        if ($found) {
            foreach ($item in $found) {
                $sizeGB = [math]::Round((Get-FolderSizeBytes $item.FullName) / 1GB, 2)
                $BACKOPs += [PSCustomObject]@{
                    FullName = $item.FullName
                    Name = $item.Name
                    CreationTime = $item.CreationTime
                    SizeGB = $sizeGB
                }
            }
            $BACKOPs = $BACKOPs | Sort-Object CreationTime -Descending
        }
    } catch {
        Write-Host "      ⚠️ Error de permisos en $searchPath" -ForegroundColor Yellow
    }
    return $BACKOPs
}

function Show-BACKOPSelector {
    param([string]$UnitPath)
    $BACKOPs = Find-BACKOPsInUnit -UnitPath $UnitPath
    if ($BACKOPs.Count -eq 0) {
        Write-Host "`n ❌ No se encontraron BACKOPs en esta unidad." -ForegroundColor $COLOR_DANGER
        return $null
    }
    
    Show-MainTitle
    Write-Host "`n 📋 BACKOPS ENCONTRADOS:" -ForegroundColor $COLOR_PRIMARY
    Write-Host $Global:LINEA -ForegroundColor Gray
    
    for ($i = 0; $i -lt $BACKOPs.Count; $i++) {
        Write-Host "   [$($i+1)] $($BACKOPs[$i].Name)" -ForegroundColor $COLOR_MENU
        Write-Host "          📅 Creado: $($BACKOPs[$i].CreationTime)" -ForegroundColor DarkGray
        Write-Host "          💾 Tamaño: $($BACKOPs[$i].SizeGB) GB" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    Write-Host $Global:LINEA -ForegroundColor Gray
    Write-Host " [X] CANCELAR" -ForegroundColor $COLOR_DANGER
    
    $sel = Read-Host "`n > SELECCIONE BACKOP (NÚMERO)"
    if ($sel -eq "X" -or $sel -eq "x") { return $null }
    
    if ($sel -match "^\d+$" -and [int]$sel -le $BACKOPs.Count) {
        return $BACKOPs[[int]$sel-1].FullName
    } else {
        Write-Host "`n ❌ Selección inválida." -ForegroundColor $COLOR_DANGER
        Start-Sleep -Seconds 1.5
        return Show-BACKOPSelector -UnitPath $UnitPath
    }
}

function Get-FolderSizeBytes {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        $sum = 0L
        Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue -File | ForEach-Object { $sum += $_.Length }
        return $sum
    } catch { return 0L }
}

function Get-DriveFreeBytes {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        $root = [System.IO.Path]::GetPathRoot($Path)
        $name = $root.TrimEnd('\')
        $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + $name + "'") -ErrorAction SilentlyContinue
        if ($d) { return [Int64]$d.FreeSpace }
        return 0L
    } catch { return 0L }
}

function Get-OptimalRobocopyThreads {
    param([string]$Path)
    try {
        $root = [System.IO.Path]::GetPathRoot($Path)
        $name = $root.TrimEnd('\')
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$name'" -ErrorAction SilentlyContinue
        if ($disk) {
            if ($disk.MediaType -like "*SSD*" -or $disk.VolumeName -like "*SSD*") { return 16 } else { return 8 }
        }
    } catch {}
    return 8 
}

function Get-UserProfilePaths {
    $profilesPath = "$env:SystemDrive\Users"
    Get-ChildItem -Path $profilesPath -Directory | Where-Object {
        $_.Name -notin @('All Users', 'Default', 'Default User', 'Public', 'desktop.ini', 'DefaultAppPool')
    } | Select-Object -ExpandProperty FullName
}

function Get-BACKOPRoot($basePath) {
    $existing = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "BACKOP_*" } | ForEach-Object { $_.Name -replace "BACKOP_", "" } | Where-Object { $_ -match "^\d+$" } | Sort-Object {[int]$_} -Descending
    if ($existing) { $next = [int]$existing[0] + 1 } else { $next = 1 }
    $root = Join-Path $basePath ("BACKOP_" + $next.ToString("00"))
    if (!(Test-Path $root)) { New-Item -Path $root -ItemType Directory -Force | Out-Null }
    return $root
}

function BACKOP-ProfileData($profilePath, $BACKOPRoot) {
    $userName = Split-Path $profilePath -Leaf
    $destRoot = Join-Path $BACKOPRoot $userName
    
    if (-not (Test-Path $destRoot)) { New-Item -Path $destRoot -ItemType Directory -Force | Out-Null }
    
    $validFolders = @()
    foreach ($folder in $USER_FOLDER_NAMES) {
        $source = Join-Path $profilePath $folder
        if (Test-Path $source) { $validFolders += $folder }
    }
    
    $total = $validFolders.Count
    $completed = 0; $totalSize = 0; $copiedSize = 0
    
    Write-Host "`n 📁 ANALIZANDO CARPETAS DE $userName ..." -ForegroundColor $COLOR_ALERT
    foreach ($folder in $validFolders) {
        $source = Join-Path $profilePath $folder
        $size = Get-FolderSizeBytes $source
        $totalSize += $size
        Write-Host "    • 📂 $folder : $(Format-Bytes $size)" -ForegroundColor Gray
    }
    
    Write-Host "`n 📊 TOTAL A RESPALDAR: $(Format-Bytes $totalSize)" -ForegroundColor Cyan
    Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    foreach ($folder in $validFolders) {
        $source = Join-Path $profilePath $folder
        $target = Join-Path $destRoot $folder
        $folderSize = Get-FolderSizeBytes $source
        
        Write-Host ""
        Write-Host " ┌─────────────────────────────────────────────────────────" -ForegroundColor Cyan
        Write-Host " │ 📤 RESPALDANDO: $userName\$folder" -ForegroundColor Yellow
        Write-Host " │ 📏 TAMAÑO: $(Format-Bytes $folderSize)" -ForegroundColor Gray
        Write-Host " │ 📍 ORIGEN: $source" -ForegroundColor DarkGray
        Write-Host " │ 🎯 DESTINO: $target" -ForegroundColor DarkGray
        Write-Host " │" -ForegroundColor Cyan
        
        $optimalThreads = Get-OptimalRobocopyThreads $target
        Write-Host " │ ⚙️ HILOS ROBOCOPY: $optimalThreads" -ForegroundColor DarkGray
        
        robocopy $source $target /E /MT:$optimalThreads /R:3 /W:5 /XJ /NP /NFL /NDL /NJH /NJS /NC /NS /XF "pagefile.sys" "hiberfil.sys" "swapfile.sys" 2>&1 | Out-Null
        
        $completed++
        $copiedSize += $folderSize
        $percentTotal = if ($totalSize -gt 0) { [math]::Round(($copiedSize / $totalSize) * 100) } else { 0 }
        
        $barLength = 40
        $filled = [math]::Round($barLength * $percentTotal / 100)
        $bar = "█" * $filled + "░" * ($barLength - $filled)
        
        Write-Host " │" -ForegroundColor Cyan
        Write-Host " │ 📊 PROGRESO GENERAL: [$bar] $percentTotal%" -ForegroundColor Green
        Write-Host " │ ✅ COMPLETADAS: $completed de $total carpetas" -ForegroundColor Green
        Write-Host " │ 💾 COPIADO: $(Format-Bytes $copiedSize) de $(Format-Bytes $totalSize)" -ForegroundColor Green
        Write-Host " └─────────────────────────────────────────────────────────" -ForegroundColor Cyan
    }
    
    Write-Host "`n ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " ✅ RESPALDO COMPLETADO: $userName" -ForegroundColor Green
    Write-Host "    📂 UBICACIÓN: $destRoot" -ForegroundColor Gray
    Write-Host "    📊 TOTAL: $(Format-Bytes $totalSize) en $total carpetas" -ForegroundColor Gray
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
}

function Restore-ProfileData($BACKOPProfilePath, $TargetUsersRoot = $null) {
    $profileName = Split-Path $BACKOPProfilePath -Leaf
    if(-not $TargetUsersRoot){ $TargetUsersRoot = "$env:SystemDrive\Users" }
    $targetRoot = Join-Path $TargetUsersRoot $profileName
    
    if (!(Test-Path $targetRoot)) { New-Item -Path $targetRoot -ItemType Directory -Force | Out-Null }
    
    $foldersToRestore = Get-ChildItem -Path $BACKOPProfilePath -Directory -ErrorAction SilentlyContinue
    $total = $foldersToRestore.Count
    $completed = 0; $totalSize = 0; $restoredSize = 0
    
    Write-Host "`n 📁 ANALIZANDO CARPETAS DE $profileName ..." -ForegroundColor $COLOR_ALERT
    foreach ($folder in $foldersToRestore) {
        $size = Get-FolderSizeBytes $folder.FullName
        $totalSize += $size
        Write-Host "    • 📂 $($folder.Name) : $(Format-Bytes $size)" -ForegroundColor Gray
    }
    
    Write-Host "`n 📊 TOTAL A RESTAURAR: $(Format-Bytes $totalSize)" -ForegroundColor Cyan
    Write-Host " ─────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    foreach ($folder in $foldersToRestore) {
        $source = $folder.FullName
        $dest = Join-Path $targetRoot $folder.Name
        $folderSize = Get-FolderSizeBytes $source
        
        Write-Host ""
        Write-Host " ┌─────────────────────────────────────────────────────────" -ForegroundColor Cyan
        Write-Host " │ 📥 RESTAURANDO: $profileName\$($folder.Name)" -ForegroundColor Yellow
        Write-Host " │ 📏 TAMAÑO: $(Format-Bytes $folderSize)" -ForegroundColor Gray
        Write-Host " │ 📍 ORIGEN: $source" -ForegroundColor DarkGray
        Write-Host " │ 🎯 DESTINO: $dest" -ForegroundColor DarkGray
        Write-Host " │" -ForegroundColor Cyan
        
        robocopy $source $dest /E /MT:8 /R:0 /W:0 /XJ /NP /NFL /NDL /NJH /NJS /NC /NS /XF "pagefile.sys" "hiberfil.sys" "swapfile.sys" | Out-Null
        
        $completed++
        $restoredSize += $folderSize
        $percentTotal = if ($totalSize -gt 0) { [math]::Round(($restoredSize / $totalSize) * 100) } else { 0 }
        
        $barLength = 40
        $filled = [math]::Round($barLength * $percentTotal / 100)
        $bar = "█" * $filled + "░" * ($barLength - $filled)
        
        Write-Host " │" -ForegroundColor Cyan
        Write-Host " │ 📊 PROGRESO GENERAL: [$bar] $percentTotal%" -ForegroundColor Green
        Write-Host " │ ✅ COMPLETADAS: $completed de $total carpetas" -ForegroundColor Green
        Write-Host " │ 💾 RESTAURADO: $(Format-Bytes $restoredSize) de $(Format-Bytes $totalSize)" -ForegroundColor Green
        Write-Host " └─────────────────────────────────────────────────────────" -ForegroundColor Cyan
    }
    
    Write-Host "`n ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " ✅ RESTAURACIÓN COMPLETADA: $profileName" -ForegroundColor Green
    Write-Host "    📁 UBICACIÓN: $targetRoot" -ForegroundColor Gray
    Write-Host "    📊 TOTAL: $(Format-Bytes $totalSize) en $total carpetas" -ForegroundColor Gray
    Write-Host " ═════════════════════════════════════════════════════════════════" -ForegroundColor Green
}

function Invoke-Engine ($Mode, $Msg) {
    Show-MainTitle

    if ($Mode -eq "BACKOP") {
        Write-Host "`n 💾 BACKUP TOTAL - SELECCIONA EL TIPO DE RESPALDO" -ForegroundColor $COLOR_ALERT
        Write-Host " 👤 [A] PERFIL ACTUAL - Respaldar tu usuario (Escritorio, Documentos, etc.)" -ForegroundColor $COLOR_PRIMARY
        Write-Host " 👥 [B] TODOS LOS PERFILES LOCALES - Respaldar todos los usuarios del equipo" -ForegroundColor $COLOR_PRIMARY
        Write-Host " 📊 [C] EXPORTAR INVENTARIO - Lista de programas instalados y drivers" -ForegroundColor $COLOR_PRIMARY
        Write-Host " ☁️ [D] DUPLICATI - BACKUP avanzado a la nube (encriptado, programado)" -ForegroundColor $COLOR_PRIMARY
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $o = Read-MenuOption "`n > SELECCIONE" -Valid @("A","B","C","D","X")
        if($o -eq "X"){ return }

        if ($o -ne "D") {
            $selectedUnit = Show-DriveSelector -Title "SELECCIONAR DESTINO DE BACKUP"
            if (-not $selectedUnit) { return }
            $Base = Join-Path $selectedUnit.Path "BACKOPs"
            if (-not (Test-Path $Base)) { New-Item -Path $Base -ItemType Directory -Force | Out-Null }
        }

        if ($o -eq "A" -or $o -eq "B") {
            Show-MainTitle
            Write-Host "`n 📋 RESUMEN DE BACKUP" -ForegroundColor $COLOR_MENU
            Write-Host " 📂 DESTINO BASE: $Base" -ForegroundColor $COLOR_PRIMARY
            Write-Host " 💾 UNIDAD SELECCIONADA: $($selectedUnit.DeviceID) ($($selectedUnit.Label))" -ForegroundColor $COLOR_MENU
            Write-Host " 📊 ESPACIO LIBRE: $($selectedUnit.FreeGB) GB de $($selectedUnit.TotalGB) GB" -ForegroundColor Gray
            Write-Host " 📁 CARPETAS INCLUIDAS:" -ForegroundColor $COLOR_PRIMARY
            $USER_FOLDER_NAMES | ForEach-Object { Write-Host "  - 📄 $_" -ForegroundColor $COLOR_MENU }
            
            $estBytes = 0L
            if ($o -eq "A") {
                foreach ($rel in $USER_FOLDER_NAMES) {
                    $p = Join-Path $env:USERPROFILE $rel
                    if (Test-Path $p) { $estBytes += Get-FolderSizeBytes $p }
                }
            } else {
                $profiles = Get-UserProfilePaths
                foreach ($profile in $profiles) {
                    foreach ($rel in $USER_FOLDER_NAMES) {
                        $p = Join-Path $profile $rel
                        if (Test-Path $p) { $estBytes += Get-FolderSizeBytes $p }
                    }
                }
            }
            
            $freeBytes = Get-DriveFreeBytes $Base
            Write-Host "`n 📊 TAMAÑO APROX (SUMA DE CARPETAS): $(Format-Bytes $estBytes)" -ForegroundColor $COLOR_ALERT
            Write-Host " 💾 ESPACIO LIBRE DESTINO:            $(Format-Bytes $freeBytes)" -ForegroundColor $COLOR_ALERT
            Write-Log "BACKOP" "EstimateBytes=$estBytes FreeBytes=$freeBytes Base=$Base Choice=$o"
            
            if ($freeBytes -gt 0 -and $estBytes -gt 0 -and $freeBytes -lt ($estBytes * 1.2)) {
                Write-Host "`n [!] POSIBLE FALTA DE ESPACIO (recomendado >= 20% extra)." -ForegroundColor $COLOR_DANGER
                if (-not (Confirm-Critical "CONTINUAR CON POSIBLE POCO ESPACIO" "APLICAR")) { return }
            } else {
                Pause-Enter " ENTER PARA CONTINUAR"
            }
        }

        if ($o -ne "D") { $BACKOPRoot = Get-BACKOPRoot $Base }

        if ($o -eq "A") {
            Write-Log "BACKOP" "Choice=A ProfileRoot=$env:USERPROFILE"
            BACKOP-ProfileData $env:USERPROFILE $BACKOPRoot
            $verify = Read-MenuOption "`n VERIFICAR BACKOP (conteo rápido)? (S/N)" -Valid @("S","N")
            if($verify -eq "S"){
                $count = (Get-ChildItem -Path $BACKOPRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                Write-Host " [+] ARCHIVOS EN BACKOP: $count" -ForegroundColor $COLOR_PRIMARY
            }
            Pause-Enter "`n BACKOP DE PERFIL ACTUAL COMPLETADO EN: $BACKOPRoot. ENTER"
            return
        }

        if ($o -eq "B") {
            $profiles = Get-UserProfilePaths
            Write-Log "BACKOP" "Choice=B ProfilesCount=$(@($profiles).Count) BACKOPRoot=$BACKOPRoot"
            foreach ($profile in $profiles) { BACKOP-ProfileData $profile $BACKOPRoot }
            $verify = Read-MenuOption "`n VERIFICAR BACKOP (conteo rápido)? (S/N)" -Valid @("S","N")
            if($verify -eq "S"){
                $count = (Get-ChildItem -Path $BACKOPRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                Write-Host " [+] ARCHIVOS EN BACKOP: $count" -ForegroundColor $COLOR_PRIMARY
            }
            Pause-Enter "`n BACKOP DE TODOS LOS PERFILES COMPLETADO EN: $BACKOPRoot. ENTER"
            return
        }

        if ($o -eq "C") {
            if (!(Test-Path $BACKOPRoot)) { New-Item -Path $BACKOPRoot -ItemType Directory -Force | Out-Null }
            $appsFile = Join-Path $BACKOPRoot "InstalledApps_$((Get-Date).ToString('yyyyMMdd_HHmmss')).txt"
            $driversPath = Join-Path $BACKOPRoot "Drivers"
            $zipFile = Join-Path $BACKOPRoot "Drivers_$env:COMPUTERNAME.zip"
            
            Write-Log "BACKOP" "Choice=C Export Apps+Drivers to $BACKOPRoot"
            Write-Host "`n [+] EXPORTANDO LISTA DE PROGRAMAS INSTALADOS..." -ForegroundColor $COLOR_PRIMARY
            Get-Package | Sort-Object Name | Format-Table -AutoSize | Out-String | Out-File $appsFile -Encoding utf8
            
            Write-Host "[+] EXPORTANDO DRIVERS INSTALADOS..." -ForegroundColor $COLOR_PRIMARY
            if (!(Test-Path $driversPath)) { New-Item -Path $driversPath -ItemType Directory -Force | Out-Null }
            Export-WindowsDriver -Online -Destination $driversPath | Out-Null
            
            $comprimir = Read-MenuOption "`n ¿COMPRIMIR DRIVERS EN ZIP? (S/N)" -Valid @("S","N")
            if ($comprimir -eq "S") {
                Write-Host "[+] COMPRIMIENDO DRIVERS..." -ForegroundColor $COLOR_ALERT
                try {
                    Compress-Archive -Path "$driversPath\*" -DestinationPath $zipFile -Force -ErrorAction Stop
                    Write-Host " [✔] ZIP CREADO: $zipFile" -ForegroundColor Green
                    $eliminar = Read-MenuOption " ¿ELIMINAR CARPETA ORIGINAL DE DRIVERS? (S/N)" -Valid @("S","N")
                    if ($eliminar -eq "S") {
                        Remove-Item -Path $driversPath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host " [✔] CARPETA ORIGINAL ELIMINADA" -ForegroundColor Green
                    }
                } catch {
                    Write-Host " [✘] ERROR AL COMPRIMIR: $($_.Exception.Message)" -ForegroundColor $COLOR_DANGER
                }
            }
            
            if (Test-Path $zipFile) {
                Write-Host "`n 📦 TAMAÑO DEL ZIP: $(Format-Bytes (Get-Item $zipFile).Length)" -ForegroundColor Cyan
            }
            Pause-Enter "`n INVENTARIO CREADO EN: $BACKOPRoot. ENTER"
            return
        }

        if ($o -eq "D") {
            while ($true) {
                Show-MainTitle
                Write-Host "`n ☁️ DUPLICATI - BACKUP EN LA NUBE (Encriptado + Programado)" -ForegroundColor $COLOR_MENU
                Write-Host " -----------------------------------------------------------------------------"
                
                $duplicatiExe = Get-ChildItem -Path @("$env:ProgramFiles\Duplicati*", "${env:ProgramFiles(x86)}\Duplicati*", "$env:LOCALAPPDATA\Programs\Duplicati*") -Filter "Duplicati.Server.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                $duplicatiService = Get-Service -Name "Duplicati" -ErrorAction SilentlyContinue
                $isInstalled = ($duplicatiExe -ne $null) -or ($duplicatiService -ne $null)
                
                if ($isInstalled) { Write-Host "                               [OK] Duplicati ya está instalado" -ForegroundColor Green } 
                else { Write-Host "                               [!] Duplicati NO está instalado" -ForegroundColor Red }
                
                Write-Host "`n ⚙️ OPCIONES:" -ForegroundColor $COLOR_PRIMARY
                Write-Host " -----------------------------------------------------------------------------"
                Write-Host " 🌐 [1] ABRIR PANEL DE CONTROL (WEB) - http://localhost:8200"
                Write-Host " 🔄 [2] REINICIAR SERVICIO / RESTAURAR ICONO DE BANDEJA"
                Write-Host " 📦 [3] INSTALAR / REPARAR DUPLICATI"
                Write-Host " 🗑️ [4] DESINSTALAR DUPLICATI"
                Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
                Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
                Write-Host " ❌ [X] VOLVER AL MENÚ DE BACKUP" -ForegroundColor $COLOR_DANGER
                
                $dupOpt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","X")
                if ($dupOpt -eq "X") { break }

                switch ($dupOpt) {
                    "1" {
                        Write-Host "`n [+] Abriendo panel de Duplicati en el navegador..." -ForegroundColor $COLOR_PRIMARY
                        $serviceRunning = Get-Service -Name "Duplicati" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
                        if (-not $serviceRunning -and $isInstalled) {
                            Start-Service -Name "Duplicati" -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 3
                        }
                        try { Start-Process "http://localhost:8200" } catch { Write-Host " [✘] Error al abrir navegador." -ForegroundColor $COLOR_DANGER }
                        Pause-Enter "`n ENTER para volver"
                    }
                    "2" {
                        Write-Host "`n [+] Reiniciando servicio..." -ForegroundColor $COLOR_PRIMARY
                        if (-not $isInstalled) { Write-Host " [!] No instalado."; Pause-Enter " ENTER"; continue }
                        Stop-Service -Name "Duplicati" -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        Start-Service -Name "Duplicati" -ErrorAction SilentlyContinue
                        Write-Host " [✔] Servicio reiniciado." -ForegroundColor Green
                        Pause-Enter "`n ENTER para volver"
                    }
                    "3" {
                        if ($isInstalled) { if ((Read-MenuOption " ¿Reinstalar? (S/N)" -Valid @("S","N")) -ne "S") { continue } }
                        Write-Host "`n [+] Instalando..." -ForegroundColor Yellow
                        winget install Duplicati.Duplicati --silent --accept-package-agreements
                        Pause-Enter "`n ENTER para volver"
                    }
                    "4" {
                        if (-not $isInstalled) { Pause-Enter " [!] No instalado."; continue }
                        if (-not (Confirm-Critical "DESINSTALAR DUPLICATI" "BORRAR")) { continue }
                        winget uninstall Duplicati.Duplicati --silent
                        Write-Host " [✔] Desinstalado." -ForegroundColor Green
                        Pause-Enter " ENTER para volver"
                    }
                }
            }
        }
        return
    }

    if ($Mode -eq "RESTORE") {
        Write-Host "`n 📀 RESTORE TOTAL" -ForegroundColor $COLOR_ALERT
        Write-Host " 🔍 [B] BUSCAR BACKOP EN TODAS LAS UNIDADES (C:, D:, USB, etc.)" -ForegroundColor $COLOR_PRIMARY
        Write-Host "`n ⌨️ CONTROL" -ForegroundColor Gray
        Write-Host " -----------------------------------------------------------------------------" -ForegroundColor $COLOR_DANGER
        Write-Host " ❌ [X] VOLVER" -ForegroundColor $COLOR_DANGER
        
        $choice = Read-MenuOption "🔽 > SELECCIONE" -Valid @("B","X")
        if ($choice -eq "X") { return }
        
        if ($choice -eq "B") {
            Write-Host "`n [+] Buscando en todas las unidades locales y USB..." -ForegroundColor $COLOR_PRIMARY
            $units = Scan-DriveUnits
            $allBACKOPs = @()
            foreach ($unit in $units) {
                $found = Find-BACKOPsInUnit -UnitPath $unit.Path
                if ($found.Count -gt 0) { $allBACKOPs += $found }
            }
            
            if ($allBACKOPs.Count -eq 0) {
                Write-Host "`n ❌ No se encontraron BACKOPs en ninguna unidad." -ForegroundColor $COLOR_DANGER
                Pause-Enter " ENTER"
                return
            }
            
            Show-MainTitle
            Write-Host "`n 📋 BACKOPS ENCONTRADOS EN TODAS LAS UNIDADES:" -ForegroundColor $COLOR_PRIMARY
            Write-Host $Global:LINEA -ForegroundColor Gray
            
            for ($i = 0; $i -lt $allBACKOPs.Count; $i++) {
                Write-Host "   [$($i+1)] $($allBACKOPs[$i].Name)" -ForegroundColor $COLOR_MENU
                Write-Host "          📍 Unidad: $([System.IO.Path]::GetPathRoot($allBACKOPs[$i].FullName))" -ForegroundColor DarkGray
                Write-Host "          📅 Creado: $($allBACKOPs[$i].CreationTime)" -ForegroundColor DarkGray
                Write-Host "          💾 Tamaño: $($allBACKOPs[$i].SizeGB) GB" -ForegroundColor DarkGray
                Write-Host ""
            }
            
            Write-Host $Global:LINEA -ForegroundColor Gray
            Write-Host " [X] CANCELAR" -ForegroundColor $COLOR_DANGER
            
            $sel = Read-Host "`n > SELECCIONE BACKOP (NÚMERO)"
            if ($sel -eq "X" -or $sel -eq "x") { return }
            
            if ($sel -match "^\d+$" -and [int]$sel -le $allBACKOPs.Count) {
                $BACKOPRoot = $allBACKOPs[[int]$sel-1].FullName
                Write-Host "`n ✅ BACKOP seleccionado: $BACKOPRoot" -ForegroundColor Green
            } else {
                Write-Host "`n ❌ Selección inválida." -ForegroundColor $COLOR_DANGER
                return
            }
        }
        
        if (-not (Test-Path $BACKOPRoot)) {
            Write-Host "`n ❌ El BACKOP seleccionado no existe o no es accesible." -ForegroundColor $COLOR_DANGER
            Pause-Enter " ENTER"
            return
        }
        
        $BACKOPProfiles = Get-ChildItem -Path $BACKOPRoot -Directory -ErrorAction SilentlyContinue
        if (!$BACKOPProfiles) { 
            Write-Host "Backop vacío o no válido." -ForegroundColor $COLOR_DANGER
            Pause-Enter " ENTER"
            return 
        }
        
        Write-Host "`n PERFILES EN EL BACKOP:" -ForegroundColor $COLOR_PRIMARY
        $BACKOPProfiles | ForEach-Object { Write-Host " [ ] $($_.Name)" -ForegroundColor $COLOR_MENU }
        $profileChoice = Read-Host ' NOMBRE DE PERFIL A RESTAURAR (ENTER PARA TODOS, X PARA VOLVER)'
        if ($profileChoice.ToUpper() -eq "X") { return }
        
        $targetUsersRoot = "$env:SystemDrive\Users"
        $alt = Read-MenuOption " RESTAURAR EN UBICACIÓN ALTERNATIVA? (S/N)" -Valid @("S","N")
        if($alt -eq "S"){
            $custom = Read-Host " RUTA BASE (ej: D:\Restores)"
            if($custom){ $targetUsersRoot = $custom }
        }
        
        if (-not $profileChoice) {
            foreach ($profile in $BACKOPProfiles) { Restore-ProfileData $profile.FullName $targetUsersRoot }
        } else {
            $selected = $BACKOPProfiles | Where-Object { $_.Name -ieq $profileChoice }
            if ($selected) { Restore-ProfileData $selected[0].FullName $targetUsersRoot }
        }
        Pause-Enter "`n PROCESO FINALIZADO. ENTER"
    }
}
