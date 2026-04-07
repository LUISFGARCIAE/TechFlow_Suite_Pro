# 🚀 TechFlow Suite Pro v4.0

[![Descargar EXE](https://img.shields.io/badge/DESCARGAR-EJECUTABLE_PRO-green?style=for-the-badge&logo=windows)](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases/latest)

Suite profesional de herramientas IT para optimización de sistemas, backups, gestión de drivers y automatización de tareas en Windows mediante PowerShell.

---

## 🧐 ¿Qué es TechFlow Suite Pro?
Es una solución integral de automatización diseñada específicamente para **especialistas en soporte TI**. Optimiza el flujo de trabajo desde el despliegue inicial (Post-Format) hasta el mantenimiento avanzado y rescate de sistemas Windows. Desarrollada en PowerShell y compilada como un ejecutable (.exe) de alto rendimiento para garantizar portabilidad y seguridad.

---

## ✨ Características Principales (Update v4.0)
* 📦 **Motor de Instalación Híbrido:** Instalación masiva (100+ Apps) alternando automáticamente entre **Winget** y **Chocolatey** para evitar fallos de descarga.
* 🌐 **Gestión de Drivers Pro (NUEVO):** Ahora permite la búsqueda e instalación de controladores directamente desde los **servidores oficiales de Microsoft Update**, garantizando drivers certificados y actualizados.
* ⚡ **Auto-Flow Express (NUEVO):** Un perfil de mantenimiento de un solo clic que ejecuta limpieza de Bloatware, borrado de temporales e instalación de apps base de forma totalmente desatendida.
* 🛠️ **Herramientas de Soporte Pro:** Bypass de Windows 11 (TPM 2.0/OOBE), gestión masiva de drivers local (.inf) y recuperación de claves BIOS (OEM).
* 🛡️ **Seguridad y Backup:** Backups ultra-rápidos con **Robocopy** (multihilo) y protección mediante PIN aleatorio para operaciones críticas.
* 💻 **Interfaz Dinámica:** Menú visual optimizado con opción de alternar entre vista Horizontal (compacta) o Vertical (detallada).
* 🚀 **Portable:** Sin instalaciones; corre directamente desde tu USB de herramientas.

---

## 🔄 Diferencias: Kit Post-Format vs Auto-Flow
Para maximizar la eficiencia en el taller, la suite divide la instalación en dos metodologías:

| Característica | 🛠️ Kit Post-Format (Opción I) | ⚡ Auto-Flow Express (Opción Q) |
| :--- | :--- | :--- |
| **Enfoque** | Personalización total. | Velocidad extrema "Zero-Click". |
| **Selección** | Manual (1 a 100 apps) o por perfiles. | Automático (Chrome, 7-Zip, VLC). |
| **Mantenimiento** | Solo instalación de software. | Limpieza de Bloatware + Temporales + Apps. |
| **Intervención** | Requiere interacción del técnico. | Presiona [ENTER] y deja que el script trabaje solo. |
| **Uso Ideal** | Equipos de oficina o gaming específicos. | Alistamiento rápido de equipos nuevos/formateados. |

---

## 🛠️ Especificaciones Técnicas
* **Lenguaje:** PowerShell Core / Windows PowerShell.
* **Módulos:** Integración con `PSWindowsUpdate` para gestión de parches oficiales.
* **Compilación:** Versión 4.0 optimizada con `ps2exe`.
* **Seguridad:** Lógica de "Freno de Mano" integrada (presiona `X` para abortar cualquier proceso en curso).
* **Versión:** 4.0.0.0 "Official Stable Release".

---

## 🚀 Cómo usarla
1. Haz clic en el botón de **Descargar** arriba o ve a la sección de **[Releases](https://github.com/LUISFGARCIAE/TechFlow_Suite_Pro/releases)**.
2. Descarga el archivo `TechFlow_Suite_Pro.exe`.
3. **Importante:** Haz clic derecho y selecciona **Ejecutar como administrador** para asegurar acceso total al registro y servicios del sistema.
4. **Navegación:** - Usa la tecla `V` para cambiar el estilo del menú.
   - Usa la tecla `X` en cualquier submenú para regresar.
   - En **Auto-Flow**, presiona `ENTER` para iniciar o `X` para cancelar antes de empezar.

❓ Preguntas Frecuentes (FAQ)
1. ¿Por qué el archivo .EXE tiene alertas en VirusTotal pero el .PS1 no? ⚠️
Es la duda más común. El código base en PowerShell (.ps1) es 100% LIMPIO. Sin embargo, al convertirlo a ejecutable (.exe) para que sea más fácil de usar, los antivirus se ponen "nerviosos" por dos razones técnicas:

El Empaquetado: Herramientas como PS2EXE envuelven el script en un ejecutable genérico. Muchos virus reales usan esta misma técnica para esconderse, por lo que los antivirus marcan el archivo como "sospechoso" por precaución (Falso Positivo).

Firma Digital: Como es un proyecto independiente y no tiene una firma digital de pago (certificados EV que cuestan cientos de dólares), Windows y otros motores no reconocen al autor y lanzan advertencias preventivas.

💡 Consejo de confianza: Si tienes dudas, no uses el .exe. Descarga el archivo .ps1, revísalo línea por línea y ejecútalo directamente con PowerShell. ¡Transparencia total!

2. ¿Es seguro darle permisos de Administrador? 🛡️
Sí. El script necesita privilegios de Administrador para realizar tareas críticas del sistema que un usuario normal no puede hacer:

Reparar archivos dañados con SFC y DISM.

Realizar copias de seguridad de los Drivers del sistema.

Modificar llaves del Registro para optimizar el rendimiento y la privacidad.

Gestionar instalaciones de software mediante Winget o Chocolatey.

3. ¿Qué hago si mi antivirus bloquea el script al ejecutarlo? 🛠️
Debido a que el script interactúa con funciones profundas del sistema (como el registro y servicios), algunos antivirus "heurísticos" pueden bloquearlo.

Solución: Agrega la carpeta donde tienes el script a las exclusiones de tu antivirus o desactiva temporalmente la protección en tiempo real mientras realizas el mantenimiento.

4. ¿Cómo puedo apoyar este proyecto? ⭐
Este es un proyecto hecho "de un colega para colegas" con mucho esfuerzo. Puedes ayudar de tres formas:

Dale una Estrella (Star): Haz clic en la ⭐ arriba a la derecha en este GitHub. Esto ayuda a subir la reputación del proyecto.

Reporta Errores: Si algo no funciona en tu equipo, abre un "Issue" aquí en GitHub para que pueda corregirlo en la v4.2.

Vota en VirusTotal: Si analizas el archivo, deja un voto positivo y un comentario confirmando que es seguro. ¡Ayúdanos a limpiar la fama del script!

<img width="1791" height="341" alt="image" src="https://github.com/user-attachments/assets/01265ba6-9089-42a8-8d27-cabe00968561" />

---

## 👨‍💻 Desarrollador
**Luis Fernando Garcia Enciso** *Especialista en Soporte TI y Automatización.*

---

## 📜 Licencia
Este proyecto cuenta con una **Licencia MIT**. Es de uso profesional y transparente (código fuente `.ps1` incluido en el repositorio).
