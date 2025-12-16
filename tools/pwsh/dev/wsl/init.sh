#!/usr/bin/env bash
#                       Copyright 2025, Sébastien Kéroack
#                             All rights reserved.
#
#  Unauthorized copying, modification, distribution, or use of this code,
#  via any medium, is strictly prohibited without the express
#  written permission of the author.
# ==============================================================================

set -u

# see: https://github.com/asdf-vm/asdf/releases
ASDF_VER="0.18.0"
ASDF_ARCHIVE="asdf-v$ASDF_VER-linux-amd64.tar.gz"
ASDF_ARCHIVE_URL="https://github.com/asdf-vm/asdf/releases/download/v$ASDF_VER/$ASDF_ARCHIVE"
CURRENT_USER=$(whoami)

# Add a newline before the shell prompt in .bashrc
tee -a ~/.bashrc <<EOF
# Add a newline before the shell prompt in .bashrc if not already present:
if [[ "\$PS1" != *"\\n\\$ "* ]]; then
  PS1=\$(echo "\$PS1" | sed 's/\\\\$ /\\\n\\\\$ /')
fi
EOF

# Setup WSL Ubuntu configuration
echo "# @see: https://learn.microsoft.com/en-us/windows/wsl/wsl-config
[boot]
command=\"\"
systemd=true

[automount]
enabled=true

[network]
generateHosts=true
generateResolvConf=true

[interop]
appendWindowsPath=true

[gpu]
enabled=true

[time]
useWindowsTimezone=true

[user]
default=$CURRENT_USER" | sudo tee /etc/wsl.conf

sudo apt-get update
sudo apt-get upgrade -y

# Install ASDF
sudo apt-get install -y git git-lfs unzip zip
mkdir -p "$HOME/.local/bin"
curl -Lo "$ASDF_ARCHIVE" "$ASDF_ARCHIVE_URL"
tar -xzf "$ASDF_ARCHIVE" -C "$HOME/.local/bin"
rm -f "$ASDF_ARCHIVE"
chmod +x "$HOME/.local/bin/asdf"
echo 'export PATH="$PATH:$HOME/.local/bin:$HOME/.asdf/shims"' >> "$HOME/.bash_profile"
source "$HOME/.bash_profile"

# Install Clang
sudo apt-get install -y make llvm-18 clang-18 clang-format

# Set clang and clang++ to use version 18 by default
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100

# Set LLVM to use version 18 by default
sudo update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-18 100

# Clean up
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*