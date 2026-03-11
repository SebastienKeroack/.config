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
#ASDF_VER="0.18.0"
#ASDF_ARCHIVE="asdf-v$ASDF_VER-linux-amd64.tar.gz"
#ASDF_ARCHIVE_URL="https://github.com/asdf-vm/asdf/releases/download/v$ASDF_VER/$ASDF_ARCHIVE"
CURRENT_USER=$(whoami)

# Add a newline before the shell prompt in .bashrc
tee -a ~/.bashrc <<EOF

# Customize shell prompt:
if [[ "\$PS1" != *"\\n\\$ "* ]]; then
  PS1=\$(echo "\$PS1" | sed 's/\\\\$ /\\\n\\\\$ /')
fi
EOF

# Setup WSL Ubuntu configuration
tee /etc/wsl.conf <<EOF
# @see: https://learn.microsoft.com/en-us/windows/wsl/wsl-config
[boot]
systemd=true

[network]
hostname=node-cac1-az1-rackv-1
generateHosts=false
generateResolvConf=false

[interop]
appendWindowsPath=true

[gpu]
enabled=true

[time]
useWindowsTimezone=false

[user]
default=$CURRENT_USER

[automount]
enabled=true
mountFsTab=true
options="uid=1000,gid=1000,umask=22,fmask=11,metadata"
root=/mnt/
EOF

install_persistent_lan0_link_wsl() {
  local link_dir link_file

  link_dir="/etc/systemd/network"
  link_file="$link_dir/10-lan0.link"

  mkdir -p "$link_dir" || return 1

  # In WSL the vNIC MAC often changes between boots, so don't match on MAC.
  # Match the original kernel name (ethX) and rename it to lan0.
  cat > "$link_file" <<'EOF'
[Match]
OriginalName=eth*

[Link]
Name=lan0
EOF

  return 0
}

# Install persistent rule (takes effect next boot)
install_persistent_lan0_link_wsl || echo "failed to install persistent lan0 rule" >&2

# Update and upgrade packages
apt-get update
apt-get upgrade -y

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*