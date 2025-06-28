$ErrorActionPreference = 'Stop'
$ProjectRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..') | Select-Object -ExpandProperty Path

function Add-LineToProfile {
  param (
    [string]$Line
  )

  if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($Line)))) {
    Add-Content -Path $PROFILE -Value $Line
    Write-Host "Added to profile: $Line"
  }
}
 
function New-Profile {
  if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "PowerShell profile created at: $PROFILE"
  }

  Add-LineToProfile 'Import-Module Terminal-Icons'
  Add-LineToProfile 'Set-Alias neovim nvim'
}

function New-Junction {
  param (
    [string]$Name
  )

  $Target = Join-Path $ProjectRoot $Name
  if (-not (Test-Path $Target)) {
    Write-Error "Target path does not exist: $Target"
    return
  }

  $Link = Join-Path $env:APPDATA $Name
  if (Test-Path $Link) {
    Write-Debug "Junction already exists: $Link"
    return
  }

  try {
    New-Item -Path $Link -ItemType Junction -Value $Target | Out-Null
    Write-Host "Junction created successfully:"
    Write-Host "`t$Link -> $Target"
  }
  catch {
    Write-Error "Failed to create junction: $_"
    throw
  }
}

function Set-EnvironmentVariable {
  param (
    [string]$Key,
    [string]$Value
  )

  if (-not $Value) {
    Write-Error "Value for environment variable '$Key' is empty."
    return
  }

  if ([Environment]::GetEnvironmentVariable($Key, "User") -eq $Value) {
    Write-Debug "Environment variable '$Key' is already set to '$Value'."
    return
  }

  [Environment]::SetEnvironmentVariable($Key, $Value, "User")
  Write-Host "Set environment variable '$Key' to '$Value'."
}

function Set-GitConfig {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed or not found in the PATH."
    return
  }

  git config --global core.ignorecase false
  git config --global credential.helper 'store'
  git config --global init.defaultBranch 'main'
  git config --global user.email 'dev@sebastienkeroack.com'
  git config --global user.name 'Sébastien Kéroack'
  git config --system core.longpaths true
}

function Backup-AndCopyFile {
  param (
    [string]$Src,
    [string]$Dst,
    [string]$Name
  )

  $SrcFile = Join-Path $Src $Name
  if (-not (Test-Path $SrcFile)) {
    Write-Error "File path does not exist: $SrcFile"
    return
  }

  $DstFile = Join-Path $Dst $Name
  if (Test-Path "$DstFile.bak") {
    Write-Debug "Backup file already exists: '$DstFile.bak'"
    return
  }

  try {
    Move-Item $DstFile "$DstFile.bak"
  }
  catch {
    Write-Error "Failed to create a backup file '$Name': $_"
    throw
  }

  try {
    Copy-Item -Path $SrcFile -Destination $DstFile -Force
    Write-Host "File '$Name' copied to: $DstFile"
  }
  catch {
    Write-Error "Failed to copy file '$Name': $_"
    throw
  }
}

function Set-VSCodeConfig {
  if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Error "VS Code is not installed or not found in the PATH."
    return
  }

  $Src = Join-Path $ProjectRoot 'vscode/User'
  if (-not (Test-Path $Src)) {
    Write-Error "Source path does not exist: $Src"
    return
  }

  $Dst = Join-Path $env:USERPROFILE 'scoop/apps/vscode/current/data/user-data/User'
  if (-not (Test-Path $Dst)) {
    Write-Error "Destination path does not exist: $Dst"
    return
  }

  Backup-AndCopyFile $Src $Dst 'settings.json'
  Backup-AndCopyFile $Src $Dst 'keybindings.json'
}

function Install-ScoopBucket {
  param (
    [string]$Bucket
  )

  if (-not (scoop bucket list | Select-String -Pattern $Bucket)) {
    Write-Host "Adding Scoop bucket: $Bucket"
    scoop bucket add $Bucket
  }
}

function Install-ScoopPackage {
  param (
    [string]$Package,
    [string]$Source = "main"
  )

  $List = scoop list *>&1
  $Pattern = "(\b$Package\b.*\b$Source\b|\b$Source\b.*\b$Package\b)"
  if (-not ($List | Select-String -Pattern $Pattern)) {
    $App = "$Source/$Package"
    Write-Host "Installing Scoop package: $App"
    scoop install $App
  }
}

function Install-ScoopPackages {
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Error "Scoop is not installed or not found in the PATH."
    return
  }

  Install-ScoopBucket "nerd-fonts"
  Install-ScoopPackage "RobotoMono-NF-Mono" -Source "nerd-fonts"
  Install-ScoopBucket "extras"
  Install-ScoopPackage "vscode" -Source "extras"
  Install-ScoopPackage "lazygit" -Source "extras"
  Install-ScoopPackage "alacritty" -Source "extras"
  Install-ScoopPackage "vcredist2022" -Source "extras"
  Install-ScoopBucket "main"
  Install-ScoopPackage "fd"
  Install-ScoopPackage "fzf"
  Install-ScoopPackage "git"
  Install-ScoopPackage "zig"
  Install-ScoopPackage "pwsh"
  Install-ScoopPackage "nodejs"
  Install-ScoopPackage "ripgrep"
  Install-ScoopPackage "neovim"
}

Set-EnvironmentVariable "XDG_CONFIG_HOME" $ProjectRoot
Install-ScoopPackages
New-Profile
New-Junction "alacritty"
Set-GitConfig
Set-VSCodeConfig