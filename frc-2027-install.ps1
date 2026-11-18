# Run as Administrator on Windows 11
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$InstallerDir = "c:\FRC2027_Installers"

# Install base apps
. "$PSScriptRoot\install-base-apps.ps1"

Write-Host "`n=== Running 2027 WPILib & Local FRC Installers ===" -ForegroundColor Cyan
if (-Not (Test-Path $InstallerDir)) {
    Write-Warning "Directory $InstallerDir does not exist. Create it and add your 2027 installers first."
    exit
}

# Mount and run the WPILib 2027 .ISO
$IsoFiles = Get-ChildItem -Path $InstallerDir -Filter "*.iso"
foreach ($Iso in $IsoFiles) {
    Write-Host "Mounting $($Iso.Name)..." -ForegroundColor Yellow
    $Mount = Mount-DiskImage -ImagePath $Iso.FullName -PassThru
    $DriveLetter = ($Mount | Get-Volume).DriveLetter + ":\"
    
    $WpiInstaller = Get-ChildItem -Path $DriveLetter -Filter "*WPILibInstaller*.exe" | Select-Object -First 1
    if ($WpiInstaller) {
        Write-Host "Launching WPILib 2027 Installer..." -ForegroundColor Green
        # Note: 2027 Alpha 7+ includes CLI support; pass --help to check final release flags, or run GUI interactively
        Start-Process -FilePath $WpiInstaller.FullName -Wait
    }
    Dismount-DiskImage -ImagePath $Iso.FullName
}

# Run 2027 FIRST Driver Station, REV Hardware Client, and Radio Network Assistant
$LocalInstallers = Get-ChildItem -Path $InstallerDir -Include "*.exe", "*.msi" -Recurse
foreach ($File in $LocalInstallers) {
    Write-Host "Executing $($File.Name)..." -ForegroundColor Green
    if ($File.Extension -eq ".msi") {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$($File.FullName)`" /passive" -Wait
    } else {
        Start-Process -FilePath $File.FullName -Wait
    }
}

# Set Angry IP Scanner default settings
. "$PSScriptRoot\angry-ip-scanner-default-settings.ps1"


#install vscode extensions

#make sure code command is available
$codePath = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
    "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $codePath) {
    Write-Error "Could not find code.cmd. Please verify where VS Code is installed."
    exit 1
Write-Host "Installing recommended VS Code extensions for FRC 2027..." -ForegroundColor Cyan
$extensions = @(
    "GitHub.remotehub",          # GitHub Repositories (virtual workspaces)
    "GitHub.codespaces",         # GitHub Codespaces (cloud workspaces)
    "vscjava.vscode-java-pack",  # Extension Pack for Java
    "ms-vscode.PowerShell",      # PowerShell
    "ms-python.python"           # Python (includes Pylance & Debugger)
)

foreach ($ext in $extensions) {
    Write-Host "Installing $ext..." -ForegroundColor Cyan
    & $codePath --install-extension $ext --force
}

Write-Host "`n=== Configuring Windows Networking & Firewall for FRC ===" -ForegroundColor Cyan
# Ensure Bonjour / mDNS discovery isn't blocked by Windows Firewall during pit troubleshooting
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Write-Warning "Windows Firewall is disabled for pit diagnostics. Re-enable after events."

Write-Host "`nSetup complete! Reboot your laptop before imaging a Systemcore or VH-109 radio." -ForegroundColor Green
