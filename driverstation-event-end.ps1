#Requires -RunAsAdministrator

# ==============================================================================
# FRC Driver Station Auto-Configuration Script
# Must be run as Administrator!
# ==============================================================================

# Ensure script is run with Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as an Administrator!"
    Exit
}

Write-Host "Starting FRC Driver Station Post Event Configuration..." -ForegroundColor Cyan

# Re-enable Windows Update Service to prevent mid-match updates
Write-Host "[*] Re-enabling Windows Update service..." -ForegroundColor Yellow
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue

# Re-enable Wi-Fi and Bluetooth to prevent interference (keep Ethernet active)
Write-Host "[*] Re-enabling Wi-Fi and Bluetooth adapters..." -ForegroundColor Yellow
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Wireless|Wi-Fi|Bluetooth" } | Enable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue

# Configure Ethernet Adapter for DHCP and disable IPv6
. "$PSScriptRoot\network-dhcp.ps1"

# 5. Completely disable Windows Defender Firewall across all profiles
Write-Host "[*] Disabling Windows Defender Firewall (Domain, Private, Public)..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

Write-Host "[-] FRC Driver Station Laptop setup complete! Reboot recommended." -ForegroundColor Green
