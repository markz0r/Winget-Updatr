# Winget-Updatr

- Manage applicaitons individually with a generic and simple intune deployment script.
- Can also be run locally to update all applications on a machine.

## Quick Start

- Recommended to run as Administrator / SYSTEM (primarily implemented for use in Intune)

`
.\src\Winget-Updatr.ps1 -APPID "7zip.7zip" -OPERATION "install" -ARGS "-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"

# This is just a wrapper for winget, valid OPERATIONS + ARGS see: https://github.com/microsoft/winget-cli/blob/master/README.md

## For Intune Deployment

- To package:

```

winget install --id Microsoft.Win32ContentPrepTool -e
git pull
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss' ; IntuneWinAppUtil.exe -c .\src\ -s .\src\Winget-Updatr.ps1 -o .\DEPLOYABLE\Winget-Updatr-$TIMESTAMP.intune

```

1. Prepare the Package for Testing
   - Before testing, ensure you have the .intunewin package and the necessary install/uninstall command parameters.
   - If you haven't already packaged your app, use the Microsoft Win32 Content Prep Tool (IntuneWinAppUtil.exe).
   - Example:

```powershell
winget install --id Microsoft.Win32ContentPrepTool -e
git pull
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss' ; IntuneWinAppUtil.exe -c .\src\ -s .\src\Winget-Updatr.ps1 -o .\DEPLOYABLE\Winget-Updatr-$TIMESTAMP.intune
```

2. Test the Installation Manually
   Run the Installation Commands Locally
   Before deploying via Intune, test the install and uninstall commands manually.
   mv
   Run the install command as SYSTEM (like Intune does)
   - Use PsExec to simulate the SYSTEM context:

```powershell
psexec -i -s cmd.exe
Then run your install command:
powershell
msiexec /i "C:\Path\to\installer.msi" /qn /l\*v "C:\temp\install.log"
powershell
powershell -ExecutionPolicy Bypass -File "C:\Path\to\install_script.ps1"
Verify that the installation completes successfully.
Run the uninstall command

Test if your uninstall command works:
powershell
Copy
Edit
msiexec /x {PRODUCT-GUID} /qn
OR
powershell
Copy
Edit
powershell -ExecutionPolicy Bypass -File "C:\Path\to\uninstall_script.ps1" 3. Simulate Intune Installation with IME (Intune Management Extension)
After confirming that installation works manually, you can simulate an Intune deployment test.

Install the Package Locally via IME
Copy your .intunewin file to a test machine.
Manually install using Intune Management Extension (IME)
Run the following to trigger a local installation:
powershell
Copy
Edit
$IntuneLogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$IntuneWinAppUtil = "C:\Path\To\YourApp.intunewin"
Start-Process -FilePath "IntuneWinAppUtil.exe" -ArgumentList "/install /quiet" -Wait
This simulates how Intune installs the app.
Check logs in C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log. 4. Deploy as a Required App to a Test Group
Once local tests are successful:

Upload the .intunewin file to Intune via Microsoft Endpoint Manager (MEM).
Assign the app to a test user or device group.
Force Intune to sync and deploy immediately:
powershell
Copy
Edit
Start-IntuneManagementExtension 5. Monitor and Troubleshoot Logs
If issues arise, check logs:

IME Logs: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
Event Viewer:
Go to Event Viewer → Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider.
Look for Win32App events.
Additional Tips
If using PowerShell scripts, ensure:
The script doesn't require interactive input.
Runs in SYSTEM context without errors.
Check registry paths for installation status:
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
```
