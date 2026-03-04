# Checklist


---

# P1 | GNS3 + Docker + Routing Stack Validation Checklist

## ✅ OVERVIEW OF WHAT YOU MUST PRODUCE

### Image 1 – Minimal host
- [ ] Based on Alpine (recommended)
- [ ] Must contain busybox (or equivalent)
- [ ] No IP configured by default

### Image 2 – Routing router
- [ ] Must include Routing suite (FRRouting recommended instead of old zebra/quagga)
- [ ] BGP daemon active
- [ ] OSPF daemon active
- [ ] IS-IS daemon active
- [ ] Must contain busybox or equivalent
- [ ] No IP configured by default

### Project Requirements
- [ ] Import both images into GNS3
- [ ] Build a small topology
- [ ] Be able to access both machines via console
- [ ] Name devices with your login (example: yilin-router, yilin-host)
- [ ] Export the project as ZIP including base images
- [ ] Store everything inside `/P1` at repo root


---

## 0 GNS3 / Docker install in vm

- [x] Install required base system packages
- [x] Install Docker Engine and enable service
- [x] Install GNS3 GUI and Server via `pipx`
- [x] Add user to relevant groups (`docker`, `libvirt`, `kvm`, `wireshark`, `ubridge`)
- [x] root succesfully installed with ssh, docker, gns3
- [x] user installed with ssh,docker, gns3
> check ssh status 
```bash
systemctl status ssh || systemctl status sshd
whoami
```
> copy ssh frm root to user(yilin) -> use same ssh 
```bash
# in user
sudo cp -r /root/.ssh/ /home/yilin/
sudo chown -R yilin:yilin /home/yilin/.ssh/
```


## 1️⃣ Environment Validation

### Docker

- [x] `docker ps` runs without error
- [ ] `docker build` works successfully
- [ ] Container starts without crashing
- [x] No permission issues

### GNS3

- [x] GNS3 GUI connects to local server
- [ ] Docker integration enabled in Preferences
- [ ] Docker template can be created
- [ ] Console access works

---

## 2️⃣ Image #1 – Minimal Host (Alpine + Busybox)

###  Build

- [ ] Image builds successfully
- [ ] Container starts correctly
- [ ] Shell accessible from GNS3

###  Runtime Behavior

- [ ] No IP address configured in Dockerfile
- [ ] No startup script assigns IP
- [ ] `ip addr` shows interface from GNS3
- [ ] IP can be manually assigned
- [ ] Can ping connected neighbor

---

## 3️⃣ Image #2 – Routing Container (FRRouting)

### # Services Running

- [ ] zebra is running
- [ ] bgpd is running
- [ ] ospfd is running
- [ ] isisd is running
- [ ] `vtysh` works
- [ ] No daemon crashes

###  Kernel Forwarding

- [ ] `net.ipv4.ip_forward = 1`

---

## 4️⃣ BGP Validation

- [ ] `show ip bgp summary` shows neighbor
- [ ] State = Established
- [ ] Correct AS numbers configured
- [ ] Prefixes are advertised
- [ ] Routes appear in routing table

---

## 5️⃣ OSPF Validation

- [ ] `show ip ospf neighbor` shows adjacency
- [ ] State = Full
- [ ] Routes learned via OSPF
- [ ] Routes appear in routing table

---✅ P1 – Step

## 6️⃣ IS-IS Validation

- [ ] `show isis neighbor` shows adjacency
- [ ] Correct level (L1/L2) configured
- [ ] Routes installed in routing table

---

## 7️⃣ Routing Table Verification

- [ ] `ip route` shows learned routes
- [ ] Not only directly connected rou✅ P1 – Steptes
- [ ] BGP / OSPF / IS-IS routes visible
- [ ] Forwarding works between networks

---

## 8️⃣ GNS3 Topology

- [ ] Two custom Docker images used
- [ ] Equipment names include login
- [ ] Interfaces connected correctly
- [ ] Consoles accessible
- [ ] No default IP inside images

---

## 9️⃣ Connectivity Tests

- [ ] Host can ping router
- [ ] Router can ping host
- [ ] End-to-end ping works through routing protocol
- [ ] Traceroute shows correct path

---

## 🔟 Repository Structure
```bash
/P1
/docker-host
/docker-router
/configs
project.gns3
exported_project.zip
```


- [ ] Dockerfiles included
- [ ] FRR configuration files included
- [ ] Configurations are commented
- [ ] Portable GNS3 project exported
- [ ] Base images included in ZIP
- [ ] Everything reproducible on fresh VM

---

## 🎯 Final Validation

- [ ] No hardcoded IP addresses in images
- [ ] Routing daemons stable
- [ ] Neighbor relationships established
- [ ] Routes propagate correctly
- [ ] Connectivity fully functional
- [ ] Project clean and documented

---

# P2 | Discovering a VXLAN Checklist

## 1️⃣ General Requirements
- [ ] Project rendered in a `/P2` folder at the root of the git repository.
- [ ] Equipment names correctly include the login of one of the group members (e.g., `router_yilin`).
- [ ] Base images are included in the ZIP export.
- [ ] Zip export is visible in the Git repository.

## 2️⃣ Static Setup
- [ ] VXLAN network configured in static mode.
- [ ] VXLAN ID set to `10`.
- [ ] VXLAN interface named `vxlan10`.
- [ ] Bridge configured named `br0`.
- [ ] Ethernet interfaces correctly assigned/configured.

## 3️⃣ Dynamic Multicast Setup
- [ ] VXLAN network configured in dynamic multicast mode.
- [ ] VXLAN ID set to `10` with bridge `br0` and interface `vxlan10`.
- [ ] Multicast group correctly configured (e.g., `239.1.1.1` or modified custom group).
- [ ] Multicast group assignment verified on machines.
- [ ] MAC address tables correctly populated across routers.

## 4️⃣ Testing & Traffic
- [ ] Traffic visualization/inspection confirms communication between the two machines in the VXLAN.
- [ ] Ping/Connectivity operational across the VXLAN in both static and dynamic stages.

## 5️⃣ Configuration & Documentation
- [ ] Configuration files provided for each equipment.
- [ ] Comments included in configuration files explaining the purpose of each setup block.
