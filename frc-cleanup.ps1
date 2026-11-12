#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the 4-digit FRC season year to uninstall (e.g., 2026)")]
    [ValidatePattern("^\d{4}$")]
    [string]$Year
)

$ErrorActionPreference = "SilentlyContinue"
$nextYear = ([int]$Year + 1).ToString()

Write-Host "Starting $Year FRC Software Cleanup (preparing for $nextYear)..." -ForegroundColor Cyan

# 1. Remove WPILib Installation & Desktop Shortcuts for the specified year
$wpilibPath = "C:\Users\Public\wpilib\$Year"
if (Test-Path $wpilibPath) {
    Write-Host "Removing WPILib $Year folder ($wpilibPath)..." -ForegroundColor Yellow
    Remove-Item -Path $wpilibPath -Recurse -Force
} else {
    Write-Host "WPILib $Year folder not found at $wpilibPath." -ForegroundColor Gray
}

Write-Host "Cleaning up $Year Public Desktop shortcuts..." -ForegroundColor Yellow
Get-ChildItem -Path "C:\Users\Public\Desktop" -Filter "*$Year*" | Remove-Item -Force

# 2. Remove WPILib PATH Environment Variables (Machine & User) for the specified year
foreach ($scope in @("Machine", "User")) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
    if ($currentPath) {
        $cleanedPath = ($currentPath -split ';' | Where-Object { $_ -notmatch "wpilib\\$Year" }) -join ';'
        if ($currentPath -ne $cleanedPath) {
            [Environment]::SetEnvironmentVariable("Path", $cleanedPath, $scope)
            Write-Host "Removed WPILib $Year from $scope PATH." -ForegroundColor Green
        }
    }
}

# 3. Uninstall NI FRC Game Tools / LabVIEW via NI Package Manager (nipkg.exe)
$nipkg = "C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
if (Test-Path $nipkg) {
    Write-Host "Querying installed NI FRC packages..." -ForegroundColor Yellow
    $installed = & $nipkg list-installed
    
    # Filter for FRC and LabVIEW FRC packages (NI Game Tools updates in-place across seasons)
    $frcPackages = $installed | Where-Object { $_ -match "frc|wpilib|labview" } | ForEach-Object { ($_ -split '\s+') }
    
    if ($frcPackages) {
        Write-Host "Removing NI packages: $($frcPackages -join ', ')" -ForegroundColor Yellow
        & $nipkg remove $frcPackages --accept-eulas --yes
    } else {
        Write-Host "No FRC-specific NI packages found via nipkg." -ForegroundColor Gray
    }
} else {
    Write-Host "NI Package Manager CLI not found at default path." -ForegroundColor Gray
}

# 4. Uninstall Any Standalone Vendor Tools matching the specified year via Registry
Write-Host "Checking Registry for $Year FRC/Vendor tools..." -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$targetApps = Get-ItemProperty $regPaths | Where-Object {
    $_.DisplayName -match "(WPILib|FRC|AdvantageScope|PathPlanner|Phoenix Tuner|REV Hardware Client)" -and
    $_.DisplayName -match $Year
}

foreach ($app in $targetApps) {
    Write-Host "Uninstalling $($app.DisplayName)..." -ForegroundColor Yellow
    if ($app.QuietUninstallString) {
        Start-Process "cmd.exe" -ArgumentList "/c `"$($app.QuietUninstallString)`"" -Wait
    } elseif ($app.UninstallString) {
        $uninst = $app.UninstallString -replace "msiexec.exe", "" -replace "/I", "/X"
        if ($app.UninstallString -match "msiexec") {
            Start-Process "msiexec.exe" -ArgumentList "$uninst /qn /norestart" -Wait
        } else {
            Start-Process "cmd.exe" -ArgumentList "/c `"$($app.UninstallString)`" /S" -Wait
        }
    }
}

Write-Host "`n$Year cleanup complete! Please reboot your PC before installing the $nextYear FRC software suite." -ForegroundColor Cyan
