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
Get-ChildItem -Path .\DEPLOYABLE\ -Filter *.intune | Remove-Item -Force -ErrorAction SilentlyContinue

$WINGET_MANAGED_PACKAGES | ForEach-Object {
    $APPID = $_
    IntuneWinAppUtil.exe -c .\src\ -s .\src\Winget-Updatr.ps1 -o ".\DEPLOYABLE\$APPID-Winget-Updatr-$TIMESTAMP.intune"
    Write-Output 'Install command:  '
    $INSTALL_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr.ps1' + " -APPID '--id $APPID' -OPERATION 'install' -ARGS '-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -NOTIFICATION_URL '$NOTIFICATION_URL'" -replace '  ', ' ' -replace "`r`n", ' '
    Write-Output $INSTALL_STRING
    Write-Output 'Uninstall command:  '
    $UNINSTALL_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr.ps1' + " -APPID '--id $APPID' -OPERATION 'uninstall' -ARGS '-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -NOTIFICATION_URL '$NOTIFICATION_URL'" -replace '  ', ' ' -replace "`r`n", ' '
    Write-Output $UNINSTALL_STRING
    Write-Output 'Detect command:  '
    $DETECT_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr-Detect.ps1' + " -APPID '$APPID' -NOTIFICATION_URL '$NOTIFICATION_URL'" -replace '  ', ' ' -replace "`r`n", ' '
    Write-Output $DETECT_STRING
}