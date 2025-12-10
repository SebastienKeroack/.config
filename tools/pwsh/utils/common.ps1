function Export-UtilsEnvironmentVariables {
  $env:PROJECTROOT = Get-ProjectRoot
  $env:PWSHPROFILE = Get-PwshProfile
}

function Get-ProjectRoot {
  $path = Join-Path "$PSScriptRoot" "../../.."
  return Resolve-Path -LiteralPath "$path" | Select-Object -ExpandProperty Path
}

function Get-PwshProfile {
  return $PROFILE.CurrentUserAllHosts
}

function Add-LineToFile {
  param (
    [string]$Path,
    [string]$Line
  )

  if (-not (Test-Path "$Path")) {
    Write-Error "File path does not exist: $Path"
    return
  }

  if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Line)))) {
    Add-Content -Path "$Path" -Value "$Line"
    Write-Host "Added to profile: $Line"
  } else {
    Write-Debug "Line already exists in profile: $Line"
  }
}

function New-Junction {
  param (
    [string]$Name
  )

  $target = Join-Path "$env:PROJECTROOT" "$Name"
  if (-not (Test-Path "$target")) {
    Write-Error "Target path does not exist: $target"
    return
  }

  $link = Join-Path "$env:APPDATA" "$Name"
  if (Test-Path "$link") {
    Write-Debug "Junction already exists: $link"
    return
  }

  try {
    New-Item -Path "$link" -ItemType Junction -Value "$target" | Out-Null
    Write-Host "Junction created successfully:"
    Write-Host "`t'$link' -> '$target'"
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

  if (-not "$Value") {
    Write-Error "Value for environment variable '$Key' is empty."
    return
  }

  if ([Environment]::GetEnvironmentVariable($Key, "User") -eq "$Value") {
    Write-Debug "Environment variable '$Key' is already set to '$Value'."
    return
  }

  [Environment]::SetEnvironmentVariable($Key, $Value, "User")
  Write-Host "Set environment variable '$Key' to '$Value'."
}

function Backup-File {
  param (
    [string]$Path
  )

  if (Test-Path ($target = "$Path.bak")) {
    Write-Debug "Backup file already exists: '$target'"
    return
  }

  $name = [System.IO.Path]::GetFileName($Path)

  try {
    Copy-Item -Path "$Path" -Destination "$target" -Force
    Write-Host "File '$name' copied to: '$target'"
  } catch {
    Write-Error "Failed to copy file '$name': $_"
    throw
  }
}

function Backup-AndCopyFile {
  param (
    [string]$Src,
    [string]$Dst,
    [string]$Name = ""
  )

  if ($Name) {
    $Src = Join-Path "$Src" "$Name"
    $Dst = Join-Path "$Dst" "$Name"
  }
  
  if (-not (Test-Path "$Src")) {
    Write-Error "File path does not exist: '$Src'"
    return
  }

  if (Test-Path "$Dst.bak") {
    Write-Debug "Backup file already exists: '$Dst.bak'"
    return
  }

  try {
    if (Test-Path "$Dst") { Move-Item "$Dst" "$Dst.bak" }
    $Name = [System.IO.Path]::GetFileName($Src)
  } catch {
    if (-not $Name) {
      $Name = [System.IO.Path]::GetFileName($Dst)
    }

    Write-Error "Failed to create a backup file '$Name': $_"
    throw
  }

  try {
    Copy-Item -Path "$Src" -Destination "$Dst" -Force
    Write-Host "File '$Name' copied to: '$Dst'"
  } catch {
    Write-Error "Failed to copy file '$Name': $_"
    throw
  }
}

function Test-Admin {
  return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
