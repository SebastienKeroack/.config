$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/utils.ps1"

$XDGConfigHome = Get-ProjectRoot

$GitUserEmail = 'dev@sebastienkeroack.com'

$GitUserName = 'Sébastien Kéroack'

$NerdFont = 'RobotoMono-NF-Mono'

$NeoVimExtraPackages = @(
  'lazygit',
  'vcredist2022'
)

$NeoVimPackages = @(
  'fd',
  'fzf',
  'zig',
  'nodejs',
  'ripgrep'
)

$RequiredPackages = @(
  'pwsh'
)

$VSCodeExtensions = @(
  'github.copilot',
  'github.copilot-chat',
  'ms-vscode.powershell',
  'tamasfe.even-better-toml',
  'vscodevim.vim'
)

$VSCodeUserCfgSrcPath = "$XDGConfigHome\user-data\vscode\settings.json"

$VSCodeUserCfgDstPath = "$env:USERPROFILE\scoop\apps\vscode\current\data\user-data\User\settings.json"

$VSCodeUserKbmSrcPath = "$XDGConfigHome\user-data\vscode\keybindings.json"

$VSCodeUserKbmDstPath = "$env:USERPROFILE\scoop\apps\vscode\current\data\user-data\User\keybindings.json"

$VSCodeTermExtWindowsExe = "${env:USERPROFILE}\scoop\shims\pwsh.exe"

$VSCodePwshAddExePaths = @{
  'scoop' = $VSCodeTermExtWindowsExe
}

function New-Profile {
  $Path = Get-PwshProfilePath
  if (-not (Test-Path $Path)) {
    New-Item -ItemType File -Path $Path -Force | Out-Null
    Write-Host "PowerShell profile created at: $Path"
  } else {
    Write-Debug "PowerShell profile already exists at: $Path"
  }
}

function Install-Git {
  Install-ScoopBucket 'main'
  Install-ScoopPackage 'git'

  git config --global core.ignorecase false
  git config --global credential.helper 'store'
  git config --global init.defaultBranch 'main'
  git config --global user.email $GitUserEmail
  git config --global user.name $GitUserName
  git config --system core.longpaths true
}

function Install-NeoVim {
  Install-ScoopBucket 'nerd-fonts'
  Install-ScoopPackage $NerdFont -Source 'nerd-fonts'

  Install-ScoopBucket 'extras'
  foreach ($pkg in $NeoVimExtraPackages) {
    Install-ScoopPackage $pkg -Source 'extras'
  }

  Install-ScoopBucket 'main'
  foreach ($pkg in $NeoVimPackages) {
    Install-ScoopPackage $pkg -Source 'main'
  }

  Install-ScoopPackage 'alacritty' -Source 'extras'
  New-Junction 'alacritty'

  Install-ScoopPackage 'neovim'
  Add-LineToFile -Path (Get-PwshProfilePath) -Line 'Set-Alias neovim nvim'
}

function Install-RequiredPackages {
  Install-ScoopBucket 'main'
  foreach ($pkg in $RequiredPackages) {
    Install-ScoopPackage $pkg -Source 'main'
  }
}

function Install-VSCode {
  Install-ScoopBucket 'extras'
  Install-ScoopPackage 'vscode' -Source 'extras'

  foreach ($path in @($VSCodeUserCfgSrcPath, $VSCodeUserCfgDstPath)) {
    $dir = [System.IO.Path]::GetDirectoryName($path)
    if (-not (Test-Path $dir)) {
      Write-Error "Directory does not exist: $dir"
      return
    }
  }

  Backup-AndCopyFile $VSCodeUserCfgSrcPath $VSCodeUserCfgDstPath
  Backup-AndCopyFile $VSCodeUserKbmSrcPath $VSCodeUserKbmDstPath

  $Cfg = Get-Content $VSCodeUserCfgDstPath -Raw | ConvertFrom-Json
  $Cfg | Add-Member `
    -NotePropertyName 'terminal.external.windowsExec' `
    -NotePropertyValue $VSCodeTermExtWindowsExe -Force
  $Cfg | Add-Member `
    -NotePropertyName 'powershell.powerShellAdditionalExePaths' `
    -NotePropertyValue $VSCodePwshAddExePaths -Force
  $Cfg | ConvertTo-Json -Depth 9 | `
    Set-Content -Path $VSCodeUserCfgDstPath -Encoding UTF8

  Install-VSCodeExtensions -Extensions $VSCodeExtensions
}

Set-EnvironmentVariable 'XDG_CONFIG_HOME' $XDGConfigHome
New-Profile
Install-RequiredPackages
Install-NeoVim
Install-Git
Install-VSCode