#!/bin/bash

# install-gns3.sh
# Installs GNS3 GUI and Server on Debian 13

set -e  # Exit if any command fails
set -u  # Treat unset variables as errors

echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y software-properties-common python3-pyqt5 python3-pyqt5.qtsvg python3-setuptools python3-dev \
    python3-pyqt5.qtwebsockets git wget curl net-tools


# Add GNS3 official repository and GPG key
echo "Adding GNS3 official repository..."
sudo add-apt-repository ppa:gns3/ppa -y || {
    echo "PPA not available, adding manually."
    sudo apt install -y lsb-release
    echo "deb https://ppa.launchpadcontent.net/gns3/ppa/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gns3.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F8B239C15DE3D5F6
}
sudo apt update

echo "Installing GNS3 GUI and Server..."
echo "Installing pipx and virtualenv for Python user installs..."
sudo apt install -y pipx python3-venv
pipx ensurepath

echo "Setting up Python virtual environment for GNS3 Server..."
python3 -m venv ~/gns3-server-venv
source ~/gns3-server-venv/bin/activate
pip install --upgrade pip
pip install gns3-server
deactivate

echo "Downloading latest GNS3 GUI AppImage..."
GNS3_GUI_URL=$(curl -s https://api.github.com/repos/GNS3/gns3-gui/releases/latest | grep browser_download_url | grep AppImage | cut -d '"' -f 4)
if [ -n "$GNS3_GUI_URL" ]; then
    wget -O ~/GNS3.AppImage "$GNS3_GUI_URL"
    chmod +x ~/GNS3.AppImage
    echo "GNS3 GUI AppImage downloaded to ~/GNS3.AppImage. Run it to start the GUI."
else
    echo "Failed to find GNS3 GUI AppImage download URL. Please check https://github.com/GNS3/gns3-gui/releases manually."
fi

echo "GNS3 Server installed in ~/gns3-server-venv. Activate with: source ~/gns3-server-venv/bin/activate && gns3server"
echo "GNS3 GUI AppImage is in your home directory as GNS3.AppImage. Run it to start the GUI."

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
