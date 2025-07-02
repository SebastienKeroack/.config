function Test-Admin {
  return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ProjectRoot {
  return Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..') | Select-Object -ExpandProperty Path
}

function Add-LineToFile {
  param (
    [string]$Path,
    [string]$Line
  )

  if (-not (Test-Path $Path)) {
    Write-Error "File path does not exist: $Path"
    return
  }

  if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($Line)))) {
    Add-Content -Path $PROFILE -Value $Line
    Write-Host "Added to profile: $Line"
  } else {
    Write-Debug "Line already exists in profile: $Line"
  }
}

function New-Junction {
  param (
    [string]$Name
  )

  $Target = Join-Path (Get-ProjectRoot) $Name
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
    Write-Host 'Junction created successfully:'
    Write-Host "`t$Link -> $Target"
  } catch {
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

  if ([Environment]::GetEnvironmentVariable($Key, 'User') -eq $Value) {
    Write-Debug "Environment variable '$Key' is already set to '$Value'."
    return
  }

  [Environment]::SetEnvironmentVariable($Key, $Value, 'User')
  Write-Host "Set environment variable '$Key' to '$Value'."
}

function Backup-AndCopyFile {
  param (
    [string]$Src,
    [string]$Dst,
    [string]$Name = ''
  )

  if ($Name) {
    $Src = Join-Path $Src $Name
    $Dst = Join-Path $Dst $Name
  }
  
  if (-not (Test-Path $Src)) {
    Write-Error "File path does not exist: $Src"
    return
  }

  if (Test-Path "$Dst.bak") {
    Write-Debug "Backup file already exists: '$Dst.bak'"
    return
  }

  try {
    Move-Item $Dst "$Dst.bak"
    $Name = [System.IO.Path]::GetFileName($Src)
  } catch {
    $Name = [System.IO.Path]::GetFileName($Dst)
    Write-Error "Failed to create a backup file '$Name': $_"
    throw
  }

  try {
    Copy-Item -Path $Src -Destination $Dst -Force
    Write-Host "File '$Name' copied to: $Dst"
  } catch {
    Write-Error "Failed to copy file '$Name': $_"
    throw
  }
}

function Install-ScoopBucket {
  param (
    [string]$Bucket
  )

  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Error 'Scoop is not installed or not found in the PATH.'
    return
  }

  if (-not (scoop bucket list | Select-String -Pattern $Bucket)) {
    Write-Host "Adding Scoop bucket: $Bucket"
    scoop bucket add $Bucket
  } else {
    Write-Debug "Scoop bucket '$Bucket' is already added."
  }
}

function Install-ScoopPackage {
  param (
    [string]$Package,
    [string]$Source = 'main'
  )

  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Error 'Scoop is not installed or not found in the PATH.'
    return
  }

  $List = scoop list *>&1
  $Pattern = "(?=.*\b$Package\b)(?=.*\b$Source\b)"
  if (-not ($List | Select-String -Pattern $Pattern)) {
    $App = "$Source/$Package"
    Write-Host "Installing Scoop package: $App"
    scoop install $App
  } else {
    Write-Debug "Scoop package '$Package' from '$Source' is already installed."
  }
}

function Install-VSCodeExtensions {
  param (
    [string[]]$Extensions
  )

  if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Error 'VS Code is not installed or not found in the PATH.'
    return
  }

  foreach ($Extension in $Extensions) {
    if (-not (code --list-extensions | Select-String -Pattern $Extension)) {
      Write-Host "Installing VS Code extension: $Extension"
      code --install-extension $Extension
    } else {
      Write-Debug "VS Code extension '$Extension' is already installed."
    }
  }
}