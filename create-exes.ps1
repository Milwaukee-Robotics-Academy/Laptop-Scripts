
<#
.SYNOPSIS
    Compiles all PowerShell scripts in the repository into standalone Windows executables (.exe).

.DESCRIPTION
    Recursively scans the directory containing this script ($PSScriptRoot) for all '.ps1' files,
    excludes this builder script itself to avoid self-compilation, and invokes PS2EXE to compile
    each PowerShell script into a corresponding '.exe' file in the same directory.

.PREREQUISITES
    Requires the PS2EXE PowerShell module. Install it via:
        Install-Module ps2exe -Scope CurrentUser

.EXAMPLE
    .\create-exes.ps1
#>


Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Verify that the PS2EXE module / cmdlet is installed and available in the current session
if (-not (Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue)) {
    throw "PS2EXE is not installed. Install it with: Install-Module ps2exe -Scope CurrentUser"
}

# Resolve the absolute path of this builder script so it can exclude itself from compilation
$builderPath = [System.IO.Path]::GetFullPath($PSCommandPath)

# Find all .ps1 files recursively within the script's root directory, filtering out this builder script
$scripts = Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1' -File -Recurse |
    Where-Object { [System.IO.Path]::GetFullPath($_.FullName) -ne $builderPath }

# Iterate through each discovered script and compile it to an .exe
foreach ($script in $scripts) {
    # Generate the output .exe path by swapping the .ps1 file extension with .exe
    $outputPath = [System.IO.Path]::ChangeExtension($script.FullName, '.exe')
    
    Write-Host "Building $($script.FullName) -> $outputPath"
    
    # Compile the PowerShell script into a standalone executable using PS2EXE
    Invoke-PS2EXE -InputFile $script.FullName -OutputFile $outputPath
}

# Display completion summary
Write-Host "Built $($scripts.Count) executable(s)." -ForegroundColor Green
