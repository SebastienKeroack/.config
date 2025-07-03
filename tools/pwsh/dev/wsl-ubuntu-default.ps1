$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../utils.ps1"

$WSLDistName = 'ubuntu-default'

$WSLDist = 'Ubuntu-24.04'

$WSLDistTempTarFile = "$env:TEMP\$WSLDist.tar"

$WSLDistDir = "$env:USERPROFILE\WSL\$WSLDistName"

$WSLDistCfgPath = "\\wsl.localhost\$WSLDistName\home\$WSLUserName\wsl.conf"

$WSLDistPreCfgPath = "$(Get-ProjectRoot)\user-data\wsl\default.conf"

$WSLUserName = (
  Get-Content $WSLDistPreCfgPath | 
  Select-String '^default='
).ToString().Split('=')[1]

$ASDF_VER = '0.18.0'

$ASDF_ARCHIVE = "asdf-v$ASDF_VER-linux-amd64.tar.gz"

if (-not (Test-Path $WSLDistTempTarFile)) {
  # 1. Install the distribution (if not already installed)
  Write-Host "Install the distribution '$WSLDist'"
  wsl --install -d $WSLDist

  Write-Host "Update the distribution '$WSLDist'"
  wsl -d $WSLDist -- sudo bash -c @'
apt update &&
apt upgrade -y &&
apt install git bash
'@

  Write-Host "Install '$ASDF_ARCHIVE' in the distribution '$WSLDist'"
  wsl -d $WSLDist -- bash -c @"
curl -L -o $ASDF_ARCHIVE https://github.com/asdf-vm/asdf/releases/download/v$ASDF_VER/$ASDF_ARCHIVE &&
tar -xzf $ASDF_ARCHIVE &&
mkdir -p ~/.local/bin &&
mv asdf ~/.local/bin/ &&
chmod +x ~/.local/bin/asdf &&
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc &&
source ~/.bashrc &&
type -a asdf &&
asdf --version
"@

  # 2. Export the distribution to a tar file
  Write-Host "Export the distribution '$WSLDist' to '$WSLDistTempTarFile'"
  wsl --export $WSLDist $WSLDistTempTarFile

  # 3. Unregister the original distribution
  Write-Host "Unregister the original distribution '$WSLDist'"
  wsl --unregister $WSLDist
} else {
  Write-Debug "Temporary tar file '$WSLDistTempTarFile' already exists."
}

# 4. Import with a custom name
$WSLDistDirBase = Split-Path -Path $WSLDistDir -Parent
if (-not (Test-Path $WSLDistDirBase)) {
  Write-Host "Create directory '$WSLDistDirBase'"
  New-Item -ItemType Directory -Path $WSLDistDirBase | Out-Null
} else {
  Write-Debug "Directory '$WSLDistDirBase' already exists."
}

if (-not (Test-Path $WSLDistCfgPath)) {
  # 5. Import the configuration file
  Write-Host "Import the distribution as '$WSLDistName' to '$WSLDistDir'"
  Write-Host @'
After importing the distribution, you may see a warning in PowerShell that the
terminal icon for the distribution profile cannot be found. To fix this, open
Windows Terminal settings, go to 'Profiles' for your distribution, and remove
the '//?/' prefix from the icon path.
'@
  wsl --import $WSLDistName $WSLDistDir $WSLDistTempTarFile

  # 6. Import the configuration file
  Write-Host "Copy config to '$WSLDistCfgPath'"
  Copy-Item $WSLDistPreCfgPath $WSLDistCfgPath

  Write-Host @'
Setting '/etc/wsl.conf' requires elevated permissions (sudo).
You may be prompted for your password.
'@
  wsl -d $WSLDistName -- sudo cp ~/wsl.conf /etc/wsl.conf
  wsl --terminate $WSLDistName
} else {
  Write-Debug "Config file '$WSLDistCfgPath' already exists."
}