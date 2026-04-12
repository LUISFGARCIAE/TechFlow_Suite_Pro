📘 Guía de Usuario y Referencia Técnica: TechFlow Suite Pro v5.0
Versión: 5.0 (Abril 2026)
Desarrollador: Luis Fernando García Enciso
Plataforma: Windows 10 / Windows 11 (PowerShell 5.1+)

Índice
Introducción

Requisitos y Preparación

Inicio y Primeros Pasos

Menú Principal (Opciones Globales)

A – Backup Total

B – Restore Total

C – Gestión de Drivers Pro

D – Purga y Formateo

E – Optimizador de Temporales

F – WinUtil de Chris Titus

G – MassGrave Activador

H – Gestión de Paquetes Pro

I – Kit Post Formato (200+ apps)

J – Gestión de Usuarios

K – Soporte Técnico Pro

L – Bypass Windows 11

M – Red y Reparación

N – Mantenimiento de Discos

O – Monitor en Vivo

P – Control de Windows Defender

Q – Auto‑Flow Express

Configuración y Personalización

Vista Horizontal / Vertical

Cambiar Clave Maestra

Arquitectura Interna y Mecanismos de Seguridad

Registro de Logs y Archivos Generados

Solución de Problemas Comunes

Notas para Desarrolladores y Personalización

1. Introducción
TechFlow Suite Pro es una herramienta todo‑en‑uno para técnicos y administradores de sistemas Windows. Automatiza tareas repetitivas de mantenimiento, despliegue de software, respaldo/restauración de perfiles, optimización del sistema y recuperación, todo desde una única consola con interfaz amigable y altos estándares de seguridad.

Principales capacidades:

Backup/Restore selectivo de carpetas de usuario (Desktop, Documents, Pictures, etc.)

Instalación masiva de 200+ aplicaciones usando Winget + Chocolatey (failover automático)

Gestión integral de controladores (exportación, reinstalación, búsqueda en Windows Update)

Limpieza profunda de archivos temporales y bloatware de fábrica

Monitor de sistema en tiempo real (CPU, RAM, procesos)

Herramientas de red, diagnóstico de discos, salud de batería y mucho más

2. Requisitos y Preparación
Requisito	Detalle
Sistema operativo	Windows 10 (1809+) o Windows 11
PowerShell	Versión 5.1 o superior (incluida por defecto)
Permisos	Se requiere Administrador para la mayoría de funciones. El script se auto‑elevará si no lo tienes.
Conexión a Internet	Necesaria para instalar aplicaciones, descargar scripts remotos y actualizar controladores.
Ejecución de scripts	Debes permitir la ejecución: Set-ExecutionPolicy Bypass -Scope Process o cambiar la política a RemoteSigned.
Antes de empezar:

Cierra cualquier programa que pueda interferir (antivirus, Office, etc.).

Si vas a hacer backup/restore, asegura espacio suficiente en el destino.

La clave maestra por defecto es ADMIN2026. Se recomienda cambiarla la primera vez que ejecutes la suite (opción S).

3. Inicio y Primeros Pasos
Descarga el script TECHFLOW_SUITE_1.ps1 o el ejecutable compilado (.exe).

Ejecuta como Administrador (clic derecho → “Ejecutar como administrador”).

Si se abre la ventana azul de PowerShell, espera a que aparezca el menú principal.

Verás un título con el nombre de la suite y una serie de opciones en dos columnas (modo horizontal por defecto).

Para navegar, simplemente escribe la letra de la opción y pulsa Enter.

💡 Consejo: Puedes alternar entre vista horizontal y vertical pulsando V en cualquier momento.

4. Menú Principal (Opciones Globales)
A continuación se detalla cada función. Las letras corresponden a las que ves en pantalla.

A – Backup Total
Realiza copia de seguridad de las carpetas de usuario (Escritorio, Documentos, Imágenes, Videos, Música, Descargas, Favoritos, Contactos).

Subopciones:

A – Solo perfil actual (el usuario que ejecuta la suite)

B – Todos los perfiles locales (cada carpeta dentro de C:\Users)

