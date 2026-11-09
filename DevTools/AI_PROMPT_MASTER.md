# TECHFLOW SUITE PRO v6.0 - MASTER CONTEXT & SYSTEM DIRECTIVES

## 1. RESUMEN DEL PROYECTO
- **Nombre**: TechFlow Suite Pro v6.0 (Edición Modular PowerShell)
- **Autor / Arquitectura**: Luis Fernando García Enciso (Soluciones IT)
- **Ruta Oficial de Trabajo**: `C:\TechFlow_Suite_Pro_v6`
- **Lanzador**: `lanzador.bat` (Auto-elevado con UAC, desacoplado de CMD con start /wait)
- **Orquestador Principal**: `TechFlow.ps1`
- **Submódulos**: `Modules\Core.ps1`, `Modules\AppsKit.ps1`, `Modules\BackupRestore.ps1`, `Modules\Maintenance.ps1`, `Modules\HardwareTools.ps1`, `Modules\MediaDownloader.ps1`

## 2. REGLAS ESTRICTAS PARA ASISTENTES IA (GEMINI, CLAUDE, GPT)
1. **REGLA DE PARIDAD 1:1 (PROHIBIDO TRUNCAR O RESUMIR)**:
   - Jamás sustituir bloques funcionales por `# [Aquí va el código...]` o versiones simplificadas.
   - Toda propuesta de actualización o corrección debe entregarse con el código fuente completo y listo para producción.
2. **AISLAMIENTO DE PROYECTO (FIREWALL PYTHON)**:
   - La carpeta `C:\TechFlowSuite` corresponde a desarrollo de Python.
   - **NUNCA** escribir, modificar o mover archivos hacia `C:\TechFlowSuite`. Toda la suite de PowerShell vive exclusivamente en `C:\TechFlow_Suite_Pro_v6`.
3. **DISEÑO DE MENÚS Y ESTÉTICA**:
   - Mantener el banner ASCII Cyan intacto con la función `Show-MainTitle`.
   - Los submenús deben usar diseño vertical con iconos, margen a 3 espacios y sin plecas horizontales amontonadas.
4. **BLINDAJE DE PROCESOS**:
   - `Ctrl + C` está interceptado a nivel consola para capturar `PipelineStoppedException` y regresar al menú principal sin que `cmd.exe` o PowerShell cierren la ventana.
5. **ARQUITECTURA DE MÓDULOS**:
   - `Core.ps1`: Primitivas del sistema (`Read-MenuOption`, `Pause-Enter`, `Require-Admin`, `Confirm-Critical`, `Format-Bytes`, logs y diagnóstico de arranque `Invoke-StartupChecks`).
   - `AppsKit.ps1`: Catálogo íntegro de 440 apps en 22 categorías, motor de búsqueda, 10 perfiles rápidos e instalador dual Winget/Chocolatey.
   - `BackupRestore.ps1`: Respaldo multihilo con Robocopy, selector dinámico de unidades fijas/extraíbles, empaquetador ZIP de drivers y panel de Duplicati.
   - `Maintenance.ps1`: Purgas temporales, Auto-Flow Express, MassGrave con bypass DNS-over-HTTPS, Defender y catálogo autónomo `$Global:KnownApps`.
   - `HardwareTools.ps1`: Soporte técnico PRO (batería HTML, temperaturas, clave BIOS OEM, modo Dios), Sysinternals Kit (11 herramientas), DiskPart simplificado, monitor en vivo y red (`[M]`).
   - `MediaDownloader.ps1`: Motor `yt-dlp` interactivo con barras de progreso vivas, recortes con FFmpeg, selector de calidad e historial.
