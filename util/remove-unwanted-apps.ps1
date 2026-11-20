#Requires -RunAsAdministrator

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
