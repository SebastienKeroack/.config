# Windows Dev Environment Setup

This repository contains scripts and configuration for setting up a Windows development environment using PowerShell and Scoop.

## Prerequisites

- Windows PowerShell or PowerShell Core

## Setup Instructions

1. **Set PowerShell Execution Policy**  
   Allows running local scripts:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Install Scoop Package Manager**  
   Installs Scoop for managing developer tools:
   ```powershell
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

3. **Run the Setup Script**  
   Installs and configures all tools and settings:
   ```powershell
   ./tools/pwsh/setup.ps1
   ```
