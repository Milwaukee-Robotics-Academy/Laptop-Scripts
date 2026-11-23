#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs and configures the latest FRC software suite, tools, and developer environment.

.DESCRIPTION
    Automates the full setup process for an FRC development laptop:
      1. Installs base diagnostic utilities and tools via WinGet (install-base-apps.ps1).
      2. Mounts the downloaded WPILib ISO image and runs the official WPILib installer.
      3. Runs all standalone installers (.exe / .msi) in the installer folder (e.g., Driver Station, REV, NI tools).
      4. Configures Angry IP Scanner preferences for FRC robot networking (10.TE.AM.x subnets).
      5. Installs recommended VS Code extensions (Java, Python, PowerShell, GitHub).
      6. Adjusts Windows Firewall profiles to ensure mDNS and Bonjour discovery function during pit diagnostics.

.PARAMETER InstallerDir
    The directory containing downloaded FRC installer files (*.iso, *.exe, *.msi).
    Defaults to 'C:\FRC_Latest_Installers'.

.EXAMPLE
    .\frc-latest-install.ps1

.EXAMPLE
    .\frc-latest-install.ps1 -InstallerDir "D:\FRC_Installers"

.NOTES
    Must be executed with elevated Administrator privileges (#Requires -RunAsAdministrator).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$InstallerDir = "C:\FRC_Latest_Installers"
)

# Stop execution immediately if a critical command fails
$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Starting Latest FRC Software Installation & Configuration       " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Fallback for $ExeDir: PS2EXE automatically sets $ExeDir when compiled to an .exe;
# when running directly as a .ps1 script, fallback to $PSScriptRoot (script directory).
if (-not $ExeDir) {
    $ExeDir = $PSScriptRoot
}


# ==============================================================================
# SECTION 1: Install Base Diagnostics & Utilities via WinGet
# ==============================================================================
Write-Host "`n[1/7] Installing base utility applications via WinGet..." -ForegroundColor Yellow
if (Test-Path "$ExeDir\util\install-base-apps.ps1") {
    . "$ExeDir\util\install-base-apps.ps1"
} else {
    Write-Warning "Utility script '$ExeDir\util\install-base-apps.ps1' not found. Skipping base apps installation."
}


# ==============================================================================
# SECTION 2: Validate Installer Directory
# ==============================================================================
Write-Host "`n[2/7] Verifying installer directory..." -ForegroundColor Yellow
if (-not (Test-Path -Path $InstallerDir)) {
    Write-Error "Installer directory '$InstallerDir' does not exist. Run frc-latest-download.ps1 first or create the directory."
    exit 1
}
Write-Host "  -> Installer directory confirmed: $InstallerDir" -ForegroundColor Green


# ==============================================================================
# SECTION 3: Mount and Run WPILib .ISO Installer
# ==============================================================================
Write-Host "`n[3/7] Checking for WPILib .ISO disk images..." -ForegroundColor Yellow

$isoFiles = Get-ChildItem -Path $InstallerDir -Filter "*.iso" -File -ErrorAction SilentlyContinue

if ($isoFiles) {
    foreach ($iso in $isoFiles) {
        Write-Host "  -> Mounting disk image: $($iso.Name)..." -ForegroundColor Yellow
        $mount = Mount-DiskImage -ImagePath $iso.FullName -PassThru
        $volume = $mount | Get-Volume
        $driveLetter = "$($volume.DriveLetter):\"
        
        Write-Host "  -> Mounted at drive: $driveLetter" -ForegroundColor Gray
        
        # Locate the WPILib installer executable on the mounted virtual drive
        $wpiInstaller = Get-ChildItem -Path $driveLetter -Filter "*WPILibInstaller*.exe" -File | Select-Object -First 1
        
        if ($wpiInstaller) {
            Write-Host "  -> Launching WPILib Installer ($($wpiInstaller.Name))..." -ForegroundColor Green
            # Note: WPILib Alpha 7+ includes CLI support; pass --help to check final release flags, or run GUI interactively
            Start-Process -FilePath $wpiInstaller.FullName -Wait
            Write-Host "  -> WPILib installation step finished." -ForegroundColor Green
        } else {
            Write-Warning "WPILibInstaller executable not found inside mounted image '$($iso.Name)'."
        }
        
        # Cleanly dismount the virtual disk image
        Write-Host "  -> Dismounting disk image: $($iso.Name)..." -ForegroundColor Gray
        Dismount-DiskImage -ImagePath $iso.FullName | Out-Null
    }
} else {
    Write-Host "  -> No .ISO files found in '$InstallerDir'. Skipping WPILib ISO installation." -ForegroundColor Gray
}


