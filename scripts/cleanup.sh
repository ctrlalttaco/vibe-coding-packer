#!/usr/bin/env bash
set -euo pipefail

echo "Starting enhanced security cleanup..."

# Detect distro
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  echo "Cannot detect Linux distribution!"
  exit 1
fi

echo "Detected distro: $DISTRO"

# Clear package caches
echo "Clearing package caches..."
case "$DISTRO" in
  amzn|rhel|rocky)
    if command -v yum &> /dev/null; then
      yum clean all
      rm -rf /var/cache/yum/*
    fi
    if command -v dnf &> /dev/null; then
      dnf clean all
      rm -rf /var/cache/dnf/*
    fi
    ;;
  ubuntu)
    if command -v apt-get &> /dev/null; then
      apt-get clean
      apt-get autoclean
      apt-get autoremove -y
      rm -rf /var/cache/apt/*
      rm -rf /var/lib/apt/lists/*
    fi
    ;;
esac

# Security-focused log cleanup
echo "Performing security-focused log cleanup..."
find /var/log -type f -name '*.log' -exec truncate -s 0 {} \;
find /var/log -type f -name '*.log.*' -delete
find /var/log -type f -name '*.[0-9]' -delete
find /var/log -type f -name '*.gz' -delete

# Clear specific security-sensitive logs
rm -f /var/log/wtmp*
rm -f /var/log/btmp*
rm -f /var/log/lastlog*
rm -f /var/log/faillog*
rm -f /var/log/tallylog*

# Clear audit logs if present
if [ -d /var/log/audit ]; then
  find /var/log/audit -type f -exec truncate -s 0 {} \;
fi

# Clear systemd journal logs
if command -v journalctl &> /dev/null; then
  journalctl --vacuum-time=1d
  journalctl --vacuum-size=10M
fi

# Clear temporary files and directories
echo "Clearing temporary files..."
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /root/tmp
rm -rf /home/*/tmp

# Clear user-specific temporary files
find /home -name ".cache" -type d -exec rm -rf {} + 2>/dev/null || true
find /home -name ".thumbnails" -type d -exec rm -rf {} + 2>/dev/null || true
find /home -name ".local/share/Trash" -type d -exec rm -rf {} + 2>/dev/null || true

# Clear bash history and command history
echo "Clearing command history..."
history -c && history -w
rm -f ~/.bash_history
rm -f /home/*/.bash_history
rm -f /root/.bash_history
rm -f ~/.zsh_history
rm -f /home/*/.zsh_history
rm -f /root/.zsh_history

# Clear SSH keys and known hosts
echo "Clearing SSH keys and known hosts..."
rm -f /home/*/.ssh/authorized_keys
rm -f /root/.ssh/authorized_keys
rm -f /home/*/.ssh/known_hosts
rm -f /root/.ssh/known_hosts
rm -f /home/*/.ssh/id_*
rm -f /root/.ssh/id_*

# Clear cloud-init data
echo "Clearing cloud-init data..."
rm -rf /var/lib/cloud/instances/*
rm -rf /var/lib/cloud/instance
rm -f /var/log/cloud-init*

# Clear network configuration that might contain sensitive data
echo "Clearing network configuration..."
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /etc/udev/rules.d/75-persistent-net-generator.rules

# Clear machine-id to ensure unique instances
echo "Clearing machine identifiers..."
if [ -f /etc/machine-id ]; then
  truncate -s 0 /etc/machine-id
fi
if [ -f /var/lib/dbus/machine-id ]; then
  truncate -s 0 /var/lib/dbus/machine-id
fi

# Clear hostname history
rm -f /etc/hostname.bak

# Clear mail spool
rm -rf /var/spool/mail/*
rm -rf /var/mail/*

# Clear cron logs and temporary files
rm -f /var/log/cron*
rm -rf /var/spool/cron/*
rm -rf /var/spool/at/*

# Clear kernel crash dumps
rm -rf /var/crash/*

# Clear swap files if any
swapoff -a 2>/dev/null || true
rm -f /swapfile
rm -f /swap.img

# Clear any core dumps
find / -name "core.*" -type f -delete 2>/dev/null || true
find / -name "*.core" -type f -delete 2>/dev/null || true

# Clear Python cache files
find / -name "*.pyc" -delete 2>/dev/null || true
find / -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Clear package manager metadata that might contain sensitive info
rm -rf /root/.rpmdb
rm -rf /var/lib/rpm/__db*

# Clear any Docker-related files if present
if [ -d /var/lib/docker ]; then
  rm -rf /var/lib/docker/tmp/*
  rm -rf /var/lib/docker/containers/*/
fi

# Clear systemd-resolved cache
if [ -f /var/lib/systemd/resolve/resolv.conf ]; then
  rm -f /var/lib/systemd/resolve/resolv.conf
fi

# Clear any Ansible facts cache
rm -rf /etc/ansible/facts.d/*
rm -rf /tmp/ansible-*

# Clear any certificates that might have been temporarily stored
find /tmp -name "*.crt" -delete 2>/dev/null || true
find /tmp -name "*.key" -delete 2>/dev/null || true
find /tmp -name "*.pem" -delete 2>/dev/null || true

# Clear any backup files that might contain sensitive data
find / -name "*.bak" -delete 2>/dev/null || true
find / -name "*~" -delete 2>/dev/null || true
find / -name ".#*" -delete 2>/dev/null || true

# Security hardening: Remove unnecessary SUID/SGID binaries
echo "Reviewing SUID/SGID binaries..."
# Note: This is informational only, actual removal would need careful consideration
find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -la {} \; 2>/dev/null | head -20 || true

# Clear any remaining sensitive environment variables
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset ANSIBLE_VAULT_PASSWORD
unset ANSIBLE_VAULT_PASSWORD_FILE

# Final filesystem sync
sync

echo "Enhanced security cleanup completed successfully."

# Display final security status
echo "=== Security Cleanup Summary ==="
echo "- Package caches cleared"
echo "- Security-sensitive logs cleared"
echo "- Temporary files removed"
echo "- Command history cleared"
echo "- SSH keys and known hosts removed"
echo "- Cloud-init data cleared"
echo "- Machine identifiers reset"
echo "- Core dumps and crash files removed"
echo "- Python cache files cleared"
echo "- Backup and temporary files removed"
echo "================================="
