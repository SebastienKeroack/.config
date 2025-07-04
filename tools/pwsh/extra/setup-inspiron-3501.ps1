$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../utils.ps1"

$AHKUrl = 'https://www.autohotkey.com/download/ahk-v2.exe'

$AHKScriptMCATSrcPath = "$(Get-ProjectRoot)\user-data\ahk\middle-click-alt-tab.ahk"

$AHKScriptMCATDstPath = "$env:USERPROFILE\Documents\AutoHotkey\middle-click-alt-tab.ahk"

$AHKSetupPath = "$env:TEMP\ahk-setup.exe"

function Install-AutoHotKey {
  Write-Host 'Downloading AutoHotkey...'
  Invoke-WebRequest -Uri $AHKUrl -OutFile $AHKSetupPath
  Invoke-WebRequest -Uri "https://www.autohotkey.com/download/ahk-v2.exe" -OutFile "$env:TEMP\ahk-setup.exe"
  if (-not (Test-Path $WSLKernelMSIPath)) {
    Write-Error 'Failed to download AutoHotKey.'
    return
  }

  Write-Host 'Installing AutoHotKey...'
  Start-Process $AHKSetupPath -ArgumentList "/silent" -Wait
  Write-Host 'AutoHotKey installed successfully.'
  Remove-Item $AHKSetupPath

  Write-Host 'Copying AutoHotKey script...'
  Copy-Item -Path $AHKScriptMCATSrcPath -Destination $AHKScriptMCATDstPath
  Start-Process $AHKScriptMCATDstPath
  Write-Host 'AutoHotKey script copied and started.'
}

# Use AutoHotKey to change the middle-click behavior
# to switch to the last used application
Install-AutoHotKey

# Use Clockify to track time spent on tasks
# and projects, with a focus on productivity
winget install Clockify.Clockify

# Use MEGASync to sync files with the MEGA cloud storage
# and access them from anywhere
winget install Mega.MEGASync

# Use EnergyStarX to monitor and optimize power usage
winget install NickJohn.EnergyStarX

# TODO: Install ExplorerPatcher to customize the taskbar
# @see: https://github.com/valinet/ExplorerPatcher?tab=readme-ov-file
# ...

# Nerd Fonts:
# PowerShell -> Settings -> Profiles -> Defaults -> Font face:
#   Roboto Mono NF Mono

# Initialize CoPilot in LazyVim
# :Copilot auth
