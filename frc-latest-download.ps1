<#
.SYNOPSIS
    Downloads the latest FRC software installers (WPILib, Driver Station) from GitHub Releases.

.DESCRIPTION
    Queries the GitHub Releases API for specified repositories (supporting pre-releases/betas),
    resolves asset URLs (from direct release assets or release notes markdown links), prepares
    the target download directory, and downloads each installer using curl.exe.

.PARAMETER DownloadDir
    The destination directory where installer files (*.iso, *.exe) will be saved.
    Defaults to 'C:\FRC_Latest_Installers'.

.PARAMETER IncludePrereleases
    Whether to include pre-release or beta builds when querying GitHub for the latest release.
    Defaults to $true.

.EXAMPLE
    .\frc-latest-download.ps1

.EXAMPLE
    .\frc-latest-download.ps1 -DownloadDir "D:\FRC_Latest_Installers" -IncludePrereleases $false
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DownloadDir = "C:\FRC_Latest_Installers",

    [Parameter(Mandatory = $false)]
    [bool]$IncludePrereleases = $true
)

# Stop execution immediately if a critical command fails
$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Starting Latest FRC Software Installer Download                 " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan


# ==============================================================================
# SECTION 1: Package Definitions & Network Configuration
# ==============================================================================

# Define packages to download (repository, asset matching pattern, and output filename).
# Additional vendor tools or utilities can be added by appending a new hashtable to this array.
$Packages = @(
    @{
        Name         = "WPILib"
        Repo         = "wpilibsuite/allwpilib"
        AssetPattern = "*Windows-x64*.iso"
        FileName     = "wpilibsuite-allwpilib-Windows-x64.iso"
    },
    @{
        Name         = "FRC Driver Station"
        Repo         = "wpilibsuite/FirstDriverStation-Public"
        AssetPattern = "*win-x64*.exe"
        FileName     = "FirstDriverStation-win-x64.exe"
    }
)

# Ensure TLS 1.2 is enabled for GitHub API connections on Windows PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Standard headers required by the GitHub REST API
$Headers = @{ 
    "User-Agent" = "FRC-Setup-Script"
}


# ==============================================================================
# SECTION 2: Helper Functions
# ==============================================================================

<#
.SYNOPSIS
    Retrieves the latest release object for a GitHub repository.
#>
function Get-GitHubRelease {
    param (
        [string]$Repo,
        [bool]$IncludePrereleases = $false,
        [hashtable]$Headers = @{}
    )

    if ($IncludePrereleases) {
        # Fetch list of releases and take the first entry (includes betas and pre-releases)
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Headers $Headers
        return ($releases | Select-Object -First 1)
    } else {
        # Fetch only the official latest stable release
        return (Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers)
    }
}

<#
.SYNOPSIS
    Extracts an asset download URL matching a wildcard pattern from a release.
    Checks direct GitHub release assets first, then falls back to markdown links in the body.
#>
function Get-ReleaseAssetUrl {
    param (
        [psobject]$Release,
        [string]$AssetPattern
    )

    # 1. Check direct release assets (standard GitHub release assets, e.g. Driver Station .exe)
    if ($Release.assets) {
        $asset = $Release.assets | Where-Object { 
            $_.name -like $AssetPattern -or $_.browser_download_url -like $AssetPattern 
        } | Select-Object -First 1
        
        if ($asset -and $asset.browser_download_url) {
            return $asset.browser_download_url
        }
    }

    # 2. Check markdown links in release notes body (common for large files exceeding GitHub's direct upload limits, e.g. WPILib .iso)
    if ($Release.body) {
        $markdownLinks = [regex]::Matches($Release.body, '\[([^\]]+)\]\((https?://[^\)]+)\)') | ForEach-Object {
            [PSCustomObject]@{
                Label = $_.Groups[1].Value
                Url   = $_.Groups[2].Value
            }
        }
        $match = $markdownLinks | Where-Object { 
            $_.Url -like $AssetPattern -or $_.Label -like $AssetPattern 
        } | Select-Object -First 1
        
        if ($match) {
            return $match.Url
        }
    }

    return $null
}


# ==============================================================================
# SECTION 3: Prepare Download Directory
# ==============================================================================
Write-Host "`nPreparing download directory: $DownloadDir ..." -ForegroundColor Yellow
if (-not (Test-Path -Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
    Write-Host "Created download directory $DownloadDir." -ForegroundColor Green
} else {
    Write-Host "Download directory $DownloadDir already exists." -ForegroundColor Gray
}


# ==============================================================================
# SECTION 4: Package Download Execution
# ==============================================================================
$downloadedCount = 0

foreach ($pkg in $Packages) {
    Write-Host "`n-----------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "Checking latest release for $($pkg.Name) ($($pkg.Repo))..." -ForegroundColor Cyan
    
    $release = Get-GitHubRelease -Repo $pkg.Repo -IncludePrereleases $IncludePrereleases -Headers $Headers

    if (-not $release) {
        Write-Warning "Could not retrieve release info for '$($pkg.Repo)'."
        continue
    }

    $releaseTag = if ($release.tag_name) { $release.tag_name } else { "latest" }
    Write-Host "  -> Found release tag: $releaseTag" -ForegroundColor Gray

    $downloadUrl = Get-ReleaseAssetUrl -Release $release -AssetPattern $pkg.AssetPattern

    if ($downloadUrl) {
        Write-Host "  -> Asset URL found: $downloadUrl" -ForegroundColor Gray
        $outFile = Join-Path $DownloadDir $pkg.FileName
        
        Write-Host "  -> Downloading $($pkg.FileName) ..." -ForegroundColor Yellow
        curl.exe -L --noproxy "*" -o $outFile $downloadUrl
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path -Path $outFile)) {
            Write-Host "  -> Download complete: $outFile" -ForegroundColor Green
            $downloadedCount++
        } else {
            Write-Warning "Download may have failed for '$($pkg.FileName)' (exit code: $LASTEXITCODE)."
        }
    } else {
        Write-Warning "No matching asset found for '$($pkg.Name)' with pattern '$($pkg.AssetPattern)'."
    }
}


# ==============================================================================
# Completion Summary
# ==============================================================================
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " Download Summary: $downloadedCount of $($Packages.Count) package(s) downloaded." -ForegroundColor Green
Write-Host " Files saved to: $DownloadDir" -ForegroundColor Cyan
Write-Host " Next step: Run .\frc-latest-install.ps1 to install the downloaded packages." -ForegroundColor Yellow
Write-Host "=================================================================`n" -ForegroundColor Cyan
