@echo off
setlocal
echo ========================================================
echo Uninstalling Anchor...
echo ========================================================

set TARGET_DIR=%LOCALAPPDATA%\Programs\Anchor

echo [1/4] Closing running Anchor processes...
taskkill /F /IM anchor.exe >nul 2>&1
timeout /t 1 /nobreak >nul 2>&1

echo [2/4] Removing Desktop and Start Menu shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$desktop = [Environment]::GetFolderPath('Desktop'); " ^
  "if (Test-Path \"$desktop\Anchor.lnk\") { Remove-Item -Force \"$desktop\Anchor.lnk\" }; " ^
  "if (Test-Path \"$desktop\anchor.exe\") { Remove-Item -Force \"$desktop\anchor.exe\" }; " ^
  "$startMenu = [Environment]::GetFolderPath('Programs'); " ^
  "if (Test-Path \"$startMenu\Anchor.lnk\") { Remove-Item -Force \"$startMenu\Anchor.lnk\" }; " ^
  "if (Test-Path \"$startMenu\Uninstall Anchor.lnk\") { Remove-Item -Force \"$startMenu\Uninstall Anchor.lnk\" }; " ^
  "if (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Anchor') { " ^
  "  Remove-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Anchor' -Recurse -Force " ^
  "};"

echo [3/4] Removing application files...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Sleep -Seconds 1; " ^
  "if (Test-Path '$env:LOCALAPPDATA\Programs\Anchor') { " ^
  "  Get-ChildItem -Path '$env:LOCALAPPDATA\Programs\Anchor' -Exclude 'Uninstall-Anchor.bat' | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue " ^
  "}"

echo [4/4] Final cleanup...
echo.
echo ========================================================
echo Anchor has been successfully uninstalled.
echo ========================================================
pause

(goto) 2>nul & del "%~f0" & rmdir "%TARGET_DIR%" 2>nul
