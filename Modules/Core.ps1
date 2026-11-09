# ============================================================
# TECHFLOW SUITE PRO - CORE FUNCTIONS
# ============================================================

$Global:COLOR_PRIMARY = "Green"
$Global:COLOR_ALERT   = "Yellow"
$Global:COLOR_DANGER  = "Red"
$Global:COLOR_MENU    = "Cyan"
$Global:COLOR_WARNING = "Yellow"
$Global:LINEA         = " ═══════════════════════════════════════════════════════════════════"

$Global:LOG_FILE = Join-Path $Global:AppRoot ("techflowlog_" + (Get-Date).ToString("yyyyMMdd") + ".log")

function Read-MenuOption {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [string[]]$Valid = @(),
        [switch]$AllowEmpty
    )
    while ($true) {
        $raw = Read-Host $Prompt
        if (-not $raw -or -not $raw.Trim()) {
            if ($AllowEmpty) { return "" }
            Write-Host "   ⚠️ Entrada requerida" -ForegroundColor Yellow
            continue
        }
        $opt = $raw.Trim().ToUpper()
        if ($Valid.Count -eq 0 -or $Valid -contains $opt) { return $opt }
        Write-Host "`n   ❌ [!] OPCIÓN NO VÁLIDA: $opt" -ForegroundColor Red
        Start-Sleep -Milliseconds 800
    }
}

function Pause-Enter {
    param([string]$Message = "   ⌨️ PRESIONE ENTER PARA VOLVER")
    Read-Host $Message | Out-Null
}

function Require-Admin {
    param([string]$ActionName = "esta operación")
    $currentUser = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "`n   🛑 [!] Requiere permisos de ADMIN para $ActionName." -ForegroundColor Red
        Pause-Enter "   ⌨️ ENTER"
        return $false
    }
    return $true
}

function Confirm-Critical {
    param([Parameter(Mandatory = $true)][string]$Title, [Parameter(Mandatory = $true)][string]$Keyword)
    Show-MainTitle
    Write-Host "`n   🔥 OPERACIÓN CRÍTICA: $Title" -ForegroundColor Red
    $pin = Get-Random -Min 1000 -Max 9999
    Write-Host "`n   🔐 PIN DE SEGURIDAD $pin" -BackgroundColor Red -ForegroundColor White
    $p = Read-Host "   ⌨️ INGRESE PIN PARA CONFIRMAR"
    if ($p -ne $pin.ToString()) {
        Write-Host "`n   ❌ [!] PIN INCORRECTO." -ForegroundColor Red
        Start-Sleep -Seconds 1
        return $false
    }
    $k = (Read-Host "   ⌨️ ESCRIBA '$Keyword' PARA CONTINUAR").Trim().ToUpper()
    if ($k -ne $Keyword.Trim().ToUpper()) {
        Write-Host "`n   ❌ [!] PALABRA DE CONFIRMACIÓN INCORRECTA." -ForegroundColor Red
        Start-Sleep -Seconds 1
        return $false
    }
    return $true
}

