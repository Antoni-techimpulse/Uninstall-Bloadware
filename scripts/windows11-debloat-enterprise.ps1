<#
.SYNOPSIS
    Windows 11 Debloat Enterprise Script

.DESCRIPTION
    Removes selected Windows 11 bloatware apps for all users, removes provisioned packages,
    disables selected services and scheduled tasks, removes optional Windows capabilities,
    applies privacy/security registry policies, and optionally removes OneDrive.

.NOTES
    Run as Administrator.
    Recommended: test in a controlled environment before broad deployment.
#>

#requires -version 5.1

$ErrorActionPreference = "SilentlyContinue"

# -----------------------------
# Admin validation
# -----------------------------
function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit 1
}

# -----------------------------
# Logging
# -----------------------------
$LogPath = Join-Path $env:USERPROFILE "windows11-debloat-enterprise-log.txt"
Start-Transcript -Path $LogPath -Append | Out-Null

Write-Host "========================================"
Write-Host " Windows 11 Debloat Enterprise Script"
Write-Host "========================================"
Write-Host "Log file: $LogPath"
Write-Host ""

# -----------------------------
# Confirmation helper
# -----------------------------
function Confirm-Action {
    param (
        [string]$Message
    )

    $confirmation = Read-Host "$Message (y/n)"
    return $confirmation -eq 'y'
}

# -----------------------------
# Appx removal
# -----------------------------
function Remove-AppEnterprise {
    param (
        [string]$AppName
    )

    if (Confirm-Action "Remove app package and provisioned package: $AppName ?") {
        Write-Output "Processing app: $AppName"

        $installedPackages = Get-AppxPackage -AllUsers -Name $AppName
        if ($installedPackages) {
            foreach ($package in $installedPackages) {
                Write-Output "Removing installed package: $($package.PackageFullName)"
                Remove-AppxPackage -Package $package.PackageFullName -AllUsers
            }
        } else {
            Write-Output "Installed package not found: $AppName"
        }

        $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $AppName }
        if ($provisionedPackages) {
            foreach ($provisioned in $provisionedPackages) {
                Write-Output "Removing provisioned package: $($provisioned.PackageName)"
                Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName | Out-Null
            }
        } else {
            Write-Output "Provisioned package not found: $AppName"
        }
    } else {
        Write-Output "Skipped app: $AppName"
    }
}

# -----------------------------
# Registry helper
# -----------------------------
function Set-RegistryKey {
    param (
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    if (Confirm-Action "Set registry value $Name in $Path to $Value ?") {
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        Write-Output "Set $Name in $Path to $Value"
    } else {
        Write-Output "Skipped registry value: $Name in $Path"
    }
}

# -----------------------------
# Service helper
# -----------------------------
function Disable-ServiceSafe {
    param (
        [string]$ServiceName
    )

    if (Confirm-Action "Disable service $ServiceName ?") {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $ServiceName -StartupType Disabled
            Write-Output "Service disabled: $ServiceName"
        } else {
            Write-Output "Service not found: $ServiceName"
        }
    } else {
        Write-Output "Skipped service: $ServiceName"
    }
}

# -----------------------------
# Scheduled task helper
# -----------------------------
function Disable-ScheduledTaskSafe {
    param (
        [string]$TaskPath,
        [string]$TaskName
    )

    if (Confirm-Action "Disable scheduled task $TaskPath$TaskName ?") {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            Disable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName | Out-Null
            Write-Output "Scheduled task disabled: $TaskPath$TaskName"
        } else {
            Write-Output "Scheduled task not found: $TaskPath$TaskName"
        }
    } else {
        Write-Output "Skipped scheduled task: $TaskPath$TaskName"
    }
}

# -----------------------------
# Capability helper
# -----------------------------
function Remove-CapabilitySafe {
    param (
        [string]$CapabilityName
    )

    if (Confirm-Action "Remove Windows capability $CapabilityName ?") {
        $capability = Get-WindowsCapability -Online -Name $CapabilityName
        if ($capability -and $capability.State -eq "Installed") {
            Remove-WindowsCapability -Online -Name $CapabilityName | Out-Null
            Write-Output "Capability removed: $CapabilityName"
        } else {
            Write-Output "Capability not installed or not found: $CapabilityName"
        }
    } else {
        Write-Output "Skipped capability: $CapabilityName"
    }
}

