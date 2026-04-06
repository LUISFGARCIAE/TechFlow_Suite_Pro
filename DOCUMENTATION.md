
# 📘 Especificaciones Técnicas: TechFlow Suite Pro v4.0

---

## 1. Introducción y Propósito

**TechFlow Suite Pro** es un framework de automatización modular desarrollado en **PowerShell**. Su objetivo principal es estandarizar el despliegue de software y el mantenimiento preventivo/correctivo en entornos Windows, reduciendo drásticamente el margen de error humano mediante procesos desatendidos y optimizados.

---

## 2. Arquitectura de Motores (Core)

### ⚡ Motor de Instalación Híbrido (`Invoke-SmartInstall`)
El sistema garantiza una alta tasa de éxito mediante una lógica de **Redundancia (Failover)**:

* **Prioridad 1 (Winget):** Utiliza el repositorio oficial de Microsoft para realizar instalaciones silenciosas, seguras y verificadas.
* **Prioridad 2 (Chocolatey):** En caso de detectar errores en el hash o indisponibilidad de Winget, el script conmuta automáticamente a Chocolatey, extrayendo el nombre corto del paquete para reintentar la operación de forma transparente.

### 🚀 Perfil Auto-Flow Express (`Invoke-AutoFlow`)
Módulo diseñado para la máxima eficiencia en el alistamiento de equipos nuevos o recién formateados (Post-Format).

* **Gestión de Buffer:** Implementa una escucha activa de teclado con una latencia de **100ms**, lo que permite una interrupción inmediata del flujo de trabajo por parte del técnico.
* **Secuencia Lógica Pro:**
    1.  **Purga de paquetes Appx:** Eliminación de Bloatware de OEM (apps preinstaladas innecesarias).
    2.  **Saneamiento:** Limpieza profunda de directorios temporales de sistema y perfiles de usuario.
    3.  **Inyección de Software:** Instalación automatizada de la terna base (Chrome, 7-Zip y VLC Player).

### 🌐 Gestión de Drivers (Microsoft Update)
A diferencia de herramientas de terceros, este módulo utiliza la API de **PSWindowsUpdate** para garantizar la integridad del sistema:

* **Búsqueda Certificada:** Se conecta directamente con los servidores de Microsoft para obtener controladores firmados y específicos para el hardware detectado.
* **Filtrado Inteligente:** Ignora parches de seguridad o actualizaciones acumulativas, centrándose exclusivamente en la categoría **Drivers** para optimizar el tiempo y el consumo de ancho de banda.

---

## 3. Seguridad y Control de Procesos

* **Validación de Identidad:** El acceso a funciones críticas está protegido por una clave maestra persistente almacenada en el archivo `suite_config.dat`.
* **PIN Dinámico:** Las operaciones destructivas (como el formateo de unidades o la purga masiva de perfiles) generan un **PIN aleatorio de 4 dígitos**. El técnico debe ingresar este código manualmente para confirmar y ejecutar la acción.
* **Interrupción Global (Tecla X):** Se ha estandarizado la tecla **X** como el "Botón de Pánico" universal, permitiendo abortar bucles de instalación, escaneo o limpieza sin necesidad de forzar el cierre de la consola.

---

## 4. Estructura de Datos y Configuración

| Variable | Propósito |
| :--- | :--- |
| `$CONFIG_FILE` | Ruta local del archivo de configuración de acceso. |
| `$USER_FOLDERS` | Array que define las rutas críticas para el motor de Backup/Restore. |
| `$Global:MenuHorizontal` | Booleano que controla el motor de renderizado de la interfaz gráfica en consola. |
| `$COLOR_DANGER` | Código de color ANSI para alertas críticas y opciones de salida. |

---

## 5. Guía de Compilación (Deployment)

Para generar el ejecutable portable oficial de la suite, siga estos lineamientos:

* **Codificación:** El archivo fuente `.ps1` debe guardarse obligatoriamente en **UTF-8 con BOM** o **ASCII** para evitar errores de sintaxis en la consola.
* **Framework de Compilación:** Se recomienda compilar con `ps2exe`, definiendo el nivel de ejecución como **HighestAvailable** para asegurar privilegios de administrador nativos desde el inicio.
* **Dependencias de Entorno:** El equipo objetivo debe tener configurada la **Execution Policy** en modo `Bypass` o `RemoteSigned` para permitir la ejecución de los módulos internos.

---

**Desarrollador:** Luis Fernando Garcia Enciso  
**Versión de Documentación:** 4.0.0 (Abril 2026)  
**Licencia:** MIT Open Source
