# VM Setup — Debian 12 + Docker + GNS3

---

## 1. Create the VM (VirtualBox)

### Recommended specs

| Setting | Value |
|---|---|
| OS type | Debian (64-bit) |
| RAM | 4096 MB minimum (8192 recommended) |
| CPUs | 2 minimum |
| Disk | 30 GB (dynamically allocated) |
| Network | NAT (add Host-Only adapter for SSH) |
| Display VRAM | 128 MB |

### Required VirtualBox settings

Before first boot:
- **System → Processor** → enable "Enable Nested VT-x/AMD-V" (needed for QEMU inside GNS3)
- **System → Acceleration** → Paravirtualization: KVM
- **Display** → Graphics Controller: VMSVGA

---

## 2. Install Debian 12

Boot from `debian-12.0.0-amd64-netinst.iso`.

### Key installer choices

```
Language:        English
Hostname:        badass (or your login)
Root password:   set one
New user:        yilin  (your login)
Partition:       Guided — use entire disk, all files in one partition
Software:        [*] SSH server
                 [*] standard system utilities
                 [ ] desktop environment  ← skip unless need GUI in VM
```

> If you need GNS3 GUI inside the VM (not via X11 forwarding), also select **Xfce** under desktop environments.

---

## 3. Post-install base setup

```bash
# Login as root, add your user to sudo
apt-get install -y sudo
usermod -aG sudo <yilin>

# Re-login as yilin, verify
sudo whoami    # should print: root
```

Install base tools:

```bash
sudo apt-get update && sudo apt-get install -y \
    curl wget git vim \
    net-tools iproute2 iputils-ping \
    ca-certificates gnupg lsb-release
```

---

## 4. Docker

### Install Docker CE

```bash
# Add Docker's GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list

# Install
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Enable at boot
sudo systemctl enable --now docker

# Allow your user to run docker without sudo
sudo usermod -aG docker $USER
newgrp docker    # apply group without logout
```

### Verify Docker

```bash
docker version               # shows Client + Server version
docker run --rm hello-world  # pulls and runs test container
docker ps                    # should show empty list (no running containers)
```

Expected output for `hello-world`:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

## 5. GNS3

### Install dependencies

```bash
sudo apt-get install -y \
    python3-pip python3-pyqt5 python3-pyqt5.qtsvg \
    python3-pyqt5.qtwebsockets \
    qemu-kvm libvirt-clients libvirt-daemon-system \
    dynamips wireshark
```

### Install ubridge

`ubridge` is a separate C binary — not a Python package — so `pip install gns3-server` cannot bundle it.
GNS3 server (Python) cannot directly manipulate raw network interfaces at the kernel level.
`ubridge` is a small C program that does exactly that: it bridges interfaces and forwards raw packets between GNS3 nodes and the host network.
Because it needs `cap_net_admin` and `cap_net_raw` (Linux capabilities for raw socket/interface access), it must be a standalone binary that you can `setcap` — you cannot `setcap` a Python script.

```
gns3-server (Python, pip)  → orchestrates topology, talks to GNS3 GUI
ubridge     (C binary)     → does the actual low-level network bridging
```

GNS3 server calls `ubridge` as a subprocess when connecting nodes. The `setcap` step below lets it do that without running as root.

It is not in the Debian 12 repos — build from source:

```bash
sudo apt-get install -y libpcap-dev make gcc
git clone https://github.com/GNS3/ubridge.git
cd ubridge && make && sudo make install
cd .. && rm -rf ubridge
```

Set capabilities so GNS3 can run it without root:

```bash
sudo setcap cap_net_admin,cap_net_raw=ep $(which ubridge)
```

### Install GNS3 server and GUI

```bash
pip3 install --user gns3-server gns3-gui
```

Add `~/.local/bin` to your PATH if not already there:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Group permissions

```bash
# GNS3 needs access to Docker socket and wireshark
sudo usermod -aG docker,wireshark $USER
newgrp docker
```

> Logout and back in (or run `newgrp docker`) to activate group membership.

### Verify GNS3

```bash
gns3server --version     # prints version, e.g. 2.2.x
gns3 --version           # GUI version
```

Check Docker is visible to GNS3:

```bash
gns3server &             # start server in background
curl -s http://localhost:3080/v2/version | python3 -m json.tool
# should return JSON with "version" key
```

Launch GUI:

```bash
gns3
```

Go to **Edit → Preferences → Docker** — it should auto-detect the Docker socket at `/var/run/docker.sock`.

---

## Quick verification checklist

```bash
# Docker
docker version                          # client + server both show
docker run --rm alpine echo ok          # prints: ok

# Docker image build (router)
docker build -t yilin-router P1/docker-images/router/
docker images | grep yilin-router       # image appears

# ubridge
which ubridge && ubridge --version

# GNS3 server
gns3server --version
curl -s http://localhost:3080/v2/version

# Groups
groups    # should include: docker wireshark
```

---

## GNS3 + Docker — workflow reminder

```
1. Build Docker images on the VM
2. Open GNS3 GUI → Edit → Preferences → Docker containers → New
3. Enter image name (e.g. yilin-router or alpine)
4. Set adapters count and console type (telnet)
5. Drag node onto canvas → right-click → Start → Console
```
