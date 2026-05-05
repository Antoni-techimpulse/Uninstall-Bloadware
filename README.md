# Windows 11 Debloat Enterprise

Script PowerShell interactivo para reducir bloatware en Windows 11, desinstalar aplicaciones Appx para todos los usuarios, eliminar paquetes provisionados, aplicar políticas de privacidad, desactivar tareas de telemetría, ajustar servicios prescindibles y controlar componentes opcionales.

> Proyecto orientado a técnicos, consultores IT y administradores que necesitan una base reutilizable para optimización post-instalación de Windows 11.

## Aviso importante

Este proyecto modifica aplicaciones instaladas, paquetes provisionados, servicios, tareas programadas, capacidades opcionales y claves de registro bajo `HKLM`. Debe ejecutarse con privilegios de administrador.

Antes de utilizarlo en producción:

- probar en una máquina virtual o equipo piloto;
- revisar la lista de aplicaciones y servicios;
- validar compatibilidad con políticas internas, Intune, GPO, SCCM o herramientas RMM;
- crear punto de restauración o imagen del sistema si procede.

## Funcionalidades

- Eliminación de aplicaciones Appx para todos los usuarios.
- Eliminación de paquetes provisionados para evitar reinstalación en nuevos perfiles.
- Desactivación de telemetría básica y contenido optimizado para la nube.
- Desactivación de Advertising ID y Activity History.
- Desactivación de Startup Boost y modo en segundo plano de Microsoft Edge.
- Desactivación de servicios asociados a telemetría, mapas, demo retail, fax y Xbox.
- Desactivación de tareas programadas de experiencia de cliente y compatibilidad.
- Eliminación opcional de capacidades de Windows como Steps Recorder, Math Recognizer, Fax/Scan y Windows Hello Face.
- Eliminación opcional de OneDrive.
- Registro de ejecución mediante transcript.
- Lanzador `.bat` con elevación UAC automática.

## Archivos principales

```text
scripts/
├── windows11-debloat-enterprise.ps1
└── ejecutar-windows11-debloat-enterprise-admin.bat
```

## Uso rápido

1. Descarga o clona este repositorio.
2. Abre la carpeta `scripts`.
3. Ejecuta `ejecutar-windows11-debloat-enterprise-admin.bat`.
4. Acepta el aviso UAC.
5. Responde `y` o `n` en cada acción.

## Ejecución manual desde PowerShell

Abre PowerShell como Administrador:

```powershell
cd "C:\ruta\al\repositorio\scripts"
Unblock-File .\windows11-debloat-enterprise.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\windows11-debloat-enterprise.ps1
```

## Registro de ejecución

El script genera un log en:

```text
%USERPROFILE%\windows11-debloat-enterprise-log.txt
```

## Elementos tratados

### Aplicaciones Appx / provisioned packages

Incluye, entre otras:

- Microsoft 3D Builder
- Bing Weather, News, Sports, Finance
- Get Help
- Get Started
- Microsoft 3D Viewer
- Microsoft Office Hub
- Microsoft Solitaire Collection
- Sticky Notes
- Mixed Reality Portal
- Paint
- OneNote
- People
- Print 3D
- Skype
- Alarms
- Camera
- Feedback Hub
- Maps
- Sound Recorder
- Xbox App y componentes Xbox
- Phone Link / Your Phone
- Microsoft To Do
- Power Automate Desktop
- Teams / MSTeams
- Quick Assist
- Outlook for Windows
- Clipchamp
- Microsoft Family
- Windows Communications Apps
- Zune Music / Video

### Registro / políticas

- `AllowTelemetry = 0`
- `DisableCloudOptimizedContent = 1`
- `DisabledByGroupPolicy = 1`
- `PublishUserActivities = 0`
- `UploadUserActivities = 0`
- `StartupBoostEnabled = 0`
- `BackgroundModeEnabled = 0`

### Servicios

- `DiagTrack`
- `dmwappushservice`
- `MapsBroker`
- `RetailDemo`
- `Fax`
- `XblGameSave`
- `XboxGipSvc`
- `XboxNetApiSvc`
- `WSearch` opcional

### Tareas programadas

- Microsoft Compatibility Appraiser
- ProgramDataUpdater
- Consolidator
- UsbCeip
- Autochk Proxy

### Capacidades opcionales

- Steps Recorder
- Math Recognizer
- Print/Fax/Scan
- Windows Hello Face opcional

## Recomendaciones de despliegue

Para despliegue masivo, revisar primero el script y convertir la confirmación interactiva en parámetros, por ejemplo:

- `-Profile Conservative`
- `-Profile Standard`
- `-Profile Enterprise`
- `-Silent`
- `-SkipOneDrive`
- `-KeepCamera`
- `-KeepTeams`

Esta versión es interactiva por diseño para reducir riesgo operativo en ejecuciones manuales.

## Limitaciones

- Algunas aplicaciones pueden no existir según edición, idioma, build de Windows 11 u OEM.
- Algunas apps pueden volver a instalarse tras actualizaciones mayores de Windows.
- No elimina Microsoft Edge, Microsoft Store ni dependencias críticas.
- No sustituye una política formal de hardening ni una baseline CIS/Microsoft Security Baseline.

## Licencia

MIT. Consulta `LICENSE`.
