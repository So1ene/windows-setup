$envFile = "$PSScriptRoot\..\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], [System.EnvironmentVariableTarget]::Process)
        }
    }
    Write-Host "✅ Environment variables loaded from .env file." -ForegroundColor Green
} else {
    Write-Host "⚠️ No .env file found at: $envFile" -ForegroundColor Yellow
}

Write-Host "Installing MesloLGS NF font using Oh My Posh..." -ForegroundColor Cyan

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

try {
    oh-my-posh font install Meslo
    if ($LASTEXITCODE -ne 0) {
        throw "Font installation failed with exit code $LASTEXITCODE"
    }
    Write-Host "✅ MesloLGS NF font installed successfully." -ForegroundColor Green
} catch {
    Write-Host "⚠️ Font installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "You can install the font manually from: https://github.com/ryanoasis/nerd-fonts/releases" -ForegroundColor Yellow
    Write-Host "Or try running 'oh-my-posh font install Meslo' manually later." -ForegroundColor Yellow
}

$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$desiredFontFace = "MesloLGLDZ Nerd Font"
$desiredFontSize = 12
$defaultPowerShellGUID = "{c68db2a9-3cce-42b0-a414-2141435c8707}"
$defaultWorkingDirectory = $env:DEFAULT_WORKING_DIRECTORY
if (-not $defaultWorkingDirectory -or $defaultWorkingDirectory -eq "") {
    $defaultWorkingDirectory = $HOME
}

if (Test-Path $terminalSettingsPath) {
    try {
        $backupPath = "$terminalSettingsPath.backup"
        Copy-Item $terminalSettingsPath $backupPath -Force
        Write-Host "📋 Created backup at: $backupPath" -ForegroundColor Cyan
        
        $originalHash = (Get-FileHash -Algorithm SHA256 $terminalSettingsPath).Hash
        $settingsJson = Get-Content -Path $terminalSettingsPath -Raw -ErrorAction Stop
        $settings = $settingsJson | ConvertFrom-Json -Depth 100
    } catch {
        Write-Host "❌ ERROR: Failed to parse settings.json. It might be malformed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to exit..."
        exit 1
    }

    if (-not $settings.profiles -or -not $settings.profiles.list) {
        Write-Host "⚠️ No profiles found in Windows Terminal settings!" -ForegroundColor Yellow
        Read-Host "Press Enter to exit..."
        exit 1
    }

    $originalProfileCount = $settings.profiles.list.Count
    $settings.profiles.list = $settings.profiles.list | Where-Object { 
        $_.source -ne "Windows.Terminal.PowershellCore" -and 
        $_.commandline -notmatch "pwsh" -and 
        $_.name -ne "PowerShell"
    }
    $removedCount = $originalProfileCount - $settings.profiles.list.Count
    if ($removedCount -gt 0) {
        Write-Host "🗑️ Removed $removedCount existing PowerShell profile(s)." -ForegroundColor Yellow
    }
    
    $powerShellGUID = $defaultPowerShellGUID

    $newProfile = @{
        guid = [string]$powerShellGUID
        name = "PowerShell"
        commandline = "pwsh.exe -nologo"
        hidden = $false
        icon = "ms-appx:///ProfileIcons/pwsh.png"
        font = @{
            face = $desiredFontFace
            size = $desiredFontSize
        }
        startingDirectory = $defaultWorkingDirectory
        source = "Windows.Terminal.PowershellCore"
    }

    $settings.profiles.list += $newProfile
    Write-Host "✅ New PowerShell profile created with GUID: $powerShellGUID" -ForegroundColor Green
    $settings.defaultProfile = [string]$powerShellGUID
    Write-Host "✅ Windows Terminal default profile set to PowerShell" -ForegroundColor Green

    try {
        $settings | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Out-Null
    } catch {
        Write-Host "❌ ERROR: JSON validation failed! Skipping save." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit 1
    }

    $updatedSettingsJson = $settings | ConvertTo-Json -Depth 100 | Out-String
    
    if ($updatedSettingsJson -match '"guid":\s*\[') {
        Write-Host "⚠️ Detected malformed GUID array in JSON. Fixing..." -ForegroundColor Yellow
        $updatedSettingsJson = $updatedSettingsJson -replace '"guid":\s*\[[^\]]*\]', "`"guid`": `"$powerShellGUID`""
    }
    
    $updatedHash = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($updatedSettingsJson)) -join ""

    if ($originalHash -ne $updatedHash) {
        $updatedSettingsJson | Set-Content -Path $terminalSettingsPath -Encoding UTF8
        Write-Host "✅ Windows Terminal settings successfully updated." -ForegroundColor Green
    } else {
        Write-Host "⚠️ No changes detected. Skipping unnecessary write." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ ERROR: Windows Terminal settings.json not found!" -ForegroundColor Red
}

