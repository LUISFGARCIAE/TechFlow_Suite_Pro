# ============================================================
# TECHFLOW SUITE PRO - HARDWARE & TOOLS MODULE (100% CLONADO)
# ============================================================

$COLOR_PRIMARY = $Global:COLOR_PRIMARY
$COLOR_ALERT   = $Global:COLOR_ALERT
$COLOR_DANGER  = $Global:COLOR_DANGER
$COLOR_MENU    = $Global:COLOR_MENU

# ============================================================
# 🌐 RED Y REPARACIÓN (OPCIÓN M)
# ============================================================
function Invoke-NetworkRepair {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 🌐 RED Y REPARACIÓN DE CONECTIVIDAD" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🔍 [1] TEST DE CONECTIVIDAD (Ping Cloudflare 1.1.1.1 y Gateway)"
        Write-Host " 🧹 [2] LIMPIAR CACHÉ DNS (FlushDNS)"
        Write-Host " 🔄 [3] LIBERAR Y RENOVAR IP (DHCP Release / Renew)"
        Write-Host " ⚙️ [4] REINICIAR PILA TCP/IP Y WINSOCK (Netsh Reset)"
        Write-Host " 📋 [5] VER CONFIGURACIÓN IP Y ADAPTADORES (Get-NetIPConfiguration)"
        Write-Host " 🔌 [6] REINICIAR ADAPTADORES DE RED (Ciclo Deshabilitar/Habilitar)"
        Write-Host " 🛡️ [7] RESTAURAR FIREWALL DE WINDOWS A VALORES POR DEFECTO"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $sub = Read-MenuOption "`n > SELECCIONE (1-7 o X)" -Valid @("1","2","3","4","5","6","7","X")
        if ($sub -eq "X") { break }

        switch ($sub) {
            "1" {
                Write-Host "`n [+] Probando resolución y latencia..." -ForegroundColor $COLOR_PRIMARY
                Test-Connection -ComputerName 1.1.1.1 -Count 4 | Format-Table Address, ResponseTime, StatusCode
                Test-Connection -ComputerName 8.8.8.8 -Count 4 | Format-Table Address, ResponseTime, StatusCode
                Pause-Enter
            }
            "2" {
                Write-Host "`n [+] Limpiando caché DNS del sistema..." -ForegroundColor $COLOR_PRIMARY
                Clear-DnsClientCache -ErrorAction SilentlyContinue
                ipconfig /flushdns
                Write-Host " ✅ Caché DNS vaciada correctamente." -ForegroundColor Green
                Pause-Enter
            }
            "3" {
                Write-Host "`n [+] Liberando y renovando concesiones DHCP..." -ForegroundColor $COLOR_PRIMARY
                ipconfig /release
                Start-Sleep -Seconds 1
                ipconfig /renew
                Write-Host " ✅ Parámetros IP renovados." -ForegroundColor Green
                Pause-Enter
            }
            "4" {
                if (-not (Require-Admin "reiniciar pila de red")) { continue }
                if (Confirm-Critical "REINICIAR PILA TCP/IP Y WINSOCK" "REINICIAR") {
                    netsh winsock reset
                    netsh int ip reset
                    Write-Host " ✅ Winsock e IP restablecidos. Se recomienda reiniciar el equipo." -ForegroundColor Green
                    Pause-Enter
                }
            }
            "5" {
                Show-MainTitle
                Write-Host "`n 📋 ADAPTADORES Y DIRECCIONES ACTIVAS:" -ForegroundColor $COLOR_PRIMARY
                Get-NetIPConfiguration | Format-Table InterfaceAlias, IPv4Address, IPv4DefaultGateway
                ipconfig /all | Out-String | Select-String -Pattern "Adaptador|IPv4|Mascara|Puerta|Servidores DNS" -Context 0,2
                Pause-Enter
            }
            "6" {
                if (-not (Require-Admin "reiniciar adaptadores")) { continue }
                Write-Host "`n [+] Reiniciando tarjetas de red físicas..." -ForegroundColor $COLOR_PRIMARY
                Get-NetAdapter | Where-Object { $_.PhysicalMediaType -ne "Unspecified" } | ForEach-Object {
                    Write-Host "  - Reiniciando $($_.Name)..." -ForegroundColor Yellow
                    Restart-NetAdapter -Name $_.Name -Confirm:$false
                }
                Write-Host " ✅ Adaptadores reiniciados." -ForegroundColor Green
                Pause-Enter
            }
            "7" {
                if (-not (Require-Admin "restaurar Firewall")) { continue }
                if (Confirm-Critical "RESTAURAR FIREWALL DE WINDOWS" "RESTAURAR") {
                    netsh advfirewall reset
                    Write-Host " ✅ Reglas de Firewall restauradas a valores predeterminados." -ForegroundColor Green
                    Pause-Enter
                }
            }
        }
    }
}

