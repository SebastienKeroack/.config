$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../utils.ps1"

$LXSSToolsPath = 'C:\Windows\System32\lxss\tools'

$VSCodeExtensions = @(
  'ms-vscode-remote.remote-wsl'
)

$WSLUserCfgSrcPath = "$(Get-ProjectRoot)\user-data\wsl\.wslconfig"

$WSLUserCfgDstPath = "$env:USERPROFILE\.wslconfig"

$WSLExePath = "$env:SystemRoot\System32\wsl.exe"

$WSLKernelPath = "$env:LOCALAPPDATA\Packages\MicrosoftCorporationII.WindowsSubsystemForLinux_8wekyb3d8bbwe\LocalState"

$WSLKernelUrl = 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'

$WSLKernelSetupPath = "$env:TEMP\wsl_update_x64.msi"

function New-WSLConfig {
  if (-not (Test-Path $WSLUserCfgDstPath)) {
    Write-Host "Creating WSL configuration file at: $WSLUserCfgDstPath"
    New-Item -ItemType File -Path $WSLUserCfgDstPath -Force | Out-Null
  } else {
    Write-Debug "WSL configuration file already exists at: $WSLUserCfgDstPath"
  }

  if (-not (Test-Path $WSLUserCfgSrcPath)) {
    Write-Error "Source directory does not exist: $WSLUserCfgSrcPath"
    return
  }

  Backup-AndCopyFile $WSLUserCfgSrcPath $WSLUserCfgDstPath
  Write-Host 'WSL configuration file created with default settings.'
}

function Install-RancherDesktop {
  Install-ScoopBucket 'extras'
  Install-ScoopPackage 'rancher-desktop' -Source 'extras'
}

function Install-WSL {
  # Enable the Windows Subsystem for Linux
  dism.exe /online /enable-feature `
    /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

  # Enable Virtual Machine feature
  dism.exe /online /enable-feature `
    /featurename:VirtualMachinePlatform /all /norestart

  Install-WSLKernel

  # Set WSL2 as the default version
  wsl --set-default-version 2

  New-WSLConfig

  Write-Host 'WSL installation commands executed. Please restart your computer.'
}

function Install-WSLKernel {
  Write-Host 'Downloading WSL2 kernel update...'
  Invoke-WebRequest -Uri $WSLKernelUrl -OutFile $WSLKernelSetupPath
  if (-not (Test-Path $WSLKernelSetupPath)) {
    Write-Error 'Failed to download the kernel update.'
    return
  }

  Write-Host 'Installing WSL2 kernel update...'
  Start-Process `
    msiexec.exe -ArgumentList "/i '$WSLKernelSetupPath' /quiet /norestart" -Wait
  Write-Host 'WSL2 kernel installed successfully.'
  Remove-Item $WSLKernelSetupPath
}

function Test-WSLAdmin {
  # Check if WSL feature are installed
  $WSLFeature = Get-WindowsOptionalFeature `
    -Online `
    -FeatureName Microsoft-Windows-Subsystem-Linux
  $VMPlatform = Get-WindowsOptionalFeature `
    -Online `
    -FeatureName VirtualMachinePlatform

  # Check if wsl.exe exists
  $WSLExePathExists = Test-Path $WSLExePath

  # Check if WSL kernel or related folders exist
  $WSLKernelPathExists = Test-Path $WSLKernelPath
  $LXSSToolsPathExists = Test-Path $LXSSToolsPath

  # Check if hypervisor is enabled (via bcdedit)
  $HypervisorType = (
    bcdedit | Select-String 'hypervisorlaunchtype') -replace '.*\s', ''
  if (-not $HypervisorType) { $HypervisorType = $null }

  # Summary output
  Write-Debug "WSL Feature Installed:    $($WSLFeature.State)"
  Write-Debug "Virtual Machine Platform: $($VMPlatform.State)"
  Write-Debug "wsl.exe exists:           $($WSLExePathExists)"
  Write-Debug "WSL kernel folder found:  $($WSLKernelPathExists)"
  Write-Debug "LXSS tools folder exists: $($LXSSToolsPathExists)"
  Write-Debug "Hypervisor type:          $($HypervisorType)"

  if (
    $WSLFeature.State -eq 'Enabled' -and
    $VMPlatform.State -eq 'Enabled' -and
    $WSLExePathExists -and
    $WSLKernelPathExists -and
    $LXSSToolsPathExists -and
    $HypervisorType
  ) {
    Write-Debug 'WSL appears to be installed and supported on this system.'
    return $true
  } else {
    Write-Debug 'WSL is either not installed or not fully supported/enabled.'
    return $false
  }
}

function Test-WSLUser {
  # Check if wsl.exe exists
  $WSLExePathExists = Test-Path $WSLExePath

  # Check if WSL kernel or related folders exist
  $WSLKernelPathExists = Test-Path $WSLKernelPath
  $LXSSToolsPathExists = Test-Path $LXSSToolsPath

  # Summary output
  Write-Debug "wsl.exe exists:           $($WSLExePathExists)"
  Write-Debug "WSL kernel folder found:  $($WSLKernelPathExists)"
  Write-Debug "LXSS tools folder exists: $($LXSSToolsPathExists)"

  if (
    $WSLExePathExists -and
    $WSLKernelPathExists -and
    $LXSSToolsPathExists
  ) {
    Write-Debug 'WSL appears to be installed and supported on this system.'
    return $true
  } else {
    Write-Debug 'WSL is either not installed or not fully supported/enabled.'
    return $false
  }
}

function Test-WSL {
  if (Test-Admin) {
    Write-Debug 'Running as administrator.'
    return Test-WSLAdmin
  } else {
    Write-Debug 'Not admin; limited WSL checks will be performed.'
    return Test-WSLUser
  }
}

if (-not (Test-WSL)) {
  Install-WSL
}

#Install-RancherDesktop
Install-VSCodeExtensions -Extensions $VSCodeExtensions
