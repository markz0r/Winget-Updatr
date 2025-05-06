$WINGET_MANAGED_PACKAGES = @(
    '7zip.7zip',
    'Amazon.AWSCLI',
    'AutoHotkey.AutoHotkey',
    'Microsoft.PowerShell',
    'Microsoft.WindowsApp',
    'Microsoft.WindowsTerminal',
    'Microsoft.VisualStudioCode',
    'Python.Python.3.13',
    'TeamViewer.TeamViewer'
)
winget install --id Microsoft.Win32ContentPrepTool -e
Write-Debug 'Ensure that you have pulled the latest versio from source'
#Check for changes at origin ahead of packaging
git status
## Commit changes with timestamp and build intunewin package comment
#git add .
#git commit -m "Updated for packaging - $(Get-Date -Format 'yyyyMMdd_HHmmss')"
#git pull
## Package the application
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss'
# Ensure we are in the script directory
$WORK_DIR = $PSScriptRoot
Set-Location -Path $WORK_DIR
$NOTIFICATION_URL = op read 'op://ZOAK/SSG_OSM_WINGET_NOTIFYR_URL/notesPlain'
winget install --id=c3er.mdview -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
Get-Command mdview
# Forcefull remove the DEPLOYABLE directory and recreate it, without prompting
Remove-Item -Path .\DEPLOYABLE\ -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path .\DEPLOYABLE\ -Force | Out-Null


$WINGET_MANAGED_PACKAGES | ForEach-Object {
    $APPID = $_
    $TIMESTAMP = Get-Date -Format 'yyyyMMddHHmmss'
    $DEPLOYABLE_PATH = ".\DEPLOYABLE\$APPID-Winget-Updatr-$TIMESTAMP"
    IntuneWinAppUtil.exe -c .\src\ -s .\src\Winget-Updatr.ps1 -o $DEPLOYABLE_PATH -q
    

    # Rename the Winget-Updatr.intunewin to the APPID-Winget-Updatr-TIMESTAMP.intunewin
    $INTUNEWIN_FILE = "$DEPLOYABLE_PATH\Winget-Updatr.intunewin"
    $NEW_INTUNEWIN_FILE = "$DEPLOYABLE_PATH\$APPID-Winget-Updatr-$TIMESTAMP.intunewin"

    if (Test-Path $INTUNEWIN_FILE) {
        Move-Item -Path $INTUNEWIN_FILE -Destination $NEW_INTUNEWIN_FILE -Force
    }
    else {
        Write-Host "Error: $INTUNEWIN_FILE does not exist."
    }
    $README_FILE = "$WORK_DIR\DEPLOYABLE\$APPID-Winget-Updatr-$TIMESTAMP\$APPID-Winget-Updatr-$TIMESTAMP-README.md"
    Write-Output "# Winget-Updatr: $APPID" | Out-File -FilePath $README_FILE -Force
    Write-Output '' | Out-File -FilePath $README_FILE -Append
    $PACKAGE_STRING = '- [' + "$DEPLOYABLE_PATH\$APPID-Winget-Updatr-$TIMESTAMP.intunewin" + '](' + "$DEPLOYABLE_PATH\$APPID-Winget-Updatr-$TIMESTAMP.intunewin)"
    Write-Output $PACKAGE_STRING | Out-File -FilePath $README_FILE -Append
    Write-Output '' | Out-File -FilePath $README_FILE -Append
    Write-Output '## Install command' | Out-File -FilePath $README_FILE -Append
    $INSTALL_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr.ps1' + " -APPID '--id $APPID' -OPERATION 'install' -ARGS '-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -NOTIFICATION_URL '$NOTIFICATION_URL"
    Write-Output '' | Out-File -FilePath $README_FILE -Append
    Write-Output '```PowerShell' | Out-File -FilePath $README_FILE -Append
    Write-Output $INSTALL_STRING | Out-File -FilePath $README_FILE -Append
    Write-Output '```' | Out-File -FilePath $README_FILE -Append
    Write-Output '' | Out-File -FilePath $README_FILE -Append
    Write-Output '## Uninstall command' | Out-File -FilePath $README_FILE -Append
    Write-Output '' | Out-File -FilePath $README_FILE -Append
    Write-Output '```PowerShell' | Out-File -FilePath $README_FILE -Append
    $UNINSTALL_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr.ps1' + " -APPID '--id $APPID' -OPERATION 'uninstall' -ARGS '-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -NOTIFICATION_URL '$NOTIFICATION_URL"
    Write-Output $UNINSTALL_STRING | Out-File -FilePath $README_FILE -Append
    Write-Output '```' | Out-File -FilePath $README_FILE -Append
    Write-Output '' | Out-File -FilePath $README_FILE -Append
    Write-Output '## Detect command' | Out-File -FilePath $README_FILE -Append
    Write-Output '' | Out-File -FilePath $README_FILE -Append
    Write-Output '```PowerShell' | Out-File -FilePath $README_FILE -Append
    $DETECT_STRING = '$APPID = "' + $APPID + '" && powershell -ExecutionPolicy Bypass -File Winget-Updatr-Detect.ps1' + " -APPID '$APPID' -NOTIFICATION_URL '$NOTIFICATION_URL"
    Write-Output $DETECT_STRING | Out-File -FilePath $README_FILE -Append
    Write-Output '```' | Out-File -FilePath $README_FILE -Append
    # Ensure only 1 trailing newline
    (Get-Content -Path $README_FILE -Raw) -replace '\n{2,}', "`n" | Set-Content -Path $README_FILE
}


Write-Host "`n`n`n ################################################ `n`n`n"
# List the intune packages and their readme files
Get-ChildItem -Path .\DEPLOYABLE\ -Directory -Recurse  | Sort-Object -Property Name | ForEach-Object {
    $README_FILE = $_.FullName + '\' + $_.Name + '-README.md'
    mdview $README_FILE
}