#Requires -RunAsAdministrator

Write-Host "Starting System Reset and Configuration..." -ForegroundColor Cyan

# 2. Clear Windows Credential Manager for GitHub
# Retrieve all stored credentials, filter for GitHub entries, and delete them
cmdkey.exe /list | Select-String -Pattern "Target:.*github" | ForEach-Object {
    $target = ($_ -replace "^\s*Target:\s*", "").Trim()
    Write-Host "Removing credential: $target" -ForegroundColor Yellow
    cmdkey.exe /delete:$target
}

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