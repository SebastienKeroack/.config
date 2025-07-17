$ErrorActionPreference = "Stop"
. "$PSScriptRoot/utils/code.ps1"
. "$PSScriptRoot/utils/common.ps1"
. "$PSScriptRoot/utils/scoop.ps1"

Export-UtilsEnvironmentVariables

$Configurations = @{
  Git = @{
    Email = "dev@sebastienkeroack.com"
    Name = "Sébastien Kéroack"
    CredentialHelper = "store"
    DefaultBranch = "main"
    IgnoreCase = $false
    LongPaths = $true
  }
  NeoVim = @{
    Font = "RobotoMono-NF-Mono"
    Dependencies = @(
      @{Name = "fd"; Source = "main"}
      @{Name = "fzf"; Source = "main"}
      @{Name = "zig"; Source = "main"}
      @{Name = "nodejs"; Source = "main"}
      @{Name = "ripgrep"; Source = "main"}
      @{Name = "lazygit"; Source = "extras"}
      @{Name = "vcredist2022"; Source = "extras"}
      @{Name = "alacritty"; Source = "extras"}
    )
  }
  RequiredPackages = @(
    @{Name = "pwsh"; Source = "main"}
  )
  VSCode = @{
    Extensions = @(
      "github.copilot",
      "github.copilot-chat",
      "ms-vscode.powershell",
      "tamasfe.even-better-toml",
      "vscodevim.vim"
    )
    UserData = @{
      "Source" = "$env:PROJECTROOT\user-data\vscode"
      "Target" = "$env:USERPROFILE\scoop\apps\vscode\current\data\user-data\User"
    }
    Settings = @{
      "powershell.powerShellDefaultVersion" = "scoop"
      "powershell.powerShellAdditionalExePaths" = @{
        "scoop" = "$env:USERPROFILE\scoop\shims\pwsh.exe"
      }
      "terminal.external.windowsExec" = "$env:USERPROFILE\scoop\shims\pwsh.exe"
    }
  }
}

$Scoop = [Scoop]::new()

function New-Profile {
  if (Test-Path ($path = $env:PWSHPROFILE)) {
    Write-Debug "PowerShell profile already exists at: $path"
    return
  }

  New-Item -ItemType File -Path $path -Force | Out-Null
  Write-Host "PowerShell profile created at: $path"
}

function Install-Git {
  Write-Host "Installing Git..."
  $Git = $Configurations.Git
  $Scoop.InstallPackage("git", "main")

  git config --global user.email "$($Git.Email)"
  git config --global user.name "$($Git.Name)"

  git config --global credential.helper "$($Git.CredentialHelper)"
  git config --global init.defaultBranch "$($Git.DefaultBranch)"
  git config --global core.ignorecase "$($Git.IgnoreCase)"
  git config --system core.longpaths "$($Git.LongPaths)"
}

function Install-NeoVim {
  Write-Host "Installing NeoVim..."
  $NeoVim = $Configurations.NeoVim
  $Scoop.InstallPackage($NeoVim.Font, "nerd-fonts")

  foreach ($dep in $NeoVim.Dependencies) {
    $Scoop.InstallPackage($dep.Name, $dep.Source)

    if ($dep.Name -eq "alacritty") {
      New-Junction "alacritty"
    }
  }

  $Scoop.InstallPackage("neovim", "main")
  Add-LineToFile -Path "$env:PWSHPROFILE" -Line "Set-Alias neovim nvim"
}

function Install-RequiredPackages {
  Write-Host "Installing Required packages..."
  foreach ($pkg in $Configurations.RequiredPackages) {
    $Scoop.InstallPackage($pkg.Name, $pkg.Source)
  }
}

function Install-VSCode {
  Write-Host "Installing VSCode..."
  $VSCode = $Configurations.VSCode
  $Scoop.InstallPackage("vscode", "extras")

  Write-Host "Copying VSCode user keybindings..."
  $name = "keybindings.json"
  $source = "$($VSCode.UserData.Source)\$name"
  $target = "$($VSCode.UserData.Target)\$name"
  Backup-AndCopyFile "$source" "$target"

  Write-Host "Copying VSCode user settings..."
  $name = "settings.json"
  $source = "$($VSCode.UserData.Source)\$name"
  $target = "$($VSCode.UserData.Target)\$name"
  $data = Get-Content "$source" -Raw | ConvertFrom-Json
  foreach ($option in $VSCode.Settings.GetEnumerator()) {
    $data | Add-Member `
      -NotePropertyName $option.Key `
      -NotePropertyValue $option.Value -Force
  }
  Backup-File "$target"
  $data | ConvertTo-Json -Depth 5 | Set-Content -Path "$target" -Encoding UTF8

  Write-Host "Installing VSCode extensions..."
  $Code = [Code]::new()
  $Code.InstallExtensions($VSCode.Extensions)
}

Set-EnvironmentVariable "XDG_CONFIG_HOME" "$env:PROJECTROOT"
New-Profile
Install-RequiredPackages
Install-NeoVim
Install-Git
Install-VSCode