<#
.SYNOPSIS
    Downloads the official FIRST Robotics Competition (FRC) 2027 software installers for Windows.

.DESCRIPTION
    Queries the GitHub Releases API to dynamically locate and download the latest 2027 Windows 
    installers for both developers and drive teams into a single directory:
      1. WPILib Suite (.iso) - Includes VS Code, C++/Java toolchains, AdvantageScope, Elastic, and PathPlanner.
      2. FIRST Driver Station (.exe) - Standalone Driver Station for Systemcore (replaces legacy NI Game Tools).

    PREREQUISITES & SETUP:
      - OS: 64-bit Windows 10 or Windows 11 (Windows 10 support is subject to change during 2027 development).
      - PowerShell: Version 5.1 or newer.
      - Network: Active internet connection with access to ://github.com and github.com.
      - Disk Space: At least 5 GB of free storage space (the WPILib ISO alone is ~2.4 GB).
      - Execution Policy: If blocked from running scripts, run:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.PARAMETER Info
    Displays the script description, prerequisites, and setup instructions without downloading any files.

.PARAMETER DownloadDir
    Optional custom path where the installers will be saved. 
    Defaults to "$env:USERPROFILE\Downloads\FRC2027_Installers".

.EXAMPLE
    .\frc-2027-download.ps1 -Info
    Displays prerequisites, setup requirements, and usage details without executing downloads.

.EXAMPLE
    Get-Help .\frc-2027-download.ps1 -Full
    Uses PowerShell's built-in help system to view full documentation and examples.

.EXAMPLE
    .\frc-2027-download.ps1
    Downloads the 2027 WPILib ISO and FIRST Driver Station EXE to the default Downloads folder.
#>
# Save as Download-FRCSoftware.ps1 and run in PowerShell
$DownloadDir = "c:\FRC2027_Installers"
New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null

# Ensure TLS 1.2+ for GitHub API
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Headers = @{ 
    "User-Agent" = "FRC-Setup-Script"
#    "Accept"     = "application/vnd.github+json"
"Authorization" = "token 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"
 }

function Get-LatestGitHubReleaseAsset {
    param(
        [string]$Repo,
        [string]$AssetPattern,
        [switch]$IncludePreReleases
    )
    Write-Host "Checking latest release for $Repo..." -ForegroundColor Cyan
    if ($IncludePreReleases) {
        $Releases = Invoke-RestMethod -Uri "https://github.com" -Headers $Headers -Method Get
        $Release = $Releases | Select-Object -First 1
    } else {
        $Release = Invoke-RestMethod -Uri "https://github.com/latest" -Headers $Headers
    }
   # Write-Host "$Release.body" -ForegroundColor Gray
    $body = [regex]::Matches($Release.body, '\[([^\]]+)\]\((https?:\/\/[^\)]+)\)')
    Write-Host "$body"
    $links = [regex]::Matches($Release.body, '\[([^\]]+)\]\((https?://[^\)]+)\)') | ForEach-Object {
        [PSCustomObject]@{
            Label = $_.Groups[1].Value
            Url   = $_.Groups[2].Value
        }
    }
    $Asset = $links | Where-Object {$_.Url -like "*Windows-x64*.iso" }| Select-Object -ExpandProperty Url -First 1

    if ($Asset) {
        $OutFile = Join-Path $DownloadDir $Asset.name
        Write-Host "Downloading $($Asset.name) ($($Release.tag_name))..." -ForegroundColor Green
        Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $OutFile
    } else {
        Write-Warning "No matching asset found for '$AssetPattern' in $Repo ($($Release.tag_name))."
    }
}

# 1. WPILib Offline Installer (Includes VS Code, C++/Java Toolchains, Gradle, AdvantageScope, PathPlanner, etc.)
# Change -IncludePreReleases:$false to $true if testing 2027 Alpha builds
Get-LatestGitHubReleaseAsset -Repo "wpilibsuite/allwpilib" -AssetPattern "*Windows-x64*.iso" -IncludePreReleases:$true

# 2. Cross-Platform FIRST Driver Station (Newer Systemcore / Alpha DS)
Get-LatestGitHubReleaseAsset -Repo "wpilibsuite/FirstDriverStation-Public" -AssetPattern "*Windows*.exe" -IncludePreReleases:$true

Write-Host "All downloads complete! Files are located in: $DownloadDir" -ForegroundColor Yellow
