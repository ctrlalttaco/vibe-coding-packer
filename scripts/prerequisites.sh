#!/usr/bin/env bash
set -o verbose

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
    # Update system
    yum update -y
    # Install EPEL
    yum install -y epel-release
    # Install additional repositories
    yum install -y yum-utils
    ;;
  rhel)
    echo "Running RHEL-specific pre-reqs..."
    # Update system
    yum update -y
    # Install EPEL
    yum install -y epel-release
    # Enable additional repositories
    subscription-manager repos --enable rhel-*-optional-rpms --enable rhel-*-extras-rpms
    ;;
  rocky)
    echo "Running Rocky Linux-specific pre-reqs..."
    # Update system
    dnf update -y
    # Install EPEL
    dnf install -y epel-release
    # Enable PowerTools repository
    dnf config-manager --set-enabled powertools
    ;;
  ubuntu)
    echo "Running Ubuntu-specific pre-reqs..."
    # Update system
    apt-get update
    apt-get upgrade -y
    # Install additional repositories
    apt-get install -y software-properties-common
    ;;
  *)
    echo "Unknown distro: $DISTRO. Running generic pre-reqs..."
    # Generic package manager update
    if command -v yum &> /dev/null; then
      yum update -y
    elif command -v dnf &> /dev/null; then
      dnf update -y
    elif command -v apt-get &> /dev/null; then
      apt-get update && apt-get upgrade -y
    fi
    ;;
esac

echo "Pre-requisite steps completed successfully."
