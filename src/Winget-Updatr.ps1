param (
    [Parameter(Mandatory = $true, HelpMessage = 'Specifies the App ID.')][ValidateNotNullOrEmpty()]
    [string]$APPID,
    [Parameter(Mandatory = $true, HelpMessage = 'Specifies operation.')][ValidateNotNullOrEmpty()]
    [string]$OPERATION = 'install',
    [Parameter(Mandatory = $true, HelpMessage = 'Specifies arguments for the operation.')][ValidateNotNullOrEmpty()]
    [string]$ARGS,
    [Parameter(Mandatory = $false, HelpMessage = 'Specifies the URL to send notifications to.')][ValidateNotNullOrEmpty()]
    [string]$NOTIFICATION_URL
)
$ErrorActionPreference = 'Stop'; $DebugPreference = 'Continue'
# C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe - 64bit
# C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe - 32bit
##################### RESTART PROCESS USING POWERSHELL 64-BIT #####################
If ($ENV:PROCESSOR_ARCHITECTURE -eq 'x86') {
    Write-Debug 'Restarting process using PowerShell 64-bit'
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit

}
###################################################################################

##################### SCRIPT SPECIFIC VARIABLES ###################################
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss'
# Ensure that APPID_CLEAN is the last ellement if there are spaces in the APPID
$APPID_CLEAN = ($APPID -replace '^(--id|-e)\s+', '').Trim()
$SCRIPT_NAME = "$APPID_CLEAN-Winget_Updatr"
$LOG_PATH = "$($env:HOMEDRIVE)\scripts\logs\"
if (-not (Test-Path $LOG_PATH)) {
    New-Item -ItemType Directory -Path $LOG_PATH -Force
}
$LOG_FILE = $LOG_PATH + $SCRIPT_NAME + '-' + $TIMESTAMP + '.log'
$LAST_SUCCESS_FLAG_FILE = $LOG_PATH + "$SCRIPT_NAME.flag"
. "$PSScriptRoot\Winget-Notifyr.ps1"
###################################################################################

##################### FUNCTION TO GET VERSION TAG FROM GITHUB RELEASES PAGES ######
function Get-GitHubReleaseVersion {
    param (
        [Parameter(Mandatory = $false, HelpMessage = 'Specifies the GitHub repository - e.g.: microsoft/winget-cli.')][ValidateNotNullOrEmpty()]
        [string]$repo = 'microsoft/winget-cli'
    )
    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{ 'Accept' = 'application/vnd.github.v3+json' }
        $latestTag = $response.tag_name
        Write-Debug "Latest WinGet release tag: $latestTag"
    }
    catch {
        Write-Debug "Failed to retrieve latest release tag. Error: $_"
    }
    return $latestTag
}

##################### FUNCTION TO UPDATE WINGET ###################################
function Update-Winget {
    $progressPreference = 'SilentlyContinue'
    Write-Debug 'Checking if WinGet is installed...'

    # Check if winget is installed
    $ResolveWingetPath = Resolve-Path "$($env:ProgramFiles)\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
    $winget_Path = $ResolveWingetPath[-1].Path
    if ((Test-Path $winget_Path) -and (Test-Path "$winget_Path\winget.exe")) {
        Write-Debug "WinGet is installed at $winget_Path"
        return "$winget_Path\winget.exe"
    }
    elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Debug 'WinGet is installed.'
        $winget_Path = (Get-Command winget).Source
        return $winget_Path
    }
    else {
        Write-Debug 'Checking for Microsoft.DesktopAppInstaller...'
        $package = Get-AppxPackage -Name Microsoft.DesktopAppInstaller
        if (-not $package) {
            Write-Debug "$($package.Name) not found. Installing $($package.Name)..."
            Start-Process 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1' -NoNewWindow -Wait
        }
        else {
            Write-Debug "App Installer is already installed. Version: $($package.Version)"
        }
        Write-Debug 'Validating WinGet installation...'
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Debug 'WinGet successfully installed and updated.'
            return (Get-Command winget).Source
        }
        else {
            Write-Debug 'Something is broken. WinGet is not installed or usable.. and script cannot proceed.'
            return $false
        }
    }
}
##################### INVOKE WINGET COMMAND #######################################
function Invoke-WingetCommand {
    param (
        [string]$winget_executable,
        [string]$operation,
        [string]$winget_args,
        [string]$tempOutputFile,
        [string]$tempErrorFile
    )

    # Override ErrorActionPreference within this function scope
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $DebugPreference = 'Continue'

    try {
        $TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss'

        # Run Winget process and capture exit code
        $winget_process = Start-Process -FilePath $winget_executable -ArgumentList "$operation $winget_args" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $tempOutputFile -RedirectStandardError $tempErrorFile  

        $exitCode = $winget_process.ExitCode
        #Write-Debug "WinGet exited with code: $exitCode"

    }
    catch {
        # Allowable exit codes
        $allowedExitCodes = @(0, 1638, 0xA)  # 1638 = Already Installed, 0xA = No Upgrade Found
        if ($exitCode -ne 0 -and $exitCode -notin $allowedExitCodes) {
            Write-Error "An error occurred while running WinGet: $_"
            Get-Content -Path $tempErrorFile | Write-Debug
            Get-Content -Path $tempOutputFile | Write-Debug
            throw "WinGet command failed. See logs: $LOG_FILE"
            throw "WinGet command failed. Exit Code: $exitCode. See logs: Output -> $tempOutputFile, Error -> $tempErrorFile"
        }
        else {
            Write-Debug "$exitCode is an allowable exit code - [Already Installed, No upgrade found]. Continuing..."
            Write-Debug "Completed winget $operation $APPID_CLEAN successfully at $TIMESTAMP"
            Write-Output "$TIMESTAMP - $APPID_CLEAN - SUCCESS" | Out-File -FilePath $LAST_SUCCESS_FLAG_FILE -Force
        }
    }
    finally {
        Write-Output "$TIMESTAMP - $APPID_CLEAN - SUCCESS" | Out-File -FilePath $LAST_SUCCESS_FLAG_FILE -Force
        $OUTPUT = Get-Content -Path $tempOutputFile 
        $ERRORS = Get-Content -Path $tempErrorFile
        Write-Debug '############### Output: '
        # Exclude non-printable characters
        $OUTPUT | ForEach-Object { $_ -replace '[^\x20-\x7e]', '' } | Write-Debug 
        Write-Debug '############### Errors: '
        $ERRORS | ForEach-Object { $_ -replace '[^\x20-\x7e]', '' } | Write-Debug
        Write-Debug '###############'
        # Restore original ErrorActionPreference to avoid breaking other parts of the script
        $ErrorActionPreference = $previousErrorAction
    }
}
#################################### MAIN #####################################
## Check if the log path exists, if not, create it
#    [Parameter(Mandatory = $true, HelpMessage = 'Specifies the App ID.')][ValidateNotNullOrEmpty()]
#    [string]$APPID,
#    [Parameter(Mandatory = $true, HelpMessage = 'Specifies operation.')][ValidateNotNullOrEmpty()]
#    [string]$OPERATION = 'update',
#    [Parameter(Mandatory = $true, HelpMessage = 'Specifies arguments for the operation.')][ValidateNotNullOrEmpty()]
#    [string]$ARGS

