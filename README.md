# 🚀 TechFlow Suite Pro v5.0 "The Next Gen"

[![Descargar EXE](https://img.shields.io/badge/DESCARGAR-EJECUTABLE_PRO-green?style=for-the-badge&logo=windows)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases/latest)

Suite definitiva de herramientas IT para optimización de sistemas, backups de alto rendimiento y automatización avanzada en Windows mediante PowerShell.

---

## 🧐 ¿Qué es TechFlow Suite Pro?
Es una solución de automatización de nivel profesional diseñada para **especialistas en soporte TI**. La v5.0 redefine el flujo de trabajo desde el despliegue inicial (Post-Format) hasta el mantenimiento crítico. Desarrollada en PowerShell y optimizada como ejecutable para garantizar portabilidad, seguridad y una experiencia de usuario fluida.

---

## ✨ Características Principales (Update v5.0)
* 🧠 **Motor Híbrido v5:** Instalación masiva de **más de 200 aplicaciones** con lógica de redundancia inteligente: si **Winget** falla, el sistema conmuta automáticamente a **Chocolatey** (Mapeo Manual).
* 🛡️ **Seguridad Avanzada:** Implementación de **PIN dinámico aleatorio** para confirmar operaciones críticas (borrado de datos, cambios en registro) y protección de configuración mediante `suite_config.dat`.
* ⚡ **Auto-Flow Express 2.0:** Mantenimiento "Zero-Click" mejorado que ejecuta limpieza profunda de Bloatware, borrado de temporales e instalación de la suite esencial en tiempo récord.
* 🌐 **Gestión de Drivers & Updates:** Búsqueda e instalación de controladores certificados mediante servidores de Microsoft Update e integración de módulos profesionales de parcheo.
* 🚀 **Backup Multihilo:** Uso de **Robocopy con 16 hilos de ejecución** para respaldar perfiles de usuario (Escritorio, Documentos, Fotos, etc.) de manera ultra-rápida.
* 💻 **Interfaz Adaptativa:** Sistema de menús dinámicos con opción de vista Horizontal (compacta) o Vertical (detallada) mediante la tecla `V`.

---

## 🔄 Metodologías: Kit Post-Format vs Auto-Flow
Diseñado para adaptarse a la carga de trabajo del taller:

| Característica | 🛠️ Kit Post-Format (Opción I) | ⚡ Auto-Flow Express (Opción Q) |
| :--- | :--- | :--- |
| **Enfoque** | Personalización total y granular. | Velocidad extrema para taller. |
| **Catálogo** | **200+ Apps** (Dev, Gaming, Office). | Apps base (Chrome, 7-Zip, VLC, AnyDesk). |
| **Intervención** | Selección manual de paquetes. | Totalmente desatendido. |
| **Seguridad** | Confirmación estándar. | Ejecución rápida con PIN de seguridad. |
| **Uso Ideal** | Estaciones de trabajo y PCs Gaming. | Alistamiento masivo de equipos nuevos. |

---

## 🛠️ Especificaciones Técnicas
* **Lenguaje:** PowerShell 5.1 / Core (con auto-elevación a Administrador).
* **Compilación:** Versión 5.0.0.0 optimizada para estabilidad.
* **Trazabilidad:** Generación automática de **Logs de sesión** (`techflow_suite_log_*.log`).
* **Seguridad:** Lógica de "Freno de Mano" (Tecla `X` para abortar) y validación de integridad.

---

## 🚀 Cómo usarla
1. **Descarga:** Haz clic en el botón verde de arriba o ve a **[Releases](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases)**.
2. **Ejecución:** Haz clic derecho y selecciona **Ejecutar como administrador**. Es vital para modificar registros y gestionar drivers.
3. **Clave Maestra:** La primera vez, utiliza la clave por defecto (`ADMIN2026`) y cámbiala en el menú de configuración (Opción `S`).
4. **Navegación:**
   - Tecla `V`: Cambia el estilo visual del menú.
   - Tecla `X`: Regresa al menú anterior o cancela un proceso.

---

## ❓ Preguntas Frecuentes (FAQ)
**1. ¿Por qué el .EXE tiene alertas en antivirus?** ⚠️
El código en PowerShell (.ps1) es transparente. Las alertas ocurren porque las herramientas de conversión (ps2exe) empaquetan el script de una forma que algunos antivirus detectan como "sospechosa" al no tener una firma digital de pago. Es un **falso positivo**.

**2. ¿Es seguro el proceso de optimización?** 🛡️
Totalmente. La suite utiliza comandos nativos de Windows (SFC, DISM, Optimize-Volume) para asegurar que la integridad del sistema nunca se vea comprometida.

**3. ¿Cómo puedo apoyar?** ⭐
- **Danos una Estrella:** Haz clic en la ⭐ arriba a la derecha en GitHub.
- **Feedback:** Si encuentras un error, abre un "Issue" para corregirlo en la v5.1.

---

## 👨‍💻 Desarrollador
**Luis Fernando Garcia Enciso**
*Especialista en Soporte TI y Automatización.*

---

## 📜 Licencia
Este proyecto cuenta con una **Licencia MIT**. Uso profesional, libre y transparente.
