# Guía de uso

## Requisitos

- Windows 11.
- PowerShell 5.1 o superior.
- Usuario con privilegios de administrador.

## Ejecución recomendada

Usar el lanzador BAT incluido:

```text
scripts\ejecutar-windows11-debloat-enterprise-admin.bat
```

El BAT:

1. comprueba si existe el `.ps1`;
2. solicita elevación UAC si no tiene permisos de administrador;
3. desbloquea el archivo PowerShell;
4. ejecuta PowerShell con `ExecutionPolicy Bypass` solo para el proceso actual.

## Ejecución PowerShell directa

```powershell
cd "C:\ruta\al\repositorio\scripts"
Unblock-File .\windows11-debloat-enterprise.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\windows11-debloat-enterprise.ps1
```

## Reversibilidad

Este script no implementa rollback automático. Para revertir cambios puede ser necesario:

- reinstalar apps desde Microsoft Store;
- reaprovisionar paquetes Appx;
- cambiar servicios a `Manual` o `Automatic`;
- volver a habilitar tareas programadas;
- revertir claves de registro;
- restaurar desde punto de restauración o imagen.

## Buenas prácticas

- Probar primero en VM.
- Ejecutar en un equipo piloto antes de producción.
- Revisar el log después de cada ejecución.
- Mantener Microsoft Store, Desktop App Installer, VCLibs, .NET y UI.Xaml fuera de la lista de eliminación.
