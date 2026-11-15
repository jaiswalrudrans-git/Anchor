@echo off
setlocal
echo ========================================================
echo Installing Anchor Desktop...
echo ========================================================

set SCRIPT_DIR=%~dp0
set TARGET_DIR=%LOCALAPPDATA%\Programs\Anchor

echo [1/3] Copying application files to %TARGET_DIR%...
taskkill /F /IM anchor.exe >nul 2>&1
timeout /t 1 /nobreak >nul 2>&1

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
xcopy "%SCRIPT_DIR%*" "%TARGET_DIR%\" /E /I /Y /Q >nul

echo [2/3] Creating Shortcuts and Registering in Windows...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; " ^
  "$desktop = [Environment]::GetFolderPath('Desktop'); " ^
  "if (Test-Path \"$desktop\anchor.exe\") { Remove-Item -Force \"$desktop\anchor.exe\" }; " ^
  "$sDesktop = $ws.CreateShortcut(\"$desktop\Anchor.lnk\"); " ^
  "$sDesktop.TargetPath = '%TARGET_DIR%\anchor.exe'; " ^
  "$sDesktop.WorkingDirectory = '%TARGET_DIR%'; " ^
  "$sDesktop.IconLocation = '%TARGET_DIR%\anchor.exe,0'; " ^
  "$sDesktop.Description = 'Anchor - Productivity & Focus'; " ^
  "$sDesktop.Save(); " ^
  "$startMenu = [Environment]::GetFolderPath('Programs'); " ^
  "$sStart = $ws.CreateShortcut(\"$startMenu\Anchor.lnk\"); " ^
  "$sStart.TargetPath = '%TARGET_DIR%\anchor.exe'; " ^
  "$sStart.WorkingDirectory = '%TARGET_DIR%'; " ^
  "$sStart.IconLocation = '%TARGET_DIR%\anchor.exe,0'; " ^
  "$sStart.Description = 'Anchor - Productivity & Focus'; " ^
  "$sStart.Save(); " ^
  "$sUninst = $ws.CreateShortcut(\"$startMenu\Uninstall Anchor.lnk\"); " ^
  "$sUninst.TargetPath = '%TARGET_DIR%\Uninstall-Anchor.bat'; " ^
  "$sUninst.WorkingDirectory = '%TARGET_DIR%'; " ^
  "$sUninst.Description = 'Uninstall Anchor'; " ^
  "$sUninst.Save(); " ^
  "$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Anchor'; " ^
  "if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }; " ^
  "Set-ItemProperty -Path $regPath -Name 'DisplayName' -Value 'Anchor'; " ^
  "Set-ItemProperty -Path $regPath -Name 'DisplayVersion' -Value '1.0.0'; " ^
  "Set-ItemProperty -Path $regPath -Name 'Publisher' -Value 'Anchor Team'; " ^
  "Set-ItemProperty -Path $regPath -Name 'DisplayIcon' -Value '%TARGET_DIR%\anchor.exe,0'; " ^
  "Set-ItemProperty -Path $regPath -Name 'InstallLocation' -Value '%TARGET_DIR%'; " ^
  "Set-ItemProperty -Path $regPath -Name 'UninstallString' -Value '\"%TARGET_DIR%\Uninstall-Anchor.bat\"'; " ^
  "Set-ItemProperty -Path $regPath -Name 'NoModify' -Value 1 -Type DWord; " ^
  "Set-ItemProperty -Path $regPath -Name 'NoRepair' -Value 1 -Type DWord;"

echo [3/3] Installation Complete!
echo.
echo Anchor is now installed on your PC.
echo   - Launch from: Desktop (Anchor shortcut) or Start Menu
echo   - To Uninstall: Use Windows Settings (Installed apps), Start Menu, or Uninstall-Anchor.bat
echo.
echo Launching Anchor now...
start "" "%TARGET_DIR%\anchor.exe"
pause
