$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/utils.ps1"

$XDGConfigHome = Get-ProjectRoot

$NerdFont = 'RobotoMono-NF-Mono'

$NeoVimExtraPackages = @(
  'lazygit',
  'vcredist2022'
)

$NeoVimPackages = @(
  'fd',
  'fzf',
  'zig',
  'pwsh',
  'nodejs',
  'ripgrep'
)

$VSCodeExtensions = @(
  'github.copilot',
  'github.copilot-chat',
  'ms-vscode.powershell',
  'tamasfe.even-better-toml',
  'vscodevim.vim'
)

$VSCodeUserCfgPath = "$env:USERPROFILE\scoop\apps\vscode\current\data\user-data\User\settings.json"

$VSCodeUserPreCfgPath = "$XDGConfigHome\user-data\vscode\settings.json"

$VSCodeUserKbmPath = "$env:USERPROFILE\scoop\apps\vscode\current\data\user-data\User\keybindings.json"

$VSCodeUserPreKbmPath = "$XDGConfigHome\user-data\vscode\keybindings.json"

$VSCodePwshAddExePaths = @{
  'scoop' = "${env:USERPROFILE}\scoop\shims\pwsh.exe"
}

function New-Profile {
  if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "PowerShell profile created at: $PROFILE"
  } else {
    Write-Debug "PowerShell profile already exists at: $PROFILE"
  }
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
  Add-LineToFile -Path $PROFILE -Line 'Set-Alias neovim nvim'
}

function Install-Git {
  Install-ScoopBucket 'main'
  Install-ScoopPackage 'git'

  git config --global core.ignorecase false
  git config --global credential.helper 'store'
  git config --global init.defaultBranch 'main'
  git config --global user.email 'dev@sebastienkeroack.com'
  git config --global user.name 'Sébastien Kéroack'
  git config --system core.longpaths true
}

function Install-VSCode {
  Install-ScoopBucket 'extras'
  Install-ScoopPackage 'vscode' -Source 'extras'

  foreach ($path in @($VSCodeUserPreCfgPath, $VSCodeUserCfgPath)) {
    $dir = [System.IO.Path]::GetDirectoryName($path)
    if (-not (Test-Path $dir)) {
      Write-Error "Directory does not exist: $dir"
      return
    }
  }

  Backup-AndCopyFile $VSCodeUserPreCfgPath $VSCodeUserCfgPath
  Backup-AndCopyFile $VSCodeUserPreKbmPath $VSCodeUserKbmPath

  $Cfg = Get-Content $VSCodeUserCfgPath -Raw | ConvertFrom-Json
  $Cfg | Add-Member `
    -NotePropertyName 'powershell.powerShellAdditionalExePaths' `
    -NotePropertyValue $VSCodePwshAddExePaths -Force
  $Cfg | ConvertTo-Json -Depth 9 | `
    Set-Content -Path $VSCodeUserCfgPath -Encoding UTF8

  Install-VSCodeExtensions -Extensions $VSCodeExtensions
}

Set-EnvironmentVariable 'XDG_CONFIG_HOME' $XDGConfigHome
New-Profile
Install-ScoopPackage 'pwsh'
Install-NeoVim
Install-Git
Install-VSCode