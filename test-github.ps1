$Headers = @{ 
    "User-Agent" = "FRC-Setup-Script"
#    "Accept"     = "application/vnd.github+json"
    "Authorization" = "token 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"
 } 
 
 $Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/wpilibsuite/allwpilib/releases" -Headers $Headers
 Write-Host "Checking latest release for wpilibsuite/allwpilib..." -ForegroundColor Cyan
 $release = $Releases | Select-Object -First 1
 $testObject = [PSCustomObject]@{
    TagName    = $release.tag_name
    Prerelease = $release.prerelease
    AssetCount = $release.assets.Count
    ZipballUrl = $release.zipball_url
    HtmlUrl    = $release.html_url
}

$links = [regex]::Matches($release.body, '\[([^\]]+)\]\((https?://[^\)]+)\)') | ForEach-Object {
    [PSCustomObject]@{
        Label = $_.Groups[1].Value
        Url   = $_.Groups[2].Value
    }
}

# Filter for the specific installer you want (e.g., Windows x64)
$mylink = $links | Where-Object {$_.Url -like "*Windows-x64*.iso" }| Select-Object -ExpandProperty Url -First 1
 $Asset = $links | Where-Object {$_.Url -like $AssetPattern }| Select-Object -ExpandProperty Url -First 1
Write-Host "$mylink" -ForegroundColor Green
 