# ============================================================
# 💾 MANTENIMIENTO DE DISCO (OPCIÓN N)
# ============================================================
function Invoke-DiskMaintenance {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 💾 MANTENIMIENTO Y SALUD DE DISCOS" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ⚡ [1] OPTIMIZAR / TRIM (Desfragmentar HDD o TRIM en SSD)"
        Write-Host " 🩺 [2] ESTADO DE SALUD FÍSICA (S.M.A.R.T. / Get-PhysicalDisk)"
        Write-Host " 🔍 [3] ESCANEO RÁPIDO CHKDSK (Solo lectura, sin desmontar)"
        Write-Host " 🛠️ [4] PROGRAMAR REPARACIÓN PROFUNDA (CHKDSK /F /R al reiniciar)"
        Write-Host " 📊 [5] RESUMEN DE ESPACIO EN TODAS LAS PARTICIONES"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $opt = Read-MenuOption "`n > SELECCIONE (1-5 o X)" -Valid @("1","2","3","4","5","X")
        if ($opt -eq "X") { break }

        switch ($opt) {
            "1" {
                if (-not (Require-Admin "optimizar unidades")) { continue }
                Write-Host "`n [+] Optimizando unidades del sistema..." -ForegroundColor $COLOR_PRIMARY
                Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.DriveType -eq 'Fixed' } | ForEach-Object {
                    Write-Host "  → Optimizando unidad $($_.DriveLetter):..." -ForegroundColor Yellow
                    Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -Verbose
                }
                Write-Host " ✅ Proceso de optimización completado." -ForegroundColor Green
                Pause-Enter
            }
            "2" {
                Show-MainTitle
                Write-Host "`n 🩺 SALUD DE DISCOS FÍSICOS:" -ForegroundColor $COLOR_PRIMARY
                Get-PhysicalDisk | Format-Table -AutoSize DeviceId, FriendlyName, MediaType, HealthStatus, OperationalStatus, @{Name="Size (GB)";Expression={[math]::Round($_.Size / 1GB, 2)}}
                Pause-Enter
            }
            "3" {
                Write-Host "`n [+] Ejecutando CHKDSK C: en modo solo lectura..." -ForegroundColor $COLOR_PRIMARY
                chkdsk C:
                Pause-Enter
            }
            "4" {
                if (-not (Require-Admin "programar CHKDSK")) { continue }
                if (Confirm-Critical "PROGRAMAR REPARACIÓN DE DISCO C: AL REINICIO" "REPARAR") {
                    echo "S" | chkdsk C: /f /r
                    Write-Host " ✅ CHKDSK programado. Se ejecutará automáticamente en el próximo arranque." -ForegroundColor Green
                    Pause-Enter
                }
            }
            "5" {
                Show-MainTitle
                Write-Host "`n 📊 ESPACIO EN DISCOS Y VOLÚMENES:" -ForegroundColor $COLOR_PRIMARY
                Get-Volume | Where-Object { $_.DriveLetter } | Format-Table DriveLetter, FileSystemLabel, FileSystem, @{Name="Capacidad (GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="Libre (GB)";Expression={[math]::Round($_.SizeRemaining/1GB,2)}}
                Pause-Enter
            }
        }
    }
}

# ============================================================
# 🛠️ SYSINTERNALS KIT (FORMATO VERTICAL 1:1)
# ============================================================
function Invoke-SysinternalsKit {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 🛠️ SYSINTERNALS KIT - 11 HERRAMIENTAS PRO" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🔍 [1]  PROCEXP       - Process Explorer (gestor de procesos avanzado)"
        Write-Host " 🚀 [2]  AUTORUNS     - Programas de inicio, servicios, tareas, drivers"
        Write-Host " 📊 [3]  PROCMON      - Monitor en tiempo real de archivos, registro y red"
        Write-Host " 🌐 [4]  TCPVIEW      - Conexiones y puertos abiertos por proceso"
        Write-Host " 🧠 [5]  RAMMAP       - Análisis detallado y vaciado de memoria física"
        Write-Host " 📋 [6]  VMMAP        - Mapa y uso de memoria virtual por aplicación"
        Write-Host " 💿 [7]  DISK2VHD     - Conversión de disco físico a disco virtual VHD"
        Write-Host " 🔧 [8]  WINOBJ       - Explorador del espacio de objetos del kernel NT"
        Write-Host " ✅ [9]  SIGCHECK     - Verificación de firmas y detección VirusTotal"
        Write-Host " 🗑️ [10] SDELETE      - Borrado seguro de archivos y espacio libre"
        Write-Host " 🔐 [11] ACCESSENUM   - Auditoría de permisos en directorios y llaves"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X]  VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $sub = Read-MenuOption "`n > SELECCIONE (1-11 o X)" -Valid @("1","2","3","4","5","6","7","8","9","10","11","X")
        if ($sub -eq "X") { break }
        
        $toolMap = @{
            "1"="procexp64.exe"; "2"="autoruns64.exe"; "3"="procmon64.exe"; "4"="tcpview64.exe"
            "5"="RAMMap64.exe"; "6"="vmmap64.exe"; "7"="disk2vhd64.exe"; "8"="winobj64.exe"
            "9"="sigcheck64.exe"; "10"="sdelete64.exe"; "11"="AccessEnum.exe"
        }
        
        $toolName = $toolMap[$sub]
        $dest = "$Global:AppRoot\$toolName"
        
        if (-not (Test-Path $dest)) {
            Write-Host "`n[+] Descargando $toolName desde live.sysinternals.com..." -ForegroundColor $COLOR_PRIMARY
            try {
                Invoke-WebRequest -Uri "https://live.sysinternals.com/$toolName" -OutFile $dest -UseBasicParsing -ErrorAction Stop
                Write-Host "[✔] Descargado correctamente" -ForegroundColor Green
            } catch {
                Write-Host "[✘] Error al descargar: $_" -ForegroundColor $COLOR_DANGER
                Pause-Enter " ENTER"
                continue
            }
        }
        Write-Host "[+] Ejecutando $toolName..." -ForegroundColor $COLOR_PRIMARY
        Start-Process $dest -Verb RunAs
    }
}

