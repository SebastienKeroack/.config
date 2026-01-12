$ErrorActionPreference = "Stop"
. "tools/pwsh/utils/code.ps1"
. "tools/pwsh/utils/common.ps1"
. "tools/pwsh/utils/scoop.ps1"

Export-UtilsEnvironmentVariables

$Configurations = @{
  Git = @{
    Email = "dev@sebastienkeroack.com"
    Name = "Sébastien Kéroack"
    CredentialHelper = "store"
    DefaultBranch = "main"
    AutoCRLF = $false
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
  VSCode = @{
    Extensions = @(
      "github.copilot",
      "github.copilot-chat",
      "ms-vscode-remote.remote-ssh",
      "ms-vscode.powershell",
      "tamasfe.even-better-toml",
      "vscodevim.vim",
      "dart-code.flutter"
    )
    UserData = @{
      "Source" = "$env:PROJECTROOT\user-data\vscode"
      "Target" = "$env:USERPROFILE\AppData\Roaming\Code\User"
    }
  }
}

$Scoop = [Scoop]::new()

function New-Profile {
  param (
    [string]$Path
  )

  if (Test-Path ($Path)) {
    Write-Debug "PowerShell profile already exists at: $Path"
    return
  }

  New-Item -ItemType File -Path $Path -Force | Out-Null
  Write-Host "PowerShell profile created at: $Path"
}

function Install-Git {
  Write-Host "Installing Git..."
  $Git = $Configurations.Git
  #$Scoop.InstallPackage("git", "main")

  git config --global user.email "$($Git.Email)"
  git config --global user.name "$($Git.Name)"

  git config --global credential.helper "$($Git.CredentialHelper)"
  git config --global init.defaultBranch "$($Git.DefaultBranch)"
  git config --global core.autocrlf "$($Git.AutoCRLF)"
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
  Add-LineToFile -Path "$env:WPSHPROFILE" -Line "Set-Alias neovim nvim"
}

function Install-PowerShell {
  if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Host "Install PowerShell"
    iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"
  }
}

function Install-VSCode {
  Write-Host "Installing VSCode..."
  $VSCode = $Configurations.VSCode
  #$Scoop.InstallPackage("vscode", "extras")

  Write-Host "Copying VSCode user keybindings..."
  $name = "keybindings.json"
  $source = "$($VSCode.UserData.Source)\$name"
  $target = "$($VSCode.UserData.Target)\$name"
  Backup-AndCopyFile "$source" "$target"

  Write-Host "Copying VSCode user settings..."
  $name = "settings.json"
  $source = "$($VSCode.UserData.Source)\$name"
  $target = "$($VSCode.UserData.Target)\$name"
  Backup-AndCopyFile "$source" "$target"

  Write-Host "Installing VSCode extensions..."
  $Code = [Code]::new()
  $Code.InstallExtensions($VSCode.Extensions)
}

Set-EnvironmentVariable "XDG_CONFIG_HOME" "$env:PROJECTROOT"
New-Profile $env:PWSHPROFILE
New-Profile $env:WPSHPROFILE
Install-PowerShell
Install-NeoVim
Install-Git
Install-VSCode