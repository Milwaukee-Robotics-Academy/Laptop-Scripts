#Requires -RunAsAdministrator

Write-Host "Starting System Reset and Configuration..." -ForegroundColor Cyan



# Remove Unwanted Apps (via Winget)
    . "$PSScriptRoot\remove-unwanted-apps.ps1"

# Install Standard Apps (via Winget)
    . "$PSScriptRoot\install-base-apps.ps1"

# Set Angry IP Scanner default settings
    . "$PSScriptRoot\angry-ip-scanner-default-settings.ps1"

# Notepad++ Configuration
    . "$PSScriptRoot\notepadplusplus-dont-remember-last-session.ps1"

Write-Host "Tasks complete. A system restart is recommended to finalize network resets." -ForegroundColor Green
# Uncomment the line below to force an automatic reboot
# Restart-Computer -Force