# Checklist

---

# P1 | GNS3 + Docker + Routing Stack

## What you must produce

### Image 1 – Host
- [ ] Use `docker pull alpine:latest` — no custom Dockerfile
- [ ] No IP configured by default
- [ ] Shell accessible from GNS3 console

### Image 2 – Router
- [ ] Based on `alpine:latest` with FRR installed
- [ ] bgpd active
- [ ] ospfd active
- [ ] isisd active
- [ ] staticd active
- [ ] zebra active
- [ ] No IP configured by default
- [ ] vxlan-unicast.sh and vxlan-multicast.sh present in image (for P2)

### Project Requirements
- [ ] Both images imported into GNS3
- [ ] Topology built: `host_yilin` ↔ `router_yilin`
- [ ] Console accessible for both nodes
- [ ] Node names include login (e.g., `router_yilin`, `host_yilin`)
- [ ] GNS3 project exported as ZIP including base images (`P1.gns3project`)
- [ ] `P1/host` and `P1/router` config files present and commented

---

## 0 | GNS3 / Docker install in VM

- [x] Install required base system packages
- [x] Install Docker Engine and enable service
- [x] Install GNS3 GUI and Server via `pipx`
- [x] Add user to relevant groups (`docker`, `libvirt`, `kvm`, `wireshark`, `ubridge`)
- [x] root successfully installed with ssh, docker, gns3
- [x] user installed with ssh, docker, gns3

> Check SSH status
```bash
systemctl status ssh || systemctl status sshd
whoami
```

> Copy SSH from root to user
```bash
sudo cp -r /root/.ssh/ /home/yilin/
sudo chown -R yilin:yilin /home/yilin/.ssh/
```

---

## 1 | Environment Validation

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

## 2 | Image 1 – Host (`alpine:latest`)

### Setup
- [ ] `docker pull alpine:latest` succeeds
- [ ] Image added to GNS3 as Docker appliance (1 adapter, telnet console)

### Runtime
- [ ] No IP address assigned by default
- [ ] `ip addr` shows interface with no IP
- [ ] IP can be manually assigned: `ip addr add X.X.X.X/24 dev eth0`
- [ ] Can ping connected neighbor

---

## 3 | Image 2 – Router (`yilin-router`)

### Build
- [ ] `docker build -t yilin-router P1/docker-images/router/` succeeds
- [ ] Image added to GNS3 as Docker appliance (2+ adapters, telnet console)

### Services running
- [ ] `zebra` is running
- [ ] `bgpd` is running
- [ ] `ospfd` is running
- [ ] `isisd` is running
- [ ] `staticd` is running
- [ ] `vtysh` works
- [ ] No daemon crashes

### Runtime
- [ ] No IP address assigned by default
- [ ] `ip addr` shows interfaces with no IP
- [ ] `sysctl net.ipv4.ip_forward` returns `1`

---

## 4 | BGP Validation

- [ ] `show ip bgp summary` shows neighbor
- [ ] State = Established
- [ ] Correct AS numbers configured
- [ ] Prefixes are advertised
- [ ] Routes appear in routing table

---

## 5 | OSPF Validation

- [ ] `show ip ospf neighbor` shows adjacency
- [ ] State = Full
- [ ] Routes learned via OSPF
- [ ] Routes appear in routing table

---

## 6 | IS-IS Validation

- [ ] `show isis neighbor` shows adjacency
- [ ] Correct level (L1/L2) configured
- [ ] Routes installed in routing table

---

## 7 | Routing Table Verification

- [ ] `ip route` shows learned routes
- [ ] Not only directly connected routes
- [ ] BGP / OSPF / IS-IS routes visible
- [ ] Forwarding works between networks

---

## 8 | GNS3 Topology

- [ ] Two Docker images used (alpine host + yilin-router)
- [ ] Equipment names include login (`host_yilin`, `router_yilin`)
- [ ] Interfaces connected correctly
- [ ] Consoles accessible
- [ ] No default IP inside images

---

## 9 | Connectivity Tests

