#Requires -RunAsAdministrator
#Requires -Version 5.1

<#
.SYNOPSIS
    Prompts the user for a Wi-Fi SSID and masked password (defaulting to 'Doublee' and '1010101010'),
    creates a temporary WPA3-Personal (SAE) WLAN profile, and connects to the network.
#>

$DefaultSSID     = "Doublee"
$DefaultPassword = "1010101010"

# 1. Prompt for SSID with default fallback
$InputSSID = Read-Host -Prompt "Enter the Wi-Fi network name (SSID) [Default: $DefaultSSID]"
$SSID = if ([string]::IsNullOrWhiteSpace($InputSSID)) { $DefaultSSID } else { $InputSSID.Trim() }

# 2. Prompt for masked Password with default fallback
$SecurePassword = Read-Host -Prompt "Enter the Wi-Fi password for '$SSID' [Default $DefaultPassword]" -AsSecureString

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
try {
    $InputPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}
finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

$PlainPassword = if ([string]::IsNullOrEmpty($InputPassword)) { $DefaultPassword } else { $InputPassword }

# 3. Convert SSID to hexadecimal and escape XML characters
$HexSSID         = ($SSID.ToCharArray() | ForEach-Object { '{0:X2}' -f [int]$_ }) -join ''
$EscapedSSID     = [System.Security.SecurityElement]::Escape($SSID)
$EscapedPassword = [System.Security.SecurityElement]::Escape($PlainPassword)

# Clear plaintext password variables from memory
Clear-Variable -Name InputPassword, PlainPassword -ErrorAction SilentlyContinue

# 4. Build Windows WLAN profile XML for WPA3-Personal (WPA3SAE / AES)
$ProfileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://microsoft.com">
    <name>$EscapedSSID</name>
    <SSIDConfig>
        <SSID>
            <hex>$HexSSID</hex>
            <name>$EscapedSSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA3SAE</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$EscapedPassword</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

# 5. Write temporary XML, import profile, and connect
$SafeFileName = ($SSID -replace '[\\/:*?"<>|]', '_')
$TempXmlPath  = Join-Path -Path $env:TEMP -ChildPath "WLAN-$SafeFileName.xml"

try {
    $ProfileXml | Out-File -FilePath $TempXmlPath -Encoding UTF8 -Force
    Clear-Variable -Name ProfileXml, EscapedPassword -ErrorAction SilentlyContinue

    Write-Host "`nAdding WPA3-Personal Wi-Fi profile for '$SSID'..." -ForegroundColor Cyan
    $AddResult = netsh wlan add profile filename="$TempXmlPath" user=all
    Write-Host $AddResult

    Write-Host "Connecting to '$SSID'..." -ForegroundColor Cyan
    $ConnectResult = netsh wlan connect name="$SSID"
    Write-Host $ConnectResult
}
finally {
    # Always delete the temporary XML file
    if (Test-Path -LiteralPath $TempXmlPath) {
        Remove-Item -LiteralPath $TempXmlPath -Force
    }
}

# 6. Wait briefly for association and DHCP, then verify connection status
Start-Sleep -Seconds 3
Write-Host "`nVerifying Wi-Fi interface and authentication status..." -ForegroundColor Cyan
netsh wlan show interfaces | Select-String -Pattern "Name|State|SSID|Authentication|Cipher|Signal"
