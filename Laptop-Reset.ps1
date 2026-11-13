#Requires -RunAsAdministrator

Write-Host "Starting System Reset and Configuration..." -ForegroundColor Cyan

# Clear Windows Credential Manager for GitHub
. "$PSScriptRoot\clear-github-creds.ps1"
# Reset Network Stack & Saved Wi-Fi Profiles
. "$PSScriptRoot\network-dhcp.ps1"
. "$PSScriptRoot\wifi-setup.ps1"

# Remove unwanted apps
. "$PSScriptRoot\remove-unwanted-apps.ps1"

# Install base apps
. "$PSScriptRoot\install-base-apps.ps1"

# App default settings
. "$PSScriptRoot\app-default-settings.ps1"


Write-Host "Tasks complete. A system restart is recommended to finalize network resets." -ForegroundColor Green
# Uncomment the line below to force an automatic reboot
# Restart-Computer -Force