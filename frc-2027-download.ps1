# Set up default parameters
$DownloadDir = "c:\FRC2027_Installers"
$INCLUDE_PRERELEASES = $true

# Define packages to download (repository, asset matching pattern, and output filename)
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

# Ensure TLS 1.2 is enabled for GitHub API connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set headers for GitHub API requests
$Headers = @{ 
    "User-Agent" = "FRC-Setup-Script"
}

# Function to get the latest GitHub release
function Get-GitHubRelease {
    param (
        [string]$Repo,
        [bool]$IncludePrereleases = $false,
        [hashtable]$Headers = @{}
    )

    if ($IncludePrereleases) {
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Headers $Headers
        return ($releases | Select-Object -First 1)
    } else {
        return (Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers)
    }
}

# Function to extract download URL from GitHub release assets or markdown body links
function Get-ReleaseAssetUrl {
    param (
        [psobject]$Release,
        [string]$AssetPattern
    )

    # 1. Check direct release assets (e.g., Driver Station)
    if ($Release.assets) {
        $asset = $Release.assets | Where-Object { $_.name -like $AssetPattern -or $_.browser_download_url -like $AssetPattern } | Select-Object -First 1
        if ($asset -and $asset.browser_download_url) {
            return $asset.browser_download_url
        }
    }

    # 2. Check markdown links in release notes body (e.g., WPILib large ISO installers)
    if ($Release.body) {
        $markdownLinks = [regex]::Matches($Release.body, '\[([^\]]+)\]\((https?://[^\)]+)\)') | ForEach-Object {
            [PSCustomObject]@{
                Label = $_.Groups[1].Value
                Url   = $_.Groups[2].Value
            }
        }
        $match = $markdownLinks | Where-Object { $_.Url -like $AssetPattern -or $_.Label -like $AssetPattern } | Select-Object -First 1
        if ($match) {
            return $match.Url
        }
    }

    return $null
}

# Ensure download directory exists
Write-Host "Creating download directory $DownloadDir ..." -ForegroundColor Green
if (-not (Test-Path -Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir | Out-Null
    Write-Host "Created download directory $DownloadDir." -ForegroundColor Green
} else {
    Write-Host "Download directory $DownloadDir already exists." -ForegroundColor Yellow
}

# Download each package
foreach ($pkg in $Packages) {
    Write-Host "`nChecking latest release for $($pkg.Name) ($($pkg.Repo))..." -ForegroundColor Cyan
    $release = Get-GitHubRelease -Repo $pkg.Repo -IncludePrereleases $INCLUDE_PRERELEASES -Headers $Headers

    if (-not $release) {
        Write-Warning "Could not retrieve release info for $($pkg.Repo)."
        continue
    }

    $downloadUrl = Get-ReleaseAssetUrl -Release $release -AssetPattern $pkg.AssetPattern

    if ($downloadUrl) {
        Write-Host "Found URL: $downloadUrl" -ForegroundColor Green
        $outFile = Join-Path $DownloadDir $pkg.FileName
        Write-Host "Downloading $($pkg.FileName) ..." -ForegroundColor Green
        curl.exe -L --noproxy "*" -o $outFile $downloadUrl
        Write-Host "Downloaded $($pkg.FileName) to $outFile" -ForegroundColor Green
    } else {
        Write-Warning "No matching asset found for '$($pkg.Name)' with pattern '$($pkg.AssetPattern)'."
    }
}
