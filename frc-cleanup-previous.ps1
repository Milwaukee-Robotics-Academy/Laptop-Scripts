#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstalls previous-season FRC software, WPILib installations, and vendor tools.

.DESCRIPTION
    Automates end-of-season cleanup to prepare laptops for a new FIRST Robotics Competition (FRC) season:
      1. Removes the WPILib installation folder (C:\Users\Public\wpilib\<Year>).
      2. Removes FRC desktop shortcuts and tool folders associated with the specified year.
      3. Cleans WPILib directory entries from both Machine and User PATH environment variables.
      4. Uninstalls National Instruments (NI) FRC Game Tools & LabVIEW packages via NI Package Manager (nipkg.exe).
      5. Detects and uninstalls season-specific vendor tools (WPILib, AdvantageScope, PathPlanner, CTRE, REV) via Registry.

.PARAMETER Year
    The 4-digit FRC season year to clean up (e.g., "2026").

.EXAMPLE
    .\frc-cleanup-previous.exe -Year 2026
    or
    .\frc-cleanup-previous.ps1 -Year 2026
    Uninstalls all 2026 FRC software in preparation for 2027.

.NOTES
    Must be executed with elevated Administrator privileges (#Requires -RunAsAdministrator).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the 4-digit FRC season year to uninstall (e.g., 2026)")]
    [ValidatePattern("^\d{4}$")]
    [string]$Year
)

# Suppress minor non-terminating errors during registry/file scans
$ErrorActionPreference = "SilentlyContinue"
$nextYear = ([int]$Year + 1).ToString()

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Starting FRC $Year Software Cleanup (Preparing for $nextYear)  " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan


# ==============================================================================
# SECTION 1: Remove WPILib Installation Directory
# ==============================================================================
Write-Host "`n[1/5] Checking WPILib $Year installation directory..." -ForegroundColor Yellow

$wpilibPath = "C:\Users\Public\wpilib\$Year"
if (Test-Path $wpilibPath) {
    Write-Host "  -> Removing WPILib $Year folder: $wpilibPath" -ForegroundColor Yellow
    Remove-Item -Path $wpilibPath -Recurse -Force
    Write-Host "  -> WPILib $Year folder removed." -ForegroundColor Green
} else {
    Write-Host "  -> WPILib $Year folder not found at $wpilibPath." -ForegroundColor Gray
}


# ==============================================================================
# SECTION 2: Remove FRC Desktop Shortcuts & Tool Folders
# ==============================================================================
Write-Host "`n[2/5] Removing FRC $Year desktop shortcuts and folders..." -ForegroundColor Yellow

# Locations where FRC installers create desktop items (all users and current user)
$desktopLocations = @(
    "C:\Users\Public\Desktop",
    [Environment]::GetFolderPath("Desktop")
) | Where-Object { Test-Path $_ } | Select-Object -Unique

$wshShell = New-Object -ComObject WScript.Shell
$removedShortcutsCount = 0

foreach ($desktop in $desktopLocations) {
    # 2.1 Remove desktop folders matching FRC / WPILib for the target year
    Get-ChildItem -Path $desktop -Directory -ErrorAction SilentlyContinue | Where-Object {
        ($_.Name -match $Year) -and ($_.Name -match "FRC|WPILib|Robotics|National Instruments")
    } | ForEach-Object {
        Write-Host "  -> Removing FRC desktop folder: $($_.FullName)" -ForegroundColor Yellow
        Remove-Item -Path $_.FullName -Recurse -Force
        $removedShortcutsCount++
    }

    # 2.2 Remove individual shortcut files (.lnk, .url) matching the target year
    Get-ChildItem -Path $desktop -File -ErrorAction SilentlyContinue | Where-Object {
        $_.Extension -in @(".lnk", ".url")
    } | ForEach-Object {
        $isMatch = $false

        # Match shortcuts with the year in the name (e.g. "WPILib VS Code 2026.lnk", "FRC Driver Station 2026.lnk")
        if ($_.Name -match $Year) {
            $isMatch = $true
        }
        # Inspect target path of .lnk files to check if it points into the WPILib year directory
        elseif ($_.Extension -eq ".lnk") {
            try {
                $shortcut = $wshShell.CreateShortcut($_.FullName)
                if ($shortcut.TargetPath -match "wpilib[\\/]$Year" -or $shortcut.TargetPath -match "FRC.*$Year") {
                    $isMatch = $true
                }
            } catch {
                # Ignore COM read errors on invalid or inaccessible shortcuts
            }
        }

        if ($isMatch) {
            Write-Host "  -> Removing FRC shortcut: $($_.FullName)" -ForegroundColor Yellow
            Remove-Item -Path $_.FullName -Force
            $removedShortcutsCount++
        }
    }
}

