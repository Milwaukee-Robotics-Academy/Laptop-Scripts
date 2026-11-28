Write-Host "=== 1. Installing CSA Diagnostic, Git & Java Utilities via WinGet ===" -ForegroundColor Cyan
$WingetApps = @(
    "WiresharkFoundation.Wireshark",  # Packet capture for FMS/radio/Systemcore debugging
    "PuTTY.PuTTY",                    # SSH/Serial console access to Systemcore
    "Git.Git",                        # Required for WPILib project version control
    "7zip.7zip",                      # Archive & log extraction
    "Notepad++.Notepad++",            # Quick log & JSON config inspection
    "AngryIPScanner.AngryIPScanner",  # Fast subnet scanning for 10.TE.AM.x devices
    "Apple.Bonjour",                  # Bonjour / mDNS discovery
    "Python.Python.3.15",             # Python language
    "mjansen4857.pathplanner",        # Path Planner
    "MechanicalAdvantage.AdvantageScope", # AdvantageScope (FRC developer dashboard for robot telemetry)
    "AgileBits.1Password",             # 1Password
    "Microsoft.PowerToys",            # MS PowerToys (FancyZones, Color Picker, etc. for FRC development)
    "Balena.Etcher",                   # Balena Etcher (USB imaging for Systemcore & VH-109 radios)
    "Microsoft.PowerShell",            # PowerShell 7.x (latest stable)
    "PlummersSoftwareLLC.TMOG"         # taskmanager replacement

)

foreach ($App in $WingetApps) {
    Write-Host "Installing $App..." -ForegroundColor Yellow
    winget install --id $App --silent --accept-source-agreements --accept-package-agreements
}