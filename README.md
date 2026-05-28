# BADASS — Bgp At Doors of Autonomous Systems is Simple

Simulate a small data center using GNS3, Docker, VXLAN, and BGP EVPN.

---

## Index
- [Basics | Key terms & diagrams](documentations/Basics.md)
- [Part 0 | VM setup](documentations/VM.md)
- [Part 1 | GNS3 + Docker setup](documentations/P1.md)
- [Part 2 | Discovering VXLAN](documentations/P2.md)
- [Part 3 | BGP with EVPN](documentations/P3.md)

---

## Part 1 | GNS3 configuration with Docker

**Concepts to learn:**
- Docker: `FROM`, `RUN`, `CMD`, `ENTRYPOINT` — build two images from scratch
- **FRR** (Free Range Routing): modern successor to Quagga; bundles `zebra`, `bgpd`, `ospfd`, `isisd` as daemons — `zebra` is the core that programs the Linux kernel routing table, all routing daemons (bgpd, ospfd, isisd) talk to zebra
- **GNS3**: network emulator that runs Docker containers as nodes connected by virtual links; access each container via its GNS3 console (telnet)
- Why "no default IP": the same two images are reused across P1 → P2 → P3 — IPs are assigned per-topology at runtime, never baked into the image

→ [Networking Basics reference](documentations/Basics.md) — key terms with diagrams, analogies, and resources

**Repo structure:**
```
P1/
├── host    ← host container setup (no IPs)
└── router  ← router container setup (no IPs)
```

**Workflow:**
```
 docker pull alpine:latest          Dockerfile (alpine + FRR + debug tools)
        │                                         │
        │  host image                             │  docker build -t yilin-router
        ▼                                         ▼
 ┌─────────────┐                        ┌─────────────────┐
 │  host_yilin │                        │  router_yilin   │
 │  (alpine)   │                        │  zebra bgpd     │
 └─────────────┘                        │  ospfd isisd    │
        │                               │  staticd        │
        │   GNS3: add as Docker         └─────────────────┘
        │   appliance (no default IP)            │
        └──────────────┬─────────────────────────┘
                       │
                       ▼
              GNS3 topology canvas
              host_yilin ──eth0── router_yilin
                       │
                       ▼
              start nodes → open console
              verify: ps | grep -E 'zebra|bgpd|ospfd|isisd|staticd'
                       │
                       ▼
              File → Export portable project
              → ZIP with base images → P1.gns3project
```

---

## Part 2 | Discovering a VXLAN

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
├── _yilin-1_host
├── _yilin-1_s                  ← static VXLAN config for router_yilin-1
├── _yilin-1_g                  ← multicast VXLAN config for router_yilin-1
├── _yilin-2_host
├── _yilin-2_s
└── _yilin-2_g
```

**Workflow:**
1. Topology: `Switch_yilin` ↔ `router_yilin-1` + `router_yilin-2`, each router ↔ one host
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

## Part 3 | BGP with EVPN

**Concepts to learn:**
- **BGP EVPN** (RFC 7432): uses BGP as the control plane for VXLAN — replaces static/multicast VTEP discovery with BGP route advertisements; MACs are learned automatically without flooding
- **Route Reflector (RR)**: a central BGP peer that re-advertises routes to all clients — avoids a full iBGP mesh; leaves only peer with the RR
- **Leaves / VTEPs**: edge routers connecting hosts to the overlay; advertise their MAC/IP bindings via BGP EVPN and receive peers' bindings automatically
- **OSPF as underlay**: routes loopback IPs (`1.1.1.x/32`) between all routers so BGP sessions use stable loopback addresses, independent of physical link IPs
- **EVPN route types**:
1. Topology: `_yilin-1` (RR) with 3 links to leaves `_yilin-2`, `_yilin-3`, `_yilin-4`; each leaf connects one host
2. **OSPF underlay** on all routers: advertise loopback (`1.1.1.x/32`) + point-to-point links → all routers learn all loopbacks
  - **Type 2** (MAC/IP Advertisement): auto-generated when a host becomes active — signals "this MAC lives behind my VTEP"
  - **Type 3** (IMET / Inclusive Multicast): pre-configured per VTEP — announces "I handle VNI 10, send BUM traffic here"
- **`address-family l2vpn evpn`**: the BGP sub-family where EVPN routes are activated; `advertise-all-vni` on leaves tells FRR to auto-generate type-3 routes for all local VNIs

**Repo structure:**
```
P3/
├── P3.gns3project
├── _yilin-1                    ← RR: OSPF + BGP route-reflector config
├── _yilin-2                    ← Leaf: OSPF + BGP + VXLAN + bridge config
├── _yilin-2_host
├── _yilin-3
├── _yilin-3_host
├── _yilin-4
└── _yilin-4_host
```

**Workflow:**
1. Topology: `_yilin-1` (RR) with 3 links to leaves `_yilin-2`, `_yilin-3`, `_yilin-4`; each leaf connects one host
2. **OSPF underlay** on all routers: advertise loopback (`1.1.1.x/32`) + point-to-point links → all routers learn all loopbacks
3. **BGP on RR** (`_yilin-1`, router-id `1.1.1.1`, AS 1):
   - Peer with each leaf loopback, `update-source lo`, `route-reflector-client`
   - `address-family l2vpn evpn` → `neighbor X activate`, `route-reflector-client`
4. **BGP on leaves** (router-id `1.1.1.x`, AS 1):
   - Peer with RR loopback only, `update-source lo`
   - `address-family l2vpn evpn` → `neighbor RR activate`, `advertise-all-vni`
5. **VXLAN on each leaf**: `ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.x` (no `remote` — BGP handles discovery), attach to `br0` with local host-facing `eth`
6. Start hosts — verify `show bgp l2vpn evpn`: type-3 routes appear (one per VTEP); type-2 routes appear as hosts send traffic
7. Ping between hosts on different VTEPs — Wireshark confirms VXLAN VNI=10 + ICMP + OSPF Hello packets
8. Export as `P3.gns3project`