C – Exportar inventario (lista de programas instalados + drivers) sin copiar archivos

Flujo:

Elige el tipo de backup.

Introduce la ruta de destino (puedes dejar vacío para usar C:\Backups).

El script calcula el tamaño aproximado y comprueba espacio libre.

Se genera una carpeta Backup_XX dentro del destino.

Para la opción C se guardan dos elementos:

InstalledApps_YYYYMMDD_HHMMSS.txt (lista de paquetes)

Carpeta Drivers con todos los controladores exportados (mediante Export-WindowsDriver).

Recomendación: Usa un disco externo o una unidad de red para no saturar el disco del sistema.

B – Restore Total
Restaura backups previamente generados con la opción A.

Métodos disponibles:

Opción	Descripción
A	Busca automáticamente en C:\Backups y en cualquier unidad lógica (USB, discos internos) carpetas con nombre Backup_*. Muestra un listado numerado para elegir.
B	Permite introducir manualmente la ruta completa (útil si el backup está en una ubicación no estándar). Además, detecta automáticamente backups en unidades USB conectadas.
C	Restaura el backup más reciente de todos los encontrados (ideal para automatizar restauraciones rápidas).
Proceso de restauración:

Tras seleccionar el backup, muestra los nombres de los perfiles contenidos.

Pregunta qué perfil restaurar (ENTER = todos, o escribe el nombre exacto).

Opcionalmente puedes cambiar la raíz de destino (por defecto C:\Users).

Confirmación crítica: Si la carpeta destino ya existe, se pide un PIN de seguridad y la palabra APLICAR para sobrescribir.

⚠️ Atención: La restauración usa robocopy con opción /E (copia todo, incluyendo subcarpetas vacías). Los archivos existentes con el mismo nombre se sobrescribirán.

C – Gestión de Drivers Pro
Submenú especializado en controladores de hardware.

Opción	Función
A – Exportar drivers	Guarda una copia de todos los controladores instalados en Drivers_NOMBREPC dentro del directorio del script. Útil para reinstalación sin internet.
B – Reinstalar drivers	Busca la carpeta generada por A y usa pnputil para agregar todos los .inf encontrados.
C – Buscar en servidores oficiales	Utiliza el módulo PSWindowsUpdate para conectar con Windows Update, filtrar solo la categoría Drivers e instalarlos automáticamente. Ignora parches de seguridad.
D – Ver hardware sin driver	Muestra una ventana gráfica (Out‑GridView) con todos los dispositivos que tienen un error en el Administrador de dispositivos. Ideal para identificar hardware problemático.
Requisito para C: Se necesita instalar el módulo PSWindowsUpdate y el proveedor NuGet la primera vez. El script lo hace automáticamente.

D – Purga y Formateo
Subopciones:

A – Purgar perfil actual
Elimina el contenido de todas las carpetas estándar del usuario actual (Desktop, Documents, etc.).
⚠️ Peligroso: Se requiere confirmación con PIN y palabra BORRAR.
Modo demo (S) solo muestra qué se borraría sin ejecutar.

B – Formatear USB
Lista las unidades extraíbles detectadas y pide la letra de unidad. Ejecuta Format-Volume -FileSystem NTFS -Force.
Útil para preparar memorias de instalación.

E – Optimizador de Temporales
Limpia archivos temporales de tres niveles:

A – Limpieza profunda (temp de usuario + C:\Windows\Temp)

B – Solo temporales del usuario actual ($env:TEMP)

C – Solo temporales del sistema (C:\Windows\Temp)

Modo Demo: Antes de ejecutar, pregunta si solo quieres ver los archivos que se eliminarían (S) o realmente borrarlos (N).
Los elementos en uso o con permisos insuficientes se omiten y se registran en el log.

