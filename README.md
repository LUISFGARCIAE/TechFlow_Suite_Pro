# 🚀 TECH FLOW SUITE PRO (v7.0 Native Go Edition)

> Suite definitiva de herramientas IT para optimización de sistemas, respaldos de alto rendimiento, soporte técnico avanzado y automatización en Windows compilada como un binario nativo independiente en Go.

Desarrollado y mantenido por **Luis Fernando García Enciso**.

[![Go Version](https://img.shields.io/badge/Go-1.22+-00ADD8.svg?style=flat&logo=go)](https://golang.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20LTSC%20%7C%20Server-0078D6.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/Architecture-Go%20Native%20x64-orange.svg)](#-arquitectura-modular-go)

---

## 🧐 ¿Qué es Tech Flow Suite Pro?

Es una solución integral de automatización de nivel profesional diseñada para administradores de sistemas, técnicos y especialistas en soporte TI. La suite cubre desde el alistamiento inicial de equipos (**Post-Format**) hasta diagnósticos críticos y mantenimiento preventivo/correctivo en entornos corporativos o de taller.

Migrada y reescrita al 100% como un **binario nativo e independiente en lenguaje Go**, elimina la lentitud de los intérpretes tradicionales de script, previene bloqueos por directivas de ejecución restringidas y ofrece tiempos de respuesta instantáneos con un consumo de recursos mínimo. Incorpora auto-elevación UAC nativa, protección y exclusión automática en Windows Defender, compatibilidad extendida con Windows LTSC/Server y un catálogo automatizado de más de 440 aplicaciones.

---

## ⚡ Descarga y Ejecución Rápida

No requiere instalar entornos adicionales ni dependencias previas.

### Opción 1: Descarga Portable (Recomendada)
1. Ve a la sección de [Releases](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases) y descarga el archivo comprimido oficial (`TechFlow_Suite_Pro_v7.0_Portable.zip`).
2. Extrae el contenido en tu unidad local o memoria USB.
3. Ejecuta `TechFlow_Pro.exe` como Administrador (o utiliza `Iniciar_TechFlow.bat`).

### Opción 2: Compilación Local desde Fuente
#```powershell
git clone [https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro.git](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro.git)
cd TechFlow_Suite_Pro
go build -ldflags="-s -w" -o TechFlow_Pro.exe ./cmd/techflow
.\TechFlow_Pro.exe

🏗️ Arquitectura Modular Go
La suite adopta una estructura desacoplada compilada en un único ejecutable sin dependencias externas:

TechFlow_Suite_Pro/
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

✨ Novedades y Características Principales

Función,Menú,Descripción
🚀 Binario Nativo Go,Sistema,Ejecución instantánea en código máquina sin dependencias de runtime.
🖥️ Pantalla Win32 Pura,Sistema,"Limpieza atada a los descriptores estándar del sistema (cls), sin parpadeos ni duplicación de banners."
🔧 Winget Universal (LTSC/Server),Auto,"Reparación en 3 capas de Winget, compatible con Windows LTSC, IoT y Server sin Microsoft Store."
🔑 MassGrave Oficial,G,Activación permanente de Windows y Office mediante el script oficial (get.activated.win).
🎵 Centro de Descargas v4.0,Z,"Descarga de música y videos desde YouTube, TikTok, IG, FB y Twitter con yt-dlp. Incluye Modo DJ y Modo Nocturno."
🔐 Generador de Contraseñas,Y,Contraseñas de alta seguridad (8 a 64 caracteres) con copiado automático al portapapeles.
🌡️ Temperaturas CPU/GPU,K → T,Monitoreo térmico en tiempo real con alertas visuales por código de color.
🕹️ Modo Dios,K → Z,Acceso directo centralizado a todos los paneles de configuración avanzados de Windows.
🧹 Limpiador DNS y Red,M,"Flush DNS, renovar IP y reinicio completo de Winsock y TCP/IP en 1 clic."
🦠 Auditoría Defender,P,Escaneo rápido o completo de malware directamente con el motor de Windows Defender.
💿 DiskPart Simplificado,D → 8,15 operaciones de particionado con confirmación crítica de seguridad.
📦 Gestión de Drivers,C,Respaldo y reinstalación de controladores mediante DISM y pnputil.
🖥️ Escritorio Remoto,T,"Lanzador integrado para mstsc, AnyDesk, RustDesk y TeamViewer."
🛠️ Sysinternals Kit,U,"Integración directa de 11 herramientas profesionales (Process Explorer, Autoruns, ProcMon, TCPView, etc.)."

🛡️ Seguridad y Trazabilidad
Confirmación Crítica por ENTER: Sistema de lectura de comandos estricto que exige confirmación explícita mediante ENTER, evitando activaciones accidentales por pulsaciones erróneas.

Doble Confirmación en DiskPart: Protección estricta en acciones de limpieza (clean), formateo, conversión de tablas (MBR/GPT) y eliminación de particiones.

Freno de Mano (Tecla X): Posibilidad de abortar o retroceder en cualquier subproceso de forma controlada.

Arranque Inteligente: Pantalla previa de comprobación que verifica repositorios, analiza versiones en GitHub y optimiza exclusiones de seguridad antes de cargar el menú.

Característica,🛠️ Kit Post-Format (Opción I),⚡ Auto-Flow Express (Opción Q)
Enfoque,Personalización granular y exhaustiva,Velocidad extrema para taller técnico
Catálogo,440 aplicaciones en 22 categorías,"Paquete base esencial (Chrome, 7-Zip, VLC, WinRAR)"
Intervención,Selección interactiva por módulos,100% desatendido (Zero-Click)
Seguridad,Confirmación estándar de usuario,Ejecución rápida protegida
Uso Ideal,"Estaciones de trabajo, diseño y PCs Gaming",Alistamiento masivo y puesta a punto de flotas

📦 KIT POST FORMAT (I) — 440 Apps en 22 categorías
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

⌨️ Atajos Globales de Navegación
Tecla V: Alterna el diseño del menú principal entre vista horizontal y vertical.

Tecla X: Regresa al menú anterior o actúa como freno de mano cancelando la tarea en curso.

Tecla T: Menú directo de Escritorios Remotos (mstsc, AnyDesk, RustDesk, TeamViewer).

Tecla Y: Generador instantáneo de contraseñas seguras.

Tecla Z: Centro de Descargas Multimedia (yt-dlp).

Tecla G: Activación Office / Windows oficial (MassGrave).

Tecla R: Refresca el menú principal de forma limpia.

❓ Preguntas Frecuentes (FAQ)
1. ¿Por qué se migró a Go?

Para ofrecer portabilidad absoluta y alto rendimiento. El ejecutable compilado en Go es un único archivo binario que arranca al instante, no depende de la configuración de PowerShell de la máquina y resuelve los problemas de renderizado de la consola.

2. ¿Es seguro el proceso de optimización?

Totalmente. La suite ejecuta comandos y APIs nativas de Windows (SFC, DISM, chkdsk, defrag) respetando la integridad del kernel y del registro del sistema operativo.

3. ¿Winget funciona en Windows LTSC o Server?

Sí. El mecanismo de auto-reparación en 3 capas instala automáticamente las dependencias necesarias (VCLibs, UI.Xaml) en sistemas donde Microsoft Store no viene preinstalado.

4. ¿Cómo funciona la activación con MassGrave?

La opción G ejecuta el script oficial de MassGrave (https://get.activated.win) en una ventana elevada independiente, garantizando transparencia y soporte para licencias digitales HWID y KMS38.

5. ¿Cómo opera el Centro de Descargas?

Gestiona de forma desatendida los binarios portables de yt-dlp.exe y ffmpeg.exe. Permite descargar listas de reproducción completas, extraer audio en alta fidelidad y cuenta con un modo nocturno que suspende o apaga el equipo al completar la cola de descargas.

Métrica,Especificación
Versión,v7.0 Native Go Edition
Formato,Binario ejecutable compilado x64 (TechFlow_Pro.exe)
Catálogo de Software,440 aplicaciones en 22 categorías
Herramientas Sysinternals,11 utilidades profesionales integradas
Plataformas Soportadas (Descargas),"YouTube, TikTok, Instagram, Facebook, X (Twitter), etc."
Sistemas Operativos Compatibles,"Windows 10, Windows 11, LTSC (2019/2021/2024), Windows Server (2019/2022/2025)"
Requisitos Mínimos,Windows 10 x64 o superior con permisos de Administrador

👨‍💻 Desarrollador
Luis Fernando García Enciso

Ingeniería de Sistemas | Automatización IT & Soporte Operativo

GitHub: @LUISFGARCIAE

📜 Licencia y Comunidad
Este proyecto cuenta con una Licencia MIT. Uso libre, profesional y transparente.

🌐 Web Oficial: techflowsuitepro.apsoft.xyz

⭐ Repositorio: github.com/LUISFGARCIAE/TechFlow_Suite_Pro

💬 WhatsApp Oficial (Betas y Soporte): Comunidad TechFlow

👥 Grupo de Facebook: Comunidad de Usuarios TechFlow

⭐ Si esta suite te ha sido útil, apóyala con una estrella en GitHub. ⭐
