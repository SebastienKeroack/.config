$ErrorActionPreference = "Stop"
. "$PSScriptRoot/../utils/code.ps1"
. "$PSScriptRoot/../utils/common.ps1"

Export-UtilsEnvironmentVariables

$Configurations = @{
  LXSSTools = "C:\Windows\System32\lxss\tools"
  WSL = @{
    Exe = "$env:SystemRoot\System32\wsl.exe"
    Kernel = @{
      Path = "$env:LOCALAPPDATA\Packages\MicrosoftCorporationII.WindowsSubsystemForLinux_8wekyb3d8bbwe\LocalState"
      Url = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
      Setup = "$env:TEMP\wsl_update_x64.msi"
    }
    UserData = @{
      Source = "$env:PROJECTROOT\user-data\wsl"
      Target = "$env:USERPROFILE"
    }
  }
  VSCode = @{
    Extensions = @(
      "ms-vscode-remote.remote-wsl"
    )
  }
}

function Install-Kernel {
  $Kernel = $Configurations.WSL.Kernel

  Write-Host "Downloading WSL2 kernel update..."
  Invoke-WebRequest -Uri "$($Kernel.Url)" -OutFile "$($Kernel.Setup)"
  if (-not (Test-Path "$($Kernel.Setup)")) {
    Write-Error "Failed to download the kernel update."
    return
  }

  Write-Host "Installing WSL2 kernel update..."
  Start-Process `
    msiexec.exe -ArgumentList "/i "$($Kernel.Setup)" /quiet /norestart" -Wait
  Write-Host "WSL2 kernel installed successfully."
  Remove-Item "$($Kernel.Setup)"
}

function Install-WSL {
  Write-Host "Installing WSL..."
  if (Test-WSL) {
    Write-Debug "WSL appears to be installed and supported on this system."
    return
  }

  # Enable the Windows Subsystem for Linux
  dism.exe /online /enable-feature `
    /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

  # Enable Virtual Machine feature
  dism.exe /online /enable-feature `
    /featurename:VirtualMachinePlatform /all /norestart

  Install-Kernel

  # Set WSL2 as the default version
  wsl --set-default-version 2

  $source = "$($Configurations.UserData.Source)\.wslconfig"
  $target = "$($Configurations.UserData.Target)\.wslconfig"
  Backup-AndCopyFile "$source" "$target"
  Write-Host "WSL configuration file created with default settings."
  Write-Host "WSL installed. Please restart your computer."
}

function Install-VSCodeExtensions {
  Write-Host "Installing VSCode extensions..."
  $Code = [Code]::new()
  $Code.InstallExtensions($Configurations.VSCode.Extensions)
}

function Test-WSL {
  $WSL = $Configurations.WSL

  $checks = @{
    ExePathExists = $false
    WSLKernelPathExists = $false
    LXSSToolsPathExists = $false
    WSLFeature = $false
    VMPlatform = $false
    HypervisorType = $null
  }

  if (Test-Admin) {
    # Check if WSL feature are installed
    $checks.WSLFeature = Get-WindowsOptionalFeature `
      -Online `
      -FeatureName Microsoft-Windows-Subsystem-Linux
    $checks.VMPlatform = Get-WindowsOptionalFeature `
      -Online `
      -FeatureName VirtualMachinePlatform

    # Check if hypervisor is enabled (via bcdedit)
    $hypervisortype = (
      bcdedit | Select-String "hypervisorlaunchtype") -replace ".*\s", ""
    if (-not $hypervisortype) { $hypervisortype = $null }
    $checks.HypervisorType = $hypervisortype
  } else {
    Write-Debug `
      "Not running as administrator; limited WSL checks will be performed."
  }

  # Check if wsl.exe exists
  $checks.WSLExePathExists = Test-Path "$($WSL.Exe)"

  # Check if WSL kernel or related folders exist
  $checks.WSLKernelPathExists = Test-Path "$($WSL.Kernel.Path)"
  $checks.LXSSToolsPathExists = Test-Path "$($Configurations.LXSSTools)"

  # Summary output
  Write-Debug "WSL Feature Installed:    $($WSLFeature.State)"
  Write-Debug "Virtual Machine Platform: $($VMPlatform.State)"
  Write-Debug "wsl.exe exists:           $WSLExePathExists"
  Write-Debug "WSL kernel folder found:  $WSLKernelPathExists"
  Write-Debug "LXSS tools folder exists: $LXSSToolsPathExists"
  Write-Debug "Hypervisor type:          $HypervisorType"

  return (
    $WSLFeature.State -eq "Enabled" -and
    $VMPlatform.State -eq "Enabled" -and
    $HypervisorType -and
    $WSLExePathExists -and
    $WSLKernelPathExists -and
    $LXSSToolsPathExists
  )
}

Install-WSL
Install-VSCodeExtensions
