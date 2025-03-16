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
Start-Process -FilePath "pwsh" -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File", "`"$PSScriptRoot\script.ps1`"" -WorkingDirectory "$HOME"
exit