# ============================================================
# 👥 GESTIÓN DE USUARIOS (FORMATO VERTICAL 1:1)
# ============================================================
function Invoke-UserManager {
    while ($true) { 
        Show-MainTitle
        Write-Host "`n 👥 GESTIÓN DE USUARIOS LOCALES Y ADMINISTRADORES" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 👤 USUARIOS LOCALES:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   📋 [A] LISTAR USUARIOS         - Muestra todas las cuentas locales"
        Write-Host "   ➕ [B] CREAR ADMINISTRADOR     - Crea nuevo usuario en grupo Administradores"
        Write-Host "   ❌ [C] ELIMINAR USUARIO        - Remueve cuenta local del sistema"
        Write-Host ""
        Write-Host " 👑 ADMINISTRADOR OCULTO (BUILT-IN):" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   ✅ [D] ACTIVAR SUPER ADMIN     - Habilita la cuenta integrada de Administrador"
        Write-Host "   ⛔ [E] DESACTIVAR SUPER ADMIN  - Deshabilita la cuenta integrada"
        Write-Host "   🔑 [F] CAMBIAR CONTRASEÑA      - Establece nueva clave a cualquier usuario"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $u = Read-MenuOption "`n > SELECCIONE" -Valid @("A","B","C","D","E","F","X")
        if ($u -eq "X") { break }
        if (-not (Require-Admin "gestión de usuarios")) { continue }

        switch ($u) {
            "A" { Show-MainTitle; net user; Pause-Enter }
            "B" {
                $n = (Read-Host " NOMBRE DEL NUEVO ADMIN").Trim()
                if ($n) {
                    net user "$n" /add
                    net localgroup administrators "$n" /add
                    Write-Host " ✅ Administrador local creado exitosamente." -ForegroundColor Green
                }
                Pause-Enter
            }
            "C" {
                $n = (Read-Host " NOMBRE DEL USUARIO A ELIMINAR").Trim()
                if ($n -and ($n.ToLower() -ne $env:USERNAME.ToLower())) {
                    if (Confirm-Critical "ELIMINAR USUARIO '$n'" "BORRAR") {
                        net user "$n" /delete
                        Write-Host " ✅ Usuario eliminado." -ForegroundColor Green
                    }
                } else {
                    Write-Host " [!] No es posible eliminar al usuario en sesión actual." -ForegroundColor Red
                }
                Pause-Enter
            }
            "D" {
                if (Confirm-Critical "ACTIVAR SUPER ADMIN" "APLICAR") {
                    net user administrador /active:yes 2>$null
                    net user administrator /active:yes 2>$null
                    Write-Host " ✅ Cuenta Super Admin activada." -ForegroundColor Green
                }
                Pause-Enter
            }
            "E" {
                if (Confirm-Critical "DESACTIVAR SUPER ADMIN" "APLICAR") {
                    net user administrador /active:no 2>$null
                    net user administrator /active:no 2>$null
                    Write-Host " ✅ Cuenta Super Admin desactivada." -ForegroundColor Green
                }
                Pause-Enter
            }
            "F" {
                $n = (Read-Host " NOMBRE DE USUARIO").Trim()
                $p = Read-Host " NUEVA CONTRASEÑA"
                if ($n -and $p -and (Confirm-Critical "CAMBIAR CONTRASEÑA DE '$n'" "APLICAR")) {
                    net user "$n" $p
                    Write-Host " ✅ Contraseña modificada correctamente." -ForegroundColor Green
                }
                Pause-Enter
            }
        }
    }
}

