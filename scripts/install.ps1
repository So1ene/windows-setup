Write-Host "🔄 Updating / installing applications..." -ForegroundColor Green
$upgradeResult = winget upgrade --all --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Winget upgrade failed. Stopping script." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

$apps = @(
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "JanDeDobbeleer.OhMyPosh",
    "GitHub.cli"
)

foreach ($app in $apps) {
  Write-Host "📦 Installing $app..." -ForegroundColor Green
  $installResult = winget install --id=$app --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install $app. Stopping script." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
  }
}

Write-Host "🚀 Refreshing to apply updates..." -ForegroundColor Green
Start-Sleep -Seconds 3
Start-Process -FilePath "pwsh" -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File", "`"$PSScriptRoot\script.ps1`"" -WorkingDirectory "$HOME"
exit
