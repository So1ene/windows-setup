$envFile = "$PSScriptRoot\.env"
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
oh-my-posh font install Meslo

$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$desiredFontFace = "MesloLGLDZ Nerd Font"
$desiredFontSize = 12
$defaultWorkingDirectory = $env:DEFAULT_WORKING_DIRECTORY
if (-not $defaultWorkingDirectory -or $defaultWorkingDirectory -eq "") {
    $defaultWorkingDirectory = $HOME
}

if (Test-Path $terminalSettingsPath) {
  try {
      $originalHash = (Get-FileHash -Algorithm SHA256 $terminalSettingsPath).Hash
      $settingsJson = Get-Content -Path $terminalSettingsPath -Raw -ErrorAction Stop
      $settings = $settingsJson | ConvertFrom-Json -Depth 100
  } catch {
      Write-Host "❌ ERROR: Failed to parse settings.json. It might be malformed." -ForegroundColor Red
      Write-Host $_.Exception.Message -ForegroundColor Yellow
      exit 1
  }

  if (-not $settings.PSObject.Properties['profiles']) {
      $settings | Add-Member -MemberType NoteProperty -Name "profiles" -Value @{}
  }

  if (-not $settings.profiles.PSObject.Properties['defaults']) {
      $settings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{}
  }

  if (-not $settings.profiles.defaults.PSObject.Properties['font']) {
      $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{size = $desiredFontSize; face = $desiredFontFace}
  } else {
      if ($settings.profiles.defaults.font.size -ne $desiredFontSize -or $settings.profiles.defaults.font.face -ne $desiredFontFace) {
          $settings.profiles.defaults.font.size = $desiredFontSize
          $settings.profiles.defaults.font.face = $desiredFontFace
      }
  }

  Write-Host "✅ Updated global default font: $desiredFontFace (Size: $desiredFontSize)" -ForegroundColor Green

  if (-not $settings.profiles.defaults.PSObject.Properties['startingDirectory']) {
      $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "startingDirectory" -Value $defaultWorkingDirectory
  } else {
      if ($settings.profiles.defaults.startingDirectory -ne $defaultWorkingDirectory) {
          $settings.profiles.defaults.startingDirectory = $defaultWorkingDirectory
      }
  }

  Write-Host "✅ Updated global default starting directory to: $defaultWorkingDirectory" -ForegroundColor Green

  $powerShell7GUID = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
  if ($settings.PSObject.Properties['defaultProfile'] -and $settings.defaultProfile -ne $powerShell7GUID) {
      $settings.defaultProfile = $powerShell7GUID
      Write-Host "✅ Windows Terminal default profile set to PowerShell 7" -ForegroundColor Green
  }

  try {
      $settings | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Out-Null
  } catch {
      Write-Host "❌ ERROR: JSON validation failed! Skipping save." -ForegroundColor Red
      exit 1
  }

  $updatedSettingsJson = $settings | ConvertTo-Json -Depth 100 | Out-String
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
}

$ompConfig = @"
# Load Oh-My-Posh theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/my-theme.omp.json" | Invoke-Expression

# Function to create a new empty file (like 'touch' in Linux)
function touch { Set-Content -Path $args[0] -Value $null }

# Function to read file contents (like 'cat' in Linux)
function cat { Get-Content -Path $args[0] }
"@

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
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
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
          "properties": {
            "cache_duration": "none"
          },
          "template": " \uf0e7 ",
          "foreground": "#1b4258",
          "type": "root",
          "style": "plain"
        },
        {
          "properties": {
            "cache_duration": "none",
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
            "cache_duration": "none"
          },
          "template": " <#61AFEF>git:(</>{{ .HEAD }}<#61AFEF>)</>",
          "foreground": "#D0666F",
          "type": "git",
          "style": "plain"
        },
        {
          "properties": {
            "cache_duration": "none"
          },
          "template": " ✗",
          "foreground": "#BF616A",
          "type": "status",
          "style": "plain"
        },
        {
          "properties": {
            "cache_duration": "none"
          },
          "template": " ❯  ",
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