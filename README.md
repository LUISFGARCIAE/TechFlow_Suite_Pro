# 🚀 TECH FLOW SUITE PRO v6.0

[![Descargar EXE](https://img.shields.io/badge/DESCARGAR-EJECUTABLE_PRO-green?style=for-the-badge&logo=windows)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases/latest)
[![Ejecutar Remoto](https://img.shields.io/badge/EJECUTAR_REMOTO-irm_|_iex-blue?style=for-the-badge&logo=powershell)](#-cómo-usarla)
[![Versión](https://img.shields.io/badge/Versión-6.0-blue?style=flat-square&logo=windows)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?style=flat-square&logo=powershell)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro)
[![Licencia](https://img.shields.io/badge/Licencia-MIT-green?style=flat-square)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/blob/main/LICENSE)

**Suite definitiva de herramientas IT para optimización de sistemas, backups de alto rendimiento y automatización avanzada en Windows mediante PowerShell.**

---

## 🧐 ¿Qué es Tech Flow Suite Pro?

Es una solución de automatización de nivel profesional diseñada para **especialistas en soporte TI**. La v6.0 redefine el flujo de trabajo desde el despliegue inicial (Post-Format) hasta el mantenimiento crítico. Desarrollada en PowerShell y optimizada como ejecutable para garantizar **portabilidad, seguridad y una experiencia de usuario fluida**.

**v6.0** es la versión más completa hasta la fecha: **catálogo ampliado a 440 aplicaciones**, **soporte completo para Windows LTSC y Server**, y **activación restaurada con MassGrave**.

---

## ✨ Novedades en v6.0

### 🆕 NUEVAS FUNCIONES

| Función | Menú | Descripción |
|---------|------|-------------|
| 🔧 **Winget Universal (LTSC/Server)** | Auto | Reparación en 3 capas de Winget, ahora compatible con Windows LTSC y Server |
| 🔑 **MassGrave Restaurado** | `G` | Activación de Windows y Office con el script oficial (`get.activated.win`) |
| 🎵 **Centro de Descargas** | `Z` | Descarga música/videos desde YouTube, TikTok, Instagram, etc. con yt-dlp |
| 📊 **Barra de Progreso** | `I → 4` | Animación visual al actualizar todas las apps del sistema |
| 🔐 **Generador de Contraseñas** | `Y` | Contraseñas seguras de 8-64 caracteres con copia al portapapeles |
| 🌡️ **Temperaturas CPU/GPU** | `K → T` | Monitoreo en tiempo real con colores según nivel térmico |
| 🕹️ **Modo Dios** | `K → Z` | Acceso a todas las herramientas de configuración de Windows |
| 🧹 **Limpiador DNS** | `M → H` | Flush DNS, renovar IP, reset Winsock y TCP/IP en 1 clic |
| 🔌 **Escaneo de Puertos** | `M → P` | Escanea 20 puertos comunes en IP local o remota |
| 🦠 **Escaneo de Malware** | `P → C` | Escaneo rápido/completo con Windows Defender |
| 💿 **DiskPart Simplificado** | `D → 8` | 15 operaciones con doble autenticación para acciones críticas |
| 📦 **Compresión ZIP** | `A → C` | Comprime drivers exportados automáticamente |
| 📡 **Servidor de Medios** | `I → 21` | Plex, Jellyfin, Sonarr, Radarr, Prowlarr y más |

### 🔧 MEJORAS EXISTENTES

| Mejora | Descripción |
|--------|-------------|
| **Catálogo ampliado a 440 apps** | Antes 117, ahora 440 apps organizadas en 22 categorías |
| **Reparación universal de Winget** | 3 capas: verificación → método oficial → fallback manual con dependencias |
| **MassGrave restaurado** | Activación de Office/Windows desde la fuente oficial |
| **BACKOP con tabla de progreso** | Muestra tamaño, barra de progreso y carpetas respaldadas |
| **RESTORE con tabla de progreso** | Mismo formato visual profesional para restaurar |
| **Actualización con barra animada** | Progreso visual al actualizar software (KIT Post-Format) |
| **Auto-reparación de Winget/Chocolatey** | Repara automáticamente si están rotos o ausentes |
| **Auto-exclusión silenciosa de Defender** | Se excluye automáticamente al iniciar |
| **Ctrl+C para salir limpio** | Salida del script sin errores rojos |
| **Hora actual en menú** | Reloj visible en la interfaz principal |
| **Menú horizontal/vertical** | Cambia la vista con la tecla `V` |
| **Interfaz más limpia** | Eliminados mensajes redundantes y moldeada la experiencia visual |
| **Escritorio Remoto** | `T` — Acceso directo a mstsc, AnyDesk, RustDesk, TeamViewer |
| **Sysinternals Kit** | `U` — 11 herramientas pro (Process Explorer, Autoruns, ProcMon, etc.) |

### 🛡️ SEGURIDAD

- **Confirmación crítica** con PIN + palabra clave para operaciones peligrosas
- **Doble autenticación** en DiskPart (`clean`, `format`, `convert`, `delete`)
- **Verificación de sistema modificado** en escaneo de malware
- **Auto-exclusión silenciosa de Windows Defender** al iniciar

---

## 🔧 Fix #1: Reparación Universal de Winget (LTSC / Server)

**Problema anterior:**
La función `Repair-Winget` solo intentaba reinstalar Winget descargando directamente el `.msixbundle` desde GitHub. Esto **fallaba en Windows LTSC, Server y sistemas sin Microsoft Store**.

**Solución implementada — 3 capas de reparación:**

**1. Capa 1 — Verificación rápida:**
Detecta si `winget --version` ya funciona.

**2. Capa 2 — Método oficial (Microsoft.WinGet.Client):**
- Instala automáticamente el proveedor **NuGet** si falta.
- Instala el módulo oficial **`Microsoft.WinGet.Client`** desde PSGallery.
- Ejecuta **`Repair-WinGetPackageManager -AllUsers`** (comando oficial de Microsoft).
- Refresca el `PATH` de máquina + usuario.

**3. Capa 3 — Fallback manual con dependencias (para LTSC sin Store):**
- Descarga e instala en orden correcto: **VCLibs → UI.Xaml → Winget**.
- Cada dependencia se valida individualmente.

**Mejoras adicionales:**
- ⚡ **Descargas más rápidas** (silencia `$ProgressPreference` para evitar cuelgues de `Invoke-WebRequest`).
- 🛡️ **Compatible con `-AllUsers`** para equipos multiusuario.
- 📋 **Logs por capa** para diagnóstico rápido.

---

## 🔑 Fix #2: Activación Office/Windows con MassGrave Restaurada

**Problema anterior:**
El enlace de GitHub de terceros para activar Office **ya no está disponible**, dejando la función inservible.

**Solución implementada:**
- Se restauró el **script oficial de MassGrave** (`https://get.activated.win`).
- Se ejecuta en **ventana elevada** (`-Verb RunAs`) para asegurar permisos correctos.
- **Confirmación crítica** antes de ejecutar.
- **Registro en log** para trazabilidad.

---

## 🛠️ Características Principales

- **📦 Catálogo de 440 apps** organizado en **22 categorías**: Navegadores, Comunicación, Utilidades, Desarrollo, Multimedia, Ofimática, Redes, Juegos, Virtualización, Respaldos, VPN, Monitor, Notas, Utilidades Avanzadas, Clientes, Limpieza, Personalización, IA, Seguridad, Data Science, Media Server, Herramientas de Sistema.
- **🎵 Centro de Descargas v4.0:** Descarga música y videos desde YouTube, TikTok, Instagram, Facebook, Twitter usando yt-dlp. Modo DJ, modo nocturno, descarga por lotes y más.
- **🧠 Motor Híbrido v5:** Instalación masiva con lógica de redundancia inteligente: si **Winget** falla, el sistema conmuta automáticamente a **Chocolatey**.
- **🔧 Reparación universal de Winget:** Funciona en Windows LTSC, Server, y sistemas sin Store.
- **🔑 Activación MassGrave:** Windows y Office con la fuente oficial.
- **📊 Barra de progreso animada:** Visualización en tiempo real al actualizar software.
- **🔗 URLs de respaldo:** Si una app falla, la suite muestra el enlace oficial.
- **🛡️ Seguridad Avanzada:** PIN dinámico + doble autenticación en DiskPart.
- **⚡ Auto-Flow Express 2.0:** Mantenimiento "Zero-Click" mejorado.
- **🌐 Gestión de Drivers & Updates:** Drivers certificados vía Microsoft Update.
- **🚀 Backup Multihilo:** Robocopy con 16 hilos.
- **💻 Interfaz Adaptativa:** Menús horizontal/vertical con la tecla `V`.
- **🎮 Sysinternals Kit integrado:** 11 herramientas profesionales.
- **🖥️ Escritorio Remoto:** mstsc, AnyDesk, RustDesk, TeamViewer.

---

## 🔄 Metodologías: Kit Post-Format vs Auto-Flow

Diseñado para adaptarse a la carga de trabajo del taller:

| Característica | 🛠️ Kit Post-Format (Opción I) | ⚡ Auto-Flow Express (Opción Q) |
| :--- | :--- | :--- |
| **Enfoque** | Personalización total y granular | Velocidad extrema para taller |
| **Catálogo** | **440 Apps** (22 categorías) | Apps base (Chrome, 7-Zip, VLC, AnyDesk) |
| **Intervención** | Selección manual de paquetes | Totalmente desatendido |
| **Seguridad** | Confirmación estándar | Ejecución rápida con PIN de seguridad |
| **Uso Ideal** | Estaciones de trabajo y PCs Gaming | Alistamiento masivo de equipos nuevos |

---

## 📋 Menús Actualizados

### 📦 KIT POST FORMAT (I) — 440 Apps en 22 categorías
`[0] Limpiar Bloatware | [1] Navegadores | [2] Comunicación | [3] Utilidades | [4] Desarrollo | [5] Multimedia | [6] Ofimática | [7] Redes y Terminal | [8] Juegos | [9] Virtualización | [10] Respaldos | [11] VPN | [12] Monitor | [13] Notas | [14] Utilidades Avanzadas | [15] Clientes | [16] Limpieza | [17] Personalización | [18] IA | [19] Seguridad | [20] Data Science | [21] Media Server | [22] Herramientas Sistema | [P] Perfiles | [U] Actualizar todo | [R] Desinstalar | [B] Buscar | [M] Instalación automática | [X] Volver`

### 🎵 CENTRO DE DESCARGAS (Z)
`[1] Disco/Playlist | [2] Canción sola | [3] YouTube por ENLACE | [4] TikTok/IG/FB/Twitter | [5] MODO DJ | [6] Configurar Calidad | [7] Configurar Límite | [8] Modo Nocturno | [9] Modo Silencioso | [C] Seleccionar Carpeta | [H] Ver Historial | [L] Descarga por lotes | [U] Actualizar yt-dlp | [X] Salir`

### 🎯 SOPORTE TÉCNICO PRO (K)
`[A] Salud Disco | [B] Reparar Sistema | [C] Clave BIOS | [D] Sincronizar Hora | [F] Salud Batería | [T] 🌡️ Temperaturas | [G] Info Técnica | [Z] 🕹️ Modo Dios | [X] Volver`

### 🌐 RED Y REPARACIÓN (M)
`[A] Resetear Red | [B] Reparar Update | [C] Ver IP | [D] Ping Monitor | [E] Ver WiFi | [F] Tracert | [G] Fast.com | [H] 🧹 Limpiar DNS | [P] 🔌 Escanear Puertos | [W] Wireshark | [X] Volver`

### 🛡️ WINDOWS DEFENDER (P)
`[1] Activar Defender | [2] Reparar Defender | [3] Escaneo de Malware | [4] Desactivar Defender | [X] Volver`

### 💿 PURGA Y FORMATEO (D)
`[1] Limpiar Temp | [2] Limpiar WinSxS | [3] Eliminar Actualizaciones | [4] Cleanmgr | [5] Formateo USB | [6] Rufus | [8] 💿 DiskPart Simplificado | [X] Volver`

### 🛠️ SYSINTERNALS KIT (U)
`[1] Process Explorer | [2] Autoruns | [3] ProcMon | [4] TCPView | [5] RAMMap | [6] VMMap | [7] Disk2VHD | [8] WinObj | [9] Sigcheck | [10] SDelete | [11] AccessEnum | [X] Volver`

---

## 🚀 Cómo usarla

### ⚡ MODO RÁPIDO (NUEVO)

Ejecuta TechFlow al instante sin descargar nada. Abre **PowerShell como Administrador** y pega este comando:

```powershell
irm "https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/TECHFLOW_SUITE_1.ps1" | iex
```

### 📥 MODO TRADICIONAL

1. **Descarga:** Haz clic en el botón verde de arriba o ve a **[Releases](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases)**.
2. **Ejecución:** Haz clic derecho en el archivo descargado y selecciona **Ejecutar como administrador**.
3. **Navegación:**
   - Tecla `V`: Cambia el estilo visual del menú
   - Tecla `X`: Regresa al menú anterior o cancela un proceso
   - Tecla `T`: Acceso directo a Escritorio Remoto
   - Tecla `Y`: Generador de contraseñas seguras
   - Tecla `Z`: Centro de Descargas (música/videos)
   - Tecla `G`: Activación Office/Windows (MassGrave)
   - Tecla `Ctrl+C`: Salida limpia del script

---

## 🛠️ Especificaciones Técnicas

- **Lenguaje:** PowerShell 5.1 / Core (con auto-elevación a Administrador).
- **Compilación:** Versión 6.0 optimizada para estabilidad y compatibilidad LTSC.
- **Trazabilidad:** Generación automática de **Logs de sesión** con rotación automática (>10 MB).
- **Seguridad:** Lógica de "Freno de Mano" (Tecla `X` para abortar) y validación de integridad.
- **Exclusiones:** Drivers de monitoreo (CPU-Z, HWMonitor, GPU-Z, MSI Afterburner) excluidos de limpieza.
- **Auto-reparación:** Winget, Chocolatey y Scoop se reparan automáticamente al inicio.
- **Compatibilidad:** Windows 10, 11, **LTSC 2019/2021/2024**, **Server 2019/2022/2025**.

---

## ❓ Preguntas Frecuentes (FAQ)

**1. ¿Por qué el .EXE tiene alertas en antivirus?** ⚠️
El código en PowerShell (.ps1) es transparente. Las alertas ocurren porque las herramientas de conversión (ps2exe) empaquetan el script de una forma que algunos antivirus detectan como "sospechosa" al no tener una firma digital de pago. Es un **falso positivo**. La v6.0 incluye auto-exclusión silenciosa para mitigar esto.

**2. ¿Es seguro el proceso de optimización?** 🛡️
Totalmente. La suite utiliza comandos nativos de Windows (SFC, DISM, Optimize-Volume) para asegurar que la integridad del sistema nunca se vea comprometida.

**3. ¿Por qué Spotify, WhatsApp o Discord no se instalan?**
Estas aplicaciones **no permiten instalación en modo administrador** por decisión de sus desarrolladores. La suite detecta el fallo y muestra el enlace oficial de descarga.

**4. ¿Winget funciona en Windows LTSC?** 🔧
**¡Sí!** A partir de la v6.0, `Repair-Winget` incluye **3 capas de reparación** que instalan automáticamente las dependencias necesarias (`VCLibs`, `UI.Xaml`) en sistemas LTSC y Server donde Microsoft Store no está presente.

**5. ¿Cómo funciona la activación con MassGrave?** 🔑
La opción `G` ejecuta el script oficial de MassGrave (`get.activated.win`) en una **ventana elevada**. Puedes activar tanto **Windows** como **Office** desde el menú interactivo que aparece. Requiere conexión a Internet.

**6. ¿Cómo funciona el Centro de Descargas?** 🎵
TechFlow descarga automáticamente `yt-dlp.exe` y `ffmpeg.exe` (si no existen). Soporta YouTube, TikTok, Instagram, Facebook, Twitter. Incluye modo DJ para recortar audios y modo nocturno que apaga el PC al terminar.

**7. ¿Cómo puedo apoyar?** ⭐
- **Danos una Estrella:** Haz clic en la ⭐ arriba a la derecha en GitHub
- **Feedback:** Si encuentras un error, abre un "Issue" para corregirlo

---

## 📊 Estadísticas

| Métrica | Valor |
|---------|-------|
| **Versión** | v6.0 |
| **Total de funciones** | 45+ |
| **Total de líneas de código** | ~7000 |
| **Aplicaciones en catálogo** | 440 (22 categorías) |
| **Herramientas Sysinternals** | 11 |
| **Plataformas de descarga** | 6 (YouTube, TikTok, IG, FB, Twitter, +) |
| **Sistemas compatibles** | Win10/11, LTSC 2019/2021/2024, Server 2019/2022/2025 |
| **Puntuación** | 9.8/10 |

---

## ✅ Resumen de cambios v5.8 → v6.0

| Área | Cambio |
|------|--------|
| **Versión** | v5.8 → v6.0 |
| **Catálogo de apps** | 117 → 440 (22 categorías) |
| **Winget** | Reparación básica → **Universal (LTSC/Server) con 3 capas** |
| **Activación Office** | Enlace roto → **MassGrave oficial restaurado** |
| **Nuevas funciones** | Centro de Descargas, Generador de Contraseñas, Temperaturas CPU/GPU, Modo Dios, Escaneo de Puertos, DiskPart Simplificado, Media Server |
| **Compatibilidad** | Windows 10/11 → **Windows 10/11 + LTSC + Server** |
| **Estadísticas** | 35+ funciones → **45+ funciones** |

---

## 👨‍💻 Desarrollador

**Luis Fernando Garcia Enciso**
*Especialista en Soporte TI y Automatización.*

---

## 📜 Licencia

Este proyecto cuenta con una **Licencia MIT**. Uso profesional, libre y transparente.

---

## 🔗 Enlaces

- 📥 **Descarga:** https://techflowsuitepro.apsoft.xyz/
- ⚡ **Ejecución Rápida:** `irm "https://raw.githubusercontent.com/LUISFGARCIAE/TechFlow_Suite_Pro/main/TECHFLOW_SUITE_1.ps1" | iex`
- ⭐ **GitHub:** https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro
- 💬 **WhatsApp (Betas):** https://chat.whatsapp.com/FCA1akMPOBFAMDxoKyZYiQ
- 👥 **Facebook:** https://www.facebook.com/groups/1994403741952828

---

⭐ **Si este proyecto te ha sido útil, considera darle una estrella en GitHub.** ⭐
