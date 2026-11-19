# Define repository URL, target directory, and required module
$PortableGitExe = ".\PortableGit.exe" # Update this path if PortableGit.exe is located elsewhere
$PortableGitDir = ".\PortableGit"
$RepoUrl = "https://github.com/Milwaukee-Robotics-Academy/Laptop-Scripts"
$TargetDir = "C:\Laptop-Scripts"
$ScriptToRun = "create-exes.ps1"
$RequiredModule = "ps2exe"

# Install Portable Git 

# Extract Portable Git if not already extracted
if (-not (Test-Path -Path "$PortableGitDir\cmd\git.exe")) {
    if (Test-Path -Path $PortableGitExe) {
        Write-Host "Extracting Portable Git to $PortableGitDir..." -ForegroundColor Cyan
        # Double backslashes are required by the 7z SFX -InstallPath parameter
        $EscapedInstallPath = $PortableGitDir -replace '\\', '\\'
        $Process = Start-Process -FilePath $PortableGitExe -ArgumentList "-y -gm2 -InstallPath=`"$EscapedInstallPath`"" -Wait -PassThru
        
        if ($Process.ExitCode -ne 0) {
            Write-Error "Failed to extract Portable Git. Exit code: $($Process.ExitCode)"
            exit 1
        }
    }
    else {
        Write-Error "Could not find $PortableGitExe. Please verify the file path."
        exit 1
    }
}
else {
    Write-Host "Portable Git is already extracted at $PortableGitDir." -ForegroundColor Green
}
# Add Portable Git to the current PowerShell session's PATH
if ($env:PATH -notlike "*$PortableGitDir\cmd*") {
    $env:PATH = "$PortableGitDir\cmd;$env:PATH"
}
# Ensure the ps2exe module is installed
if (-not (Get-Module -ListAvailable -Name $RequiredModule)) {
    Write-Host "Module '$RequiredModule' not found. Installing..." -ForegroundColor Yellow
    
    # Ensure NuGet provider is available to prevent interactive prompts
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }

    # Install ps2exe for the current user without confirmation prompts
    Install-Module -Name $RequiredModule -Scope CurrentUser -Force -AllowClobber
    Import-Module -Name $RequiredModule
}
else {
    Write-Host "Module '$RequiredModule' is already installed." -ForegroundColor Green
}

# Check if the directory already exists to avoid git clone errors
if (Test-Path -Path $TargetDir) {
    Write-Warning "Directory $TargetDir already exists. Removing it for a fresh clone..."
    Remove-Item -Path $TargetDir -Recurse -Force
}

# Clone the repository
Write-Host "Cloning repository into $TargetDir..." -ForegroundColor Cyan
git clone -q $RepoUrl $TargetDir

# Verify the clone succeeded before proceeding
if ($LASTEXITCODE -eq 0) {
    # Navigate to the cloned directory
    Set-Location -Path $TargetDir

    # Verify the target script exists and execute it
    if (Test-Path -Path ".\$ScriptToRun") {
        Write-Host "Executing $ScriptToRun..." -ForegroundColor Green
        & ".\$ScriptToRun"
    }
    else {
        Write-Error "Could not find $ScriptToRun inside $TargetDir."
    }
}

