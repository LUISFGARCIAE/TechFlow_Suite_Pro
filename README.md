@'
# 🚀 TechFlow Suite Pro (Native Go Edition)

![TechFlow Banner](https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/banner.png)

[![Release](https://img.shields.io/github/v/release/LUISFGARCIAE/TechFlow_Suite_Pro?color=brightgreen)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases)
[![Go Version](https://img.shields.io/badge/Go-1.22+-00ADD8?style=flat&logo=go)](https://golang.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-blue)](https://microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

Toolkit integral de optimización, mantenimiento avanzado, gestión de software y diagnóstico para entornos Windows. Migrado y reescrito al 100% como un binario nativo e independiente en **lenguaje Go**, garantizando máximo rendimiento, cero dependencias y respuesta instantánea.

---

## ⚡ Novedades de la Versión Go
- 🚀 **Binario Único Nativo:** Ejecutable independiente sin intérpretes lentos de PowerShell.
- 🛡️ **Limpieza Visual Pura:** Cero parpadeos en pantalla y manipulación limpia de buffers de consola mediante API nativa Win32.
- 📦 **Kit Post-Formato Híbrido:** Catálogo de 22 categorías con instalador dual Winget y Chocolatey.
- 💾 **Motor Robocopy Integrado:** Respaldo y restauración multihilo con selector dinámico de discos y perfiles.
- 🎵 **Centro Multimedia Avanzado:** Motor `yt-dlp` interactivo con soporte de recortes DJ por marcas de tiempo y modo nocturno con apagado automático.

---

## 📥 Instalación Rápida

### Opción 1: Descarga Portable (Recomendada)
1. Descarga la versión más reciente desde [Releases](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases).
2. Extrae el archivo ZIP en cualquier ubicación (ej. `C:\TechFlow` o Escritorio).
3. Ejecuta `TechFlow_Pro.exe` como Administrador.

### Opción 2: Compilación Local desde Fuente
powershell
git clone [https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro.git](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro.git)
cd TechFlow_Suite_Pro
go build -ldflags="-s -w" -o TechFlow_Pro.exe ./cmd/techflow
.\TechFlow_Pro.exe

🏗️ Arquitectura Modular GoLa suite adopta una estructura de paquetes desacoplada compilada en un único ejecutable sin dependencias externas:PlaintextTechFlow_Suite_Pro/
├── cmd/
│   └── techflow/
│       ├── app.manifest           # Manifiesto UAC nativo de Windows (requireAdministrator)
│       └── main.go                # Orquestador del menú principal y navegación interactiva
├── pkg/
│   ├── core/                      # Pantalla limpia por Win32 API, startup checks y lectura de teclado
│   ├── apps/                      # Gestor híbrido Winget/Chocolatey, 22 categorías (440 apps) y perfiles
│   ├── backup/                    # Motor multihilo Robocopy con selector dinámico de unidades y perfiles
│   ├── maintenance/               # Limpieza WinSxS ResetBase, temporales, DiskPart y Auto-Flow
│   ├── hardware/                  # Monitoreo térmico, salud de batería, clave BIOS y generador de contraseñas
│   ├── devtools/                  # Integración en caliente de herramientas Microsoft Sysinternals
│   └── media/                     # Centro multimedia yt-dlp con modo DJ por marcas de tiempo y modo nocturno
├── DevTools/                      # Centro de control privado del autor (DevHub, escáneres y versionado)
├── go.mod                         # Módulo de Go
└── README.md                      # Documentación oficial
✨ Novedades y Características PrincipalesFunciónMenúDescripción🚀 Binario Nativo GoSistemaEjecución instantánea en código máquina sin dependencias de runtime.🖥️ Pantalla Win32 PuraSistemaLimpieza atada a los descriptores estándar del sistema (cls), sin parpadeos ni duplicación de banners.🔧 Winget Universal (LTSC/Server)AutoReparación en 3 capas de Winget, compatible con Windows LTSC, IoT y Server sin Microsoft Store.🔑 MassGrave OficialGActivación permanente de Windows y Office mediante el script oficial (get.activated.win).🎵 Centro de Descargas v4.0ZDescarga de música y videos desde YouTube, TikTok, IG, FB y Twitter con yt-dlp. Incluye Modo DJ y Modo Nocturno.🔐 Generador de ContraseñasYContraseñas de alta seguridad (8 a 64 caracteres) con copiado automático al portapapeles.🌡️ Temperaturas CPU/GPUK → TMonitoreo térmico en tiempo real con alertas visuales por código de color.🕹️ Modo DiosK → ZAcceso directo centralizado a todos los paneles de configuración avanzados de Windows.🧹 Limpiador DNS y RedMFlush DNS, renovar IP y reinicio completo de Winsock y TCP/IP en 1 clic.🦠 Auditoría DefenderPEscaneo rápido o completo de malware directamente con el motor de Windows Defender.💿 DiskPart SimplificadoD → 815 operaciones de particionado con confirmación crítica de seguridad.📦 Gestión de DriversCRespaldo y reinstalación de controladores mediante DISM y pnputil.🖥️ Escritorio RemotoTLanzador integrado para mstsc, AnyDesk, RustDesk y TeamViewer.🛠️ Sysinternals KitUIntegración directa de 11 herramientas profesionales (Process Explorer, Autoruns, ProcMon, TCPView, etc.).🛡️ Seguridad y TrazabilidadConfirmación Crítica por ENTER: Sistema de lectura de comandos estricto que exige confirmación explícita mediante ENTER, evitando activaciones accidentales por pulsaciones erróneas.Doble Confirmación en DiskPart: Protección estricta en acciones de limpieza (clean), formateo, conversión de tablas (MBR/GPT) y eliminación de particiones.Freno de Mano (Tecla X): Posibilidad de abortar o retroceder en cualquier subproceso de forma controlada.Arranque Inteligente: Pantalla previa de comprobación que verifica repositorios, analiza versiones en GitHub y optimiza exclusiones de seguridad antes de cargar el menú.🔄 Metodologías: Kit Post-Format vs Auto-Flow ExpressCaracterística🛠️ Kit Post-Format (Opción I)⚡ Auto-Flow Express (Opción Q)EnfoquePersonalización granular y exhaustivaVelocidad extrema para taller técnicoCatálogo440 aplicaciones en 22 categoríasPaquete base esencial (Chrome, 7-Zip, VLC, WinRAR)IntervenciónSelección interactiva por módulos100% desatendido (Zero-Click)SeguridadConfirmación estándar de usuarioEjecución rápida protegidaUso IdealEstaciones de trabajo, diseño y PCs GamingAlistamiento masivo y puesta a punto de flotas📋 Menús y Módulos de la SuitePlaintext📦 KIT POST FORMAT (I) — 440 Apps en 22 categorías
[0] Limpiar Bloatware | [1] Navegadores | [2] Comunicación | [3] Utilidades | [4] Desarrollo | [5] Multimedia
[6] Ofimática | [7] Redes y Terminal | [8] Juegos | [9] Virtualización | [10] Respaldos | [11] VPN
[12] Monitor | [13] Notas | [14] Utilidades Avanzadas | [15] Clientes | [16] Limpieza | [17] Personalización
[18] IA | [19] Seguridad | [20] Data Science | [21] Media Server | [22] Herramientas Sistema
[P] Perfiles | [U] Actualizar todo | [R] Desinstalar | [B] Buscar | [M] Instalación automática | [X] Volver

🎵 CENTRO DE DESCARGAS (Z)
[1] Disco/Playlist | [2] Canción sola | [3] YouTube por ENLACE | [4] TikTok/IG/FB/Twitter
[5] MODO DJ | [6] Configurar Calidad | [7] Configurar Límite | [8] Modo Nocturno
[9] Modo Silencioso | [C] Seleccionar Carpeta | [H] Ver Historial | [L] Descarga por lotes | [X] Salir

🎯 SOPORTE TÉCNICO PRO (K)
[A] Salud Disco | [B] Reparar Sistema | [C] Clave BIOS | [D] Sincronizar Hora
[F] Salud Batería | [T] 🌡️ Temperaturas | [G] Info Técnica | [Z] 🕹️ Modo Dios | [X] Volver

🌐 RED Y REPARACIÓN (M)
[1] Limpiar DNS | [2] Reiniciar Winsock / IP | [3] Renovar IP | [4] Ping Cloudflare 1.1.1.1 | [X] Volver

💿 PURGA Y FORMATEO (D)
[1] Limpiar Temp | [2] Limpiar WinSxS | [3] Eliminar Actualizaciones | [4] Cleanmgr
[5] Formateo USB | [6] Rufus | [8] 💿 DiskPart Simplificado | [X] Volver

🛠️ SYSINTERNALS KIT (U)
[1] Process Explorer | [2] Autoruns | [3] ProcMon | [4] TCPView | [5] RAMMap | [6] VMMap
[7] Disk2VHD | [8] WinObj | [9] Sigcheck | [10] SDelete | [11] AccessEnum | [X] Volver
⌨️ Atajos Globales de NavegaciónTecla V: Alterna el diseño del menú principal entre vista horizontal y vertical.Tecla X: Regresa al menú anterior o actúa como freno de mano cancelando la tarea en curso.Tecla T: Menú directo de Escritorios Remotos (mstsc, AnyDesk, RustDesk, TeamViewer).Tecla Y: Generador instantáneo de contraseñas seguras.Tecla Z: Centro de Descargas Multimedia (yt-dlp).Tecla G: Activación Office / Windows oficial (MassGrave).Tecla R: Refresca el menú principal de forma limpia.❓ Preguntas Frecuentes (FAQ)1. ¿Por qué se migró a Go?Para ofrecer portabilidad absoluta y alto rendimiento. El ejecutable compilado en Go es un único archivo binario que arranca al instante, no depende de la configuración de PowerShell de la máquina y resuelve los problemas de renderizado de la consola.2. ¿Es seguro el proceso de optimización?Totalmente. La suite ejecuta comandos y APIs nativas de Windows (SFC, DISM, chkdsk, defrag) respetando la integridad del kernel y del registro del sistema operativo.3. ¿Winget funciona en Windows LTSC o Server?Sí. El mecanismo de auto-reparación en 3 capas instala automáticamente las dependencias necesarias (VCLibs, UI.Xaml) en sistemas donde Microsoft Store no viene preinstalado.4. ¿Cómo funciona la activación con MassGrave?La opción G ejecuta el script oficial de MassGrave (https://get.activated.win) en una ventana elevada independiente, garantizando transparencia y soporte para licencias digitales HWID y KMS38.5. ¿Cómo opera el Centro de Descargas?Gestiona de forma desatendida los binarios portables de yt-dlp.exe y ffmpeg.exe. Permite descargar listas de reproducción completas, extraer audio en alta fidelidad y cuenta con un modo nocturno que suspende o apaga el equipo al completar la cola de descargas.📊 Métricas y Especificaciones TécnicasMétricaEspecificaciónVersiónv7.0 Native Go EditionFormatoBinario ejecutable compilado x64 (TechFlow_Pro.exe)Catálogo de Software440 aplicaciones en 22 categoríasHerramientas Sysinternals11 utilidades profesionales integradasPlataformas Soportadas (Descargas)YouTube, TikTok, Instagram, Facebook, X (Twitter), etc.Sistemas Operativos CompatiblesWindows 10, Windows 11, LTSC (2019/2021/2024), Windows Server (2019/2022/2025)Requisitos MínimosWindows 10 x64 o superior con permisos de Administrador👨‍💻 DesarrolladorLuis Fernando García EncisoIngeniería de Sistemas | Automatización IT & Soporte OperativoGitHub: @LUISFGARCIAE📜 Licencia y ComunidadEste proyecto cuenta con una Licencia MIT. Uso libre, profesional y transparente.🌐 Web Oficial: techflowsuitepro.apsoft.xyz⭐ Repositorio: github.com/LUISFGARCIAE/TechFlow_Suite_Pro💬 WhatsApp Oficial (Betas y Soporte): Comunidad TechFlow👥 Grupo de Facebook: Comunidad de Usuarios TechFlow⭐ Si esta suite te ha sido útil, apóyala con una estrella en GitHub. ⭐'@ | Set-Content -Encoding UTF8 -Path "C:\TechFlow_Go\README.md"