- [ ] Host can ping router
- [ ] Router can ping host
- [ ] End-to-end ping works through routing protocol
- [ ] Traceroute shows correct path

---

## 10 | Repository Structure

```
P1/
├── host        ← commented config for host node (no IPs)
└── router      ← commented config for router node (no IPs)
```

- [ ] `P1/host` present and commented
- [ ] `P1/router` present and commented
- [ ] Portable GNS3 project exported (`P1.gns3project`)
- [ ] Base images included in ZIP
- [ ] Everything reproducible on fresh VM

---

## Final Validation

- [ ] No hardcoded IP addresses in images
- [ ] All routing daemons stable (zebra, bgpd, ospfd, isisd, staticd)
- [ ] Neighbor relationships established
- [ ] Routes propagate correctly
- [ ] Connectivity fully functional
- [ ] Project clean and documented

---

# P2 | Discovering a VXLAN

## 1 | General Requirements
- [ ] Project in `/P2` folder at repo root
- [ ] Equipment names include login (e.g., `router_yilin`)
- [ ] Base images included in ZIP export
- [ ] ZIP export visible in git repository

## 2 | Static VXLAN Setup
- [ ] VXLAN configured in static (unicast) mode
- [ ] VXLAN ID = `10`
- [ ] VXLAN interface named `vxlan10`
- [ ] Bridge named `br0`
- [ ] `vxlan10` and host-facing `eth` both attached to `br0`
- [ ] Remote VTEP IP configured (`remote <peer_ip>`)

## 3 | Dynamic Multicast VXLAN Setup
- [ ] VXLAN configured in multicast mode
- [ ] VXLAN ID = `10`, bridge `br0`, interface `vxlan10`
- [ ] Multicast group configured (e.g., `239.1.1.1`)
- [ ] Both VTEPs joined to same multicast group
- [ ] MAC address tables correctly populated across routers

## 4 | Testing & Traffic
- [ ] Ping works between hosts across VXLAN (static mode)
- [ ] Ping works between hosts across VXLAN (multicast mode)
- [ ] Wireshark/tcpdump confirms VXLAN header with VNI=10
- [ ] `brctl showmacs br0` shows learned MACs

## 5 | Configuration & Documentation
- [ ] Config files provided for each node
- [ ] Comments explain purpose of each setup block
- [ ] `vxlan-unicast.sh` and `vxlan-multicast.sh` scripts working

---

# P3 | BGP with EVPN

## 1 | General Requirements
- [ ] Project in `/P3` folder at repo root
- [ ] Equipment names include login
- [ ] Base images included in ZIP export

## 2 | OSPF Underlay
- [ ] OSPF running on all routers (RR + leaves)
- [ ] Loopback IPs advertised (`1.1.1.x/32`)
- [ ] All routers learn all loopbacks via OSPF
- [ ] Point-to-point links advertised

## 3 | BGP Route Reflector (RR)
- [ ] RR configured (router-id `1.1.1.1`, AS 1)
- [ ] Peering with each leaf loopback (`update-source lo`)
- [ ] `route-reflector-client` set for each leaf
- [ ] `address-family l2vpn evpn` activated for all neighbors

## 4 | BGP Leaves
- [ ] Each leaf peers with RR loopback only
- [ ] `update-source lo` configured
- [ ] `address-family l2vpn evpn` + `advertise-all-vni` configured
- [ ] Router-id and AS set correctly

## 5 | VXLAN on Leaves
- [ ] `vxlan10` created with `local 1.1.1.x` (no `remote` — BGP handles discovery)
- [ ] `vxlan10` and host-facing `eth` attached to `br0`
- [ ] VNI = 10, dstport = 4789

## 6 | Validation
- [ ] `show bgp l2vpn evpn` shows Type-3 routes (one per VTEP)
- [ ] Type-2 routes appear after host traffic
- [ ] Ping between hosts on different VTEPs works
- [ ] Wireshark confirms VXLAN VNI=10 + OSPF Hello packets
- [ ] GNS3 project exported as `P3.gns3project`
