@echo off
setlocal EnableExtensions

:: Windows 11 Debloat Enterprise Launcher
:: Place this BAT in the same folder as windows11-debloat-enterprise.ps1

set "SCRIPT=%~dp0windows11-debloat-enterprise.ps1"

if not exist "%SCRIPT%" (
    echo ERROR: Script not found:
    echo "%SCRIPT%"
    echo.
    pause
    exit /b 1
)

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Running Windows 11 Debloat Enterprise as Administrator...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '%SCRIPT%' -ErrorAction SilentlyContinue; & '%SCRIPT%'"

echo.
echo Finished. Review the PowerShell output and log file.
pause
endlocal