Start-Transcript -Append $LOG_FILE
$PRIMARY_USER = (Get-WmiObject -Class Win32_ComputerSystem).UserName -replace '.*\\', ''
$CLIENT_IP = (Invoke-WebRequest -Uri 'https://ifconfig.io' -ErrorAction SilentlyContinue).Content.Trim()
try {
    Write-Debug 'Ensuring winget is up-to-date...'
    # C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.24.25200.0_x64__8wekyb3d8bbwe C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.24.25200.0_x64__8wekyb3d8bbwe\winget.exe
    $WINGET_EXE = Update-Winget
    # 
    Write-Debug "Gut, Winget is up-to-date at $WINGET_EXE"
}
catch {
    Write-Debug 'ERROR: WINGET UPDATE FAILED'
    Write-Debug 'Failed to run Update-Winget'
    Write-Debug $_
    Stop-Transcript
    if ($NOTIFICATION_URL) {
        Send-TeamsNotification -outcome_message 'Failed' -client_ip "$ENV:COMPUTERNAME" -script_name $SCRIPT_NAME -log_file "$LOG_FILE" -notify_url $NOTIFICATION_URL
    }
    Write-Error 'Failed to run Update-Winget. Exiting...'
    exit 1
}   
Write-Debug "Running $SCRIPT_NAME with arguments at ${TIMESTAMP}:"
Write-Debug "APPID: $APPID [$APPID_CLEAN]"
Write-Debug "OPERATION: $OPERATION"
Write-Debug "ARGS: $ARGS"
try {
    Write-Debug "Resolved winget.exe path: $WINGET_EXE"

    # Run winget command with supplied arguments and ensure the output including errors are captured to the transcript
    $tempOutputFile = "$LOG_PATH\$SCRIPT_NAME-$TIMESTAMP.out"
    $tempErrorFile = "$LOG_PATH\$SCRIPT_NAME-$TIMESTAMP.err"
    $WINGET_ARGS = "$APPID $ARGS"
    Write-Debug "Running $WINGET_EXE with arguments: "
    #$WINGET_ARGS | Write-Debug
    Invoke-WingetCommand -winget_executable $WINGET_EXE -operation $OPERATION -winget_args $WINGET_ARGS -tempOutputFile $tempOutputFile -tempErrorFile $tempErrorFile
}
catch {
    Write-Debug "Failed to run $exe_to_run with arguments: $winget_list_args"
    Write-Debug $_
    Stop-Transcript
    if ($NOTIFICATION_URL) {
        Send-TeamsNotification -outcome_message 'Failed' -script_name $SCRIPT_NAME -log_file "$LOG_FILE" -notify_url $NOTIFICATION_URL
    }
    exit 1
}
finally {
    Remove-Item -Path $tempOutputFile -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempErrorFile -Force -ErrorAction SilentlyContinue
}
# Clean up all but last 5 log files
$files = Get-ChildItem -Path $LOG_PATH -Filter "$SCRIPT_NAME-*.log" | Sort-Object -Property LastWriteTime -Descending
if ($files.Count -gt 5) {
    $files | Select-Object -Skip 5 | Remove-Item -Force
}
Stop-Transcript
# Send a success notification
if ($NOTIFICATION_URL) {
    Send-TeamsNotification -primary_username $PRIMARY_USER -outcome_message 'Success' -client_ip $CLIENT_IP -device_name $env:COMPUTERNAME -timestamp $TIMESTAMP -script_name $SCRIPT_NAME -log_file "$LOG_FILE" -notify_url $NOTIFICATION_URL
}
###################################################################################