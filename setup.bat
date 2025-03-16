@echo off
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Requesting Administrator permissions...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~fnx0' -Verb RunAs"
    exit /b
)

echo Setting execution policy to allow scripts...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; Clear-Host"

echo Installing the latest PowerShell...
winget install --id Microsoft.Powershell --source winget --accept-source-agreements --accept-package-agreements

echo Waiting for PowerShell installation to complete...
timeout /t 5 /nobreak >nul

echo Starting PowerShell as Administrator and running script...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process pwsh -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0scripts\install.ps1\"' -WorkingDirectory "$HOME" -Verb RunAs"
exit /b 0
