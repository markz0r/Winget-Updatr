param (
    [Parameter(Mandatory = $true)]
    [string]$APPID,
    [Parameter(Mandatory = $false)]
    [string]$FrequencyInDays = 7,
    [Parameter(Mandatory = $false)]
    [string]$NOTIFICATION_URL

)
##################### SCRIPT SPECIFIC VARIABLES ###################################
#if APPID is prefixed with --.* , set APPID to the value after --.* 
# Get the last element of the split array, whether it is 0,1,2...n
$APPID_CLEAN = ($APPID -replace '^(--id|-e)\s+', '').Trim()
$SCRIPT_NAME = "$APPID_CLEAN-Winget_Updatr"
$LOG_PATH = "$($env:HOMEDRIVE)\scripts\logs\"
if (-not (Test-Path $LOG_PATH)) {
    New-Item -ItemType Directory -Path $LOG_PATH -Force
}
$LAST_SUCCESS_FLAG_FILE = $LOG_PATH + "$SCRIPT_NAME.flag"
. "$PSScriptRoot\Winget-Notifyr.ps1" | Out-Null
###################################################################################
# Check if the file exists
if (Test-Path -Path $LAST_SUCCESS_FLAG_FILE -ErrorAction SilentlyContinue) {
    # Get the last modified date
    $LastModified = (Get-Item $LAST_SUCCESS_FLAG_FILE).LastWriteTime

    # Calculate the threshold date
    $ThresholdDate = (Get-Date).AddDays(-$FrequencyInDays)

    # Check if the file was modified within the frequency period
    try {
        $WingetOutput = winget show $APPID_CLEAN
        $VERSION = ($WingetOutput | Select-String 'Version:\s+(.+)$').Matches.Groups[1].Value.Trim()
        if ($LastModified -ge $ThresholdDate) {
            $SUCCESS_MESSAGE = "OK - $APPID_CLEAN Detected: App: $APPID_CLEAN, Version: $VERSION, last update attempted: $LastModified - No action"
            if ($NOTIFICATION_URL) {
                Send-TeamsNotification -outcome_message $SUCCESS_MESSAGE -script_name "$SCRIPT_NAME-Detect" -notify_url $NOTIFICATION_URL
            }
            exit 0  # Success: File was modified within the timeframe
        }
        else {
            $SUCCESS_MESSAGE = "UPDATE - $APPID_CLEAN Detected: App: $APPID_CLEAN, Version: $VERSION, last update attempted: $LastModified - Update to be attempted"
            if ($NOTIFICATION_URL) {
                Send-TeamsNotification -outcome_message $SUCCESS_MESSAGE -script_name "$SCRIPT_NAME-Detect" -notify_url $NOTIFICATION_URL
            }
            exit 1
        }
    }
    catch {
        $FAIL_OUT_MESSAGE = "UNEXPECTED ERROR: Winget-Updatr-Detect Failed: APPID: $APPID_CLEAN, FrequencyInDays: $FrequencyInDays, error: $_"
        if ($NOTIFICATION_URL) {
            Send-TeamsNotification -outcome_message $FAIL_OUT_MESSAGE -script_name "$SCRIPT_NAME-Detect" -notify_url $NOTIFICATION_URL
        }
        exit 1  # Failure: File not modified within the timeframe
    }
}
else {
    $FAIL_OUT_MESSAGE = "$APPID_CLEAN Not Detected: will attempt to install"
    if ($NOTIFICATION_URL) {
        Send-TeamsNotification -outcome_message $FAIL_OUT_MESSAGE -script_name "$SCRIPT_NAME-Detect" -notify_url $NOTIFICATION_URL
    }
    exit 1  # Failure: File not modified within the timeframe
}