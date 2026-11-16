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

#Requires -Version 5.1
[CmdletBinding()]
param (
    [Alias("Help", "h", "?")]
    [switch]$Info,

    [string]$DownloadDir = ("C:\FRC_2027_Downloads")
)

# If -Info (or -Help) is passed, display the comment-based help and exit without running downloads
if ($Info) {
    Get-Help -Name $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

$ErrorActionPreference = "Stop"

# 1. Configure destination folder
if (-not (Test-Path -Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir | Out-Null
}

# GitHub API requires a User-Agent header
$Headers = @{ "User-Agent" = "FRC-2027-Downloader" }

# Helper function to query GitHub Releases (including pre-releases) and download matching Windows assets
function Get-LatestFrc2027Asset {
    param (
        [string]$Repo,
        [string]$AssetPattern,
        [string]$Label
    )

    Write-Host "Checking $Repo for latest 2027 $Label..." -ForegroundColor Cyan
    $ApiUrl = "https://://github.com/repos/$Repo/releases"
    
    # Fetch releases and filter for 2027 tags (catches both pre-release alphas/betas and final kickoff releases)
    $Releases = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers
    $TargetRelease = $Releases | Where-Object { $_.tag_name -match "2027" } | Select-Object -First 1

    if (-not $TargetRelease) {
        Write-Warning "No 2027 release found in $Repo."
        return
    }

    $Asset = $TargetRelease.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1

    if (-not $Asset) {
        Write-Warning "No asset matching '$AssetPattern' found in release $($TargetRelease.tag_name)."
        return
    }

    $OutFile = Join-Path -Path $DownloadDir -ChildPath $Asset.name
    Write-Host "Found $($TargetRelease.tag_name): Downloading $($Asset.name) ($([math]::Round($Asset.size / 1MB, 1)) MB)..." -ForegroundColor Green

    # Use WebClient for faster downloads on large ISO/EXE files compared to Invoke-WebRequest
    $WebClient = New-Object System.Net.WebClient
    $WebClient.Headers.Add("User-Agent", "FRC-2027-Downloader")
    $WebClient.DownloadFile($Asset.browser_download_url, $OutFile)
    $WebClient.Dispose()

    Write-Host "Saved to: $OutFile`n" -ForegroundColor Gray
}

# 2. Download WPILib 2027 Windows Installer
Get-LatestFrc2027Asset -Repo "wpilibsuite/allwpilib" -AssetPattern "Windows.*\.iso$" -Label "WPILib Suite"

# 3. Download 2027 FIRST Driver Station Windows Installer
Get-LatestFrc2027Asset -Repo "wpilibsuite/FirstDriverStation-Public" -AssetPattern "\.exe$" -Label "FIRST Driver Station"

Write-Host "All downloads complete! Files are located in: $DownloadDir" -ForegroundColor Yellow