# ============================================================
# 🖥️ ESCRITORIO REMOTO (FORMATO VERTICAL 1:1)
# ============================================================
function Invoke-RemoteDesktop {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 🖥️ ESCRITORIO REMOTO Y CONEXIONES" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🖥️ [1] RDP NATIVO (MSTSC) - Conexión de escritorio remoto estándar de Windows"
        Write-Host " 🚀 [2] ANYDESK            - Asistencia remota rápida y portable"
        Write-Host " 🔓 [3] RUSTDESK           - Cliente de escritorio remoto open source"
        Write-Host " 👁️ [4] TEAMVIEWER         - Conexión y soporte corporativo"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $sub = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","X")
        if ($sub -eq "X") { break }
        switch ($sub) {
            "1" { Start-Process "mstsc.exe" }
            "2" { winget install AnyDesk.AnyDesk --silent; Pause-Enter }
            "3" { winget install RustDesk.RustDesk --silent; Pause-Enter }
            "4" { winget install TeamViewer.TeamViewer --silent; Pause-Enter }
        }
    }
}

# ============================================================
# 🧹 PURGA Y FORMATEO (FORMATO VERTICAL 1:1)
# ============================================================
function Show-DiagnosticMenu {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 🧹 PURGA Y FORMATEO - LIMPIEZA AVANZADA DEL SISTEMA" -ForegroundColor $COLOR_DANGER
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🗑️ [1] LIMPIAR TEMPORALES PROFUNDO      - Purga carpetas Temp y cachés"
        Write-Host " 🧽 [2] LIMPIAR CACHÉ DE WINDOWS (WinSxS)- Limpieza de almacén de componentes DISM"
        Write-Host " 🔄 [3] ELIMINAR ACTUALIZACIONES OBSOLETAS- Remueve respaldos de parches antiguos"
        Write-Host " 📊 [4] LIBERADOR DE ESPACIO (CLEANMGR)  - Abre la herramienta nativa de Windows"
        Write-Host " ⚡ [5] FORMATEO RÁPIDO DE UNIDAD USB    - Formatea unidad USB en FAT32/NTFS"
        Write-Host " 💿 [6] CREAR USB BOOTEABLE (RUFUS)      - Descarga oficial de Rufus"
        Write-Host " 🛠️ [8] DISKPART SIMPLIFICADO            - Gestor guiado de particiones y unidades"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $opt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","5","6","8","X")
        if ($opt -eq "X") { break }
        
        switch ($opt) {
            "1" {
                Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host " ✅ Limpieza completada" -ForegroundColor Green
                Pause-Enter
            }
            "2" {
                if (Require-Admin "WinSxS") {
                    dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
                    Write-Host " ✅ WinSxS optimizado" -ForegroundColor Green
                    Pause-Enter
                }
            }
            "3" {
                if (Require-Admin "actualizaciones") {
                    dism /online /Cleanup-Image /SPSuperseded
                    Write-Host " ✅ Actualizaciones antiguas purgadas" -ForegroundColor Green
                    Pause-Enter
                }
            }
            "4" { Start-Process "cleanmgr.exe"; Pause-Enter " ENTER después de cerrar" }
            "5" {
                $l = Read-Host " LETRA DE LA UNIDAD USB (ej: D)"
                if ($l -and (Confirm-Critical "FORMATEAR UNIDAD $($l):" "FORMATEAR")) {
                    & cmd /c "format $($l): /FS:FAT32 /Q /Y"
                    Write-Host " ✅ Formateo finalizado" -ForegroundColor Green
                }
                Pause-Enter
            }
            "6" { Start-Process "https://rufus.ie/es/"; Pause-Enter }
            "8" { Invoke-SimpleDiskPart }
        }
    }
}

