$ErrorActionPreference = 'Stop'

if (-not (Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue)) {
    throw "PS2EXE is not installed. Install it with: Install-Module ps2exe -Scope CurrentUser"
}

$builderPath = [System.IO.Path]::GetFullPath($PSCommandPath)
$scripts = Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1' -File -Recurse |
    Where-Object { [System.IO.Path]::GetFullPath($_.FullName) -ne $builderPath }

foreach ($script in $scripts) {
    $outputPath = [System.IO.Path]::ChangeExtension($script.FullName, '.exe')
    Write-Host "Building $($script.FullName) -> $outputPath"
    Invoke-PS2EXE -InputFile $script.FullName -OutputFile $outputPath
}

Write-Host "Built $($scripts.Count) executable(s)." -ForegroundColor Green