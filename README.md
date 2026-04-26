# 🚀 TECH FLOW SUITE PRO v5.5

[![Descargar EXE](https://img.shields.io/badge/DESCARGAR-EJECUTABLE_PRO-green?style=for-the-badge&logo=windows)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases/latest)

Suite definitiva de herramientas IT para optimización de sistemas, backups de alto rendimiento y automatización avanzada en Windows mediante PowerShell.

---

## 🧐 ¿Qué es Tech Flow Suite Pro?
Es una solución de automatización de nivel profesional diseñada para **especialistas en soporte TI**. La v5.5 redefine el flujo de trabajo desde el despliegue inicial (Post-Format) hasta el mantenimiento crítico. Desarrollada en PowerShell y optimizada como ejecutable para garantizar portabilidad, seguridad y una experiencia de usuario fluida.

---

## ✨ Novedades en v5.5 (Últimas integraciones)

| Área | Mejora |
|------|--------|
| **🧹 Optimizar Temp** | Nueva opción `[5]` BleachBit - Limpieza profunda de navegadores y cachés |
| **📊 Monitor en vivo** | Nuevas opciones `[P]` Process Lasso y `[E]` Everything Search |
| **💾 Backup Total** | Nueva opción `[D]` Duplicati - Backup encriptado a la nube |
| **🌐 Red y Reparación** | Nueva opción `[W]` Wireshark - Análisis de tráfico de red |
| **📦 KIT POST FORMAT** | Nueva opción `[5]` Desinstalación de programas (Revo, BCUninstaller, Panel Control) |
| **🖥️ Escritorio Remoto** | Nueva opción `[T]` con AnyDesk, RustDesk y TeamViewer |
| **🔧 BCUninstaller** | ID corregido a `Klocman.BulkCrapUninstaller` |
| **🪟 Ventana winget** | Ahora es oculta (no molesta al usuario) |
| **✅ App ya instalada** | Mensaje claro cuando ya está en última versión |

---

## 🛠️ Características Principales

* **🧠 Motor Híbrido v5:** Instalación masiva de **117 aplicaciones** con lógica de redundancia inteligente: si **Winget** falla, el sistema conmuta automáticamente a **Chocolatey** (Mapeo Manual).
* **🔗 URLs de respaldo:** Si una app falla, la suite muestra el enlace oficial para descarga manual.
* **🛡️ Seguridad Avanzada:** Implementación de **PIN dinámico aleatorio** para confirmar operaciones críticas (borrado de datos, cambios en registro) y protección de configuración mediante `suite_config.dat`.
* **⚡ Auto-Flow Express 2.0:** Mantenimiento "Zero-Click" mejorado que ejecuta limpieza profunda de Bloatware, borrado de temporales e instalación de la suite esencial en tiempo récord.
* **🌐 Gestión de Drivers & Updates:** Búsqueda e instalación de controladores certificados mediante servidores de Microsoft Update e integración de módulos profesionales de parcheo.
* **🚀 Backup Multihilo:** Uso de **Robocopy con 16 hilos de ejecución** para respaldar perfiles de usuario (Escritorio, Documentos, Fotos, etc.) de manera ultra-rápida.
* **💻 Interfaz Adaptativa:** Sistema de menús dinámicos con opción de vista Horizontal (compacta) o Vertical (detallada) mediante la tecla `V`.
* **🎮 Sysinternals Kit integrado:** 11 herramientas profesionales (Process Explorer, Autoruns, ProcMon, TCPView, RAMMap, etc.)

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

## 🛠️ Especificaciones Técnicas

* **Lenguaje:** PowerShell 5.1 / Core (con auto-elevación a Administrador).
* **Compilación:** Versión 5.5 optimizada para estabilidad.
* **Trazabilidad:** Generación automática de **Logs de sesión** con rotación automática (>10 MB).
* **Seguridad:** Lógica de "Freno de Mano" (Tecla `X` para abortar) y validación de integridad.
* **Exclusiones:** Drivers de monitoreo (CPU-Z, HWMonitor, GPU-Z, MSI Afterburner) excluidos de limpieza.

---

## 🚀 Cómo usarla

1. **Descarga:** Haz clic en el botón verde de arriba o ve a **[Releases](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases)**.
2. **Ejecución:** Haz clic derecho y selecciona **Ejecutar como administrador**. Es vital para modificar registros y gestionar drivers.
3. **Clave Maestra:** La primera vez, utiliza la clave por defecto (`ADMIN2026`) y cámbiala en el menú de configuración.
4. **Navegación:**
   - Tecla `V`: Cambia el estilo visual del menú.
   - Tecla `X`: Regresa al menú anterior o cancela un proceso.
   - Tecla `T`: Acceso directo a Escritorio Remoto.

---

## ❓ Preguntas Frecuentes (FAQ)

**1. ¿Por qué el .EXE tiene alertas en antivirus?** ⚠️
El código en PowerShell (.ps1) es transparente. Las alertas ocurren porque las herramientas de conversión (ps2exe) empaquetan el script de una forma que algunos antivirus detectan como "sospechosa" al no tener una firma digital de pago. Es un **falso positivo**.

**2. ¿Es seguro el proceso de optimización?** 🛡️
Totalmente. La suite utiliza comandos nativos de Windows (SFC, DISM, Optimize-Volume) para asegurar que la integridad del sistema nunca se vea comprometida.

**3. ¿Por qué Spotify, WhatsApp o Discord no se instalan?** 
Estas aplicaciones **no permiten instalación en modo administrador** por decisión de sus desarrolladores. La suite detecta el fallo y muestra el enlace oficial de descarga.

**4. ¿Cómo puedo apoyar?** ⭐
- **Danos una Estrella:** Haz clic en la ⭐ arriba a la derecha en GitHub.
- **Feedback:** Si encuentras un error, abre un "Issue" para corregirlo.

---

## 👨‍💻 Desarrollador

**Luis Fernando Garcia Enciso**
*Especialista en Soporte TI y Automatización.*

---

## 📜 Licencia

Este proyecto cuenta con una **Licencia MIT**. Uso profesional, libre y transparente.