# ============================================================
# 🛠️ DISKPART SIMPLIFICADO (FORMATO VERTICAL 1:1)
# ============================================================
function Invoke-SimpleDiskPart {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 🛠️ DISKPART SIMPLIFICADO - ADMINISTRACIÓN DE DISCOS Y PARTICIONES" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 📊 INFORMACIÓN:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   [1]  LISTAR DISCOS FÍSICOS"
        Write-Host "   [2]  VER DETALLES DE UN DISCO"
        Write-Host "   [3]  VER VOLÚMENES Y LETRAS ASIGNADAS"
        Write-Host ""
        Write-Host " ⚙️ GESTIÓN DE PARTICIONES:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   [4]  ASIGNAR LETRA DE UNIDAD"
        Write-Host "   [5]  EXTENDER PARTICIÓN"
        Write-Host "   [6]  REDUCIR PARTICIÓN (SHRINK)"
        Write-Host ""
        Write-Host " ⚡ PREPARACIÓN Y FORMATEO USB:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   [9]  LIMPIAR UNIDAD POR COMPLETO (CLEAN)"
        Write-Host "   [10] FORMATEAR A FAT32 (Rápido)"
        Write-Host "   [11] FORMATEAR A NTFS (Rápido)"
        Write-Host "   [12] MARCAR PARTICIÓN COMO ACTIVA (BOOT)"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ ANTERIOR" -ForegroundColor $COLOR_DANGER
        
        $opt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","5","6","9","10","11","12","X")
        if ($opt -eq "X") { break }
        
        $script = ""
        switch ($opt) {
            "1" { $script = "list disk`nexit" }
            "2" { $d = Read-Host " NÚMERO DE DISCO"; $script = "select disk $d`ndetail disk`nexit" }
            "3" { $script = "list volume`nexit" }
            "4" { $d = Read-Host " DISCO"; $p = Read-Host " PARTICIÓN"; $l = Read-Host " LETRA"; $script = "select disk $d`nselect partition $p`nassign letter=$l`nexit" }
            "5" { $d = Read-Host " DISCO"; $p = Read-Host " PARTICIÓN"; $script = "select disk $d`nselect partition $p`nextend`nexit" }
            "6" { $d = Read-Host " DISCO"; $p = Read-Host " PARTICIÓN"; $s = Read-Host " MB A REDUCIR"; $script = "select disk $d`nselect partition $p`nshrink desired=$s`nexit" }
            "9" { $d = Read-Host " DISCO"; if (Confirm-Critical "LIMPIAR DISCO $d" "BORRAR") { $script = "select disk $d`nclean`ncreate partition primary`nactive`nformat fs=ntfs quick`nassign`nexit" } }
            "10"{ $d = Read-Host " DISCO"; $p = Read-Host " PARTICIÓN"; if (Confirm-Critical "FORMAT FAT32" "FORMATEAR") { $script = "select disk $d`nselect partition $p`nformat fs=fat32 quick`nexit" } }
            "11"{ $d = Read-Host " DISCO"; $p = Read-Host " PARTICIÓN"; if (Confirm-Critical "FORMAT NTFS" "FORMATEAR") { $script = "select disk $d`nselect partition $p`nformat fs=ntfs quick`nexit" } }
            "12"{ $d = Read-Host " DISCO"; $p = Read-Host " PARTICIÓN"; if (Confirm-Critical "ACTIVAR BOOT" "APLICAR") { $script = "select disk $d`nselect partition $p`nactive`nexit" } }
        }
        if ($script) {
            $tempFile = [System.IO.Path]::GetTempFileName()
            $script | Out-File -FilePath $tempFile -Encoding ascii
            diskpart /s $tempFile
            Remove-Item $tempFile -Force
        }
        Pause-Enter
    }
}

# ============================================================
# 🔧 GESTIÓN DE DRIVERS
# ============================================================
function Invoke-DriverManagement {
    while ($true) { 
        Show-MainTitle
        Write-Host "`n 🔧 GESTION DE DRIVERS PRO" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 💾 [A] EXPORTAR DRIVERS (Backup local en carpeta del equipo)"
        Write-Host " 🔄 [B] RE-INSTALAR DRIVERS (Desde carpeta de backup)"
        Write-Host " 🔍 [C] BUSCAR EN SERVIDORES OFICIALES (Microsoft Update)"
        Write-Host " 🆔 [D] VER IDENTIFICADORES DE HARDWARE (Sin driver / Con error)"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
      
        $o = Read-MenuOption "`n > SELECCIONE" -Valid @("A","B","C","D","X")
        if ($o -eq "X") { break }
        
        if ($o -eq "A") {
            if (-not (Require-Admin "exportar drivers")) { continue }
            $p = "$Global:AppRoot\Drivers_$env:COMPUTERNAME"
            if (-not (Test-Path $p)) { New-Item $p -ItemType Directory -Force | Out-Null }
            Write-Host " [+] Exportando controladores instalados..." -ForegroundColor $COLOR_MENU
            Export-WindowsDriver -Online -Destination $p
            Pause-Enter " [+] Backup creado en: $p. Presiona ENTER"
        }
        if ($o -eq "B") {
            if (-not (Require-Admin "instalar drivers")) { continue }
            $path = "$Global:AppRoot\Drivers_$env:COMPUTERNAME"
            if (Test-Path $path) {
                Write-Host " [+] Re-instalando controladores desde backup..." -ForegroundColor $COLOR_PRIMARY
                $infs = Get-ChildItem "$path\*.inf" -Recurse -ErrorAction SilentlyContinue
                Write-Host " [+] Controladores INF encontrados: $(if ($infs) { $infs.Count } else { 0 })" -ForegroundColor $COLOR_MENU
                foreach ($inf in $infs) { pnputil /add-driver $inf.FullName /install 2>&1 | Out-Null }
                Pause-Enter " [+] Proceso finalizado. Presiona ENTER"
            } else {
                Write-Host " [!] No se encontró carpeta de backup en: $path" -ForegroundColor $COLOR_DANGER
                Start-Sleep -Seconds 2
            }
        }
        if ($o -eq "C") {
            if (-not (Require-Admin "actualizar drivers")) { continue }
            Write-Host " 🔌 [+] Conectando con Microsoft Update..." -ForegroundColor $COLOR_PRIMARY
            if (-not (Get-Module -ListAvailable PSWindowsUpdate)) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
                Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser | Out-Null
            }
            Import-Module PSWindowsUpdate
            Get-WindowsUpdate -Category "Drivers" -Install -AcceptAll -IgnoreReboot 2>&1
            Write-Host "`n ✅ Búsqueda y actualización completada." -ForegroundColor Green
            Pause-Enter
        }
        if ($o -eq "D") {
            $missing = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
            if ($missing) {
                $missing | Select-Object Name, Status, DeviceID | Out-GridView -Title "Drivers con Incidencias"
            } else {
                Write-Host " [+] Todos los dispositivos de hardware cuentan con controlador operativo." -ForegroundColor Green
            }
            Pause-Enter
        }
    }
}

