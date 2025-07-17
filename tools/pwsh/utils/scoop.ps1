using namespace System.Collections.Generic

class Scoop {
  [HashSet[string]]$Buckets
  [HashSet[string]]$Packages
  [boolean]$RefreshCalled

  Scoop() {
    $this.Buckets = [HashSet[string]]::new()
    $this.Packages = [HashSet[string]]::new()
    $this.RefreshCalled = $false
  }

  [void]RefreshCache() {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
      Write-Error "Scoop is not installed or not found in the PATH."
      return
    }

    foreach ($bucket in (scoop bucket list)) {
      $name = $bucket.Name
      if ($name) { $this.Buckets.Add($name) }
    }

    foreach ($pkg in (scoop list *>&1)) {
      $name = $pkg.Name
      if ($name) { $this.Packages.Add($name) }
    }

    $this.RefreshCalled = $true
  }

  [void]MaybeRefreshCache() {
    if (-not $this.RefreshCalled) {
      $this.RefreshCache()
    }
  }

  [void]AddBucket([string]$Name) {
    $this.MaybeRefreshCache()

    if ($this.Buckets.Contains($Name)) {
      Write-Debug "Bucket '$Name' already added."
      return
    }

    scoop bucket add $Name
    $this.Buckets.Add($Name)
  }

  [void]InstallPackage([string]$Name, [string]$Source = $null) {
    $this.MaybeRefreshCache()

    if ($this.Packages.Contains($Name)) {
      Write-Debug "Package '$Name' already installed."
      return
    }

    if ($Source) {
      $this.AddBucket($Source)
      scoop install $Name -s $Source
    } else {
      scoop install $Name
    }

    $this.Packages.Add($Name)
  }
}
