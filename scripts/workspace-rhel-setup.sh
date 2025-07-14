#!/bin/bash
set -e

# Amazon Workspaces required packages for RHEL 8 and 9
# See: https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-linux-2.html (for reference)

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION_ID=${VERSION_ID%%.*}
else
    echo "Cannot detect Linux distribution!"
    exit 1
fi

if [[ "$DISTRO" != "rhel" ]]; then
    echo "This script is intended for RHEL 8 or 9 only."
    exit 1
fi

if [[ "$VERSION_ID" != "8" && "$VERSION_ID" != "9" ]]; then
    echo "This script is intended for RHEL 8 or 9 only."
    exit 1
fi

echo "Detected RHEL $VERSION_ID. Installing Amazon Workspaces required packages..."

# Update and install EPEL
sudo yum -y update
sudo yum -y install epel-release

# Install required packages (common for both RHEL 8 and 9)
sudo yum -y install \
    xorg-x11-server-Xorg \
    xorg-x11-xauth \
    xorg-x11-apps \
    xorg-x11-xinit \
    xorg-x11-utils \
    xorg-x11-fonts-Type1 \
    xorg-x11-fonts-misc \
    xorg-x11-drivers \
    gnome-session \
    gnome-terminal \
    gnome-classic-session \
    gnome-panel \
    metacity \
    nautilus \
    control-center \
    liberation-fonts \
    firefox \
    NetworkManager \
    polkit \
    polkit-gnome \
    gdm \
    dbus-x11 \
    alsa-utils \
    pulseaudio \
    pulseaudio-utils \
    pavucontrol \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-good \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    gstreamer1-plugins-base-tools

# Enable graphical target
sudo systemctl set-default graphical.target

# Enable and start GDM
sudo systemctl enable gdm
sudo systemctl start gdm

echo "Amazon Workspaces required packages installed. Please reboot to start the graphical environment." 