# ============================================================
# 🛠️ SOPORTE TÉCNICO PRO (FORMATO VERTICAL 1:1)
# ============================================================
function Invoke-TechSupport {
    while ($true) { 
        Show-MainTitle
        Write-Host "`n 🛠️ SOPORTE TECNICO PRO" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 💾 [A] SALUD DE DISCO           - Estado físico y verificación rápida"
        Write-Host " 🔧 [B] REPARAR SISTEMA          - Escaneo SFC y restauración DISM"
        Write-Host " 🔑 [C] CLAVE BIOS (OEM)         - Recupera licencia original embebida"
        Write-Host " ⏰ [D] SINCRONIZAR HORA         - Fuerza sincronización NTP"
        Write-Host " 🔋 [F] SALUD DE BATERÍA         - Diagnóstico y reporte HTML"
        Write-Host " 🌡️ [T] TEMPERATURAS CPU/GPU     - Sensores térmicos en tiempo real"
        Write-Host " ℹ️ [G] INFORMACIÓN TÉCNICA      - Auditoría completa de HW y SW"
        Write-Host " 🌲 [P] ÁRBOL DE PROCESOS        - Jerarquía visual de subprocesos"
        Write-Host " 🔒 [L] DESBLOQUEO DE ARCHIVOS   - Detecta qué proceso bloquea un archivo"
        Write-Host " ⚡ [Z] MODO DIOS (PANEL TOTAL)  - Acceso a todas las funciones de Windows"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $s = Read-MenuOption "`n > SELECCIONE" -Valid @("A","B","C","D","F","G","T","P","L","Z","X")
        if ($s -eq "X") { break }

        switch ($s) {
            "A" { Get-PhysicalDisk | Format-Table -AutoSize; chkdsk C:; Pause-Enter }
            "B" {
                if (Require-Admin "reparar sistema") {
                    sfc /scannow
                    dism /online /cleanup-image /restorehealth
                    Pause-Enter
                }
            }
            "C" {
                $key = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
                Write-Host "`n CLAVE ORIGINAL DETECTADA: $key" -ForegroundColor Green
                Pause-Enter
            }
            "D" {
                if (Require-Admin "sincronizar hora") {
                    net stop w32time | Out-Null; net start w32time | Out-Null
                    w32tm /resync /force
                    Pause-Enter
                }
            }
            "F" { Show-BatteryHealth }
            "G" { Show-FullSystemInfo }
            "T" { Show-Temperatures }
            "P" { Show-ProcessTree }
            "L" { Get-FileLockingProcess }
            "Z" { Start-Process "explorer.exe" "shell:::{ED7BA470-8E54-465E-825C-99712043E01C}"; Pause-Enter }
        }
    }
}

