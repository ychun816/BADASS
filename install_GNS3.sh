#!/bin/bash

# install-gns3.sh
# Installs GNS3 GUI and Server on Debian 13

set -e  # Exit if any command fails
set -u  # Treat unset variables as errors

echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y software-properties-common python3-pyqt5 python3-pyqt5.qtsvg python3-pip python3-setuptools python3-dev \
    python3-wheel python3-pyqt5.qtwebsockets git wget curl net-tools

echo "Installing GNS3 GUI and Server..."
sudo apt install -y gns3-gui gns3-server

echo "Adding current user to ubridge group (required for GNS3 networking)..."
sudo adduser $USER ubridge || true  # ignore if user already in group

echo "Adding current user to kvm group (if KVM virtualization needed)..."
sudo adduser $USER kvm || true

echo "Installing additional packages for Docker support in GNS3..."
sudo apt install -y docker.io

echo "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Installation complete!"
echo "Please log out and log back in (or reboot) to apply group changes."
echo "Then run 'gns3' to start the GUI."
