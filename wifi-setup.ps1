#Requires -RunAsAdministrator

$defaultSSID = 'Doublee'
$defaultPassword = '1010101010'

$ssidInput = Read-Host "Wi-Fi SSID [$defaultSSID]"
$ssid = if ([string]::IsNullOrWhiteSpace($ssidInput)) { $defaultSSID } else { $ssidInput.Trim() }

$securePassword = Read-Host 'Wi-Fi password (press Enter for default)' -AsSecureString
if ($securePassword.Length -eq 0) {
		$password = $defaultPassword
} else {
		$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
		try {
				$password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
		} finally {
				[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
		}
}

$escapedSSID = [Security.SecurityElement]::Escape($ssid)
$escapedPassword = [Security.SecurityElement]::Escape($password)
$profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>$escapedSSID</name>
	<SSIDConfig><SSID><name>$escapedSSID</name></SSID></SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<MSM><security>
		<authEncryption>
			<authentication>WPA3SAE</authentication>
			<encryption>AES</encryption>
			<useOneX>false</useOneX>
		</authEncryption>
		<sharedKey>
			<keyType>passPhrase</keyType>
			<protected>false</protected>
			<keyMaterial>$escapedPassword</keyMaterial>
		</sharedKey>
	</security></MSM>
</WLANProfile>
"@

$profilePath = Join-Path $env:TEMP ("wifi-{0}.xml" -f [guid]::NewGuid())
try {
		[IO.File]::WriteAllText($profilePath, $profileXml, [Text.UTF8Encoding]::new($false))
        & netsh.exe wlan show profile "name=$ssid" *> $null
if ($LASTEXITCODE -ne 0) {
		& netsh.exe wlan add profile "filename=$profilePath" user=current
		if ($LASTEXITCODE -ne 0) { throw 'Failed to add the WPA3-Personal Wi-Fi profile.' }
}

#		& netsh.exe wlan connect "name=$ssid" "ssid=$ssid"
#		if ($LASTEXITCODE -ne 0) { throw 'Failed to start the Wi-Fi connection.' }
#        Start-Sleep -Seconds 3
#        $connection = Get-NetConnectionProfile | Where-Object { $_.Name -eq $ssid }
#        if (-not $connection) { throw "Could not find the connected Wi-Fi network '$ssid'." }
#        $connection | Set-NetConnectionProfile -NetworkCategory Public
Write-Host "Wi-Fi setup complete!" -ForegroundColor Green
} finally {
		Remove-Item -LiteralPath $profilePath -Force -ErrorAction SilentlyContinue
		$password = $null
		$escapedPassword = $null
		$profileXml = $null
}