function Show-BatteryHealth {
    Show-MainTitle
    Write-Host "`n ===== SALUD DE BATERÍA =====`n" -ForegroundColor Cyan
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if (-not $battery) {
        Write-Host " [!] No se detectó ninguna batería en este equipo." -ForegroundColor $COLOR_DANGER
        Pause-Enter " ENTER"; return
    }
    Write-Host " ESTADO ACTUAL:" -ForegroundColor $COLOR_PRIMARY
    Write-Host "   Carga: $(if ($battery.EstimatedChargeRemaining) { "$($battery.EstimatedChargeRemaining)%" } else { 'N/A' })" -ForegroundColor $COLOR_MENU
    
    $tempHtml = Join-Path $env:TEMP ("BatteryReport_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".html")
    powercfg /batteryreport /output "$tempHtml" 2>&1 | Out-Null
    if (Test-Path $tempHtml) {
        Write-Host " [✔] Reporte generado: $tempHtml" -ForegroundColor Green
        if ((Read-Host " ¿Abrir en navegador? (S/N)").ToUpper() -eq "S") { Start-Process $tempHtml }
    }
    Pause-Enter
}

function Show-Temperatures {
    Show-MainTitle
    Write-Host "`n 🌡️ TEMPERATURAS DEL SISTEMA" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    try {
        $temps = Get-CimInstance -Namespace root/WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        if ($temps) {
            foreach ($temp in $temps) {
                $celsius = [math]::Round(($temp.CurrentTemperature - 2732) / 10, 1)
                Write-Host "    🌡️ $($temp.InstanceName) : $celsius °C" -ForegroundColor Yellow
            }
        } else { Write-Host "    ⚠️ Sensores WMI no compatibles en esta placa." -ForegroundColor Gray }
    } catch {}
    Pause-Enter
}

function Show-FullSystemInfo {
    Show-MainTitle
    Write-Host "`n ===== INFORME TÉCNICO COMPLETO =====`n" -ForegroundColor Cyan
    $cs = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    $physMem = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
    $totalInstalledGB = if ($physMem) { [math]::Round(($physMem | Measure-Object Capacity -Sum).Sum / 1GB, 2) } else { 0 }

    Write-Host " EQUIPO: $env:COMPUTERNAME" -ForegroundColor Green
    Write-Host " MODELO: $(if ($cs) { $cs.Name } else { 'N/A' })" -ForegroundColor Green
    Write-Host " CPU:    $(if ($cpu) { $cpu.Name.Trim() } else { 'N/A' })" -ForegroundColor Green
    Write-Host " RAM:    ${totalInstalledGB} GB" -ForegroundColor Green
    
    Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host " DISCO:  $($_.FriendlyName) [$($_.MediaType)] - $([math]::Round($_.Size / 1GB, 2)) GB | Salud: $($_.HealthStatus)" -ForegroundColor Yellow
    }
    Pause-Enter
}

function Show-ProcessTree {
    Show-MainTitle
    Write-Host "`n ÁRBOL DE PROCESOS (Jerarquía WMI)" -ForegroundColor $COLOR_MENU
    $allProcs = Get-WmiObject -Class Win32_Process -ErrorAction SilentlyContinue | ForEach-Object {
        [PSCustomObject]@{ Id = $_.ProcessId; Name = $_.Name -replace '\.exe$', ''; ParentId = $_.ParentProcessId }
    }
    function Draw-Tree($parentId, $indent) {
        $children = $allProcs | Where-Object { $_.ParentId -eq $parentId }
        foreach ($child in $children) {
            Write-Host ((" " * $indent) + "├─ " + "$($child.Name) ($($child.Id))") -ForegroundColor $COLOR_PRIMARY
            Draw-Tree $child.Id ($indent + 2)
        }
    }
    Draw-Tree 0 0
    Pause-Enter
}

function Get-FileLockingProcess {
    $filePath = Read-Host "`n Ruta completa del archivo o carpeta a verificar"
    if (-not $filePath -or -not (Test-Path $filePath)) { return }
    $handleExe = "$Global:AppRoot\handle64.exe"
    if (-not (Test-Path $handleExe)) {
        try { Invoke-WebRequest -Uri "https://live.sysinternals.com/handle64.exe" -OutFile $handleExe -UseBasicParsing } catch { return }
    }
    & $handleExe -accepteula "$filePath" 2>&1 | ForEach-Object { Write-Host $_ }
    Pause-Enter
}

function Show-LiveMonitor {
    $refreshMs = 1500
    while ($true) {
        Show-MainTitle
        Write-Host "`n [O] MONITOR DE SISTEMA EN VIVO" -ForegroundColor $COLOR_MENU
        $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        $mem = Get-CimInstance Win32_OperatingSystem | Select-Object @{Name="Free";Expression={"{0:N2}" -f ($_.FreePhysicalMemory / 1MB)}}, @{Name="Total";Expression={"{0:N2}" -f ($_.TotalVisibleMemorySize / 1MB)}}
        Write-Host " CPU: $cpu % | RAM LIBRE: $($mem.Free) GB / $($mem.Total) GB" -ForegroundColor $COLOR_PRIMARY
        
        Write-Host "`n TOP PROCESOS (RAM):" -ForegroundColor $COLOR_ALERT
        Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Host " [$($_.Id.ToString().PadRight(6))] $($_.ProcessName.PadRight(20)) | Uso: $("{0:N2}" -f ($_.WorkingSet / 1MB)) MB"
        }
        Write-Host "`n [K] FINALIZAR PROCESO | [T] CAMBIAR REFRESH (ms) | [X] SALIR" -ForegroundColor $COLOR_MENU
        
        $action = ""
        if ($Host.UI.RawUI.KeyAvailable) { $action = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character.ToString().ToUpper() }
        if ($action -eq "X") { break }
        if ($action -eq "K") {
            $target = Read-Host " Ingrese PID o Nombre de ejecutable"
            if ($target) { try { Stop-Process -Name $target -Force } catch { Stop-Process -Id $target -Force } }
        }
        if ($action -eq "T") { $v = Read-Host " Milisegundos"; if ($v -match "^\d+$") { $refreshMs = [int]$v } }
        Start-Sleep -Milliseconds $refreshMs
    }
}