F – WinUtil de Chris Titus
Descarga y ejecuta el famoso script de optimización de Windows de Chris Titus Tech (https://christitus.com/win).

Proceso:

Solicita confirmación (script remoto).

Comprueba conexión a Internet.

Descarga el script a la carpeta temporal.

Muestra la ruta y el hash SHA256.

Pregunta si deseas ejecutarlo ahora.

ℹ️ Este script permite desactivar telemetría, quitar bloatware avanzado, ajustar servicios, etc. No es parte del código original de TechFlow, se integra como utilidad externa.

G – MassGrave Activador
Igual que el anterior, pero descarga el script de activación Microsoft (https://get.activated.win). Incluye métodos HWID, KMS38 y Online KMS para Windows y Office.

Precaución: Los activadores pueden ser detectados como malware por algunos antivirus. Úselo bajo su responsabilidad.

H – Gestión de Paquetes Pro (Winget/Chocolatey/Scoop)
Menú central para la administración de software mediante los tres gestores más populares de Windows.

Opción	Descripción
A – Winget: actualizar todo	Ejecuta winget upgrade --all
B – Winget: listar disponibles	Muestra actualizaciones pendientes
C – Winget: reparar cliente	Descarga e instala el último .msixbundle del repositorio oficial de GitHub
D – Choco: instalar Chocolatey	Instala el gestor Chocolatey desde cero (requiere admin)
E – Choco: actualizar todo	choco upgrade all -y
F – Choco: buscar paquete	Permite buscar una aplicación en el repositorio de Chocolatey
G – Instalar por nombre	Intenta instalar cualquier aplicación escribiendo su ID (ej: Google.Chrome). Usa el motor híbrido Winget+Choco.
H – Instalar Winget (App Installer)	Fuerza la instalación/reparación del cliente Winget desde GitHub.
I – Scoop: instalar/configurar	Ofrece 4 métodos para instalar Scoop (oficial, manual, binario, vía Choco). Luego actualiza los buckets.
J – Scoop: buscar/instalar app	Busca una app en Scoop y pregunta si instalarla.
K – Scoop: listar actualizaciones	Muestra el estado de las aplicaciones instaladas con Scoop.
L – Multi‑search	Busca la misma palabra clave en Winget, Scoop y Chocolatey simultáneamente.
Motor Híbrido (Invoke-SmartInstall):
Para cualquier instalación individual, primero intenta Winget. Si falla, busca en un diccionario interno que mapea IDs de Winget a nombres cortos de Chocolatey y reintenta. Si aún falla, hace un segundo intento con Winget. Esto garantiza más del 95% de éxito.

I – Kit Post Formato (200+ apps)
El corazón de la suite para técnicos que formatean equipos con frecuencia. Permite instalar lotes de aplicaciones de forma masiva y silenciosa.

Opciones del kit:

Código	Qué hace
0	Elimina bloatware básico (Candy Crush, Netflix, TikTok, Instagram, Disney)
1	Perfil básico: Google Chrome, 7‑Zip, VLC, AnyDesk, Microsoft Teams
2	Perfil gaming: Steam, Discord, VLC, f.lux (para reducir fatiga visual)
3	Selección manual (listado completo de 200 aplicaciones paginado + buscador)
4	Actualizar todo el software ya instalado mediante winget upgrade --all
Selección manual (opción 3):

Navegación por páginas de 40 apps (N = siguiente, P = anterior, G = ir a página).

Buscador por nombre (B): escribe parte del nombre y filtra la lista.

Una vez visualizadas las apps, puedes introducir números separados por comas o rangos, por ejemplo:
1,5,10-15,20
Esto instalará las apps con IDs 1,5,10,11,12,13,14,15,20.

El script mostrará un resumen final de éxitos y fallos.

Nota: Las instalaciones se realizan en segundo plano sin ventanas emergentes. Si una app requiere interacción manual (casos raros), se notificará en el log.

J – Gestión de Usuarios
Herramientas de administración de cuentas locales (no requiere Active Directory).

Opción	Acción
A	Listar todos los usuarios locales
B	Crear un nuevo usuario local y agregarlo al grupo Administradores
C	Eliminar un usuario (no permite borrar el usuario actual)
D	Activar la cuenta oculta Administrator (según idioma del sistema)
E	Desactivar la cuenta Administrator
F	Cambiar la contraseña de un usuario existente
Confirmación: Las opciones destructivas (C, D, E, F) requieren PIN + palabra APLICAR.

K – Soporte Técnico Pro
Conjunto de utilidades de diagnóstico y reparación.

Opción	Función
A – Salud de disco	Muestra el estado de salud de los discos físicos (Get-PhysicalDisk) y ejecuta chkdsk C: en modo solo lectura.
B – Reparar sistema	Ejecuta sfc /scannow y dism /online /cleanup-image /restorehealth secuencialmente.
C – Clave BIOS	Recupera la clave de producto OEM almacenada en la BIOS (si existe).
D – Sincronizar hora	Reinicia el servicio de tiempo de Windows y fuerza una resincronización con w32tm /resync.
F – Salud de batería	Muestra nivel de carga actual y, si es posible, el porcentaje de desgaste (capacidad actual vs diseño). Genera un reporte HTML con powercfg /batteryreport y lo guarda en el escritorio (o en TEMP). Pregunta si abrirlo.
G – Informe técnico completo	Recopila y muestra: modelo de equipo, número de serie, procesador (núcleos), RAM instalada y máxima soportada, placa base, tarjetas gráficas (VRAM), discos (capacidad, salud, tipo de bus), edición y versión de Windows. Ofrece guardar como archivo de texto.
L – Bypass Windows 11
Permite eludir los requisitos de hardware y red durante la instalación de Windows 11.

Opción	Efecto
A – Bypass hardware	Crea las claves de registro LabConfig con BypassTPMCheck=1, BypassSecureBootCheck=1, BypassRAMCheck=1. Útil para instalar Windows 11 en equipos no compatibles.
B – Bypass Internet	Ejecuta C:\Windows\System32\oobe\bypassnro.cmd (archivo oficial de Microsoft). Permite crear una cuenta local sin conexión durante la configuración inicial.
C – Ver estado actual	Muestra si las claves de bypass están presentes en el registro.
D – Revertir bypass hardware	Elimina las claves LabConfig creadas.
Nota: Estas modificaciones solo son efectivas durante la instalación (modo OOBE) o si ejecutas el script antes de la primera configuración. No afectan a un sistema ya instalado.

M – Red y Reparación
Utilidades de red agrupadas.

Opción	Comando / Acción
A – Resetear red	netsh winsock reset, netsh int ip reset, ipconfig /flushdns. Requiere reinicio después.
B – Reparar Windows Update	Detiene servicios wuauserv y bits, borra C:\Windows\SoftwareDistribution y reinicia los servicios. Modo demo disponible.
C – Ver IP	Muestra las direcciones IPv4 de todas las interfaces (excepto loopback).
D – Ping monitor	Realiza ping continuo a una IP/dominio (por defecto 8.8.8.8) hasta que se pulse cualquier tecla.
E – Ver claves WiFi	Extrae y muestra todas las redes WiFi guardadas junto con sus contraseñas en texto claro.
F – Traza de ruta	Ejecuta tracert a un dominio introducido por el usuario.
G – Test velocidad	Abre el navegador predeterminado en la página fast.com (test de velocidad de Netflix).
N – Mantenimiento de Discos
Opción	Función
A – Desfragmentar HDD	Ejecuta defrag C: /O (optimización para discos mecánicos).
B – Optimizar SSD	Ejecuta Optimize-Volume -DriveLetter C -ReTrim (envía comando TRIM).
C – Limpieza DISM	dism /online /Cleanup-Image /StartComponentCleanup (reduce el tamaño de la caché de componentes).
Requisito: Todas requieren permisos de administrador y confirmación crítica.

O – Monitor en Vivo (Pro)
Pantalla de monitoreo de sistema actualizable en tiempo real.

Muestra:

Porcentaje de uso de CPU (promedio de todos los núcleos)

RAM libre y total (en GB)

Top 10 procesos por consumo de RAM

Top 10 procesos por tiempo de CPU acumulado

Comandos interactivos:

Tecla	Acción
K	Matar un proceso (pide ID o nombre)
R	Refrescar manualmente la pantalla
T	Cambiar el intervalo de refresco automático (en milisegundos, ej: 1500)
Q o X	Salir del monitor y volver al menú principal
El refresco automático se ejecuta cada cierto tiempo (valor por defecto 1500 ms). Si pulsas ENTER sin tecla, simplemente se refresca la pantalla.

P – Control de Windows Defender
Permite activar o desactivar la protección en tiempo real de Microsoft Defender.

Opción	Efecto
A – Activar	Establece DisableAntiSpyware=0 (elimina la desactivación).
B – Desactivar	Crea las claves DisableAntiSpyware=1 y DisableRealtimeMonitoring=1.
Nota importante: La desactivación requiere confirmación con PIN + palabra APLICAR y necesita reinicio para surtir efecto completo. Defender se reactivará automáticamente tras ciertas actualizaciones de Windows.

Q – Auto‑Flow Express
Flujo automatizado de mantenimiento exprés, ideal para equipos recién formateados o con poco tiempo.

Pasos que ejecuta:

Eliminación de bloatware (mismos patrones que la opción 0 del Kit Post Formato)

Limpieza de temporales ($env:TEMP y C:\Windows\Temp)

Instalación de la tríada básica: Google Chrome, 7‑Zip, VLC Player

Interrupción: Durante todo el proceso, el script escucha la tecla X. Si la pulsas, aborta inmediatamente la operación y vuelve al menú.

Confirmación inicial: Antes de comenzar, debes pulsar ENTER (no X). Es útil para presentaciones o demostraciones.

5. Configuración y Personalización
Vista Horizontal / Vertical
Pulsa la tecla V en cualquier momento para alternar entre:

Modo horizontal (predeterminado): las opciones se muestran en varias columnas, aprovechando el ancho de la consola.

Modo vertical: cada opción en una línea, útil en ventanas pequeñas o para leer con facilidad.

Cambiar Clave Maestra
La clave maestra protege operaciones sensibles y se almacena en el archivo suite_config.dat (en el mismo directorio del script). Por defecto es ADMIN2026.

Para cambiarla:

En el menú principal, pulsa S.

Introduce la nueva clave (no se muestra en pantalla por seguridad).

Repite la nueva clave para confirmar.

Confirma la operación crítica con PIN y la palabra APLICAR.

A partir de ese momento, todas las confirmaciones usarán la nueva clave.

🔐 Seguridad: La clave se guarda en texto plano. Si el archivo se pierde, puedes volver a crearlo manualmente con una sola línea de texto.

6. Arquitectura Interna y Mecanismos de Seguridad
Auto‑elevación
Al iniciar, el script verifica si se ejecuta como administrador. Si no, se reinicia a sí mismo con -Verb RunAs. Esto garantiza que todas las funciones críticas tengan los permisos necesarios.

Clave Maestra y PIN Dinámico
Clave maestra: Se usa para validar el cambio de clave y como capa adicional en algunas funciones (aunque la mayoría de las críticas usan PIN).

PIN aleatorio de 4 dígitos: Para operaciones de alto riesgo (formateo, purga de perfiles, sobrescritura de backups, desactivación de Defender, etc.) se genera un número aleatorio entre 1000 y 9999. El usuario debe teclearlo exactamente. Esto evita ejecuciones accidentales o por error de dedo.

Palabra de Confirmación
Junto al PIN, se pide escribir una palabra concreta en mayúsculas (por ejemplo APLICAR, BORRAR, FORMAT). Esto añade una segunda capa cognitiva que reduce drásticamente los errores humanos.

Interrupción Global (Tecla X)
En la mayoría de los bucles (instalaciones, limpiezas, monitores), pulsar la tecla X (mayúscula o minúscula) aborta la operación de forma controlada. No es necesario cerrar la ventana ni usar Ctrl+C.

Logs Detallados
Cada ejecución genera un archivo de log en la misma carpeta del script con el formato techflow_suite_log_YYYYMMDD_HHMMSS.log. Allí se registran:

Inicio y fin de cada función.

Comandos ejecutados y sus códigos de salida.

Errores capturados con try/catch.

Confirmaciones exitosas o fallidas.

Rutas de backups, instalaciones, etc.

Esto es invaluable para auditoría y depuración.

Preferencias Persistentes
El archivo suite_prefs.json guarda la última opción elegida en el Kit Post Formato (lastKitOption). Al volver a entrar, si pulsas ENTER directamente, se repetirá esa misma selección, ahorrando tiempo.

7. Registro de Logs y Archivos Generados
Archivo	Ubicación	Propósito
techflow_suite_log_*.log	$PSScriptRoot	Registro detallado de la sesión actual
suite_config.dat	$PSScriptRoot	Clave maestra en texto plano
suite_prefs.json	$PSScriptRoot	Preferencias de usuario (última opción del kit)
Backup_XX/	Ruta elegida por el usuario	Contiene los archivos respaldados (estructura de carpetas)
Drivers_NOMBREPC/	$PSScriptRoot	Backup de controladores (opción C-A)
BatteryReport_*.html	Escritorio o TEMP	Reporte generado por powercfg /batteryreport
TechFlow_SystemInfo_*.txt	$PSScriptRoot	Informe técnico completo guardado manualmente
8. Solución de Problemas Comunes
Problema	Posible causa	Solución
El script no se ejecuta, error de política	ExecutionPolicy restringida	Abre PowerShell como admin y ejecuta Set-ExecutionPolicy RemoteSigned -Force
Las instalaciones fallan constantemente	Winget desactualizado o ausente	Usa opción H del menú de paquetes para reinstalar Winget
No se encuentra el comando winget	Windows 10 versión anterior	Actualiza a Windows 10 1809+ o instala manualmente el App Installer desde la Microsoft Store
El backup no incluye ciertas carpetas	Las carpetas no están en la lista $USER_FOLDER_NAMES	Edita el script y añade los nombres de carpeta que desees
El restore sobrescribe archivos sin preguntar	Es el comportamiento por defecto de robocopy	Antes de restaurar, mueve o renombra la carpeta destino si quieres conservar datos
No se ven las opciones completas en la consola	Tamaño de ventana pequeño	Amplía la ventana o cambia a modo vertical con V
El script pide PIN aunque no hayas hecho nada	Alguna operación crítica requiere confirmación	Revisa el mensaje; normalmente es porque elegiste una opción como B de restore y existía perfil destino
No se puede activar/desactivar Defender	Políticas de grupo de empresa	Necesitas ser administrador local y que no haya GPO que prevenga el cambio
9. Notas para Desarrolladores y Personalización
Si deseas modificar o extender TechFlow Suite Pro:

Añadir más aplicaciones al Kit Post Formato:
Edita el hashtable $apps dentro de la función Invoke-KitPostFormat. Cada entrada debe tener la forma:
"numero" = @{Name="Nombre visible"; ID="WingetId"}
El ID debe ser el que usa winget show. Si necesitas mapeo a Chocolatey, añade una entrada en $chocoMapping dentro de Invoke-SmartInstall.

Cambiar las carpetas de backup:
Modifica la variable $USER_FOLDER_NAMES al inicio del script.

Personalizar colores:
Las variables $COLOR_PRIMARY, $COLOR_ALERT, $COLOR_DANGER, $COLOR_MENU aceptan cualquier nombre de color de consola estándar (ej: DarkCyan, Magenta).

Añadir nuevas herramientas remotas:
Sigue el patrón de las opciones F y G: usar Confirm-RemoteScript, Download-RemoteScript, mostrar hash y luego ejecutar condicionalmente.

Compilar a EXE:
Se recomienda ps2exe con los parámetros:
.\ps2exe.ps1 -inputFile TECHFLOW_SUITE_1.ps1 -outputFile TechFlowSuite.exe -requireAdmin -noConsole
(o -noConsole para que no muestre ventana negra adicional).

Ejecución sin ventana de PowerShell:
Si usas el script .ps1 directamente, puedes crear un acceso directo con el destino:
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "ruta\TECHFLOW_SUITE_1.ps1"

Desarrollador: Luis Fernando García Enciso
Versión del documento: 5.0 (Abril 2026)
Licencia: MIT – Libre uso y modificación, bajo responsabilidad del usuario.

“Automatiza hoy, administra mañana.”
