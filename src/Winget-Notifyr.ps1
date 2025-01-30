function Send-TeamsNotification {
    param (
        [Parameter(Mandatory = $false)]
        [string]$primary_username = 'Unknown',
        [Parameter(Mandatory = $false)]
        [string]$outcome_message = 'Unknown',
        [Parameter(Mandatory = $false)]
        [string]$client_ip = 'Unknown',
        [Parameter(Mandatory = $false)]
        [string]$device_name = 'Unknown',
        [Parameter(Mandatory = $false)]
        [string]$timestamp = (Get-Date).ToString('yyyyMMdd HHmm_ss'),
        [Parameter(Mandatory = $false)]
        [string]$script_name = 'Unknown',
        [Parameter(Mandatory = $false)]
        [string]$log_file = $false,
        [Parameter(Mandatory = $false)]
        [string]$json_template_file = "$PSScriptRoot\OSM-Winget-NotifyrCard.json",
        [Parameter(Mandatory = $false)]
        [string]$config_url = 'https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/AppsMenu/~/allApps',
        [Parameter(Mandatory = $true)]
        [string]$notify_url 
    )
    # Read the JSON template file and replace the placeholders with the actual values
    $JSON_TITLE = "Winget Notifyr - $script_name"
    $primary_username = (Get-WmiObject -Class Win32_ComputerSystem).UserName -replace '.*\\', ''
    $client_ip = (Invoke-WebRequest -Uri 'https://ifconfig.io' -ErrorAction SilentlyContinue).Content.Trim()
    $device_name = (Get-WmiObject -Class Win32_ComputerSystem).Name
    $timestamp = (Get-Date).ToString('yyyyMMdd HHmm_ss')
    
    # Template placeholders <<REPLACE_ME>>
    # To get a list of all placeholders, run the following command:
    # $fileContent = Get-Content -Path $json_template_file -Raw; $matches = [regex]::Matches($fileContent, '<<.*?>>'); $matches | ForEach-Object { $_.Value } | Sort-Object -Unique

    # Replace the placeholders with the actual values
    $json_data = Get-Content -Path $json_template_file -Raw
    $json_data = $json_data -replace '<<PRIMARY_USERNAME>>', $primary_username
    $json_data = $json_data -replace '<<OUTCOME_MESSAGE>>', $outcome_message
    $json_data = $json_data -replace '<<TIMESTAMP>>', $timestamp
    $json_data = $json_data -replace '<<SCRIPT_NAME>>', $script_name
    $json_data = $json_data -replace '<<TITLE>>', $JSON_TITLE
    $json_data = $json_data -replace '<<CLIENT_IP>>', $client_ip
    $json_data = $json_data -replace '<<DEVICE_NAME>>', $device_name
    $json_data = $json_data -replace '<<VIEW_URL>>', $config_url
    if (-not (Test-Path -Path $log_file -ErrorAction SilentlyContinue) -or (-not (Get-Content -Path $log_file -ErrorAction SilentlyContinue))) {
        $log_data = 'No log data available'
    }
    else {
        $script_log_output = Get-Content -Path "$log_file"
        $log_data = $script_log_output.Trim() | Where-Object { $_.Length -gt 1 } | ForEach-Object {
            $_ -replace '"', '' -replace '\\', '_' -replace '/', '_' -replace '[()]', '_'
        }
    }
    $json_log_data = ''
    # for each line in the log file, add to $json_log_data with a newline character of '\n'

    foreach ($line in $log_data) {
        $json_log_data += "$line\n"
    }
    
    # Facts, keys and values
    $FACTS = @(
        @{
            title = 'Outcome'
            value = $outcome_message
        },
        @{
            title = 'Script Name'
            value = $script_name
        },
        @{
            title = 'Device Name'
            value = $device_name
        },
        @{
            title = 'Primary User'
            value = $primary_username
        },
        @{
            title = 'Date & Time'
            value = $timestamp
        },
        @{
            title = 'Source IP'
            value = $client_ip
        },
        @{
            title = 'Config URL'
            value = $config_url
        }
    )
    $FACTS_JSON = $FACTS | ConvertTo-Json -Compress
    $json_data = $json_data -replace '<<FACTS_JSON>>', $FACTS_JSON
    if ($json_log_data -eq '') {
        $json_log_data = 'No log data available'
    }
    $json_data = $json_data -replace '<<LOG_DATA>>', $json_log_data
    Write-Debug $json_data

    # Make a POST request to the notify_url with the filecon0tents as the payload and application/json as the content type
    Invoke-RestMethod -Uri $notify_url -Method Post -Body $json_data -ContentType 'application/json'
}