function Invoke-RemoteDesktop {
    while ($true) {
        Show-MainTitle
        Write-Host "`n 🖥️ ESCRITORIO REMOTO Y ASISTENCIA (MODO PORTABLE)" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🖥️ [1] RDP NATIVO (MSTSC)      - Cliente de escritorio remoto integrado"
        Write-Host " 🚀 [2] ANYDESK (PORTABLE)      - Descarga y ejecuta directo sin instalar"
        Write-Host " 🔓 [3] RUSTDESK (PORTABLE)     - Cliente de código abierto sin instalación"
        Write-Host " 👁️ [4] TEAMVIEWER (PORTABLE)   - QuickSupport directo"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER
        
        $sub = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2","3","4","X")
        if ($sub -eq "X") { break }

        $toolsFolder = "$Global:AppRoot\RemoteTools"
        if (-not (Test-Path $toolsFolder)) { New-Item -Path $toolsFolder -ItemType Directory -Force | Out-Null }

        switch ($sub) {
            "1" { Start-Process "mstsc.exe" }
            "2" {
                $anyExe = "$toolsFolder\AnyDesk.exe"
                if (-not (Test-Path $anyExe)) {
                    Write-Host "`n [+] Descargando AnyDesk Portable..." -ForegroundColor Yellow
                    Invoke-WebRequest -Uri "https://download.anydesk.com/AnyDesk.exe" -OutFile $anyExe -UseBasicParsing
                }
                Start-Process $anyExe
            }
            "3" {
                $rustExe = "$toolsFolder\RustDesk.exe"
                if (-not (Test-Path $rustExe)) {
                    Write-Host "`n [+] Descargando RustDesk Portable oficial..." -ForegroundColor Yellow
                    Invoke-WebRequest -Uri "https://github.com/rustdesk/rustdesk/releases/download/1.3.1/rustdesk-1.3.1-x86_64.exe" -OutFile $rustExe -UseBasicParsing
                }
                Start-Process $rustExe
            }
            "4" {
                $tvExe = "$toolsFolder\TeamViewerQS.exe"
                if (-not (Test-Path $tvExe)) {
                    Write-Host "`n [+] Descargando TeamViewer QuickSupport..." -ForegroundColor Yellow
                    Invoke-WebRequest -Uri "https://download.teamviewer.com/download/TeamViewerQS.exe" -OutFile $tvExe -UseBasicParsing
                }
                Start-Process $tvExe
            }
        }
    }
}

function Invoke-PasswordGenerator {
    Show-MainTitle
    Write-Host "`n 🔐 GENERADOR DE CONTRASEÑAS SEGURAS" -ForegroundColor $COLOR_MENU
    Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host " Longitudes recomendadas: 16 (Estándar), 24 (Alta seguridad), 32 (Crítica)"
    $lenInput = Read-Host "`n Longitud de contraseña deseada (o ENTER para 16)"
    $length = if ($lenInput -match "^\d+$" -and [int]$lenInput -ge 8) { [int]$lenInput } else { 16 }

    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%^&*()_+-=[]{}|;:,.<>?"
    $charsArray = $chars.ToCharArray()
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $bytes = New-Object byte[] 4

    Write-Host "`n 📋 CONTRASEÑAS GENERADAS (${length} CARACTERES):" -ForegroundColor $COLOR_PRIMARY
    Write-Host " ─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    for ($i = 1; $i -le 5; $i++) {
        $pwd = ""
        for ($j = 0; $j -lt $length; $j++) {
            $rng.GetBytes($bytes)
            $pwd += $charsArray[[BitConverter]::ToUInt32($bytes, 0) % $charsArray.Length]
        }
        Write-Host " [$i]  $pwd" -ForegroundColor Cyan
        if ($i -eq 1) { Set-Clipboard -Value $pwd }
    }
    Write-Host " ─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host " ✅ La contraseña [1] ha sido copiada al portapapeles." -ForegroundColor Green
    Pause-Enter
}

