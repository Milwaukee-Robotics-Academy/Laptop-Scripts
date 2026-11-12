#Requires -RunAsAdministrator

Write-Host "Starting System Reset and Configuration..." -ForegroundColor Cyan

# 1. Reset Network Stack & Saved Wi-Fi Profiles
Write-Host "Resetting network settings..." -ForegroundColor Yellow
netsh wlan delete profile name=* i=*
ipconfig /release
ipconfig /flushdns
netsh winsock reset
netsh int ip reset
# Re-enable DHCP on standard Wi-Fi/Ethernet adapters if static IPs were set
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Set-NetIPInterface -Dhcp Enabled

# 2. Clear Windows Credential Manager for GitHub
# Retrieve all stored credentials, filter for GitHub entries, and delete them
cmdkey.exe /list | Select-String -Pattern "Target:.*github" | ForEach-Object {
    $target = ($_ -replace "^\s*Target:\s*", "").Trim()
    Write-Host "Removing credential: $target" -ForegroundColor Yellow
    cmdkey.exe /delete:$target
}
# Remove unwanted apps
. "$PSScriptRoot\remove-unwanted-apps.ps1"

# Install base apps
. "$PSScriptRoot\install-base-apps.ps1"

# Angry IP Scanner default settings
. "$PSScriptRoot\angry-ip-scanner-default-settings.ps1"


Write-Host "Tasks complete. A system restart is recommended to finalize network resets." -ForegroundColor Green
# Uncomment the line below to force an automatic reboot
# Restart-Computer -Force