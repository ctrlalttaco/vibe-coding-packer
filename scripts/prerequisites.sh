#!/bin/bash
set -e

echo "Running pre-requisite steps..."

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
    echo "Running Amazon Linux-specific pre-reqs..."
    # Add Amazon Linux-specific commands here
    ;;
  rhel)
    echo "Running RHEL-specific pre-reqs..."
    # Add RHEL-specific commands here
    ;;
  rocky)
    echo "Running Rocky Linux-specific pre-reqs..."
    # Add Rocky Linux-specific commands here
    ;;
  ubuntu)
    echo "Running Ubuntu-specific pre-reqs..."
    # Add Ubuntu-specific commands here
    ;;
  *)
    echo "Unknown distro: $DISTRO. No specific pre-reqs run."
    ;;
esac
