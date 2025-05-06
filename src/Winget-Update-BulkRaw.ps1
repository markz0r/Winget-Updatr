# Ensure winget is managing all possible apps/packages and applying updates silently
$START_TIME = Get-Date
$logPath = "$env:HOMEDRIVE\scripts\logs\winget"
$logFile = "$logPath\winget_update-$($START_TIME | Get-Date -Format 'yyyyMMdd_hhmmss').log"

# Enable transcript logging
Start-Transcript -Path $logFile -Append

try {
    # Check if winget is installed
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error 'winget is not installed. Please install it from the Microsoft Store or manually.'
        exit 1
    }
    Write-Output '##### winget --info'
    winget --info | Format-Table -AutoSize

    # List all installed packages
    Write-Output '##### Retrieving list of all installed packages...'
    winget list --accept-source-agreements | Format-Table -AutoSize
    Write-Output '##### Listing available updates'
    winget upgrade | Format-Table -AutoSize

    # Update all installed packages silently
    Write-Output 'Updating all installed packages using winget...'
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements | Write-Output


    ## Define a list of known apps to ensure they're managed by winget
    #$requiredApps = @(
    #    'Microsoft.Edge',
    #    # "Microsoft.VisualStudioCode",
    #    'Git.Git',
    #    '7zip.7zip',
    #    'Mozilla.Firefox'
    #)

    #foreach ($app in $requiredApps) {
    #    try {
    #        Write-Output "Ensuring $app is installed and managed by winget..."
    #        $isInstalled = $installedPackages | Where-Object { $_.Id -eq $app }
    #        if (-not $isInstalled) {
    #            Write-Output "$app is not installed. Installing..."
    #            winget install $app --silent --accept-package-agreements --accept-source-agreements | Write-Output
    #        }
    #        else {
    #            Write-Output "$app is already installed. Ensuring it's updated..."
    #            winget upgrade $app --silent --accept-package-agreements --accept-source-agreements | Write-Output
    #        }
    #    }
    #    catch {
    #        Write-Output "ERROR: Failed to process $app. Error: $_" 
    #    }
    #}

    Write-Output 'All applications are managed and updated successfully.'
}
catch {
    Write-Output "ERROR: An error occurred during the script execution: $_"
}
finally {
    Stop-Transcript
    Write-Debug "Transcript and logs saved to $logFile"
}