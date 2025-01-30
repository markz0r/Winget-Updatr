# Winget-Updatr

- Manage applications individually with a generic and simple Intune deployment script.
- Can also be run locally to update all applications on a machine.

## Quick Start

- Recommended to run as Administrator / SYSTEM (primarily implemented for use in Intune)

```powershell
.\src\Winget-Updatr.ps1 -APPID "7zip.7zip" -OPERATION "install" -ARGS "-e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
```

This is just a wrapper for winget, valid OPERATIONS + ARGS see: [Winget CLI README](https://github.com/microsoft/winget-cli/blob/master/README.md)

## For Intune Deployment

### To package:

1. Run the packaging command (details to be added).

### Test the Installation Manually

Before deploying via Intune, test the install and uninstall commands manually.

1. Run the install command as SYSTEM (like Intune does)
   - Use PsExec to simulate the SYSTEM context:

```powershell
psexec -i -s cmd.exe
```

Then run your install command:

```powershell
msiexec /i "C:\Path\to\installer.msi" /qn /l*v "C:\temp\install.log"
powershell -ExecutionPolicy Bypass -File "C:\Path\to\install_script.ps1"
```

Verify that the installation completes successfully.

2. Run the uninstall command

Test if your uninstall command works:

```powershell
msiexec /x {PRODUCT-GUID} /qn
powershell -ExecutionPolicy Bypass -File "C:\Path\to\uninstall_script.ps1"
```

### Simulate Intune Installation with IME (Intune Management Extension)

After confirming that installation works manually, you can simulate an Intune deployment test.

1. Install the Package Locally via IME
   - Copy your .intunewin file to a test machine.
   - Manually install using Intune Management Extension (IME)
   - Run the following to trigger a local installation:

```powershell
$IntuneLogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$IntuneWinAppUtil = "C:\Path\To\YourApp.intunewin"
Start-Process -FilePath "IntuneWinAppUtil.exe" -ArgumentList "/install /quiet" -Wait
```

This simulates how Intune installs the app. Check logs in `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.

### Deploy as a Required App to a Test Group

Once local tests are successful:

1. Upload the .intunewin file to Intune via Microsoft Endpoint Manager (MEM).
2. Assign the app to a test user or device group.
3. Force Intune to sync and deploy immediately:

```powershell
Start-IntuneManagementExtension
```

### Monitor and Troubleshoot Logs

If issues arise, check logs:

- IME Logs: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- Event Viewer:
  - Go to Event Viewer → Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider.
  - Look for Win32App events.

### Additional Tips

If using PowerShell scripts, ensure:

- The script doesn't require interactive input.
- Runs in SYSTEM context without errors.

Check registry paths for installation status:

- `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps`
- `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall`
