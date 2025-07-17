$ErrorActionPreference = "Stop"
. "$PSScriptRoot/../../utils/common.ps1"

Export-UtilsEnvironmentVariables

$Configurations = @{
  AHK = @{
    Url = "https://www.autohotkey.com/download/ahk-v2.exe"
    Setup = "$env:TEMP\ahk-setup.exe"
    Scripts = @{
      Source = "$env:PROJECTROOT\user-data\ahk"
      Target = "$env:USERPROFILE\Documents\AutoHotkey"
    }
  }
}

function Install-AutoHotKey {
  Write-Host "Installing AutoHotKey..."
  $AHK = $Configurations.AHK

  Invoke-WebRequest -Uri "$($AHK.Url)" -OutFile "$($AHK.Setup)"
  if (-not (Test-Path "$($AHK.Setup)")) {
    Write-Error "Failed to download AutoHotKey."
    return
  }

  Start-Process "$($AHK.Setup)" -ArgumentList "/silent" -Wait
  Write-Host "AutoHotKey installed successfully."
  Remove-Item "$($AHK.Setup)"

  Write-Host "Copying AutoHotKey script..."
  $name = "middle-click-alt-tab.ahk"
  $source = "$($AHK.Scripts.Source)\$name"
  $target = "$($AHK.Scripts.Target)\$name"
  Copy-Item -Path "$source" -Destination "$target"
  Start-Process "$target"
  Write-Host "AutoHotKey script copied and started."
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
