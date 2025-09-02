@echo off
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Requesting Administrator permissions...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~fnx0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Restricted -Scope LocalMachine -Force -ErrorAction SilentlyContinue; Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo Checking if winget is available...
winget --version >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: Winget is not installed or not available.
    echo Please install winget from the Microsoft Store ^(App Installer^) or download it from:
    echo https://github.com/microsoft/winget-cli/releases
    pause
    exit /b 1
)

echo Installing the latest PowerShell...
winget install --id Microsoft.Powershell --source winget --accept-source-agreements --accept-package-agreements

echo Waiting for PowerShell installation to complete...
timeout /t 5 /nobreak >nul

echo Starting PowerShell as Administrator and running script...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process pwsh -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0scripts\install.ps1\"' -WorkingDirectory "$HOME" -Verb RunAs"
exit /b 0