if (!(Test-Path $PROFILE)) {
  Write-Host "Creating PowerShell profile: $PROFILE" -ForegroundColor Green
  New-Item -ItemType File -Path $PROFILE -Force | Out-Null
} else {
  $profileBackupPath = "$PROFILE.backup"
  Copy-Item $PROFILE $profileBackupPath -Force
  Write-Host "📋 Created PowerShell profile backup at: $profileBackupPath" -ForegroundColor Cyan
}

$ompConfig = @'
# Load Oh-My-Posh theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/my-theme.omp.json" | Invoke-Expression

# Function to create a new empty file (like 'touch' in Linux)
function touch { Set-Content -Path $args[0] -Value $null }

# Function to read file contents (like 'cat' in Linux)
function cat { Get-Content -Path $args[0] }

# Function to open in explorer (like 'open' in Linux)
function open { explorer.exe $args[0] }
'@

Write-Host "Writing Oh-My-Posh configuration and functions to PowerShell profile..." -ForegroundColor Green
Set-Content -Path $PROFILE -Value $ompConfig -Force

if (!(Test-Path $PROFILE)) {
    Write-Host "ERROR: Profile file was not created successfully!" -ForegroundColor Red
    exit
}

Write-Host "PowerShell profile has been created with the Oh-My-Posh configuration." -ForegroundColor Green

$themeDest = "$env:POSH_THEMES_PATH/my-theme.omp.json"

if (!(Test-Path $env:POSH_THEMES_PATH)) {
    Write-Host "Creating POSH themes directory: $env:POSH_THEMES_PATH" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $env:POSH_THEMES_PATH -Force | Out-Null
}

$myThemeJson = @"
{
    "`$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
    "blocks": [
        {
            "type": "prompt",
            "alignment": "left",
            "segments": [
                {
                    "properties": {
                        "cache_duration": "none",
                        "time_format": "15:04"
                    },
                    "template": "\n[{{ .CurrentDate | date .Format }}]",
                    "foreground": "#1b4258",
                    "type": "time",
                    "style": "plain"
                },
                {
                    "template": " \uf0e7 ",
                    "foreground": "#1b4258",
                    "type": "root",
                    "style": "plain"
                },
                {
                    "properties": {
                        "folder_icon": "\ue5fe",
                        "home_icon": "~",
                        "style": "agnoster"
                    },
                    "template": " {{ .Path }}",
                    "foreground": "#56B6C2",
                    "type": "path",
                    "style": "plain"
                },
                {
                    "properties": {
                        "branch_icon": "",
                        "fetch_status": true
                    },
                    "foreground": "#D0666F",
                    "style": "plain",
                    "template": " <#61AFEF>git:(</>{{ .HEAD }}<#61AFEF>)</>{{ if or (.Working.Changed) (.Staging.Changed) }}<yellow> ✗</yellow></>{{ end }}",
                    "type": "git"
                },
                {
                "foreground": "#DCB977",
                "style": "plain",
                "template": " \uf119 ",
                "type": "status"
                },
                {
                    "template": "<#1b4258> ❯ </#1b4258> ",
                    "foreground": "#1b4258",
                    "type": "text",
                    "style": "plain"
                }
            ]
        }
    ],
    "version": 3
}
"@

Write-Host "Saving custom theme: my-theme.omp.json" -ForegroundColor Green
$myThemeJson | Set-Content -Path $themeDest -Force -Encoding UTF8

Write-Host "Custom theme applied successfully!" -ForegroundColor Green

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

Write-Host "Configuring Git..." -ForegroundColor Cyan
$gitUserName = [System.Environment]::GetEnvironmentVariable("GIT_USERNAME", "Process")
$gitEmail = [System.Environment]::GetEnvironmentVariable("GIT_EMAIL", "Process")

if (-not $gitUserName) {
    Write-Host "Enter your Git user name:" -ForegroundColor Yellow
    $gitUserName = Read-Host
}
if (-not $gitEmail) {
    Write-Host "Enter your Git email:" -ForegroundColor Yellow
    $gitEmail = Read-Host
}

git config --global user.name "$gitUserName"
git config --global user.email "$gitEmail"
git config --global --list

Write-Host "Logging into GitHub CLI..." -ForegroundColor Cyan
gh auth login --hostname github.com --web
gh config set git_protocol ssh

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
Start-Process "shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"
$host.SetShouldExit(0)
exit