#Requires -RunAsAdministrator

# Reset Network Stack & Saved Wi-Fi Profiles
Write-Host "Resetting network settings..." -ForegroundColor Yellow
netsh wlan delete profile name=* i=*
ipconfig /release
ipconfig /flushdns
netsh winsock reset
netsh int ip reset
# Re-enable DHCP on standard Wi-Fi/Ethernet adapters if static IPs were set
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Set-NetIPInterface -Dhcp Enabled