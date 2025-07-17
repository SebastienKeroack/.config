using namespace System.Collections.Generic

class Code {
  [HashSet[string]]$Extensions
  [boolean]$RefreshCalled

  Code() {
    $this.Extensions = [HashSet[string]]::new()
    $this.RefreshCalled = $false
  }

  [void]RefreshCache() {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
      Write-Error "VS Code is not installed or not found in the PATH."
      return
    }

    foreach ($extension in (code --list-extensions)) {
      $this.Extensions.Add($extension)
    }

    $this.RefreshCalled = $true
  }

  [void]MaybeRefreshCache() {
    if (-not $this.RefreshCalled) {
      $this.RefreshCache()
    }
  }

  [void]InstallExtension([string]$Name) {
    $this.MaybeRefreshCache()

    if ($this.Extensions.Contains($Name)) {
      Write-Debug "VS Code extension '$Name' already installed."
      return
    }

    Write-Host "Installing VS Code extension: $Name"
    code --install-extension "$Name"
    $this.Extensions.Add($Name)
  }

  [void]InstallExtensions([string[]]$List) {
    foreach ($extension in $List) {
      $this.InstallExtension($extension)
    }
  }
}
