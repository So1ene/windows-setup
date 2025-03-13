# Allow script execution
Set-ExecutionPolicy Bypass -Scope Process -Force

# Ensure PowerShell is running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    Write-Host "Press Enter to exit..."
    Read-Host | Out-Null
    Stop-Transcript
    exit
}

# Function to check if an application is installed
function Test-AppInstalled {
    param ($appId)
    $installedApps = winget list | Select-String -Pattern $appId
    return $null -ne $installedApps
}

# Update all installed apps using winget
Write-Host "Updating installed applications..." -ForegroundColor Cyan
winget upgrade --all --silent --accept-source-agreements

# Install required applications if not already installed
$apps = @(
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "JanDeDobbeleer.OhMyPosh",
    "GitHub.cli"
)

foreach ($app in $apps) {
    if (-not (Test-AppInstalled $app)) {
        Write-Host "Installing $app..." -ForegroundColor Green
        winget install --id=$app --silent --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "$app is already installed, skipping..." -ForegroundColor Yellow
    }
}

Start-Process -FilePath "pwsh" -ArgumentList "-NoExit", "-File", "`"$PSScriptRoot\script.ps1`""
exit