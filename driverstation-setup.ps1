#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configures a Windows laptop for an FRC Driver Station with a static IP and disables all firewalls.
.PARAMETER TeamNumber
    Your 1 to 5 digit FIRST FRC team number (e.g., 254, 1114, 10254).
.EXAMPLE
    .\Setup-FRCDriverStation.ps1 -TeamNumber 254
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Enter your FRC Team Number (1-99999)")]
    [ValidateRange(1, 99999)]
    [int]$TeamNumber
)

# Ensure script is run with Administrator privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as an Administrator!"
    Exit
}

# Calculate FRC IP octets from Team Number
$octet2 = [math]::Floor($TeamNumber / 100)
$octet3 = $TeamNumber % 100

$dsIP = "10.$octet2.$octet3.5"
$gatewayIP = "10.$octet2.$octet3.4"
$prefixLength = 8 # Equivalent to 255.0.0.0

Write-Host "Starting FRC Driver Station Setup for Team $TeamNumber..." -ForegroundColor Cyan
Write-Host "Target Static IP: $dsIP | Subnet: 255.0.0.0 | Gateway: $gatewayIP" -ForegroundColor Cyan

# Disable Windows Update Service to prevent mid-match updates
Write-Host "[*] Stopping and disabling Windows Update service..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue

# Disable Wi-Fi and Bluetooth to prevent interference
Write-Host "[*] Disabling Wi-Fi and Bluetooth adapters..." -ForegroundColor Yellow
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Wireless|Wi-Fi|Bluetooth" } | Disable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue

# Configure Ethernet Adapter with Static IP and disable IPv6
Write-Host "[*] Configuring Ethernet adapter with Static IP..." -ForegroundColor Yellow
$ethAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -notmatch "Wireless|Wi-Fi|Bluetooth|Virtual|Loopback" -and ($_.Status -eq "Up" -or $_.MediaType -eq "802.3") } | Select-Object -First 1

if ($ethAdapter) {
    Write-Host "    Found Ethernet Adapter: $($ethAdapter.Name)" -ForegroundColor Gray
    
    # Disable IPv6
    Disable-NetAdapterBinding -Name $ethAdapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    
    # Remove any existing static IPs or routes on this adapter to prevent conflicts
    Remove-NetIPAddress -InterfaceIndex $ethAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $ethAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    
    # Disable DHCP and assign the FRC Static IP
    Set-NetIPInterface -InterfaceIndex $ethAdapter.ifIndex -Dhcp Disabled -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceIndex $ethAdapter.ifIndex -IPAddress $dsIP -PrefixLength $prefixLength -DefaultGateway $gatewayIP -ErrorAction Stop | Out-Null
    
    Write-Host "    Successfully assigned $dsIP to $($ethAdapter.Name)" -ForegroundColor Green
} else {
    Write-Warning "No physical Ethernet adapter found! Connect your Ethernet cable or USB-to-Ethernet adapter and try again."
}

ipconfig /flushdns | Out-Null

# disable USB Selective Suspend and Power Saving
Write-Host "[*] Disabling USB power saving..." -ForegroundColor Yellow
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bec330b35d 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_USB usbust 0
powercfg /setactive SCHEME_CURRENT

# Completely disable Windows Defender Firewall across all profiles
Write-Host "[*] Disabling Windows Defender Firewall (Domain, Private, Public)..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

Write-Host "[-] FRC Driver Station setup complete! A reboot is recommended." -ForegroundColor Green
