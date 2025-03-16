Set-ExecutionPolicy Bypass -Scope Process -Force

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Please run this script as Administrator." -ForegroundColor Red
    Write-Host "Press Enter to exit..."
    Read-Host | Out-Null
    exit
}

Write-Host "🔄 Updating / installing applications..." -ForegroundColor Green
winget upgrade --all --accept-source-agreements --accept-package-agreements

$apps = @(
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "JanDeDobbeleer.OhMyPosh",
    "GitHub.cli"
)

foreach ($app in $apps) {
  Write-Host "📦 Installing $app..." -ForegroundColor Green
  winget install --id=$app --accept-source-agreements --accept-package-agreements
}

Write-Host "🚀 Refreshing to apply updates..." -ForegroundColor Green
Start-Sleep -Seconds 3
Start-Process -FilePath "pwsh" -ArgumentList "-NoExit", "-File", "`"$PSScriptRoot\script.ps1`"" -WorkingDirectory "$HOME"
exit
