$WINGET_MANAGED_PACKAGES = @('Amazon.AWSCLI', '7zip.7zip', 'Microsoft.PowerShell', 'Microsoft.WindowsApp', 'Microsoft.WindowsTerminal', 'Microsoft.VisualStudioCode', 'Python.Python.3.13')
winget install --id Microsoft.Win32ContentPrepTool -e
Write-Debug 'Ensure that you have pulled the latest versio from source'
#Check for changes at origin ahead of packaging
git status
# Commit changes with timestamp and build intunewin package comment
git add .
git commit -m "Updated for packaging - $(Get-Date -Format 'yyyyMMdd_HHmmss')"
git pull
# Package the application
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss'
# Ensure we are in the script directory
Set-Location -Path $PSScriptRoot
$NOTIFICATION_URL = op read 'op://ZOAK/SSG_OSM_WINGET_NOTIFYR_URL/notesPlain'

#Remove any existing intunewin packages in DEPLOYABLE based on the extension
Get-ChildItem -Path .\DEPLOYABLE\ -Folder | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

$WINGET_MANAGED_PACKAGES | ForEach-Object {
    $APPID = $_
    IntuneWinAppUtil.exe -c .\src\ -s .\src\Winget-Updatr.ps1 -o ".\DEPLOYABLE\$APPID-Winget-Updatr-$TIMESTAMP" -q
    # Rename the Winget-Updatr.intunewin to the APPID-Winget-Updatr-TIMESTAMP.intunewin
    $INTUNEWIN_FILE = ".\DEPLOYABLE\$APPID-Winget-Updatr-$TIMESTAMP\Winget-Updatr.intunewin"
    $NEW_INTUNEWIN_FILE = ".\DEPLOYABLE\$APPID-Winget-Updatr-$TIMESTAMP\$APPID-Winget-Updatr-$TIMESTAMP.intunewin"
    Rename-Item -Path $INTUNEWIN_FILE -NewName $NEW_INTUNEWIN_FILE -Force
    $README_FILE = ".\DEPLOYABLE\$APPID-Winget-Updatr-$TIMESTAMP\$APPID-Winget-Updatr-$TIMESTAMP-README.md"
    Write-Output '# Winget-Updatr: ' + $APPID | Out-File -FilePath $README_FILE -Force
    Write-Output '## Install command:' | Out-File -FilePath $README_FILE -Append
    $INSTALL_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr.ps1' + " -APPID '--id $APPID' -OPERATION 'install' -ARGS '-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -NOTIFICATION_URL '$NOTIFICATION_URL'" -replace '  ', ' ' -replace "`r`n", ' '
    Write-Output '```PowerShell' | Out-File -FilePath $README_FILE -Append
    Write-Output $INSTALL_STRING | Out-File -FilePath $README_FILE -Append
    Write-Output '```' | Out-File -FilePath $README_FILE -Append
    Write-Output '## Uninstall command:' | Out-File -FilePath $README_FILE -Append
    Write-Output '```PowerShell' | Out-File -FilePath $README_FILE -Append
    $UNINSTALL_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr.ps1' + " -APPID '--id $APPID' -OPERATION 'uninstall' -ARGS '-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -NOTIFICATION_URL '$NOTIFICATION_URL'" -replace '  ', ' ' -replace "`r`n", ' '
    Write-Output $UNINSTALL_STRING | Out-File -FilePath $README_FILE -Append
    Write-Output '```' | Out-File -FilePath $README_FILE -Append
    Write-Output '## Detect command:' | Out-File -FilePath $README_FILE -Append
    Write-Output '```PowerShell' | Out-File -FilePath $README_FILE -Append
    $DETECT_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr-Detect.ps1' + " -APPID '$APPID' -NOTIFICATION_URL '$NOTIFICATION_URL'" -replace '  ', ' ' -replace "`r`n", ' '
    Write-Output $DETECT_STRING | Out-File -FilePath $README_FILE -Append
    Write-Output '```' | Out-File -FilePath $README_FILE -Append
}

# List the intune packages and their readme files
Get-ChildItem -Path .\DEPLOYABLE\ -Directory | ForEach-Object {
    $INTUNEWIN_FILE = $_.FullName + '\' + $_.Name + '.intunewin'
    $README_FILE = $_.FullName + '\' + $_.Name + '-README.md'
    Write-Output "IntuneWinAppUtil.exe -Info $INTUNEWIN_FILE"
    Write-Output "Get-Content -Path $README_FILE"
}