function Write-Log {
    param([Parameter(Mandatory = $true)][string]$Level, [Parameter(Mandatory = $true)][string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "$ts [$Level] $Message"
    Add-Content -Path $Global:LOG_FILE -Value $logEntry -Encoding utf8 -ErrorAction SilentlyContinue
}

function Format-Bytes([Int64]$Bytes) {
    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    if ($Bytes -lt 1GB) { return "{0:N2} MB" -f ($Bytes / 1GB) }
    if ($Bytes -lt 1TB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    return "{0:N2} TB" -f ($Bytes / 1TB)
}

# ============================================================
# 🚀 DIAGNÓSTICO ESTÉTICO DE ARRANQUE (SINCRONIZADO CON VERSION.JSON)
# ============================================================
function Invoke-StartupChecks {
    # 0. Lectura dinámica de versión desde DevTools\VERSION.json
    $vFile = Join-Path $Global:AppRoot "DevTools\VERSION.json"
    $localVersion = "6.0.0"
    $majorMinor = "6.0"
    if (Test-Path $vFile) {
        try {
            $vData = Get-Content $vFile -Raw | ConvertFrom-Json
            if ($vData.version) {
                $localVersion = $vData.version.Trim()
                $p = $localVersion.Split('.')
                if ($p.Count -ge 2) { $majorMinor = "$($p[0]).$($p[1])" }
            }
        } catch {}
    }

    Clear-Host
    Write-Host @"
 ╔══════════════════════════════════════════════════════════════════════════════════╗
 ║                                                                                  ║
 ║                   INICIALIZANDO TECHFLOW SUITE PRO v$majorMinor                          ║
 ║                 COMPROBACIÓN Y OPTIMIZACIÓN PREVIA DEL SISTEMA                   ║
 ║                                                                                  ║
 ╚══════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    Write-Host "`n ┌── ESTADO DE SERVICIOS Y MOTORES AUXILIARES ─────────────────────────────────┐" -ForegroundColor Gray

    # 1. Windows Defender Auto-Exclusión
    Write-Host " │ 🛡️  Windows Defender       : " -NoNewline -ForegroundColor Gray
    try {
        $exclusionPath = $Global:AppRoot
        $currentExclusions = (Get-MpPreference -ErrorAction SilentlyContinue).ExclusionPath
        if ($currentExclusions -notcontains $exclusionPath) {
            Add-MpPreference -ExclusionPath $exclusionPath -ErrorAction SilentlyContinue
            Write-Host "[PROTEGIDO - EXCLUSIÓN AÑADIDA] " -ForegroundColor Green
            Write-Log "SECURITY" "Exclusión añadida en Defender: $exclusionPath"
        } else {
            Write-Host "[PROTEGIDO - OK]                " -ForegroundColor Green
        }
    } catch {
        Write-Host "[OMITIDO - PERMISOS LIMITADOS] " -ForegroundColor DarkGray
    }

    # 2. Microsoft Winget
    Write-Host " │ 📦 Gestor Microsoft Winget : " -NoNewline -ForegroundColor Gray
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        Write-Host "[ACTUALIZANDO FUENTES...]      " -NoNewline -ForegroundColor Yellow
        winget source update 2>&1 | Out-Null
        Write-Host "`r │ 📦 Gestor Microsoft Winget : [ACTUALIZADO - REPO OFICIAL]   " -ForegroundColor Green
    } else {
        Write-Host "[NO DETECTADO EN EL SISTEMA]   " -ForegroundColor Red
    }

    # 3. Chocolatey
    Write-Host " │ 🍫 Gestor Chocolatey       : " -NoNewline -ForegroundColor Gray
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoCmd) {
        Write-Host "[ACTIVO - LISTO]               " -ForegroundColor Green
    } else {
        Write-Host "[NO INSTALADO - WINGET ACTIVO] " -ForegroundColor DarkGray
    }

        # 4. Sincronización GitHub (Comparación Semántica y Detección de Desfase)
    Write-Host " │ 🌐 Sincronización GitHub    : " -NoNewline -ForegroundColor Gray
    
    $repoUrls = @(
        "https://raw.githubusercontent.com/LuisFernandoGarcia/TechFlowSuite/main/DevTools/VERSION.json",
        "https://raw.githubusercontent.com/LuisFernandoGarcia/TechFlowSuite/main/VERSION.json",
        "https://raw.githubusercontent.com/LuisFernandoGarcia/TechFlowSuite/main/version.json"
    )
    
    $remoteVersion = $null
    $changelog = ""
    $consultaExitosa = $false

    foreach ($url in $repoUrls) {
        try {
            $webReq = [System.Net.WebRequest]::Create($url)
            $webReq.Timeout = 3000
            $response = $webReq.GetResponse()
            $reader = [System.IO.StreamReader]::new($response.GetResponseStream())
            $jsonRaw = $reader.ReadToEnd()
            $reader.Close(); $response.Close()
            
            $remoteData = $jsonRaw | ConvertFrom-Json
            if ($remoteData.version) {
                $remoteVersion = $remoteData.version.Trim()
                $changelog = $remoteData.changelog
                $consultaExitosa = $true
                break
            }
        } catch {}
    }

    if ($consultaExitosa) {
        # Limpieza para comparar como System.Version
        $localClean  = ($localVersion  -replace '[^\d\.]', '')
        $remoteClean = ($remoteVersion -replace '[^\d\.]', '')
        while (($localClean.Split('.')).Count -lt 3)  { $localClean  += ".0" }
        while (($remoteClean.Split('.')).Count -lt 3) { $remoteClean += ".0" }

        $vLocal  = [System.Version]$localClean
        $vRemote = [System.Version]$remoteClean

        if ($vLocal -ne $vRemote) {
            Write-Host "[DESFASE DETECTADO]           " -ForegroundColor Yellow
            Write-Host " └─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Gray
            
            Write-Host ""
            Write-Host " ╔══════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
            Write-Host " ║ 🔔 DISCREPANCIA DE VERSIÓN DETECTADA CON GITHUB                                  ║" -ForegroundColor Yellow
            Write-Host " ║    Versión en tu equipo : v$localVersion" -ForegroundColor White
            Write-Host " ║    Versión en GitHub    : v$remoteVersion" -ForegroundColor Cyan
            if ($changelog) {
                $chgDisplay = if ($changelog.Length -gt 60) { $changelog.Substring(0, 57) + "..." } else { $changelog }
                Write-Host " ║    Notas                : $chgDisplay" -ForegroundColor Gray
            }
            Write-Host " ╚══════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
            Write-Host "   [1] 🚀 Abrir GitHub para sincronizar / descargar" -ForegroundColor Green
            Write-Host "   [2] ⏭️  Continuar al menú principal (Ignorar desfase)" -ForegroundColor Yellow
            
            $updOpt = Read-MenuOption "`n > SELECCIONE" -Valid @("1","2")
            if ($updOpt -eq "1") {
                Write-Host "`n [+] Abriendo repositorio oficial..." -ForegroundColor Cyan
                Start-Process "https://github.com/LuisFernandoGarcia/TechFlowSuite"
                Start-Sleep -Seconds 1
            }
        } else {
            Write-Host "[AL DÍA - v$localVersion]             " -ForegroundColor Green
            Write-Host " └─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Gray
            Write-Host "`n ✅ Entorno validado. Ingresando a la suite..." -ForegroundColor Green
            Start-Sleep -Milliseconds 700
        }
    } else {
        Write-Host "[SIN CONEXIÓN / VERSIÓN LOCAL]" -ForegroundColor DarkGray
        Write-Host " └─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Gray
        Write-Host "`n ⚠️ No se pudo consultar GitHub. Iniciando en modo local..." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 700
    }
}


