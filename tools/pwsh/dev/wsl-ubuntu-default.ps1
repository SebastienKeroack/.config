$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../utils.ps1"

$WSLDistName = 'ubuntu-default'

$WSLDist = 'Ubuntu-24.04'

$WSLDistTempTarFile = "$env:TEMP\$WSLDist.tar"

$WSLDistDir = "$env:USERPROFILE\WSL\$WSLDistName"

$WSLDistCfgSrcPath = "$(Get-ProjectRoot)\user-data\wsl\default.conf"

$WSLUserName = (
  Get-Content $WSLDistCfgSrcPath | 
  Select-String '^default = '
).ToString().Split(' = ')[1]

$WSLDistCfgDstPath = "\\wsl.localhost\$WSLDistName\home\$WSLUserName\wsl.conf"

$ASDF_VER = '0.18.0'

$ASDF_ARCHIVE = "asdf-v$ASDF_VER-linux-amd64.tar.gz"

if (-not (Test-Path $WSLDistTempTarFile)) {
  # 1. Install the distribution (if not already installed)
  Write-Host @"
Install the distribution '$WSLDist'
When asked, choose the default user '$WSLUserName' specified in '$WSLDistCfgSrcPath'
"@
  wsl --install -d $WSLDist

  Write-Host @"
Updating the distribution '$WSLDist' requires elevated permissions (sudo).
You may be prompted for your password.
"@
  wsl -d $WSLDist -e sudo bash -c @'
apt-get update
apt-get upgrade -&
# Install required packages for asdf and Python
apt-get install -y bash git unzip zip
# Install required packages to compile TensorFlow
apt-get install -y make llvm-18 clang-18 clang-format
# Set clang and clang++ to use version 18 by default
update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100
# Set LLVM to use version 18 by default
update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-18 100
# Install required packages to compile Python
apt-get install -y build-essential gdb lcov pkg-config \
  libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
  libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
  lzma lzma-dev tk-dev uuid-dev zlib1g-dev libzstd-dev
'@

  Write-Host "Download '$ASDF_ARCHIVE' in the distribution '$WSLDist'"
  wsl -d $WSLDist -- bash -c @"
curl -L -o $ASDF_ARCHIVE https://github.com/asdf-vm/asdf/releases/download/v$ASDF_VER/$ASDF_ARCHIVE
tar -xzf $ASDF_ARCHIVE
"@

  Write-Host "Install asdf v$ASDF_VER in the distribution '$WSLDist'"
  wsl -d $WSLDist -e bash -c @'
mkdir -p ~/.local/bin
mv asdf ~/.local/bin/
chmod +x ~/.local/bin/asdf
echo 'export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
'@

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

if (-not (Test-Path $WSLDistCfgDstPath)) {
  # 5. Import the configuration file
  Write-Host @"
Import the distribution as '$WSLDistName' to '$WSLDistDir'
After importing the distribution, you may see a warning in PowerShell that the
terminal icon for the distribution profile cannot be found. To fix this, open
Windows Terminal settings, go to 'Profiles' for your distribution, and remove
the '//?/' prefix from the icon path.
"@
  wsl --import $WSLDistName $WSLDistDir $WSLDistTempTarFile

  # 6. Import the configuration file
  Write-Host "Copy config to '$WSLDistCfgDstPath'"
  Copy-Item $WSLDistCfgSrcPath $WSLDistCfgDstPath

  Write-Host @'
Setting '/etc/wsl.conf' requires elevated permissions (sudo).
You may be prompted for your password.
'@
  wsl -d $WSLDistName -e sudo cp "/home/$WSLUserName/wsl.conf" '/etc/wsl.conf'
  wsl --terminate $WSLDistName
} else {
  Write-Debug "Config file '$WSLDistCfgDstPath' already exists."
}