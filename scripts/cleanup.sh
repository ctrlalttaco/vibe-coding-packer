#!/bin/bash
set -e

echo "Running cleanup steps..."

# Detect distro
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  echo "Cannot detect Linux distribution!"
  exit 1
fi

echo "Detected distro: $DISTRO"

case "$DISTRO" in
  amzn)
    echo "Running Amazon Linux-specific cleanup..."
    yum clean all || true
    rm -rf /var/cache/yum
    ;;
  ubuntu)
    echo "Running Ubuntu-specific cleanup..."
    # Clean apt cache
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    ;;
  rhel)
    echo "Running RHEL-specific cleanup..."
    # Clean yum/dnf cache
    if command -v dnf >/dev/null 2>&1; then
      dnf clean all
    else
      yum clean all
    fi
    rm -rf /var/cache/yum
    ;;
  rocky)
    echo "Running Rocky Linux-specific cleanup..."
    if command -v dnf >/dev/null 2>&1; then
      dnf clean all
    else
      yum clean all
    fi
    rm -rf /var/cache/yum
    ;;
  *)
    echo "Unknown distro: $DISTRO. No specific cleanup run."
    ;;
esac

# Common cleanup for all distros

# Remove SSH host keys
rm -f /etc/ssh/ssh_host_*

# Truncate log files
find /var/log -type f -exec truncate -s 0 {} \;

# Remove cloud-init logs and data
rm -rf /var/lib/cloud/instances
rm -f /var/log/cloud-init.log /var/log/cloud-init-output.log

# Remove machine-id
truncate -s 0 /etc/machine-id || true
rm -f /var/lib/dbus/machine-id

# Remove temporary files
rm -rf /tmp/* /var/tmp/*

# Remove history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/*/.bash_history

# Sync to ensure all data is written to disk
sync
