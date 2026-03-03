#!/bin/bash

# install-gns3.sh
# Installs GNS3 GUI and Server on Debian 13

set -e  # Exit if any command fails
set -u  # Treat unset variables as errors

echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y python3 python3-pip pipx python3-pyqt5 python3-pyqt5.qtwebsockets python3-pyqt5.qtsvg \
    qemu-kvm qemu-utils libvirt-clients libvirt-daemon-system virtinst dynamips \
    software-properties-common ca-certificates curl gnupg2 git wget net-tools

echo "Installing GNS3 GUI and Server using pipx..."
pipx ensurepath
pipx install gns3-server
pipx install gns3-gui

echo "Injecting GNS server and QT elements into GUI..."
pipx inject gns3-gui gns3-server PyQt5

echo "Adding current user to required groups..."
sudo usermod -aG libvirt,kvm,wireshark,docker $(whoami) || true
sudo adduser $USER ubridge || true

echo "Installing additional packages for Docker support in GNS3..."
sudo apt install -y docker.io

echo "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Installation complete!"
echo "Please log out and log back in (or reboot) to apply group changes."
echo "Then run 'gns3' to start the GUI."
