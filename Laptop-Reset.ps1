#Requires -RunAsAdministrator

Write-Host "Starting System Reset and Configuration..." -ForegroundColor Cyan

# Clear Windows Credential Manager for GitHub
. "$ExeDir\util\clear-github-creds.ps1"
# Reset Network Stack & Saved Wi-Fi Profiles
. "$ExeDir\util\network-dhcp.ps1"
. "$ExeDir\util\wifi-setup.ps1"

# Remove unwanted apps
. "$ExeDir\util\remove-unwanted-apps.ps1"

# Install base apps
. "$ExeDir\util\install-base-apps.ps1"

# App default settings
. "$ExeDir\util\app-default-settings.ps1"


Write-Host "Tasks complete. A system restart is recommended to finalize network resets." -ForegroundColor Green
# Uncomment the line below to force an automatic reboot
# Restart-Computer -Force