# BADASS — Bgp At Doors of Autonomous Systems is Simple

Simulate a small data center using GNS3, Docker, VXLAN, and BGP EVPN.

---

## Index

- [Part 1 — GNS3 + Docker setup](p1_readme.md)
- [Part 2 — Discovering VXLAN](p2_readme.md)
- [Part 3 — BGP with EVPN](p3_readme.md)

---

## Part 1 — GNS3 configuration with Docker

**Concepts to learn:**
- Docker: `FROM`, `RUN`, `CMD`, `ENTRYPOINT` — build two images from scratch
- **FRR** (Free Range Routing): modern successor to Quagga; bundles `zebra`, `bgpd`, `ospfd`, `isisd` as daemons — `zebra` is the core that programs the Linux kernel routing table, all routing daemons (bgpd, ospfd, isisd) talk to zebra
- **GNS3**: network emulator that runs Docker containers as nodes connected by virtual links; access each container via its GNS3 console (telnet)
- Why "no default IP": the same two images are reused across P1 → P2 → P3 — IPs are assigned per-topology at runtime, never baked into the image

**Repo structure:**
```
P1/
├── P1.gns3project              ← ZIP export (File > Export portable project, include base images)
├── _ychun-1_host               ← commented config explaining host container setup
└── _ychun-2_routeur            ← commented config explaining router container setup

docker-images/
├── host/
│   ├── Dockerfile              ← Image 1: Debian 13 trixie + busybox
│   └── entrypoint.sh
└── router/
   ├── Dockerfile              ← Image 2: Debian 13 trixie + FRR
    ├── daemons                 ← bgpd=yes, ospfd=yes, isisd=yes, zebra=yes
    ├── frr.conf                ← FRR config skeleton (no IPs)
    └── sysctl.conf             ← net.ipv4.ip_forward=1
```

**Workflow:**
1. Build `host` image: Debian 13 trixie + `busybox iproute2 iputils-ping bash`
2. Build `router` image: Debian 13 trixie + FRR, copy `daemons` file enabling all four services
3. Import both Docker images into GNS3 as Docker appliances (no persistent IP configured)
4. Build topology: `host_ychun-1` ↔ `routeur_ychun`
5. Start both nodes, verify with `ps` — expect `zebra`, `bgpd`, `ospfd`, `isisd` running in the router
6. Export: GNS3 → File → Export portable project → ZIP with base images → `P1.gns3project`

---

## Part 2 — Discovering a VXLAN

**Concepts to learn:**
- **VXLAN** (RFC 7348): tunnels L2 Ethernet frames over UDP port 4789 — lets machines on different physical segments act as if on the same LAN
- **VNI** (VXLAN Network Identifier): the "VLAN ID" of the overlay network — use `10` throughout this project
- **VTEP** (VXLAN Tunnel Endpoint): the router interface that encapsulates outgoing frames into VXLAN-UDP and decapsulates incoming ones
- **Bridge `br0`**: a software L2 switch — attach both the physical `eth` and `vxlan10` to it so traffic forwards between real hosts and the tunnel
- **Static mode**: each VTEP hard-codes the remote VTEP IP (`remote <peer_ip>`) — simple, no multicast needed
- **Dynamic multicast mode**: VTEPs join a multicast group (e.g. `239.1.1.1`) and flood BUM (Broadcast/Unknown/Multicast) traffic to the group instead of manual peer config

**Repo structure:**
```
P2/
├── P2.gns3project
├── _ychun-1_host
├── _ychun-1_s                  ← static VXLAN config for routeur_ychun-1
├── _ychun-1_g                  ← multicast VXLAN config for routeur_ychun-1
├── _ychun-2_host
├── _ychun-2_s
└── _ychun-2_g
```

**Workflow:**
1. Topology: `Switch_ychun` ↔ `routeur_ychun-1` + `routeur_ychun-2`, each router ↔ one host
2. Assign IPs to router `eth0` interfaces (e.g. `30.1.1.1/24`, `30.1.1.2/24`)
3. **Static VXLAN** on each router:
   ```sh
   ip link add vxlan10 type vxlan id 10 remote <peer_eth0_ip> dstport 4789 dev eth0
   ip link add br0 type bridge
   ip link set vxlan10 master br0 && ip link set eth1 master br0
   ip link set vxlan10 up && ip link set br0 up
   ```
4. **Multicast VXLAN**: replace `remote <ip>` with `group 239.1.1.1 dev eth0` — both VTEPs join the same group
5. Verify: `brctl showmacs br0` shows learned MACs; hosts ping each other across the tunnel
6. Capture in Wireshark — confirm VXLAN header with VNI=10 wrapping the inner Ethernet frame
7. Export as `P2.gns3project`

