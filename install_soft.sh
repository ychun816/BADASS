sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

need_cmd() { command -v "$1" >/dev/null 2>&1; }

install_docker() {
	if need_cmd docker; then
		echo "Docker already installed"
	else
		sudo install -m 0755 -d /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		sudo chmod a+r /etc/apt/keyrings/docker.gpg
		VERSION_CODENAME=$(grep "VERSION_CODENAME" /etc/os-release | cut -d= -f2)
		echo \
			"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
			https://download.docker.com/linux/debian \
			$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt-get update
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
		sudo systemctl enable docker
		sudo systemctl start docker
	fi
}

install_gns3() {
	if need_cmd gns3; then
		echo "gns3 installed"
	else
		sudo apt update
		sudo apt install python3 python3-pip pipx python3-pyqt6 python3-pyqt6.sip python3-pyqt6.qtwebsockets python3-pyqt6.qtsvg \
		qemu-kvm qemu-utils libvirt-clients libvirt-daemon-system virtinst software-properties-common gnupg2 \
		python3-pyqt5.sip python3-sip

		pipx install --system-site-packages gns3-server
		pipx install --system-site-packages gns3-gui
	fi
}


install_docker
install_gns3
