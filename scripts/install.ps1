# Allow script execution
Set-ExecutionPolicy Bypass -Scope Process -Force

# Ensure PowerShell is running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Please run this script as Administrator." -ForegroundColor Red
    Write-Host "Press Enter to exit..."
    Read-Host | Out-Null
    exit
}

# Function to check if an application is installed
function Test-AppInstalled {
    param ($appId)
    return $null -ne (winget list --id $appId | Select-String -Pattern $appId)
}

# Function to check if an application needs an upgrade
function Test-AppUpgrade {
    param ($appId)
    return $null -ne (winget upgrade --id $appId | Select-String -Pattern $appId)
}

# Install or upgrade required applications
$apps = @(
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "JanDeDobbeleer.OhMyPosh",
    "GitHub.cli"
)

foreach ($app in $apps) {
    if (Test-AppUpgrade $app) {
        Write-Host "⬆️ Upgrading $app..." -ForegroundColor Green
        winget upgrade --id=$app --silent --accept-source-agreements --accept-package-agreements
    } elseif (-not (Test-AppInstalled $app)) {
        Write-Host "📦 Installing $app..." -ForegroundColor Green
        winget install --id=$app --silent --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "✅ $app is up to date, skipping..." -ForegroundColor Yellow
    }
}

Write-Host "🚀 Restarting script to apply updates..."
Start-Sleep -Seconds 1
Start-Process -FilePath "pwsh" -ArgumentList "-NoExit", "-File", "`"$PSScriptRoot\script.ps1`""
exit
