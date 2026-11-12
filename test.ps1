#Requires -RunAsAdministrator

Write-Host "Starting System Reset and Configuration..." -ForegroundColor Cyan



# 3. Remove Unwanted Programs (via Winget)
Write-Host "Removing specified programs..." -ForegroundColor Yellow
$appsToRemove = @(
    #"Zoom.Zoom",
    "Spotify.Spotify"
    # Example: "Zoom.Zoom", "Spotify.Spotify"
)
foreach ($app in $appsToRemove) {
    winget uninstall --id $app --silent --accept-source-agreements
}

# 4. Install Standard Programs (via Winget)
#Write-Host "Installing required programs..." -ForegroundColor Yellow
#$appsToInstall = @(
#    "Google.Chrome",
#    "WiresharkFoundation.Wireshark",  # Packet capture for FMS/radio/Systemcore debugging
#    "PuTTY.PuTTY",                    # SSH/Serial console access to Systemcore
#    "Git.Git",                        # Required for WPILib project version control
#    "7zip.7zip",                      # Archive & log extraction
#    "Notepad++.Notepad++",            # Quick log & JSON config inspection
#    "AngryIPScanner.AngryIPScanner"   # Fast subnet scanning for 10.TE.AM.x devices
    # Example: "Google.Chrome", "7zip.7zip"
#)
#foreach ($app in $appsToInstall) {
#    winget install --id $app --silent --accept-package-agreements --accept-source-agreements
#}

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
    New-ItemProperty -Path $RegPath -Name $Key -Value $Preferences[$Key] -PropertyType String -Force 
}
Write-Host "Angry IP Scanner CSA preferences applied successfully." -ForegroundColor Green

$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$InstalledSoftware = Get-ItemProperty -Path $RegistryPaths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName -Unique

# Display results in a readable table
$InstalledSoftware | Format-Table -AutoSize
# 1. Remove Modern / Preinstalled OEM Office & Default Microsoft Store Apps (Appx)
Write-Host "Removing preinstalled Microsoft Store (Appx) apps..." -ForegroundColor Cyan
$AppxPatterns = @(
    "*Microsoft.Office*",
    "*Microsoft.MicrosoftOfficeHub*",
    "*Microsoft.Office.OneNote*",
    "*Microsoft.OneDriveSync*",
    "*Microsoft.Todos*",
    "*Microsoft.OutlookForWindows*",
    "*Microsoft.Copilot*",
    "*Microsoft.Teams*",
    "*MSTeams*",
    "*Clipchamp.Clipchamp*",
    "*Microsoft.BingNews*",
    "*Microsoft.BingWeather*",
    "*Microsoft.GetHelp*",
    "*Microsoft.Getstarted*",
    "*Microsoft.WindowsFeedbackHub*",
    "*Microsoft.YourPhone*",
    "*Microsoft.ZuneMusic*",
    "*Microsoft.ZuneVideo*",
	"*MicrosoftSolitaireCollection*"
)

foreach ($Pattern in $AppxPatterns) {
    # Remove for all existing users
    Get-AppxPackage -AllUsers -Name $Pattern -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Removing AppxPackage: $($_.Name)" -ForegroundColor Yellow
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
    # Remove provisioned packages so they do not reinstall for new users
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $Pattern } | ForEach-Object {
        Write-Host "Removing Provisioned Package: $($_.PackageName)" -ForegroundColor Yellow
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
}

# 2. Remove Click-to-Run (Microsoft 365, Office 2016, 2019, 2021, 2024)
Write-Host "Checking for Click-to-Run Office installations..." -ForegroundColor Cyan
$C2RPaths = @(
    "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe",
    "${env:ProgramFiles(x86)}\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
)

$UninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$OfficeInstalls = Get-ItemProperty $UninstallKeys -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -match "Microsoft 365|Microsoft Office|Office 16 Click-to-Run|OneNote|Visio|Project" -and
    $_.DisplayName -notmatch "Visual C\+\+|SQL|Database Engine"
}

foreach ($App in $OfficeInstalls) {
    Write-Host "Found desktop installation: $($App.DisplayName)" -ForegroundColor Yellow
    $UninstallString = $App.UninstallString

    if ($UninstallString -match "OfficeClickToRun\.exe") {
        # Append silent flags for Click-to-Run
        $CleanArgs = ($UninstallString -split "\.exe")[1].Trim() + " displaylevel=false forceappshutdown=true"
        $ExePath = ($UninstallString -split "\.exe")[0].Trim('"') + ".exe"
        Start-Process -FilePath $ExePath -ArgumentList $CleanArgs -Wait -NoNewWindow
    }
    elseif ($UninstallString -match "msiexec\.exe") {
        # Extract GUID and run silent MSI uninstall
        if ($UninstallString -match "\{[0-9A-Fa-f\-]+\}") {
            $Guid = $Matches[0]
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $Guid /qn /norestart" -Wait -NoNewWindow
        }
    }
    elseif ($UninstallString) {
        # Fallback for other standard uninstallers
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$UninstallString`" /quiet /norestart" -Wait -NoNewWindow
    }
}

Write-Host "Tasks complete. A system restart is recommended to finalize network resets." -ForegroundColor Green
# Uncomment the line below to force an automatic reboot
# Restart-Computer -Force