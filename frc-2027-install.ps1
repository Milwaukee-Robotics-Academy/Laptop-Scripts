# Run as Administrator on Windows 11
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$InstallerDir = "C:\FRC_2027_Installers"

# Install base apps
. "$PSScriptRoot\install-base-apps.ps1"

Write-Host "`n=== 2. Running 2027 WPILib & Local FRC Installers ===" -ForegroundColor Cyan
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
. "$PSSrciptRoot\angry-ip-scanner-default-settings.ps1"

Write-Host "`n=== 3. Configuring Windows Networking & Firewall for FRC ===" -ForegroundColor Cyan
# Ensure Bonjour / mDNS discovery isn't blocked by Windows Firewall during pit troubleshooting
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Write-Warning "Windows Firewall is disabled for pit diagnostics. Re-enable after events."

Write-Host "`nSetup complete! Reboot your laptop before imaging a Systemcore or VH-109 radio." -ForegroundColor Green
