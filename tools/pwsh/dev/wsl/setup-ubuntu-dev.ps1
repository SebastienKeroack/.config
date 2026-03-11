$ErrorActionPreference = "Stop"
. "tools/pwsh/utils/common.ps1"

Export-UtilsEnvironmentVariables

$Configurations = @{
  Distribution = @{
    Name = "Ubuntu-24.04"
    DesiredName = "dev"
  }
  InitScript = @{
    Source = "tools/pwsh/dev/wsl/init.sh"
    Target = "/root/init.sh"
  }
}

$Name = $Configurations.Distribution.Name
$DistroTempTarFile = "$env:TEMP\$Name.tar"
if (-not (Test-Path "$DistroTempTarFile")) {
  # 1. Install the distribution (if not already installed)
  Write-Host "Installing the distribution '$Name'..."
  wsl --install -d $Name --no-launch

  # 2. Export the distribution to a tar file
  Write-Host "Exporting the distribution..."
  wsl --export $Name "$DistroTempTarFile"
} else {
  Write-Debug "Temporary tar file '$DistroTempTarFile' already exists."
}

# 3. Import with a custom name
$DistrosLocation = "$env:USERPROFILE\wsl"
if (-not (Test-Path "$DistrosLocation")) {
  New-Item -ItemType Directory -Path "$DistrosLocation" | Out-Null
} else {
  Write-Debug "Directory '$DistrosLocation' already exists."
}

$DesiredName = $Configurations.Distribution.DesiredName
$DistroLocation = "$DistrosLocation\$DesiredName"
if (-not (Test-Path "$DistroLocation")) {
  # 4. Import the configuration file
  Write-Host @"
Import the distribution as '$DesiredName' to '$DistroLocation'
After importing the distribution, you may see a warning in PowerShell that the
terminal icon for the distribution profile cannot be found. To fix this, open
Windows Terminal settings, go to 'Profiles' for your distribution, and remove
the '//?/' prefix from the icon path.
"@
  New-Item -ItemType Directory -Path "$DistroLocation" | Out-Null
  wsl --import "$DesiredName" "$DistroLocation" "$DistroTempTarFile"

  # 5. Import init file
  $InitScript = $Configurations.InitScript
  Write-Host "Copying init.sh into the distribution..."
  (Get-Content $InitScript.Source -Raw) -replace "`r`n", "`n" `
  | wsl -d "$DesiredName" -- tee $InitScript.Target > $null

  # 6. Execute the init file
  Write-Host "Executing the init file..."
  wsl -d "$DesiredName" -- bash $InitScript.Target

  # 7. Set the default distribution (optional)
  Write-Host "Setting '$DesiredName' as the default distribution..."
  wsl --set-default "$DesiredName"
  wsl --terminate "$DesiredName"
} else {
  Write-Debug "Config file '$DistroLocation' already exists."
}