#Requires -RunAsAdministrator

# Close Notepad++ if running so it does not overwrite config.xml on exit
Get-Process -Name "notepad++" -ErrorAction SilentlyContinue | Stop-Process -Force

$ConfigDir  = "$env:APPDATA\Notepad++"
$ConfigFile = "$ConfigDir\config.xml"

# Ensure the config directory exists
if (-not (Test-Path $ConfigDir)) {
    New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
}

# If Notepad++ has never been launched yet, initialize config.xml with a minimal valid structure
if (-not (Test-Path $ConfigFile)) {
    @"
<?xml version="1.0" encoding="UTF-8" ?>
<NotepadPlus>
    <GUIConfigs>
        <GUIConfig name="RememberLastSession">no</GUIConfig>
    </GUIConfigs>
</NotepadPlus>
"@ | Set-Content -Path $ConfigFile -Encoding UTF8
    Write-Host "Created config.xml with RememberLastSession set to 'no'." -ForegroundColor Green
} else {
    # Load existing XML, update or add the RememberLastSession node, and save
    [xml]$Xml = Get-Content -Path $ConfigFile
    $Node = $Xml.SelectSingleNode("//GUIConfig[@name='RememberLastSession']")

    if ($Node) {
        $Node.InnerText = "no"
    } else {
        $NewNode = $Xml.CreateElement("GUIConfig")
        $NewNode.SetAttribute("name", "RememberLastSession")
        $NewNode.InnerText = "no"
        $Xml.NotepadPlus.GUIConfigs.AppendChild($NewNode) | Out-Null
    }

    $Xml.Save($ConfigFile)
    Write-Host "Updated existing config.xml: RememberLastSession set to 'no'." -ForegroundColor Green
}

# Optional: Remove any saved session.xml so existing tabs don't linger
$SessionFile = "$ConfigDir\session.xml"
if (Test-Path $SessionFile) {
    Remove-Item -Path $SessionFile -Force
}
