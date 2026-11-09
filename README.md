# 🚀 TECH FLOW SUITE PRO (v7.0 Modular Edition)

> Suite definitiva de herramientas IT para optimización de sistemas, backups de alto rendimiento, soporte técnico avanzado y automatización en Windows mediante PowerShell.

Desarrollado y mantenido por **Luis Fernando García Enciso**.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue.svg)](https://microsoft.com/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20LTSC%20%7C%20Server-0078D6.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/Architecture-Modular%20v7.0-orange.svg)](#-arquitectura-modular-v70)

---

## 🧐 ¿Qué es Tech Flow Suite Pro?

Es una solución integral de automatización de nivel profesional diseñada para administradores de sistemas, técnicos y especialistas en soporte TI. La suite cubre desde el alistamiento inicial de equipos (**Post-Format**) hasta diagnósticos críticos y mantenimiento preventivo/correctivo en entornos corporativos o de taller.

Desarrollada en PowerShell con soporte nativo tanto para consolas interactivas como para ejecución desatendida, incorpora protección automática en Windows Defender, compatibilidad extendida con Windows LTSC/Server y un catálogo automatizado de más de 440 aplicaciones.

---

## ⚡ Instalación y Ejecución Rápida (PowerShell One-Liner)

No requiere clonar manualmente el repositorio ni descargar archivos por adelantado. Abre **PowerShell como Administrador** y ejecuta:

```powershell
irm [https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/install.ps1](https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/install.ps1) | iex
```

### ¿Qué hace el instalador web automático?
1. **Elevación UAC Transparente:** Verifica privilegios de Administrador y reabre la sesión elevada de forma automática si es necesario.
2. **Auto-Exclusión en Defender:** Agrega automáticamente `C:\TechFlow_Suite_Pro_v6` a la lista de exclusiones de Windows Defender para evitar falsos positivos durante la ejecución de herramientas de diagnóstico o utilidades portables.
3. **Despliegue Limpio:** Descarga la versión más reciente desde la rama `main` de GitHub, verifica la integridad de los paquetes y extrae la estructura modular en disco.
4. **Acceso Directo:** Crea el acceso directo oficial en el Escritorio apuntando a `lanzador.bat`.
5. **Arranque Inmediato:** Inicializa el orquestador principal listo para usarse.

---

## 🏗️ Arquitectura Modular (v7.0)

La suite adopta una estructura modular desacoplada con carga bajo demanda:

```text
C:\TechFlow_Suite_Pro_v6\
├── TechFlow.ps1             # Orquestador del menú principal y navegación
├── lanzador.bat             # Punto de entrada interactivo con elevación UAC
├── install.ps1              # Script de despliegue y actualización web (IEX)
├── VERSION.json             # Manifiesto semántico de versión y changelog público
├── README.md                # Documentación oficial
├── Modules\                 # Núcleo modular de funcionalidades
│   ├── Core.ps1             # Logging, validación semántica y chequeo contra GitHub
│   ├── AppsKit.ps1          # Gestor de instalación de software y paquetes (440 apps)
│   ├── Maintenance.ps1      # Limpieza profunda, optimización y reparación de sistema
│   ├── HardwareTools.ps1    # Diagnóstico de almacenamiento, red y componentes
│   ├── BackupRestore.ps1    # Respaldos multihilo de perfil, drivers e información crítica
│   └── MediaDownloader.ps1  # Centro de descargas multimedia (yt-dlp + ffmpeg)
└── RemoteTools\             # Herramientas y utilidades portables complementarias
```

---

## ✨ Novedades y Características Principales

| Función | Menú | Descripción |
| :--- | :---: | :--- |
| **🔧 Winget Universal (LTSC/Server)** | `Auto` | Reparación en 3 capas de Winget, compatible con Windows LTSC, IoT y Server sin Microsoft Store. |
| **🔑 MassGrave Oficial** | `G` | Activación permanente de Windows y Office mediante el script oficial (`get.activated.win`). |
| **🎵 Centro de Descargas v4.0** | `Z` | Descarga de música y videos desde YouTube, TikTok, IG, FB y Twitter con `yt-dlp`. Incluye Modo DJ y Modo Nocturno. |
| **📊 Barra de Progreso Animada** | `I → 4` | Animación visual en tiempo real al actualizar todas las aplicaciones del sistema. |
| **🔐 Generador de Contraseñas** | `Y` | Contraseñas de alta seguridad (8 a 64 caracteres) con copiado automático al portapapeles. |
| **🌡️ Temperaturas CPU/GPU** | `K → T` | Monitoreo térmico en tiempo real con alertas visuales por código de color. |
| **🕹️ Modo Dios** | `K → Z` | Acceso directo centralizado a todos los paneles de configuración avanzados de Windows. |
| **🧹 Limpiador DNS y Red** | `M → H` | Flush DNS, renovar IP y reinicio completo de Winsock y TCP/IP en 1 clic. |
| **🔌 Escaneo de Puertos** | `M → P` | Escaneo de los 20 puertos más comunes en IP local o remota. |
| **🦠 Auditoría Defender** | `P → C` | Escaneo rápido o completo de malware directamente con el motor de Windows Defender. |
| **💿 DiskPart Simplificado** | `D → 8` | 15 operaciones de particionado con confirmación crítica de seguridad. |
| **📦 Compresión ZIP de Drivers** | `A → C` | Exportación y compresión automática de controladores con `Export-WindowsDriver`. |
| **📡 Media Server Deployment** | `I → 21` | Despliegue automatizado de Plex, Jellyfin, Sonarr, Radarr, Prowlarr y ecosistema multimedia. |
| **🖥️ Escritorio Remoto** | `T` | Lanzador integrado para mstsc, AnyDesk, RustDesk y TeamViewer. |
| **🛠️ Sysinternals Kit** | `U` | Integración directa de 11 herramientas profesionales (Process Explorer, Autoruns, ProcMon, TCPView, etc.). |

---

## 🛡️ Seguridad y Trazabilidad

- **Confirmación Crítica:** Uso de PIN dinámico y palabras clave para operaciones irreversibles o destructivas en almacenamiento.
- **Doble Autenticación en DiskPart:** Protección estricta en acciones de limpieza (`clean`), formateo, conversión de tablas y eliminación de particiones.
- **Freno de Mano (Tecla X):** Posibilidad de abortar o retroceder en cualquier subproceso de forma controlada.
- **Salida Limpia (`Ctrl + C`):** Cierre seguro sin volcados de errores rojos en consola.
- **Logs de Sesión Automatizados:** Trazabilidad completa con rotación automática de archivos de registro cuando superan los 10 MB.

---

## 🔧 Correcciones Críticas de Ingeniería

### 1. Reparación Universal de Winget en 3 Capas (LTSC / Server)
* **Capa 1 — Verificación Rápida:** Detección de respuesta inmediata de `winget --version`.
* **Capa 2 — Método Oficial (`Microsoft.WinGet.Client`):** Despliegue del proveedor NuGet, instalación del módulo oficial de Microsoft desde PSGallery y ejecución de `Repair-WinGetPackageManager -AllUsers` con refresco de variables de entorno (`PATH`).
* **Capa 3 — Fallback Manual con Dependencias:** Descarga secuencial e instalación de componentes base: `VCLibs` → `UI.Xaml` → `Winget MSIXBundle`, permitiendo funcionamiento total en entornos sin Microsoft Store.

### 2. Sincronización y Validación Semántica con GitHub
`Modules\Core.ps1` valida en tiempo de arranque el manifiesto público `VERSION.json` alojado en el repositorio oficial. Ante cualquier discrepancia entre la versión instalada y la remota, el sistema notifica al operador permitiéndole actualizar con un clic o continuar la ejecución local.

---

## 🔄 Metodologías: Kit Post-Format vs Auto-Flow Express

| Característica | 🛠️ Kit Post-Format (Opción `I`) | ⚡ Auto-Flow Express (Opción `Q`) |
| :--- | :--- | :--- |
| **Enfoque** | Personalización granular y exhaustiva | Velocidad extrema para taller técnico |
| **Catálogo** | 440 aplicaciones en 22 categorías | Paquete base esencial (Chrome, 7-Zip, VLC, AnyDesk) |
| **Intervención** | Selección interactiva por módulos | 100% desatendido (*Zero-Click*) |
| **Seguridad** | Confirmación estándar de usuario | Ejecución rápida protegida con PIN |
| **Uso Ideal** | Estaciones de trabajo, diseño y PCs Gaming | Alistamiento masivo y puesta a punto de flotas |

---

## 📋 Menús y Módulos de la Suite

```text
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
[A] Resetear Red | [B] Reparar Update | [C] Ver IP | [D] Ping Monitor
[E] Ver WiFi | [F] Tracert | [G] Fast.com | [H] 🧹 Limpiar DNS | [P] 🔌 Escaneo Puertos | [X] Volver

💿 PURGA Y FORMATEO (D)
[1] Limpiar Temp | [2] Limpiar WinSxS | [3] Eliminar Actualizaciones | [4] Cleanmgr
[5] Formateo USB | [6] Rufus | [8] 💿 DiskPart Simplificado | [X] Volver

🛠️ SYSINTERNALS KIT (U)
[1] Process Explorer | [2] Autoruns | [3] ProcMon | [4] TCPView | [5] RAMMap | [6] VMMap
[7] Disk2VHD | [8] WinObj | [9] Sigcheck | [10] SDelete | [11] AccessEnum | [X] Volver
```

---

## ⌨️ Atajos Globales de Navegación

* **`Tecla V`**: Alterna el diseño del menú entre vista horizontal y vertical.
* **`Tecla X`**: Regresa al menú anterior o actúa como freno de mano cancelando la tarea en curso.
* **`Tecla T`**: Menú directo de Escritorios Remotos (mstsc, AnyDesk, RustDesk, TeamViewer).
* **`Tecla Y`**: Generador instantáneo de contraseñas seguras.
* **`Tecla Z`**: Centro de Descargas Multimedia.
* **`Tecla G`**: Activación Office / Windows oficial (MassGrave).
* **`Ctrl + C`**: Salida limpia del script cerrando subprocesos sin volcar errores en pantalla.

---

## ❓ Preguntas Frecuentes (FAQ)

**1. ¿Es seguro el proceso de optimización?**  
Totalmente. La suite ejecuta comandos y APIs nativas de Windows (`SFC`, `DISM`, `Optimize-Volume`, cmdlets de PowerShell) respetando la integridad del kernel y del registro del sistema operativo.

**2. ¿Por qué algunas apps como Spotify o Discord fallan si se instalan como Administrador?**  
Determinados instaladores no admiten privilegios elevados por diseño de sus fabricantes. La suite intercepta estos fallos y muestra el enlace oficial para su instalación en contexto de usuario estándar.

**3. ¿Winget funciona en Windows LTSC o Server?**  
Sí. El mecanismo de auto-reparación en 3 capas instala automáticamente las dependencias necesarias (`VCLibs`, `UI.Xaml`) en sistemas donde Microsoft Store no viene preinstalado.

**4. ¿Cómo funciona la activación con MassGrave?**  
La opción `G` ejecuta el script oficial de MassGrave (`https://get.activated.win`) en una ventana elevada independiente, garantizando transparencia y soporte para licencias digitales HWID y KMS38.

**5. ¿Cómo opera el Centro de Descargas?**  
Gestiona de forma desatendida los binarios portables de `yt-dlp.exe` y `ffmpeg.exe`. Permite descargar listas de reproducción completas, extraer audio en alta fidelidad y cuenta con un modo nocturno que suspende o apaga el equipo al completar la cola de descargas.

---

## 📊 Métricas y Especificaciones Técnicas

| Métrica | Especificación |
| :--- | :--- |
| **Versión** | v7.0 Modular Edition |
| **Módulos Activos** | 6 submódulos principales + utilidades portables |
| **Catálogo de Software** | 440 aplicaciones en 22 categorías |
| **Herramientas Sysinternals** | 11 utilidades profesionales integradas |
| **Plataformas Soportadas (Descargas)** | YouTube, TikTok, Instagram, Facebook, X (Twitter), etc. |
| **Sistemas Operativos Compatibles** | Windows 10, Windows 11, LTSC (2019/2021/2024), Windows Server (2019/2022/2025) |
| **Requisitos Mínimos** | PowerShell 5.1 / PowerShell 7+ con privilegios de Administrador |

---

## 👨‍💻 Desarrollador

**Luis Fernando García Enciso**  
*Ingeniería de Sistemas | Automatización IT & Soporte Operativo*  
GitHub: [@LUISFGARCIAE](https://github.com/LUISFGARCIAE)

---

## 📜 Licencia y Comunidad

Este proyecto cuenta con una **Licencia MIT**. Uso libre, profesional y transparente.

* 🌐 **Web Oficial:** [techflowsuitepro.apsoft.xyz](https://techflowsuitepro.apsoft.xyz/)
* ⚡ **Ejecución Rápida:** `irm https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/install.ps1 | iex`
* ⭐ **Repositorio:** [github.com/LUISFGARCIAE/TechFlow_Suite_Pro](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro)
* 💬 **WhatsApp Oficial (Betas y Soporte):** [Comunidad TechFlow](https://chat.whatsapp.com/FCA1akMPOBFAMDxoKyZYiQ)
* 👥 **Grupo de Facebook:** [Comunidad de Usuarios TechFlow](https://www.facebook.com/groups/1994403741952828)

⭐ *Si esta suite te ha sido útil, apóyala con una estrella en GitHub.* ⭐
