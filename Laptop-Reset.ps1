#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Automated FRC laptop reset and initial environment configuration script.

.DESCRIPTION
    Prepares or resets a laptop for FIRST Robotics Competition (FRC) programming and driver station use:
      1. Clears stored GitHub credentials from Windows Credential Manager to prevent account bleed across users.
      2. Resets the Windows network stack (Winsock, IP, DNS, DHCP) and configures team Wi-Fi.
      3. Removes preinstalled consumer bloatware and unnecessary Microsoft Store (Appx) applications.
      4. Installs core robotics utilities and diagnostic tools via WinGet.
      5. Applies optimized default configurations for applications and Windows Explorer.

.NOTES
    - Must be executed with elevated Administrator privileges (#Requires -RunAsAdministrator).
    - Compatible with both raw PowerShell execution (using $PSScriptRoot) and standalone PS2EXE binaries (using $ExeDir).

.EXAMPLE
    .\Laptop-Reset.exe
#>

Write-Host "Starting System Reset and Configuration..." -ForegroundColor Cyan

# Ensure $ExeDir is set:
# PS2EXE automatically populates $ExeDir when compiled into an executable;
# when running directly as a .ps1 script, fallback to $PSScriptRoot (script directory).
if (-not $ExeDir) {
    $ExeDir = $PSScriptRoot
}

# ------------------------------------------------------------------------------
# 1. Clear Windows Credential Manager for GitHub
# ------------------------------------------------------------------------------
# Removes any saved personal or team GitHub credentials from Windows Credential Manager
# to ensure clean git authentication state and avoid unauthorized commits across users.
. "$ExeDir\util\clear-github-creds.ps1"

# ------------------------------------------------------------------------------
# 2. Reset Network Stack & Configure Wi-Fi
# ------------------------------------------------------------------------------
# Flush DNS, reset Winsock and IP stack, wipe old Wi-Fi profiles, and revert adapters
# from static pit IPs (e.g., 10.TE.AM.x) back to automatic DHCP.
. "$ExeDir\util\network-dhcp.ps1"

# Add or update the team's standard Wi-Fi profile (SSID and security credentials).
. "$ExeDir\util\wifi-setup.ps1"

# ------------------------------------------------------------------------------
# 3. Remove Unwanted Applications (Debloat)
# ------------------------------------------------------------------------------
# Uninstall preinstalled OEM bloatware and consumer Microsoft Store / Appx apps
# (such as News, Weather, Games, Xbox, Teams) to free system resources and prevent background popups.
. "$ExeDir\util\remove-unwanted-apps.ps1"

# ------------------------------------------------------------------------------
# 4. Install Base Robotics & Diagnostic Apps
# ------------------------------------------------------------------------------
# Install core FRC utilities via WinGet (Wireshark, PuTTY, Git, 7-Zip, Notepad++,
# Angry IP Scanner, Apple Bonjour mDNS, Python, PathPlanner, PowerToys, etc.).
. "$ExeDir\util\install-base-apps.ps1"

# ------------------------------------------------------------------------------
# 5. Apply Application & Explorer Default Settings
# ------------------------------------------------------------------------------
# Configure default settings for installed utilities:
#   - Angry IP Scanner: Preset favorite IP ranges for FRC subnets (10.TE.AM.x)
#   - Notepad++: Disable "remember last session" to keep editor clean
#   - Windows Explorer: Show file extensions, hidden files, and full folder paths
. "$ExeDir\util\app-default-settings.ps1"

# ------------------------------------------------------------------------------
# Completion & Reboot
# ------------------------------------------------------------------------------
Write-Host "Tasks complete. A system restart is recommended to finalize network resets." -ForegroundColor Green

# Uncomment the line below to force an automatic reboot after completion:
# Restart-Computer -Force
