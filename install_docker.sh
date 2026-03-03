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

install_docker
