# Ensure Angry IP Scanner is not running so it doesn't overwrite registry changes on exit
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
    New-ItemProperty -Path $RegPath -Name $Key -Value $Preferences[$Key] -PropertyType String -Force | Out-Null
}

Write-Host "Angry IP Scanner CSA preferences applied successfully." -ForegroundColor Green