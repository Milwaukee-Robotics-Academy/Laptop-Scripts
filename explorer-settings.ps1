# Registry paths for Explorer settings
$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$cabinetPath  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"

# Show hidden files, folders, and drives (1 = Show, 2 = Don't show)
Set-ItemProperty -Path $advancedPath -Name "Hidden" -Value 1

# Show protected operating system files (1 = Show, 0 = Hide)
Set-ItemProperty -Path $advancedPath -Name "ShowSuperHidden" -Value 1

# Show file extensions for known file types (0 = Show, 1 = Hide)
Set-ItemProperty -Path $advancedPath -Name "HideFileExt" -Value 0

# Show empty drives (0 = Show, 1 = Hide)
Set-ItemProperty -Path $advancedPath -Name "HideDrivesWithNoMedia" -Value 0

# Display the full path in the title bar (1 = Show, 0 = Don't show)
if (!(Test-Path $cabinetPath)) {
    New-Item -Path $cabinetPath -Force | Out-Null
}
Set-ItemProperty -Path $cabinetPath -Name "FullPath" -Value 1

# Restart Windows Explorer to apply the changes immediately
Stop-Process -Name explorer -Force