# -----------------------------
# OneDrive removal helper
# -----------------------------
function Remove-OneDriveSafe {
    if (Confirm-Action "Remove OneDrive completely ?") {
        Write-Output "Stopping OneDrive..."
        taskkill /f /im OneDrive.exe 2>$null

        $oneDriveSetup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        $oneDriveSetup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"

        if (Test-Path $oneDriveSetup64) {
            Start-Process $oneDriveSetup64 "/uninstall" -Wait
            Write-Output "OneDrive uninstall launched from SysWOW64."
        } elseif (Test-Path $oneDriveSetup32) {
            Start-Process $oneDriveSetup32 "/uninstall" -Wait
            Write-Output "OneDrive uninstall launched from System32."
        } else {
            Write-Output "OneDriveSetup.exe not found."
        }
    } else {
        Write-Output "Skipped OneDrive removal."
    }
}

# -----------------------------
# Apps to remove
# -----------------------------
$appsToRemove = @(
    # Original baseline
    "Microsoft.3DBuilder",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.MSPaint",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",

    # Recommended: consumer / bloatware
    "Microsoft.Todos",
    "Microsoft.PowerAutomateDesktop",
    "MicrosoftTeams",
    "MSTeams",
    "MicrosoftCorporationII.QuickAssist",
    "Microsoft.OutlookForWindows",
    "Clipchamp.Clipchamp",
    "MicrosoftFamily",
    "MicrosoftCorporationII.MicrosoftFamily",

    # Gaming / consumer
    "Microsoft.GamingApp",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameCallableUI",

    # Legacy / redundant
    "Microsoft.WindowsCommunicationsApps",

    # Promotional / OEM common apps
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingFinance",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

Write-Host ""
Write-Host "[1/7] Removing Appx packages and provisioned packages..."
foreach ($app in $appsToRemove | Sort-Object -Unique) {
    Remove-AppEnterprise -AppName $app
}

Write-Host ""
Write-Host "[2/7] Applying privacy and cloud-content registry policies..."

# Telemetry
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

# Cloud optimized content
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value 1

# Advertising ID
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1

# Activity history
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0

# Edge: avoid background startup behaviour
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0
Set-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Value 0

Write-Host ""
Write-Host "[3/7] Disabling selected services..."

$servicesToDisable = @(
    "DiagTrack",
    "dmwappushservice",
    "MapsBroker",
    "RetailDemo",
    "Fax",
    "XblGameSave",
    "XboxGipSvc",
    "XboxNetApiSvc"
)

foreach ($service in $servicesToDisable) {
    Disable-ServiceSafe -ServiceName $service
}

if (Confirm-Action "Disable Windows Search indexing service WSearch ? Recommended only if you do not rely on indexed search") {
    Disable-ServiceSafe -ServiceName "WSearch"
} else {
    Write-Output "Skipped optional service: WSearch"
}

Write-Host ""
Write-Host "[4/7] Disabling telemetry scheduled tasks..."

Disable-ScheduledTaskSafe "\Microsoft\Windows\Application Experience\" "Microsoft Compatibility Appraiser"
Disable-ScheduledTaskSafe "\Microsoft\Windows\Application Experience\" "ProgramDataUpdater"
Disable-ScheduledTaskSafe "\Microsoft\Windows\Customer Experience Improvement Program\" "Consolidator"
Disable-ScheduledTaskSafe "\Microsoft\Windows\Customer Experience Improvement Program\" "UsbCeip"
Disable-ScheduledTaskSafe "\Microsoft\Windows\Autochk\" "Proxy"

Write-Host ""
Write-Host "[5/7] Removing optional Windows capabilities..."

Remove-CapabilitySafe "App.StepsRecorder~~~~0.0.1.0"
Remove-CapabilitySafe "MathRecognizer~~~~0.0.1.0"
Remove-CapabilitySafe "Print.Fax.Scan~~~~0.0.1.0"

if (Confirm-Action "Remove Windows Hello Face capability ? Only choose yes if Windows Hello facial login is not used") {
    Remove-CapabilitySafe "Hello.Face~~~~0.0.1.0"
} else {
    Write-Output "Skipped optional capability: Hello.Face"
}

Write-Host ""
Write-Host "[6/7] Optional OneDrive removal..."
Remove-OneDriveSafe

Write-Host ""
Write-Host "[7/7] Final status..."
Write-Host "Windows 11 Debloat Enterprise completed."
Write-Host "Review log file: $LogPath"
Write-Host "A restart is recommended."

Stop-Transcript | Out-Null
