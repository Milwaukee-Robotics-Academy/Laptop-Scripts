#Set up our default parameters

$WPILIB_REPO = "wpilibsuite/allwpilib"
$WPILIB_ASSET_PATTERN = "*Windows-x64*.iso"
$WPILIB_ASSET_NAME = "wpilibsuite-allwpilib-Windows-x64.iso"
$FRC_DS_REPO = "wpilibsuite/FirstDriverStation-Public"
$FRC_DS_ASSET_PATTERN = "*win-x64*.exe"
$FRC_DS_ASSET_NAME = "FirstDriverStation-win-x64.exe"
$DownloadDir = "c:\FRC2027_Installers"
$INCLUDE_PRERELEASES = $true


#set headers for GitHub API request
$Headers = @{ 
    "User-Agent" = "FRC-Setup-Script"
#    "Accept"     = "application/vnd.github+json"
} 
 
#get the latest release information from the GitHub API
if ($INCLUDE_PRERELEASES) {
    $WPILibReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/$WPILIB_REPO/releases" -Headers $Headers
    $WPILibRelease = $WPILibReleases | Select-Object -First 1
} else {
    $WPILibRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$WPILIB_REPO/releases/latest" -Headers $Headers
}

#pull all the links from the release body using regex for the assets
$WPILibLinks = [regex]::Matches($WPILibRelease.body, '\[([^\]]+)\]\((https?://[^\)]+)\)') | ForEach-Object {
    [PSCustomObject]@{
        Label = $_.Groups[1].Value
        Url   = $_.Groups[2].Value
    }
}

# Filter for the specific installer you want (e.g., Windows x64)
$myWPILibLink = $WPILibLinks | Where-Object {$_.Url -like $WPILIB_ASSET_PATTERN }| Select-Object -ExpandProperty Url -First 1
$myWPILibLinkName = $WPILibLinks | Where-Object {$_.Url -like $WPILIB_ASSET_PATTERN }| Select-Object -ExpandProperty Label -First 1

Write-Host "$myWPILibLink" -ForegroundColor Green
 

# Get DS 
#get the latest release information from the GitHub API
if ($INCLUDE_PRERELEASES) {
    $FRC_DS_Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$FRC_DS_REPO/releases" -Headers $Headers
    $FRC_DS_Release = $FRC_DS_Releases | Select-Object -First 1
} else {
    $FRC_DS_Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$FRC_DS_REPO/releases/latest" -Headers $Headers
}
#Write-Host "Checking latest release for $FRC_DS_REPO..." -ForegroundColor Cyan
$FRC_DS_Release = $FRC_DS_Releases | Select-Object -First 1

#$myDSLink = $FRC_DS_Release.assets | Where-Object { $_.name -like $FRC_DS_ASSET_PATTERN } | Select-Object -ExpandProperty url -First 1
$DSDownloadUrl = $FRC_DS_Release.assets | Where-Object { $_.name -like $FRC_DS_ASSET_PATTERN } | Select-Object -ExpandProperty browser_download_url -First 1
Write-Host "$DSDownloadUrl" -ForegroundColor Green
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Creating download directory $DownloadDir ..." -ForegroundColor Green
if (-not (Test-Path -Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir | Out-Null
    Write-Host "Created download directory $DownloadDir." -ForegroundColor Green
} else {
    Write-Host "Download directory $DownloadDir already exists." -ForegroundColor Yellow
}

write-Host "Downloading $($FRC_DS_ASSET_NAME) ..." -ForegroundColor Green
   
if ($DSDownloadUrl) {
    $OutFile = Join-Path $DownloadDir $FRC_DS_ASSET_NAME
    Write-Host "Downloading $($FRC_DS_ASSET_NAME) ..." -ForegroundColor Green
    #   Invoke-WebRequest -Uri $myDSLink -OutFile $OutFile
    curl.exe -L --noproxy "*" -o $OutFile $DSDownloadUrl
    #write-host "curl.exe --noproxy "*" -o $OutFile $DSDownloadUrl"
    Write-Host "Downloaded $($FRC_DS_ASSET_NAME) to $OutFile" -ForegroundColor Green
} else {
    Write-Warning "No matching asset found for '$DSDownloadUrl'."
}

write-Host "Downloading $($WPILIB_ASSET_NAME) ..." -ForegroundColor Green
if ($myWPILibLink) {
    $OutFile = Join-Path $DownloadDir $WPILIB_ASSET_NAME
    Write-Host "Downloading $($WPILIB_ASSET_NAME) ..." -ForegroundColor Green
    #   Invoke-WebRequest -Uri $myWPILibLink -OutFile $OutFile
    curl.exe -L --noproxy "*" -o $OutFile $myWPILibLink
    Write-Host "Downloaded $($WPILIB_ASSET_NAME) to $OutFile" -ForegroundColor Green
} else {
    Write-Warning "No matching asset found for '$myWPILibLink'."
}