---

## Part 3 — BGP with EVPN

**Concepts to learn:**
- **BGP EVPN** (RFC 7432): uses BGP as the control plane for VXLAN — replaces static/multicast VTEP discovery with BGP route advertisements; MACs are learned automatically without flooding
- **Route Reflector (RR)**: a central BGP peer that re-advertises routes to all clients — avoids a full iBGP mesh; leaves only peer with the RR
- **Leaves / VTEPs**: edge routers connecting hosts to the overlay; advertise their MAC/IP bindings via BGP EVPN and receive peers' bindings automatically
- **OSPF as underlay**: routes loopback IPs (`1.1.1.x/32`) between all routers so BGP sessions use stable loopback addresses, independent of physical link IPs
- **EVPN route types**:
1. Topology: `_ychun-1` (RR) with 3 links to leaves `_ychun-2`, `_ychun-3`, `_ychun-4`; each leaf connects one host
2. **OSPF underlay** on all routers: advertise loopback (`1.1.1.x/32`) + point-to-point links → all routers learn all loopbacks
  - **Type 2** (MAC/IP Advertisement): auto-generated when a host becomes active — signals "this MAC lives behind my VTEP"
  - **Type 3** (IMET / Inclusive Multicast): pre-configured per VTEP — announces "I handle VNI 10, send BUM traffic here"
- **`address-family l2vpn evpn`**: the BGP sub-family where EVPN routes are activated; `advertise-all-vni` on leaves tells FRR to auto-generate type-3 routes for all local VNIs

**Repo structure:**
```
P3/
├── P3.gns3project
├── _ychun-1                    ← RR: OSPF + BGP route-reflector config
├── _ychun-2                    ← Leaf: OSPF + BGP + VXLAN + bridge config
├── _ychun-2_host
├── _ychun-3
├── _ychun-3_host
├── _ychun-4
└── _ychun-4_host
```

**Workflow:**
1. Topology: `_ychun-1` (RR) with 3 links to leaves `_ychun-2`, `_ychun-3`, `_ychun-4`; each leaf connects one host
2. **OSPF underlay** on all routers: advertise loopback (`1.1.1.x/32`) + point-to-point links → all routers learn all loopbacks
3. **BGP on RR** (`_ychun-1`, router-id `1.1.1.1`, AS 1):
   - Peer with each leaf loopback, `update-source lo`, `route-reflector-client`
   - `address-family l2vpn evpn` → `neighbor X activate`, `route-reflector-client`
4. **BGP on leaves** (router-id `1.1.1.x`, AS 1):
   - Peer with RR loopback only, `update-source lo`
   - `address-family l2vpn evpn` → `neighbor RR activate`, `advertise-all-vni`
5. **VXLAN on each leaf**: `ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.x` (no `remote` — BGP handles discovery), attach to `br0` with local host-facing `eth`
6. Start hosts — verify `show bgp l2vpn evpn`: type-3 routes appear (one per VTEP); type-2 routes appear as hosts send traffic
7. Ping between hosts on different VTEPs — Wireshark confirms VXLAN VNI=10 + ICMP + OSPF Hello packets
8. Export as `P3.gns3project` 

---

## install commands 

1. Install Docker on Debian 13

```bash
sudo apt update
sudo apt install -y docker.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
newgrp docker

#verify
docker --version
sudo systemctl status docker --no-pager
docker ps
docker run --rm hello-world

```

2. Install GNS3 on Debian 13
```bash
sudo apt update
sudo apt install -y python3-pip python3-venv pipx
pipx ensurepath
pipx install gns3-gui
pipx install gns3-server



#verify
which gns3-gui
which gns3server
gns3-gui --version
gns3server --version
pipx list | grep -i gns3
```

3. Build the P1 Docker images inside the VM
Host image:

```
cd /home/yilin/GITHUB/badass/P1/docker-images/host
docker build -t ychun-host:trixie .
```
Router image:
```
cd /home/yilin/GITHUB/badass/P1/docker-images/router
docker build -t ychun-router:trixie .
```

4. Check that the images exist
```
docker images | grep ychun
```

5. Open GNS3 and import the images
6. Create the topology
- `yilin-host`
- `yilin-router`

7. Verify inside the containers
```bash
# host
ip addr
# router
ps -ef | grep -E 'zebra|bgpd|ospfd|isisd'
vtysh -c "show running-config"
```

8. Export the portable project
