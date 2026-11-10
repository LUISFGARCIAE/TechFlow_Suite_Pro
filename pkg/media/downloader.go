package media

import (
"archive/zip"
"bufio"
"fmt"
"io"
"net/http"
"os"
"os/exec"
"path/filepath"
"strconv"
"strings"
"time"
"techflow/pkg/core"
)

type DownloadCenterState struct {
DestFolder       string
AudioQuality     string
VideoQuality     string
QualityText      string
LimitCount       int
SilentMode       bool
NightMode        bool
SuccessfulCount  int
FFmpegInstalled  bool
ToolsDir         string
DefaultFolder    string
HistoryFile      string
BatchFile        string
}

func fileExists(path string) bool {
info, err := os.Stat(path)
if os.IsNotExist(err) {
return false
}
return !info.IsDir()
}

func downloadFileHTTP(url, dest string) error {
out, err := os.Create(dest)
if err != nil {
return err
}
defer out.Close()

resp, err := http.Get(url)
if err != nil {
return err
}
defer resp.Body.Close()

if resp.StatusCode != http.StatusOK {
return fmt.Errorf("error HTTP: %d", resp.StatusCode)
}

_, err = io.Copy(out, resp.Body)
return err
}

func unzipArchive(src, dest string) error {
r, err := zip.OpenReader(src)
if err != nil {
return err
}
defer r.Close()

_ = os.MkdirAll(dest, 0755)
for _, f := range r.File {
fpath := filepath.Join(dest, f.Name)
if f.FileInfo().IsDir() {
_ = os.MkdirAll(fpath, f.Mode())
continue
}
if err := os.MkdirAll(filepath.Dir(fpath), 0755); err != nil {
return err
}
outFile, err := os.OpenFile(fpath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
if err != nil {
return err
}
rc, err := f.Open()
if err != nil {
outFile.Close()
return err
}
_, err = io.Copy(outFile, rc)
outFile.Close()
rc.Close()
if err != nil {
return err
}
}
return nil
}

func ensureDependencies(state *DownloadCenterState) string {
ytdlpPath := filepath.Join(state.ToolsDir, "yt-dlp.exe")
if !fileExists(ytdlpPath) {
fmt.Println("   \033[33m📥 Descargando yt-dlp.exe oficial...\033[0m")
url := "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
if err := downloadFileHTTP(url, ytdlpPath); err != nil {
fmt.Printf("   \033[31m❌ Error al descargar yt-dlp: %v\033[0m\n", err)
return ""
}
fmt.Println("   \033[32m✅ yt-dlp listo!\033[0m")
}

// Verificar FFmpeg en PATH o en herramientas locales
_, err := exec.LookPath("ffmpeg")
ffmpegLocal := filepath.Join(state.ToolsDir, "ffmpeg.exe")
if err == nil || fileExists(ffmpegLocal) {
state.FFmpegInstalled = true
} else {
fmt.Println("   \033[33m🔧 FFmpeg no encontrado. Descargando binarios esenciales...\033[0m")
zipPath := filepath.Join(state.ToolsDir, "ffmpeg.zip")
tempExtract := filepath.Join(state.ToolsDir, "ffmpeg-temp")
ffmpegURL := "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
if err := downloadFileHTTP(ffmpegURL, zipPath); err == nil {
if err := unzipArchive(zipPath, tempExtract); err == nil {
// Buscar ffmpeg.exe y ffprobe.exe dentro de subdirectorios extraídos
_ = filepath.Walk(tempExtract, func(path string, info os.FileInfo, err error) error {
if err == nil && !info.IsDir() {
base := strings.ToLower(info.Name())
if base == "ffmpeg.exe" || base == "ffprobe.exe" {
destBin := filepath.Join(state.ToolsDir, info.Name())
_ = os.Rename(path, destBin)
}
}
return nil
})
_ = os.Remove(zipPath)
_ = os.RemoveAll(tempExtract)
if fileExists(ffmpegLocal) {
state.FFmpegInstalled = true
fmt.Println("   \033[32m✅ FFmpeg instalado!\033[0m")
}
}
}
}
return ytdlpPath
}

func detectUSB() string {
psCmd := `
$vol = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter } | Select-Object -First 1
if ($vol) { $vol.DriveLetter } else { "" }
`
out, _ := core.RunPowerShellCmd(psCmd)
clean := strings.TrimSpace(out)
if clean != "" {
return clean + ":"
}
return ""
}

func sanitizeFilename(name string) string {
invalid := []string{"\\", "/", ":", "*", "?", "\"", "<", ">", "|"}
res := name
for _, c := range invalid {
res = strings.ReplaceAll(res, c, "_")
}
return strings.TrimSpace(res)
}

func logDownloadHistory(state *DownloadCenterState, title, platform, url string) {
ts := time.Now().Format("2006-01-02 15:04:05")
entry := fmt.Sprintf("%s | %s | %s | %s | %s\n", ts, platform, title, url, state.DestFolder)
f, err := os.OpenFile(state.HistoryFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
if err == nil {
defer f.Close()
_, _ = f.WriteString(entry)
}
}

func showDownloadHistory(state *DownloadCenterState) {
core.ShowBanner()
fmt.Println("\n \033[36m📜 HISTORIAL DE DESCARGAS\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")

if !fileExists(state.HistoryFile) {
fmt.Println("   \033[33mℹ️ Aún no hay historial. Realiza tu primera descarga!\033[0m")
} else {
content, err := os.ReadFile(state.HistoryFile)
if err == nil {
lines := strings.Split(strings.TrimSpace(string(content)), "\n")
start := 0
if len(lines) > 20 {
start = len(lines) - 20
}
fmt.Printf("   \033[32m📋 Últimas %d descargas:\033[0m\n\n", len(lines)-start)
for i := start; i < len(lines); i++ {
fmt.Printf("   \033[90m%s\033[0m\n", lines[i])
}
fmt.Printf("\n   \033[36m📊 Total de descargas registradas: %d\033[0m\n", len(lines))
}
}
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
core.PauseEnter("")
}

func showNotes() {
core.ShowBanner()
fmt.Println("\n \033[33m📖 GUÍA RÁPIDA - CENTRO DE DESCARGAS\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println("   1. LÍMITE DE RESULTADOS: Controla cuántas canciones descarga en listas.")
fmt.Println("   2. DESCARGA POR LOTES: Procesa URLs listadas en lista_descargas.txt.")
fmt.Println("   3. SOLO CONTENIDO PÚBLICO: No requiere autenticación privada.")
fmt.Println("   4. Presiona Ctrl+C en cualquier momento para interrumpir la tarea.")
fmt.Println("   5. MODO NOCTURNO: Apaga la PC en 60 segundos tras finalizar.")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
core.PauseEnter("")
}

func executeBatchDownload(ytdlp string, state *DownloadCenterState) {
core.ShowBanner()
fmt.Println("\n \033[36m📦 DESCARGA POR LOTES DESDE ARCHIVO\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")

if !fileExists(state.BatchFile) {
sample := "# Lista de URLs para descarga por lotes\n# Pega una URL por linea\nhttps://youtube.com/watch?v=ejemplo\n"
_ = os.WriteFile(state.BatchFile, []byte(sample), 0644)
fmt.Println("   \033[33m⚠️ No existia 'lista_descargas.txt'. Se ha creado un archivo de ejemplo.\033[0m")
fmt.Printf("   📁 Ubicacion: %s\n", state.BatchFile)
core.PauseEnter("")
return
}

content, err := os.ReadFile(state.BatchFile)
if err != nil {
return
}

lines := strings.Split(string(content), "\n")
var urls []string
for _, l := range lines {
trim := strings.TrimSpace(l)
if trim != "" && !strings.HasPrefix(trim, "#") && strings.HasPrefix(trim, "http") {
urls = append(urls, trim)
}
}

if len(urls) == 0 {
fmt.Println("   \033[31m❌ No se encontraron URLs validas en lista_descargas.txt.\033[0m")
core.PauseEnter("")
return
}

fmt.Printf("   \033[32m📊 Se encontraron %d URLs validas.\033[0m\n", len(urls))
confirm := core.ReadMenuOption("   ¿Desea descargar todas ahora? (S/N):", []string{"S", "N"}, "N")
if confirm != "S" {
return
}

success := 0
for i, u := range urls {
fmt.Printf("\n \033[36m[%d/%d] Descargando: %s\033[0m\n", i+1, len(urls), u)
outTpl := filepath.Join(state.DestFolder, "%(title)s.%(ext)s")
cmd := exec.Command(ytdlp, "--no-playlist", "-o", outTpl, u)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err == nil {
success++
state.SuccessfulCount++
}
}
fmt.Printf("\n \033[32m📊 RESUMEN: %d de %d descargas completadas exitosamente.\033[0m\n", success, len(urls))
core.PauseEnter("")
}

func evaluateNightShutdown(state *DownloadCenterState) {
if state.NightMode {
fmt.Println("\n \033[31m🔥 MODO NOCTURNO ACTIVO. Apagando PC en 60 segundos...\033[0m")
fmt.Printf(" \033[36m📊 Total descargas exitosas: %d\033[0m\n", state.SuccessfulCount)
time.Sleep(3 * time.Second)
_ = exec.Command("shutdown", "/s", "/f", "/t", "60").Run()
os.Exit(0)
}
}

// InvokeDownloadCenter replica de forma 1 a 1 el Centro de Descargas v4.0
func InvokeDownloadCenter() {
desktop := filepath.Join(os.Getenv("USERPROFILE"), "Desktop")
toolsDir := filepath.Join(desktop, "Herramientas_Descarga")
defaultDir := filepath.Join(desktop, "Descargas_YTDLP")

_ = os.MkdirAll(toolsDir, 0755)
_ = os.MkdirAll(defaultDir, 0755)

state := &DownloadCenterState{
DestFolder:      defaultDir,
DefaultFolder:   defaultDir,
ToolsDir:        toolsDir,
AudioQuality:    "5",
VideoQuality:    "bv*[height<=720]+ba/b[height<=720]/bv*+ba/b",
QualityText:     "Media (192kbps / 720p)",
LimitCount:      50,
SilentMode:      false,
NightMode:       false,
SuccessfulCount: 0,
HistoryFile:     filepath.Join(toolsDir, "historial_descargas.txt"),
BatchFile:       filepath.Join(toolsDir, "lista_descargas.txt"),
}

ytdlpExe := ensureDependencies(state)
if ytdlpExe == "" {
core.PauseEnter("ENTER para volver")
return
}

for {
core.ShowBanner()

usb := detectUSB()
usbText := "\033[90mSin USB conectada\033[0m"
if usb != "" {
usbText = fmt.Sprintf("\033[32mUSB DETECTADA (Unidad %s)\033[0m", usb)
}

nightText := "\033[90mDESACTIVADO\033[0m"
if state.NightMode {
nightText = "\033[31mACTIVO\033[0m"
}

silentText := "NO"
if state.SilentMode {
silentText = "SI"
}

fmt.Println("\n \033[35m🎵 CENTRO DE DESCARGAS INTELIGENTE v4.0\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Printf("   📂 Destino actual: \033[33m%s\033[0m\n", state.DestFolder)
fmt.Printf("   💿 %s\n", usbText)
fmt.Printf("   🎚️ Calidad    : \033[36m%s\033[0m\n", state.QualityText)
fmt.Printf("   🔢 Límite     : \033[36m%d canciones\033[0m\n", state.LimitCount)
fmt.Printf("   🔇 Modo Silent: \033[36m%s\033[0m\n", silentText)
fmt.Printf("   🌙 Modo Noche : %s\n", nightText)
fmt.Printf("   📊 Descargas  : \033[32m%d exitosas\033[0m\n", state.SuccessfulCount)
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println("\n   \033[35m🎬 YOUTUBE:\033[0m")
fmt.Println("   [1] Descargar Disco / Playlist")
fmt.Println("   [2] Descargar Canción sola")
fmt.Println("   [3] YouTube por ENLACE")
fmt.Println("\n   \033[36m📱 OTRAS PLATAFORMAS:\033[0m")
fmt.Println("   [4] TikTok, Instagram, Facebook, Twitter")
fmt.Println("\n   \033[33m🛠️ HERRAMIENTAS:\033[0m")
if state.FFmpegInstalled {
fmt.Println("   [5] MODO DJ: Recortar audio")
} else {
fmt.Println("   \033[90m[5] MODO DJ: NO DISPONIBLE (Falta FFmpeg)\033[0m")
}
fmt.Println("   [6] Configurar Calidad")
fmt.Println("   [7] Configurar Límite")
fmt.Println("   [8] Configurar Modo Nocturno")
fmt.Println("   [9] Configurar Modo Silencioso")
fmt.Println("   [C] Seleccionar Carpeta Destino")
fmt.Println("   [H] Ver Historial")
fmt.Println("   [L] Descarga por Lotes")
fmt.Println("   [N] Ver Notas")
fmt.Println("   [U] Actualizar yt-dlp")
fmt.Println("\n   \033[90m⌨️ CONTROL\033[0m")
fmt.Println("   \033[31m═══════════════════════════════════════════════════════════════════\033[0m")
fmt.Println("   \033[31m[X] SALIR DEL CENTRO DE DESCARGAS\033[0m")

opt := core.ReadMenuOption("\n   > SELECCIONE:", []string{
"1", "2", "3", "4", "5", "6", "7", "8", "9",
"C", "H", "L", "N", "U", "X",
}, "")

if opt == "X" {
break
}

baseArgs := []string{"--no-mtime"}
if !state.SilentMode {
baseArgs = append(baseArgs, "--restrict-filenames")
}

switch opt {
case "1":
core.ShowBanner()
fmt.Println("\n \033[35m🎵 DESCARGAR DISCO / PLAYLIST\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
album := core.ReadMenuOption("   Artista y nombre del Álbum o Playlist:", nil, "")
if album != "" {
cleanName := sanitizeFilename(album)
outTpl := filepath.Join(state.DestFolder, cleanName, "%(playlist_index)s - %(title)s.%(ext)s")
args := append([]string{
"-x", "--audio-format", "mp3", "--audio-quality", state.AudioQuality,
"--yes-playlist", "--playlist-end", strconv.Itoa(state.LimitCount),
}, baseArgs...)

if strings.HasPrefix(album, "http") {
args = append(args, album, "-o", outTpl)
} else {
args = append(args, fmt.Sprintf("ytsearchplaylist%d:%s", state.LimitCount, album), "-o", outTpl)
}

cmd := exec.Command(ytdlpExe, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err == nil {
state.SuccessfulCount++
logDownloadHistory(state, album, "YouTube Playlist", album)
fmt.Println("\n   \033[32m✅ Descarga de álbum/playlist finalizada!\033[0m")
} else {
fmt.Println("\n   \033[31m❌ Error durante la descarga.\033[0m")
}
core.PauseEnter("")
evaluateNightShutdown(state)
}

case "2":
core.ShowBanner()
fmt.Println("\n \033[35m🎵 DESCARGAR CANCIÓN SOLA\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
query := core.ReadMenuOption("   Nombre de la canción o término de búsqueda:", nil, "")
if query != "" {
outTpl := filepath.Join(state.DestFolder, "%(title)s.%(ext)s")
args := append([]string{
"-x", "--audio-format", "mp3", "--audio-quality", state.AudioQuality,
"--no-playlist",
}, baseArgs...)
args = append(args, fmt.Sprintf("ytsearch1:%s", query), "-o", outTpl)

cmd := exec.Command(ytdlpExe, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err == nil {
state.SuccessfulCount++
logDownloadHistory(state, query, "YouTube Track", query)
fmt.Println("\n   \033[32m✅ Canción descargada exitosamente.\033[0m")
} else {
fmt.Println("\n   \033[31m❌ No se pudo completar la descarga.\033[0m")
}
core.PauseEnter("")
evaluateNightShutdown(state)
}

case "3":
core.ShowBanner()
fmt.Println("\n \033[36m🎬 YOUTUBE POR ENLACE\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
link := core.ReadMenuOption("   Pegue la URL del video:", nil, "")
if link != "" {
kind := core.ReadMenuOption("   ¿Descargar como Música [M] o Video [V]?:", []string{"M", "V"}, "M")
outTpl := filepath.Join(state.DestFolder, "%(title)s.%(ext)s")
var args []string
if kind == "V" {
args = append([]string{"-f", state.VideoQuality, "--no-playlist"}, baseArgs...)
} else {
args = append([]string{"-x", "--audio-format", "mp3", "--audio-quality", state.AudioQuality, "--no-playlist"}, baseArgs...)
}
args = append(args, "-o", outTpl, link)

cmd := exec.Command(ytdlpExe, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err == nil {
state.SuccessfulCount++
logDownloadHistory(state, link, "YouTube URL", link)
fmt.Println("\n   \033[32m✅ Descarga completada.\033[0m")
} else {
fmt.Println("\n   \033[31m❌ Error al procesar el enlace.\033[0m")
}
core.PauseEnter("")
evaluateNightShutdown(state)
}

case "4":
core.ShowBanner()
fmt.Println("\n \033[36m📱 REDES SOCIALES (TikTok, Instagram, Facebook, Twitter)\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
url := core.ReadMenuOption("   Pegue la URL del contenido público:", nil, "")
if url != "" {
tipo := core.ReadMenuOption("   ¿Solo audio [S] o Video completo [V]?:", []string{"S", "V"}, "V")
outTpl := filepath.Join(state.DestFolder, "%(title)s.%(ext)s")

isProfile := !strings.Contains(url, "/video/") && !strings.Contains(url, "/status/") && !strings.Contains(url, "watch?v=") && !strings.Contains(url, "/p/")
var playlistArgs []string
if isProfile {
fmt.Println("   \033[33m🔍 URL de perfil detectada. Se procesaran hasta 20 videos.\033[0m")
playlistArgs = []string{"--yes-playlist", "--playlist-end", "20"}
} else {
playlistArgs = []string{"--no-playlist"}
}

var args []string
if tipo == "S" {
args = append([]string{"-x", "--audio-format", "mp3", "--audio-quality", state.AudioQuality}, playlistArgs...)
} else {
args = append([]string{"-f", state.VideoQuality}, playlistArgs...)
}
args = append(args, baseArgs...)
args = append(args, "-o", outTpl, url)

cmd := exec.Command(ytdlpExe, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err == nil {
state.SuccessfulCount++
logDownloadHistory(state, url, "SocialMedia", url)
fmt.Println("\n   \033[32m✅ Descarga de red social completada.\033[0m")
} else {
fmt.Println("\n   \033[31m❌ Error: video privado o enlace incorrecto.\033[0m")
}
core.PauseEnter("")
evaluateNightShutdown(state)
}

case "5":
if !state.FFmpegInstalled {
fmt.Println("\n   \033[31m⚠️ MODO DJ no disponible: FFmpeg no está instalado.\033[0m")
core.PauseEnter("")
continue
}
core.ShowBanner()
fmt.Println("\n \033[33m🎧 MODO DJ: RECORTAR AUDIO\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
track := core.ReadMenuOption("   Nombre de la canción:", nil, "")
start := core.ReadMenuOption("   Segundo o minuto de inicio (HH:MM:SS o MM:SS):", nil, "00:00:00")
end := core.ReadMenuOption("   Segundo o minuto de fin (HH:MM:SS o MM:SS):", nil, "")

if track != "" && end != "" {
outTpl := filepath.Join(state.DestFolder, "%(title)s_recortado.%(ext)s")
section := fmt.Sprintf("*%s-%s", start, end)
args := append([]string{
"-x", "--audio-format", "mp3", "--audio-quality", state.AudioQuality,
"--no-playlist", "--download-sections", section, "--force-keyframes-at-cuts",
fmt.Sprintf("ytsearch1:%s", track), "-o", outTpl,
}, baseArgs...)

cmd := exec.Command(ytdlpExe, args...)
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
if err := cmd.Run(); err == nil {
state.SuccessfulCount++
fmt.Println("\n   \033[32m✅ Recorte DJ descargado correctamente.\033[0m")
} else {
fmt.Println("\n   \033[31m❌ No se pudo recortar el fragmento solicitado.\033[0m")
}
core.PauseEnter("")
evaluateNightShutdown(state)
}

case "6":
core.ShowBanner()
fmt.Println("\n \033[33m⚙️ CONFIGURAR CALIDAD DE SALIDA\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println("   [1] Alta (320kbps / 1080p)")
fmt.Println("   [2] Media (192kbps / 720p)")
fmt.Println("   [3] Baja (128kbps / 480p)")
cOpt := core.ReadMenuOption("\n   Opción:", []string{"1", "2", "3"}, "2")
switch cOpt {
case "1":
state.AudioQuality = "0"
state.VideoQuality = "bv*+ba/b"
state.QualityText = "Alta (320kbps / 1080p)"
case "3":
state.AudioQuality = "9"
state.VideoQuality = "bv*[height<=480]+ba/b[height<=480]/bv*+ba/b"
state.QualityText = "Baja (128kbps / 480p)"
default:
state.AudioQuality = "5"
state.VideoQuality = "bv*[height<=720]+ba/b[height<=720]/bv*+ba/b"
state.QualityText = "Media (192kbps / 720p)"
}
fmt.Printf("\n   \033[32m✅ Calidad cambiada a: %s\033[0m\n", state.QualityText)
time.Sleep(1 * time.Second)

case "7":
core.ShowBanner()
fmt.Println("\n \033[33m⚙️ CONFIGURAR LÍMITE DE CANCIONES EN PLAYLISTS\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Printf("   Límite actual: %d canciones\n", state.LimitCount)
fmt.Println("   [1] 10   [2] 25   [3] 50   [4] 100   [5] Todas (sin límite)")
lOpt := core.ReadMenuOption("\n   Opción:", []string{"1", "2", "3", "4", "5"}, "3")
switch lOpt {
case "1":
state.LimitCount = 10
case "2":
state.LimitCount = 25
case "3":
state.LimitCount = 50
case "4":
state.LimitCount = 100
case "5":
state.LimitCount = 9999
}
fmt.Printf("\n   \033[32m✅ Límite configurado en %d canciones.\033[0m\n", state.LimitCount)
time.Sleep(1 * time.Second)

case "8":
state.NightMode = !state.NightMode
if state.NightMode {
fmt.Println("\n   \033[33m🌙 Modo Nocturno ACTIVADO.\033[0m")
fmt.Println("   \033[31m⚠️ El PC se apagará automáticamente al terminar cualquier descarga.\033[0m")
} else {
fmt.Println("\n   \033[32m🌙 Modo Nocturno DESACTIVADO.\033[0m")
}
time.Sleep(1500 * time.Millisecond)

case "9":
state.SilentMode = !state.SilentMode
if state.SilentMode {
fmt.Println("\n   \033[33m🔇 Modo Silencioso ACTIVADO.\033[0m")
} else {
fmt.Println("\n   \033[32m🔇 Modo Silencioso DESACTIVADO.\033[0m")
}
time.Sleep(1 * time.Second)

case "C":
core.ShowBanner()
fmt.Println("\n \033[36m📂 SELECCIONAR CARPETA DESTINO\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Printf("   [1] Carpeta por defecto (%s)\n", state.DefaultFolder)
fmt.Println("   [2] Especificar ruta manual")
fOpt := core.ReadMenuOption("\n   Opción:", []string{"1", "2"}, "1")
if fOpt == "2" {
reader := bufio.NewReader(os.Stdin)
fmt.Print("   Escriba la ruta completa: ")
customPath, _ := reader.ReadString('\n')
customPath = strings.TrimSpace(customPath)
if customPath != "" {
_ = os.MkdirAll(customPath, 0755)
state.DestFolder = customPath
fmt.Printf("\n   \033[32m✅ Carpeta cambiada a: %s\033[0m\n", customPath)
}
} else {
state.DestFolder = state.DefaultFolder
fmt.Println("\n   \033[32m✅ Carpeta restablecida a la predeterminada.\033[0m")
}
time.Sleep(1 * time.Second)

case "H":
showDownloadHistory(state)

case "L":
executeBatchDownload(ytdlpExe, state)

case "N":
showNotes()

case "U":
core.ShowBanner()
fmt.Println("\n \033[36m🔄 ACTUALIZANDO MOTOR YT-DLP\033[0m")
fmt.Println(" ═══════════════════════════════════════════════════════════════════")
fmt.Println("   ⏳ Verificando y descargando versión más reciente...")
cmd := exec.Command(ytdlpExe, "-U")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr
_ = cmd.Run()
fmt.Println("\n   \033[32m✅ Motor yt-dlp actualizado!\033[0m")
core.PauseEnter("")
}
}
}
