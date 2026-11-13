# Retrieve all stored credentials, filter for GitHub entries, and delete them
cmdkey.exe /list | Select-String -Pattern "Target:.*github" | ForEach-Object {
    $target = ($_ -replace "^\s*Target:\s*", "").Trim()
    Write-Host "Removing credential: $target" -ForegroundColor Yellow
    cmdkey.exe /delete:$target
}
