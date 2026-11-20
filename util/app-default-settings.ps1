<#
.SYNOPSIS
    Applies recommended default configurations for FRC tools and Windows Explorer.

.DESCRIPTION
    Coordinates applying optimized environment and application settings for robotics laptops:
      1. Angry IP Scanner: Configures fast ping timeouts, standard FRC diagnostic ports (22, 80, 443, 5800, 8080),
         and suppresses confirmation popups.
      2. Notepad++: Disables session history ("Remember Last Session") so previous user tabs and logs don't persist.
      3. Windows Explorer: Enables developer-friendly views (shows hidden files, protected OS files, known file extensions,
         and full folder paths in title bars).

.NOTES
    Compatible with:
      - Direct execution as a standalone script (resolving $PSScriptRoot)
      - Invocation from parent scripts (e.g., Laptop-Reset.ps1, frc-2027-install.ps1)
      - Standalone PS2EXE compiled executables (resolving $ExeDir)

.EXAMPLE
    .\app-default-settings.ps1
#>

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Applying Default Application & Environment Settings             " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Resolve the directory containing the utility scripts:
# If $ExeDir is provided by a parent script or PS2EXE executable, use $ExeDir\util;
# otherwise fall back to $PSScriptRoot (the folder where this script resides).
$utilDir = if ($ExeDir -and (Test-Path "$ExeDir\util")) {
    "$ExeDir\util"
} else {
    $PSScriptRoot
}

# ------------------------------------------------------------------------------
# 1. Angry IP Scanner Default Settings
# ------------------------------------------------------------------------------
# Configures IP scan preferences (ports 22, 80, 443, 5800, 8080; fast ping timeout; display alive hosts only)
Write-Host "`n[1/3] Configuring Angry IP Scanner default settings..." -ForegroundColor Yellow
. "$utilDir\angry-ip-scanner-default-settings.ps1"

# ------------------------------------------------------------------------------
# 2. Notepad++ Session Settings
# ------------------------------------------------------------------------------
# Disables "Remember Last Session" in config.xml and removes lingering session.xml
Write-Host "`n[2/3] Configuring Notepad++ session preferences..." -ForegroundColor Yellow
. "$utilDir\notepadplusplus-dont-remember-last-session.ps1"

# ------------------------------------------------------------------------------
# 3. Windows Explorer View Settings
# ------------------------------------------------------------------------------
# Configures Registry settings to show file extensions, hidden files, and full folder paths
Write-Host "`n[3/3] Configuring Windows Explorer display settings..." -ForegroundColor Yellow
. "$utilDir\explorer-settings.ps1"

Write-Host "`nDefault settings configuration complete!" -ForegroundColor Green
