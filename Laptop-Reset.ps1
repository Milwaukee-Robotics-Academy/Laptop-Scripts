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

# 6 Ensure Angry IP Scanner is not running so it doesn't overwrite registry changes on exit
Get-Process -Name "ipscan" -ErrorAction SilentlyContinue | Stop-Process -Force

$RegPath = "HKCU:\Software\JavaSoft\Prefs\ipscan"

# Create the preference key if Angry IP Scanner hasn't been launched yet
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Java Preferences stores all values in the Windows Registry as REG_SZ (Strings)
$Preferences = @{
    "ping/Timeout"         = "200"
    "port/String"          = "22,80,443,5800,8080"
    "display/Method"       = "ALIVE"
    "show/Scan/Stats"       = "false"
    "ask/Scan/Confirmation" = "false"
}

foreach ($Key in $Preferences.Keys) {
    New-ItemProperty -Path $RegPath -Name $Key -Value $Preferences[$Key] -PropertyType String -Force 
}
Write-Host "Angry IP Scanner CSA preferences applied successfully." -ForegroundColor Green


Write-Host "Tasks complete. A system restart is recommended to finalize network resets." -ForegroundColor Green
# Uncomment the line below to force an automatic reboot
# Restart-Computer -Force