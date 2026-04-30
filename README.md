# 🚀 TECH FLOW SUITE PRO v5.7

[![Descargar EXE](https://img.shields.io/badge/DESCARGAR-EJECUTABLE_PRO-green?style=for-the-badge&logo=windows)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases/latest)
[![Versión](https://img.shields.io/badge/Versión-5.7-blue?style=flat-square&logo=windows)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?style=flat-square&logo=powershell)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro)

**Suite definitiva de herramientas IT para optimización de sistemas, backups de alto rendimiento y automatización avanzada en Windows mediante PowerShell.**

---

## 🧐 ¿Qué es Tech Flow Suite Pro?

Es una solución de automatización de nivel profesional diseñada para **especialistas en soporte TI**. La v5.7 redefine el flujo de trabajo desde el despliegue inicial (Post-Format) hasta el mantenimiento crítico. Desarrollada en PowerShell y optimizada como ejecutable para garantizar portabilidad, seguridad y una experiencia de usuario fluida.

---

## ✨ Novedades en v5.7

### 🆕 NUEVAS FUNCIONES

| Función | Menú | Descripción |
|---------|------|-------------|
| **Generador de Contraseñas** | `Y` | Contraseñas seguras de 8-64 caracteres con copia al portapapeles |
| **Temperaturas CPU/GPU** | `K → T` | Monitoreo en tiempo real con colores según nivel térmico |
| **Modo Dios** | `K → Z` | Acceso a todas las herramientas de configuración de Windows |
| **Limpiador DNS** | `M → H` | Flush DNS, renovar IP, reset Winsock y TCP/IP en 1 clic |
| **Escaneo de Puertos** | `M → P` | Escanea 20 puertos comunes en IP local o remota |
| **Escaneo de Malware** | `P → C` | Escaneo rápido/completo con Windows Defender |
| **DiskPart Simplificado** | `D → 8` | 15 operaciones con doble autenticación para acciones críticas |
| **Compresión ZIP** | `A → C` | Comprime drivers exportados automáticamente |

### 🔧 MEJORAS EXISTENTES

| Mejora | Descripción |
|--------|-------------|
| **BACKOP con tabla de progreso** | Muestra tamaño, barra de progreso y carpetas respaldadas |
| **RESTORE con tabla de progreso** | Mismo formato visual profesional para restaurar |
| **Auto-reparación de Winget/Chocolatey** | Repara automáticamente si están rotos o ausentes |
| **Auto-exclusión silenciosa de Defender** | Se excluye automáticamente al iniciar |
| **Ctrl+C para salir limpio** | Salida del script sin errores rojos |
| **Hora actual en menú** | Reloj visible en la interfaz principal |
| **Menú horizontal/vertical** | Cambia la vista con la tecla `V` |
| **Interfaz más limpia** | Eliminados mensajes redundantes y moldeada la experiencia visual |

### 🛡️ SEGURIDAD

- **Confirmación crítica** con PIN + palabra clave para operaciones peligrosas
- **Doble autenticación** en DiskPart (`clean`, `format`, `convert`, `delete`)
- **Verificación de sistema modificado** en escaneo de malware
- **Auto-exclusión silenciosa de Windows Defender** al iniciar

---

## 🛠️ Características Principales

- **🧠 Motor Híbrido v5:** Instalación masiva de **117 aplicaciones** con lógica de redundancia inteligente: si **Winget** falla, el sistema conmuta automáticamente a **Chocolatey** (Mapeo Manual + URLs de respaldo).
- **🔗 URLs de respaldo:** Si una app falla, la suite muestra el enlace oficial para descarga manual.
- **🛡️ Seguridad Avanzada:** Implementación de **PIN dinámico aleatorio** para confirmar operaciones críticas y doble autenticación en DiskPart.
- **⚡ Auto-Flow Express 2.0:** Mantenimiento "Zero-Click" mejorado que ejecuta limpieza profunda de Bloatware, borrado de temporales e instalación de la suite esencial en tiempo récord.
- **🌐 Gestión de Drivers & Updates:** Búsqueda e instalación de controladores certificados mediante servidores de Microsoft Update.
- **🚀 Backup Multihilo:** Uso de **Robocopy con 16 hilos de ejecución** para respaldar perfiles de usuario (Escritorio, Documentos, Fotos, etc.) de manera ultra-rápida.
- **💻 Interfaz Adaptativa:** Sistema de menús dinámicos con opción de vista Horizontal (compacta) o Vertical (detallada) mediante la tecla `V`.
- **🎮 Sysinternals Kit integrado:** 11 herramientas profesionales (Process Explorer, Autoruns, ProcMon, TCPView, RAMMap, etc.)

---

## 🔄 Metodologías: Kit Post-Format vs Auto-Flow

Diseñado para adaptarse a la carga de trabajo del taller:

| Característica | 🛠️ Kit Post-Format (Opción I) | ⚡ Auto-Flow Express (Opción Q) |
| :--- | :--- | :--- |
| **Enfoque** | Personalización total y granular | Velocidad extrema para taller |
| **Catálogo** | **117 Apps** (Dev, Gaming, Office) | Apps base (Chrome, 7-Zip, VLC, AnyDesk) |
| **Intervención** | Selección manual de paquetes | Totalmente desatendido |
| **Seguridad** | Confirmación estándar | Ejecución rápida con PIN de seguridad |
| **Uso Ideal** | Estaciones de trabajo y PCs Gaming | Alistamiento masivo de equipos nuevos |

---

## 📋 Menús Actualizados

### 🎯 SOPORTE TÉCNICO PRO (K)
`[A] Salud Disco | [B] Reparar Sistema | [C] Clave BIOS | [D] Sincronizar Hora | [F] Salud Batería | [T] 🌡️ Temperaturas | [G] Info Técnica | [Z] 🕹️ Modo Dios | [X] Volver`

### 🌐 RED Y REPARACIÓN (M)
`[A] Resetear Red | [B] Reparar Update | [C] Ver IP | [D] Ping Monitor | [E] Ver WiFi | [F] Tracert | [G] Fast.com | [H] 🧹 Limpiar DNS | [P] 🔌 Escanear Puertos | [W] Wireshark | [X] Volver`

### 🛡️ WINDOWS DEFENDER (P)
`[A] Activar Defender | [B] Desactivar Defender | [C] 🦠 Escanear Malware | [X] Volver`

### 💿 PURGA Y FORMATEO (D)
`[1] Limpiar Temp | [2] Limpiar WinSxS | [3] Eliminar Actualizaciones | [4] Cleanmgr | [5] Formateo USB | [6] Rufus | [8] 💿 DiskPart Simplificado | [X] Volver`

---

## 🛠️ Especificaciones Técnicas

- **Lenguaje:** PowerShell 5.1 / Core (con auto-elevación a Administrador).
- **Compilación:** Versión 5.7 optimizada para estabilidad.
- **Trazabilidad:** Generación automática de **Logs de sesión** con rotación automática (>10 MB).
- **Seguridad:** Lógica de "Freno de Mano" (Tecla `X` para abortar) y validación de integridad.
- **Exclusiones:** Drivers de monitoreo (CPU-Z, HWMonitor, GPU-Z, MSI Afterburner) excluidos de limpieza.
- **Auto-reparación:** Winget, Chocolatey y Scoop se reparan automáticamente al inicio.

---

## 🚀 Cómo usarla

1. **Descarga:** Haz clic en el botón verde de arriba o ve a **[Releases](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases)**.
2. **Ejecución:** Haz clic derecho y selecciona **Ejecutar como administrador**.
3. **Navegación:**
   - Tecla `V`: Cambia el estilo visual del menú
   - Tecla `X`: Regresa al menú anterior o cancela un proceso
   - Tecla `T`: Acceso directo a Escritorio Remoto
   - Tecla `Y`: Generador de contraseñas seguras
   - Tecla `Ctrl+C`: Salida limpia del script

---

## ❓ Preguntas Frecuentes (FAQ)

**1. ¿Por qué el .EXE tiene alertas en antivirus?** ⚠️
El código en PowerShell (.ps1) es transparente. Las alertas ocurren porque las herramientas de conversión (ps2exe) empaquetan el script de una forma que algunos antivirus detectan como "sospechosa" al no tener una firma digital de pago. Es un **falso positivo**. La v5.7 incluye auto-exclusión silenciosa para mitigar esto.

**2. ¿Es seguro el proceso de optimización?** 🛡️
Totalmente. La suite utiliza comandos nativos de Windows (SFC, DISM, Optimize-Volume) para asegurar que la integridad del sistema nunca se vea comprometida.

**3. ¿Por qué Spotify, WhatsApp o Discord no se instalan?**
Estas aplicaciones **no permiten instalación en modo administrador** por decisión de sus desarrolladores. La suite detecta el fallo y muestra el enlace oficial de descarga.

**4. ¿Qué pasa si Winget o Chocolatey están rotos?** 🔧
La v5.7 incluye **auto-reparación inteligente**. Si un gestor falla, el sistema lo repara automáticamente o muestra la URL de descarga manual.

**5. ¿Cómo puedo apoyar?** ⭐
- **Danos una Estrella:** Haz clic en la ⭐ arriba a la derecha en GitHub
- **Feedback:** Si encuentras un error, abre un "Issue" para corregirlo

---

## 📊 Estadísticas

| Métrica | Valor |
|---------|-------|
| **Versión** | v5.7 |
| **Total de funciones** | 35+ |
| **Total de líneas de código** | ~5000 |
| **Aplicaciones en catálogo** | 117 |
| **Herramientas Sysinternals** | 11 |
| **Puntuación** | 9.8/10 |

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
- ⭐ **GitHub:** https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro
- 💬 **WhatsApp (Betas):** https://chat.whatsapp.com/FCA1akMPOBFAMDxoKyZYiQ
- 👥 **Facebook:** https://www.facebook.com/groups/1994403741952828

---

⭐ **Si este proyecto te ha sido útil, considera darle una estrella en GitHub.** ⭐