# Release the COM object
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wshShell) | Out-Null

if ($removedShortcutsCount -gt 0) {
    Write-Host "  -> Removed $removedShortcutsCount FRC $Year desktop item(s)." -ForegroundColor Green
} else {
    Write-Host "  -> No FRC $Year desktop shortcuts or folders found." -ForegroundColor Gray
}


# ==============================================================================
# SECTION 3: Clean Environment Variables (PATH)
# ==============================================================================
Write-Host "`n[3/5] Cleaning WPILib $Year from PATH environment variables..." -ForegroundColor Yellow

foreach ($scope in @("Machine", "User")) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
    if ($currentPath) {
        # Filter out any path segment referencing wpilib\<Year>
        $cleanedSegments = $currentPath -split ';' | Where-Object { $_ -notmatch "wpilib\\$Year" }
        $cleanedPath = $cleanedSegments -join ';'
        
        if ($currentPath -ne $cleanedPath) {
            [Environment]::SetEnvironmentVariable("Path", $cleanedPath, $scope)
            Write-Host "  -> Removed WPILib $Year entries from $scope PATH." -ForegroundColor Green
        } else {
            Write-Host "  -> No WPILib $Year entries found in $scope PATH." -ForegroundColor Gray
        }
    }
}


# ==============================================================================
# SECTION 4: Uninstall NI FRC Game Tools & LabVIEW via NI Package Manager
# ==============================================================================
Write-Host "`n[4/5] Checking for NI FRC packages via NI Package Manager..." -ForegroundColor Yellow

$nipkg = "C:\Program Files\National Instruments\NI Package Manager\nipkg.exe"
if (Test-Path $nipkg) {
    Write-Host "  -> Querying installed NI packages..." -ForegroundColor Gray
    $installed = & $nipkg list-installed
    
    # Extract package IDs matching FRC, WPILib, or LabVIEW
    $frcPackages = $installed | Where-Object { $_ -match "frc|wpilib|labview" } | ForEach-Object {
        ($_ -split '\s+')[0]
    } | Select-Object -Unique
    
    if ($frcPackages) {
        Write-Host "  -> Found NI packages to remove: $($frcPackages -join ', ')" -ForegroundColor Yellow
        & $nipkg remove $frcPackages --accept-eulas --yes
        Write-Host "  -> NI packages removed." -ForegroundColor Green
    } else {
        Write-Host "  -> No FRC-specific NI packages found via nipkg." -ForegroundColor Gray
    }
} else {
    Write-Host "  -> NI Package Manager CLI not found at '$nipkg'. Skipping." -ForegroundColor Gray
}


# ==============================================================================
# SECTION 5: Uninstall Season Vendor Tools via Windows Registry
# ==============================================================================
Write-Host "`n[5/5] Checking Registry for $Year FRC and vendor software..." -ForegroundColor Yellow

# Registry locations for both 64-bit and 32-bit (WOW6432Node) installed software
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Search for vendor tools tied specifically to the target year
$targetApps = Get-ItemProperty $regPaths -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -match "(WPILib|FRC|AdvantageScope|PathPlanner|Phoenix Tuner|REV Hardware Client)" -and
    $_.DisplayName -match $Year
}

if ($targetApps) {
    foreach ($app in $targetApps) {
        Write-Host "  -> Uninstalling: $($app.DisplayName)..." -ForegroundColor Yellow
        
        if ($app.QuietUninstallString) {
            # Use vendor-provided silent uninstall command if available
            Start-Process "cmd.exe" -ArgumentList "/c `"$($app.QuietUninstallString)`"" -Wait
        } elseif ($app.UninstallString) {
            if ($app.UninstallString -match "msiexec") {
                # Format MSI command for non-interactive silent uninstall (/x ... /qn /norestart)
                $msiArgs = ($app.UninstallString -replace "msiexec(\.exe)?", "" -replace "/[iI]", "/x").Trim()
                Start-Process "msiexec.exe" -ArgumentList "$msiArgs /qn /norestart" -Wait
            } else {
                # Fallback to running standard uninstaller with silent flag
                Start-Process "cmd.exe" -ArgumentList "/c `"$($app.UninstallString)`" /S" -Wait
            }
        }
        Write-Host "  -> Uninstalled $($app.DisplayName)." -ForegroundColor Green
    }
} else {
    Write-Host "  -> No matching $Year vendor tools found in Windows Registry." -ForegroundColor Gray
}


# ==============================================================================
# Completion Summary
# ==============================================================================
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " FRC $Year cleanup complete!" -ForegroundColor Green
Write-Host " Please reboot your computer before installing the $nextYear FRC software suite." -ForegroundColor Cyan
Write-Host "=================================================================`n" -ForegroundColor Cyan
