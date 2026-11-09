# ============================================================
# TECHFLOW SUITE PRO - MEDIA DOWNLOADER MODULE (CLON COMPLETO)
# ============================================================

$COLOR_PRIMARY = $Global:COLOR_PRIMARY
$COLOR_ALERT   = $Global:COLOR_ALERT
$COLOR_DANGER  = $Global:COLOR_DANGER
$COLOR_MENU    = $Global:COLOR_MENU
$COLOR_WARNING = $Global:COLOR_WARNING

function Invoke-YtdlpDownload {
    param(
        [Parameter(Mandatory = $true)][string]$YtdlpPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$Titulo = "Descargando..."
    )

    $progressTemplate = "download:PROGRESS|%(progress._percent_str)s|%(progress._eta_str)s|%(progress._downloaded_bytes_str)s|%(progress._total_bytes_str)s|%(progress._speed_str)s"

    $fullArgs = @(
        "--quiet", "--no-warnings", "--no-color", "--newline", "--no-simulate",
        "--progress-template", $progressTemplate,
        "--print", "after_move:FILE:%(filepath)s",
        "--print", "before_dl:BEFOREDL:%(playlist_index)s|%(playlist_count)s|%(title)s"
    ) + $Arguments

    $script:ytdlpLastDrawTop = $null
    $script:ytdlpProgressStarted = $false
    $lastFile = $null
    $script:ytdlpErrorMsg = $null
    $playlistInfo = ""

    $drawRealProgress = {
        param($pct, $etaStr, $dlStr, $totalStr, $spdStr, $tituloStr, $playlistStr)
        $barLength = 30
        $filled = [math]::Round($barLength * ($pct / 100))
        if ($filled -gt $barLength) { $filled = $barLength }
        if ($filled -lt 0) { $filled = 0 }
        $bar = ("█" * $filled) + ("░" * ($barLength - $filled))

        $tituloDisplay = if ($tituloStr.Length -gt 44) { $tituloStr.Substring(0, 41) + "..." } else { $tituloStr }

        if ($playlistStr) {
            $line1 = "║  📦 " + $playlistStr.PadRight(45) + " ║"
            $line2 = "║  🎬 " + $tituloDisplay.PadRight(45) + " ║"
            $line3 = "║  [$bar] " + $pct.ToString().PadLeft(3) + "%       ║"
        } else {
            $line1 = "║  🎬 " + $tituloDisplay.PadRight(45) + " ║"
            $line2 = "║  [$bar] " + $pct.ToString().PadLeft(3) + "%       ║"
            $line3 = $null
        }

        $infoStr = "  ⏱️  ETA: $etaStr  |  💾 $dlStr / $totalStr"
        if ($spdStr -and $spdStr -ne "N/A" -and $spdStr -ne "Unknown") { $infoStr += "  🚀 $spdStr" }
        $visibleLen = ($infoStr -replace '[⏱️💾🚀🎬📦]', 'XX').Length
        while ($visibleLen -lt 48) { $infoStr += " "; $visibleLen++ }
        $infoLine = "║" + $infoStr + "  ║"

        if ($script:ytdlpLastDrawTop -eq $null) { $script:ytdlpLastDrawTop = [Console]::CursorTop } 
        else { try { [Console]::SetCursorPosition(0, $script:ytdlpLastDrawTop) } catch {} }

        Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host $line1 -ForegroundColor Cyan
        if ($playlistStr) { Write-Host $line2 -ForegroundColor White; Write-Host $line3 -ForegroundColor Yellow } 
        else { Write-Host $line2 -ForegroundColor Yellow }
        Write-Host $infoLine -ForegroundColor Gray
        Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    }

    $drawSpinner = {
        param($segundos, $frame, $tituloStr, $statusTxt, $playlistStr)
        $framesChar = @('◐','◓','◑','◒')
        $spinnerChar = $framesChar[$frame % 4]
        $barLength = 30
        $pos = $frame % ($barLength * 2)
        if ($pos -ge $barLength) { $pos = ($barLength * 2) - 1 - $pos }
        $bloque = "▓" * 5
        $tail = $barLength - $pos - 5
        if ($tail -lt 0) { $tail = 0 }
        $bar = ("░" * $pos) + $bloque + ("░" * $tail)
        if ($bar.Length -gt $barLength) { $bar = $bar.Substring(0, $barLength) }
        if ($bar.Length -lt $barLength) { $bar += "░" * ($barLength - $bar.Length) }

        $tituloDisplay = if ($tituloStr.Length -gt 44) { $tituloStr.Substring(0, 41) + "..." } else { $tituloStr }

        if ($playlistStr) {
            $line1 = "║  📦 " + $playlistStr.PadRight(45) + " ║"
            $line2 = "║  🎬 " + $tituloDisplay.PadRight(45) + " ║"
            $line3 = "║  [$bar]  $spinnerChar      ║"
        } else {
            $line1 = "║  🎬 " + $tituloDisplay.PadRight(45) + " ║"
            $line2 = "║  [$bar]  $spinnerChar      ║"
            $line3 = $null
        }

        $infoStr = "  $statusTxt | ⏱️  ${segundos}s"
        $visibleLen = ($infoStr -replace '[⏱️💾🚀🎬📦◐◓◑◒▓░]', 'XX').Length
        while ($visibleLen -lt 48) { $infoStr += " "; $visibleLen++ }
        $infoLine = "║" + $infoStr + "  ║"

        if ($script:ytdlpLastDrawTop -eq $null) { $script:ytdlpLastDrawTop = [Console]::CursorTop } 
        else { try { [Console]::SetCursorPosition(0, $script:ytdlpLastDrawTop) } catch {} }

        Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host $line1 -ForegroundColor Cyan
        if ($playlistStr) { Write-Host $line2 -ForegroundColor White; Write-Host $line3 -ForegroundColor Magenta } 
        else { Write-Host $line2 -ForegroundColor Magenta }
        Write-Host $infoLine -ForegroundColor DarkYellow
        Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $YtdlpPath
    $psi.Arguments = ($fullArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join " "
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path $YtdlpPath -Parent

    & $drawSpinner 0 0 $Titulo "Iniciando proceso" $playlistInfo
    $process = [System.Diagnostics.Process]::Start($psi)
    $startTime = Get-Date
    $frameIdx = 0
    $videoActual = $Titulo
    $readTask = $process.StandardOutput.ReadLineAsync()

    while (-not $process.HasExited -or -not $readTask.IsCompleted) {
        if (-not $script:ytdlpProgressStarted) {
            $segundos = [int]((Get-Date) - $startTime).TotalSeconds
            & $drawSpinner $segundos $frameIdx $videoActual "Procesando" $playlistInfo
            $frameIdx++
        }
        if ($readTask.IsCompleted) {
            $line = $readTask.Result
            if ($null -ne $line) {
                if ($line -match '^BEFOREDL:(\d+)\|(\d+)\|(.+)$') {
                    $playlistInfo = "Playlist: $($matches[1]) / $($matches[2]) videos"
                    $videoActual = $matches[3]
                    $script:ytdlpProgressStarted = $false
                    $frameIdx = 0
                } elseif ($line -match '^PROGRESS\|(.+?)\|(.+?)\|(.+?)\|(.+?)\|(.+?)$') {
                    $script:ytdlpProgressStarted = $true
                    $pct = [double]($matches[1] -replace '[^\d\.]', '')
                    $eta = $matches[2].Trim()
                    $dl  = $matches[3].Trim()
                    $tot = $matches[4].Trim()
                    $spd = $matches[5].Trim()
                    & $drawRealProgress $pct $eta $dl $tot $spd $videoActual $playlistInfo
                } elseif ($line -match '^FILE:(.+)$') {
                    $lastFile = $matches[1]
                } elseif ($line -match '^ERROR:\s*(.+)$') {
                    $script:ytdlpErrorMsg = $matches[1]
                }

                if (-not $process.HasExited) {
                    $readTask = $process.StandardOutput.ReadLineAsync()
                } else { break }
            } else { break }
        }
        Start-Sleep -Milliseconds 250
    }

    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -eq 0) {
        if ($script:ytdlpProgressStarted) { & $drawRealProgress 100 "00:00" "OK" "OK" "0 B/s" $videoActual $playlistInfo }
        $script:ytdlpLastDrawTop = $null
        $script:ytdlpProgressStarted = $false
        Write-Host "`n   ✅ DESCARGA COMPLETADA" -ForegroundColor Green
        if ($lastFile) { Write-Host "   📁 Archivo: $lastFile" -ForegroundColor DarkGray }
        return @{ Success = $true; File = $lastFile; PlaylistInfo = $playlistInfo }
    } else {
        $script:ytdlpLastDrawTop = $null
        $script:ytdlpProgressStarted = $false
        Write-Host "`n   ❌ ERROR EN LA DESCARGA (Código $($process.ExitCode))" -ForegroundColor Red
        if ($script:ytdlpErrorMsg) { Write-Host "      $($script:ytdlpErrorMsg)" -ForegroundColor DarkGray } 
        elseif ($stderr) {
            ($stderr -split "`n" | Where-Object { $_ -match "ERROR" } | Select-Object -First 3) | ForEach-Object {
                Write-Host "      $($_.Trim())" -ForegroundColor DarkGray
            }
        }
        return @{ Success = $false; Error = $stderr }
    }
}

function Invoke-DownloadCenter {
    $Escritorio = [Environment]::GetFolderPath("Desktop")
    $Herramientas = Join-Path $Escritorio "Herramientas_Descarga"
    $DescargasPredeterminada = Join-Path $Escritorio "Descargas_YTDLP"
    $HistorialPath = Join-Path $Herramientas "historial_descargas.txt"
    $YtdlpExe = "$Herramientas\yt-dlp.exe"
    $script:DescargasExitosas = 0
    $script:LimiteDescarga = 50

    if (-not (Test-Path $Herramientas)) { New-Item -ItemType Directory -Path $Herramientas -Force | Out-Null }
    if (-not (Test-Path $DescargasPredeterminada)) { New-Item -ItemType Directory -Path $DescargasPredeterminada -Force | Out-Null }

    function Verificar-Herramientas {
        if (-not (Test-Path $YtdlpExe)) {
            Write-Host "`n   📥 Descargando yt-dlp oficial..." -ForegroundColor Yellow
            try {
                Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile $YtdlpExe -UseBasicParsing
                Write-Host "   ✅ yt-dlp listo." -ForegroundColor Green
            } catch {
                Write-Host "   ❌ Error al descargar yt-dlp: $($_.Exception.Message)" -ForegroundColor Red
                Pause-Enter; return $false
            }
        }

        $global:FFmpegDisponible = [bool](Get-Command ffmpeg -ErrorAction SilentlyContinue)
        if (-not $global:FFmpegDisponible) {
            Write-Host "`n   ⚠️ FFmpeg no detectado en el PATH (necesario para recortar y convertir audio)." -ForegroundColor Yellow
            $inst = Read-MenuOption "   ¿Deseas instalar FFmpeg automáticamente con Winget? (S/N)" -Valid @("S","N")
            if ($inst -eq "S") {
                Write-Host "   ⏳ Instalando FFmpeg..." -ForegroundColor Cyan
                winget install Gyan.FFmpeg --silent --accept-package-agreements --accept-source-agreements
                $global:FFmpegDisponible = [bool](Get-Command ffmpeg -ErrorAction SilentlyContinue)
            }
        }
        return $true
    }

    if (-not (Verificar-Herramientas)) { return }

    if ($null -eq $Global:CalidadAudio) { $Global:CalidadAudio = "5" }
    if ($null -eq $Global:CalidadVideo) { $Global:CalidadVideo = "bv*[height<=720]+ba/b[height<=720]/bv*+ba/b" }
    if ($null -eq $Global:TextoCalidad) { $Global:TextoCalidad = "Media (192kbps / 720p)" }
    if ($null -eq $Global:RutaDestinoActual) { $Global:RutaDestinoActual = $DescargasPredeterminada }

    function Registrar-Historial($tipo, $detalle) {
        $fecha = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $HistorialPath -Value "[$fecha] [$tipo] $detalle" -Encoding utf8 -ErrorAction SilentlyContinue
    }

    do {
        Show-MainTitle
        Write-Host "`n 🎵 CENTRO DE DESCARGAS INTELIGENTE v6.0" -ForegroundColor $COLOR_MENU
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host "   📂 Destino actual : $Global:RutaDestinoActual" -ForegroundColor Yellow
        Write-Host "   🎚️ Calidad audio   : $Global:TextoCalidad" -ForegroundColor Cyan
        Write-Host "   📊 Descargas sesión: $script:DescargasExitosas exitosas" -ForegroundColor Green
        Write-Host "   🎬 Motor FFmpeg   : $(if ($global:FFmpegDisponible) { 'Disponible' } else { 'No instalado' })" -ForegroundColor Gray
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " 🎬 DESCARGAS PRINCIPALES:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   [1] 💿 Descargar Álbum / Playlist completa de YouTube"
        Write-Host "   [2] 🎵 Descargar Canción suelta por búsqueda"
        Write-Host "   [3] 🔗 Descargar desde YouTube por ENLACE directo"
        Write-Host "   [4] 📱 OTRAS PLATAFORMAS (TikTok, Instagram, Facebook, X, etc.)"
        Write-Host "   [5] ✂️ RECORTAR AUDIO O VIDEO (Por marcas de tiempo con FFmpeg)"
        Write-Host ""
        Write-Host " ⚙️ CONFIGURACIÓN Y MANTENIMIENTO:" -ForegroundColor $COLOR_PRIMARY
        Write-Host "   [6] 🎚️ Configurar Calidad predeterminada (320k, 192k, 1080p, 720p)"
        Write-Host "   [7] 📁 Cambiar carpeta de destino"
        Write-Host "   [8] 📜 Ver historial de descargas"
        Write-Host "   [U] 🔄 Actualizar motor yt-dlp a la última versión"
        Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
        Write-Host " ❌ [X] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor $COLOR_DANGER

        $opcion = (Read-Host "`n   > SELECCIONE").Trim().ToUpper()
        $argsBase = @("--restrict-filenames", "--no-mtime")

        switch ($opcion) {
            "1" {
                $album = Read-Host "`n   Artista y nombre del Álbum o Playlist"
                if (-not $album) { continue }
                $nom = $album -replace '[<>:"/\\|?*]','_'
                $carpetaAlbum = Join-Path $Global:RutaDestinoActual $nom
                $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                    "-x", "--audio-format", "mp3", "--audio-quality", $Global:CalidadAudio,
                    "--yes-playlist", "--playlist-end", "$script:LimiteDescarga"
                ) + $argsBase + @(
                    "ytsearchplaylist$script:LimiteDescarga:$album",
                    "-o", "$carpetaAlbum/%(playlist_index)s - %(title)s.%(ext)s"
                )) -Titulo "Descargando álbum: $album"
                if ($res.Success) { $script:DescargasExitosas++; Registrar-Historial "ALBUM" $album }
                Pause-Enter
            }
            "2" {
                $busqueda = Read-Host "`n   Nombre de la canción y artista"
                if (-not $busqueda) { continue }
                $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                    "-x", "--audio-format", "mp3", "--audio-quality", $Global:CalidadAudio,
                    "--no-playlist"
                ) + $argsBase + @(
                    "ytsearch1:$busqueda",
                    "-o", "$Global:RutaDestinoActual/%(title)s.%(ext)s"
                )) -Titulo "Buscando: $busqueda"
                if ($res.Success) { $script:DescargasExitosas++; Registrar-Historial "CANCIÓN" $busqueda }
                Pause-Enter
            }
            "3" {
                $link = Read-Host "`n   Pega el enlace de YouTube"
                if (-not $link) { continue }
                $tipo = Read-MenuOption "   ¿Descargar solo Música [M] o Video [V]?" -Valid @("M","V")
                if ($tipo -eq "V") {
                    $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                        "-f", $Global:CalidadVideo, "--no-playlist"
                    ) + $argsBase + @(
                        "-o", "$Global:RutaDestinoActual/%(title)s.%(ext)s", $link
                    )) -Titulo "Descargando video..."
                } else {
                    $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                        "-x", "--audio-format", "mp3", "--audio-quality", $Global:CalidadAudio,
                        "--no-playlist"
                    ) + $argsBase + @(
                        "-o", "$Global:RutaDestinoActual/%(title)s.%(ext)s", $link
                    )) -Titulo "Descargando audio..."
                }
                if ($res.Success) { $script:DescargasExitosas++; Registrar-Historial "ENLACE_YT" $link }
                Pause-Enter
            }
            "4" {
                $url = Read-Host "`n   Pega el enlace (TikTok, Instagram, Facebook, X, etc.)"
                if (-not $url) { continue }
                $tipo = Read-MenuOption "   ¿Descargar solo Audio [A] o Video [V]?" -Valid @("A","V")
                if ($tipo -eq "A") {
                    $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                        "-x", "--audio-format", "mp3", "--audio-quality", $Global:CalidadAudio,
                        "--no-playlist"
                    ) + $argsBase + @(
                        "-o", "$Global:RutaDestinoActual/%(title)s.%(ext)s", $url
                    )) -Titulo "Descargando audio de red..."
                } else {
                    $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                        "-f", "bv*+ba/b", "--no-playlist"
                    ) + $argsBase + @(
                        "-o", "$Global:RutaDestinoActual/%(title)s.%(ext)s", $url
                    )) -Titulo "Descargando video de red..."
                }
                if ($res.Success) { $script:DescargasExitosas++; Registrar-Historial "RED_SOCIAL" $url }
                Pause-Enter
            }
            "5" {
                if (-not $global:FFmpegDisponible) {
                    Write-Host "`n   ❌ FFmpeg no está disponible. No se puede realizar el recorte." -ForegroundColor Red
                    Pause-Enter; continue
                }
                $link = Read-Host "`n   Pega el enlace a recortar"
                if (-not $link) { continue }
                $inicio = Read-Host "   Tiempo de inicio (formato HH:MM:SS o MM:SS, ej: 01:15)"
                $fin    = Read-Host "   Tiempo final  (formato HH:MM:SS o MM:SS, ej: 02:45)"
                $tipo   = Read-MenuOption "   ¿Salida en Audio [A] o Video [V]?" -Valid @("A","V")
                
                $postArgs = "ffmpeg:-ss $inicio -to $fin"
                if ($tipo -eq "A") {
                    $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                        "-x", "--audio-format", "mp3", "--audio-quality", $Global:CalidadAudio,
                        "--postprocessor-args", $postArgs, "--no-playlist"
                    ) + $argsBase + @(
                        "-o", "$Global:RutaDestinoActual/%(title)s_recorte.%(ext)s", $link
                    )) -Titulo "Descargando y recortando fragmento..."
                } else {
                    $res = Invoke-YtdlpDownload -YtdlpPath $YtdlpExe -Arguments (@(
                        "-f", $Global:CalidadVideo,
                        "--postprocessor-args", $postArgs, "--no-playlist"
                    ) + $argsBase + @(
                        "-o", "$Global:RutaDestinoActual/%(title)s_recorte.%(ext)s", $link
                    )) -Titulo "Descargando y recortando fragmento..."
                }
                if ($res.Success) { $script:DescargasExitosas++; Registrar-Historial "RECORTE" "$link ($inicio - $fin)" }
                Pause-Enter
            }
            "6" {
                Show-MainTitle
                Write-Host "`n 🎚️ CONFIGURAR CALIDAD PREDETERMINADA" -ForegroundColor $COLOR_MENU
                Write-Host "   [1] Alta     : 320 kbps MP3  |  1080p Video"
                Write-Host "   [2] Media    : 192 kbps MP3  |  720p Video (Recomendada)"
                Write-Host "   [3] Ligera   : 128 kbps MP3  |  480p Video (Rápida)"
                $q = Read-MenuOption "`n   > SELECCIONE" -Valid @("1","2","3")
                switch ($q) {
                    "1" { $Global:CalidadAudio = "0"; $Global:CalidadVideo = "bv*[height<=1080]+ba/b[height<=1080]/bv*+ba/b"; $Global:TextoCalidad = "Alta (320kbps / 1080p)" }
                    "2" { $Global:CalidadAudio = "5"; $Global:CalidadVideo = "bv*[height<=720]+ba/b[height<=720]/bv*+ba/b";  $Global:TextoCalidad = "Media (192kbps / 720p)" }
                    "3" { $Global:CalidadAudio = "9"; $Global:CalidadVideo = "bv*[height<=480]+ba/b[height<=480]/bv*+ba/b";  $Global:TextoCalidad = "Baja (128kbps / 480p)" }
                }
                Write-Host "   ✅ Configuración aplicada." -ForegroundColor Green
                Pause-Enter
            }
            "7" {
                Write-Host "`n   Ruta actual: $Global:RutaDestinoActual" -ForegroundColor Yellow
                $nuevaRuta = Read-Host "   Ingresa nueva ruta de destino (o ENTER para mantener)"
                if ($nuevaRuta -and (Test-Path $nuevaRuta)) {
                    $Global:RutaDestinoActual = $nuevaRuta
                    Write-Host "   ✅ Carpeta actualizada." -ForegroundColor Green
                } elseif ($nuevaRuta) {
                    try {
                        New-Item -Path $nuevaRuta -ItemType Directory -Force | Out-Null
                        $Global:RutaDestinoActual = $nuevaRuta
                        Write-Host "   ✅ Carpeta creada y asignada." -ForegroundColor Green
                    } catch { Write-Host "   ❌ Ruta no válida." -ForegroundColor Red }
                }
                Pause-Enter
            }
            "8" {
                Show-MainTitle
                Write-Host "`n 📜 HISTORIAL DE DESCARGAS REGISTRADAS" -ForegroundColor $COLOR_MENU
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                if (Test-Path $HistorialPath) {
                    Get-Content $HistorialPath -Tail 25 | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
                } else {
                    Write-Host "   (Sin registros previos aún)" -ForegroundColor Gray
                }
                Write-Host " ═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
                Pause-Enter
            }
            "U" {
                Write-Host "`n [+] Actualizando motor yt-dlp..." -ForegroundColor Yellow
                & $YtdlpExe -U
                Write-Host " ✅ Proceso de actualización finalizado." -ForegroundColor Green
                Pause-Enter
            }
        }
    } while ($opcion -ne "X")
}
