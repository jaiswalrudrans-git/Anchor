<#
.SYNOPSIS
    Builds the Anchor Windows release executable and packages it into an Inno Setup installer.

.DESCRIPTION
    1. Extracts application version from pubspec.yaml.
    2. Runs 'flutter build windows --release'.
    3. Locates Inno Setup 6 compiler (ISCC.exe).
    4. Compiles windows/installer/anchor_setup.iss into build/windows/installer/Anchor-Setup-<version>.exe.
#>

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

Write-Host "=== Building Anchor Windows Release & Installer ===" -ForegroundColor Cyan

# 1. Read version from pubspec.yaml
$PubspecPath = Join-Path $RootDir "pubspec.yaml"
if (-not (Test-Path $PubspecPath)) {
    throw "pubspec.yaml not found at $PubspecPath"
}

$VersionLine = Get-Content $PubspecPath | Where-Object { $_ -match "^version:\s*(.+)$" } | Select-Object -First 1
if ($VersionLine -match "version:\s*([0-9\.]+)") {
    $AppVersion = $Matches[1]
} else {
    $AppVersion = "1.0.0"
}
Write-Host "Detected Version: $AppVersion" -ForegroundColor Green

# 2. Build Flutter Windows Release
Write-Host "Running: flutter build windows --release..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows release build failed."
}

# 3. Locate Inno Setup Compiler (ISCC.exe)
$IsccCandidates = @(
    "ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe"
)

$IsccPath = $null
foreach ($candidate in $IsccCandidates) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
        $IsccPath = (Get-Command $candidate).Source
        break
    } elseif (Test-Path $candidate) {
        $IsccPath = $candidate
        break
    }
}

if (-not $IsccPath) {
    Write-Warning "Inno Setup 6 (ISCC.exe) was not found on this system."
    Write-Host "The Windows release executable is ready at: build\windows\x64\runner\Release\anchor.exe" -ForegroundColor Green
    Write-Host "To build the setup installer, install Inno Setup 6 from https://jrsoftware.org/isdl.php and rerun this script." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found Inno Setup Compiler at: $IsccPath" -ForegroundColor Green

# 4. Compile Installer
$IssPath = Join-Path $RootDir "windows\installer\anchor_setup.iss"
$OutDir = Join-Path $RootDir "build\windows\installer"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Compiling installer with ISCC..." -ForegroundColor Cyan
& $IsccPath "/DMyAppVersion=$AppVersion" $IssPath
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed."
}

Write-Host "`n=== Successfully created Anchor Installer! ===" -ForegroundColor Green
Write-Host "Installer package: build\windows\installer\Anchor-Setup-$AppVersion.exe" -ForegroundColor Green