# ==============================================================================
# SECTION 4: Run Standalone Installers (.EXE / .MSI)
# ==============================================================================
Write-Host "`n[4/7] Running standalone installers (.exe / .msi)..." -ForegroundColor Yellow

# Find all standalone executable installers in the directory
$localInstallers = Get-ChildItem -Path $InstallerDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".exe", ".msi") }

if ($localInstallers) {
    foreach ($file in $localInstallers) {
        Write-Host "  -> Executing: $($file.Name)..." -ForegroundColor Green
        
        if ($file.Extension -eq ".msi") {
            # Run Windows Installer packages quietly/passively
            Start-Process "msiexec.exe" -ArgumentList "/i `"$($file.FullName)`" /passive" -Wait
        } else {
            # Run executable installers interactively or with default behavior
            Start-Process -FilePath $file.FullName -Wait
        }
        Write-Host "  -> Completed: $($file.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "  -> No standalone .exe or .msi installers found in '$InstallerDir'." -ForegroundColor Gray
}


# ==============================================================================
# SECTION 5: Configure Application Settings (Angry IP Scanner)
# ==============================================================================
Write-Host "`n[5/7] Configuring application default settings..." -ForegroundColor Yellow

if (Test-Path "$ExeDir\util\angry-ip-scanner-default-settings.ps1") {
    . "$ExeDir\util\angry-ip-scanner-default-settings.ps1"
} else {
    Write-Host "  -> Angry IP Scanner configuration script not found at '$ExeDir\util\angry-ip-scanner-default-settings.ps1'." -ForegroundColor Gray
}


# ==============================================================================
# SECTION 6: Install Recommended VS Code Extensions
# ==============================================================================
Write-Host "`n[6/7] Installing recommended VS Code extensions for FRC..." -ForegroundColor Yellow

# Locate VS Code's command-line interface (code.cmd) in standard user or system install locations
$codePath = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
    "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

$extensions = @(
    "GitHub.remotehub",          # GitHub Repositories (virtual workspaces)
    "GitHub.codespaces",         # GitHub Codespaces (cloud workspaces)
    "vscjava.vscode-java-pack",  # Extension Pack for Java (FRC robot code)
    "ms-vscode.PowerShell",      # PowerShell language support
    "ms-python.python",          # Python (includes Pylance and debugger)
    "anthropic.claude-code",     # Claude AI code assistant (optional, if available)
    "GitHub.copilot",            # GitHub Copilot AI code assistant (optional, if available)
    "GitHub.copilot-chat",       # GitHub Copilot AI code assistant (optional, if available)
    "Google.google-antigravity"  # Google Antigravity 
)
    
if ($codePath) {
    Write-Host "  -> Found VS Code CLI at: $codePath" -ForegroundColor Gray
    foreach ($ext in $extensions) {
        Write-Host "  -> Installing extension: $ext..." -ForegroundColor Cyan
        & $codePath --install-extension $ext --force
    }
    Write-Host "  -> VS Code extensions installed." -ForegroundColor Green
} else {
    Write-Warning "VS Code CLI (code.cmd) was not found in standard installation paths. Skipping extension install."
}


# ==============================================================================
# SECTION 7: Windows Networking & Firewall Configuration for FRC
# ==============================================================================
Write-Host "`n[7/7] Configuring Windows Firewall for FRC robot diagnostics..." -ForegroundColor Yellow

# Ensure Bonjour / mDNS discovery and roboRIO communication aren't blocked by Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Write-Warning "Windows Firewall disabled across Domain, Public, and Private profiles for pit diagnostics. Remember to re-enable after events."


# ==============================================================================
# Completion Summary
# ==============================================================================
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " FRC Setup Complete!" -ForegroundColor Green
Write-Host " Reboot your laptop before imaging a Systemcore or VH-109 radio." -ForegroundColor Cyan
Write-Host "=================================================================`n" -ForegroundColor Cyan
