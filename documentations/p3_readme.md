# Part 3 — BGP with EVPN

[← Back to main README](README.md)

---

## Goal

Replace the manual/multicast VXLAN control plane from P2 with BGP EVPN. A Route Reflector (`_ychun-1`) distributes MAC/IP reachability information automatically to all leaf VTEPs (`_ychun-2`, `_ychun-3`, `_ychun-4`). Hosts can ping each other without any static VTEP config.

---

## Topology

```
                    _ychun-1  (RR — Route Reflector)
                   /    |    \
           e0    e1    e2
          /       |       \
    _ychun-2   _ychun-3   _ychun-4     ← Leaves / VTEPs
       |           |           |
  host_ychun-1  host_ychun-2  host_ychun-3
```

All links use point-to-point subnets (`10.1.1.x/30`).
Each device has a loopback: `1.1.1.x/32` (x = 1,2,3,4).

---

## Concepts

### Why BGP EVPN over P2's approach
| P2 (static/multicast) | P3 (BGP EVPN) |
|-----------------------|---------------|
| Manual remote IPs or multicast group | Automatic VTEP discovery via BGP |
| BUM traffic floods to all VTEPs | RR distributes MAC info — no flooding needed |
| Does not scale | Scales to thousands of VTEPs |

### Control plane vs data plane
```
Control plane (BGP EVPN):
  VTEP announces MAC → RR → RR reflects to all other VTEPs

Data plane (VXLAN):
  Once VTEP knows remote MAC's location → unicast VXLAN packet directly
  No multicast, no flooding
```

### OSPF as underlay
- OSPF runs on all physical links + loopbacks
- Goal: every device knows how to reach every loopback (`1.1.1.x`)
- BGP sessions are established between loopbacks (stable — survives link changes)

### BGP session structure
```
_ychun-2 (lo: 1.1.1.2) ──┐
_ychun-3 (lo: 1.1.1.3) ──┤── _ychun-1 RR (lo: 1.1.1.1)
_ychun-4 (lo: 1.1.1.4) ──┘

All sessions: iBGP (same AS = 1), update-source loopback
RR reflects routes — leaves do NOT peer with each other
```

### EVPN route types
| Type | Name | When generated | What it carries |
|------|------|----------------|-----------------|
| 3 | IMET / Inclusive Multicast | On VTEP startup | "I handle VNI 10 — send me BUM traffic" |
| 2 | MAC/IP Advertisement | When host sends first frame | "MAC xx:xx:xx:xx:xx:xx is behind me at VTEP 1.1.1.x" |

---

## Configuration

### All routers — OSPF underlay (FRR vtysh)
```
router ospf
  ospf router-id 1.1.1.x
  network 1.1.1.x/32 area 0        ! loopback
  network 10.1.1.x/30 area 0       ! point-to-point links
!
```

### RR (`_ychun-1`) — BGP config
```
router bgp 1
  bgp router-id 1.1.1.1
  neighbor 1.1.1.2 remote-as 1
  neighbor 1.1.1.2 update-source lo
  neighbor 1.1.1.3 remote-as 1
  neighbor 1.1.1.3 update-source lo
  neighbor 1.1.1.4 remote-as 1
  neighbor 1.1.1.4 update-source lo
  !
  address-family l2vpn evpn
    neighbor 1.1.1.2 activate
    neighbor 1.1.1.2 route-reflector-client
    neighbor 1.1.1.3 activate
    neighbor 1.1.1.3 route-reflector-client
    neighbor 1.1.1.4 activate
    neighbor 1.1.1.4 route-reflector-client
  exit-address-family
!
```

### Leaf (`_ychun-2`) — BGP + VXLAN config
```
router bgp 1
  bgp router-id 1.1.1.2
  neighbor 1.1.1.1 remote-as 1
  neighbor 1.1.1.1 update-source lo
  !
  address-family l2vpn evpn
    neighbor 1.1.1.1 activate
    advertise-all-vni               ! auto-generate type-3 routes for all VNIs
  exit-address-family
!
```

VXLAN + bridge on each leaf (shell commands):
```sh
# Loopback
ip addr add 1.1.1.2/32 dev lo
ip link set lo up

# VXLAN — no remote, no group; BGP fills the FDB
ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.2
ip link set vxlan10 up

# Bridge
ip link add br0 type bridge
ip link set eth1 master br0       # host-facing interface
ip link set vxlan10 master br0
ip link set br0 up
```

---

## Verification

```sh
# On any leaf — check BGP neighbors
vtysh -c "show bgp summary"

# See all EVPN routes (type-3 = VTEPs, type-2 = MACs)
vtysh -c "show bgp l2vpn evpn"

# Check OSPF routes (should see all 1.1.1.x loopbacks)
vtysh -c "show ip route ospf"

# After a host sends traffic — check FDB
bridge fdb show dev vxlan10
```

Expected flow:
1. All 4 routers come up → OSPF converges → all loopbacks reachable
2. BGP sessions establish via loopbacks → RR distributes type-3 routes → each VTEP knows about the others
3. Host sends first frame → leaf sees MAC → BGP advertises type-2 route to RR → RR reflects to all leaves
4. Other leaves add entry to VXLAN FDB → future frames are unicast directly, no flooding

---

## Repo files

| File | Content |
|------|---------|
| `P3/_ychun-1` | RR: OSPF + BGP route-reflector config with comments |
| `P3/_ychun-2` | Leaf: OSPF + BGP + VXLAN + bridge config with comments |
| `P3/_ychun-3` | Leaf config |
| `P3/_ychun-4` | Leaf config |
| `P3/_ychun-2_host` | Host IP assignment |
| `P3/_ychun-3_host` | Host IP assignment |
| `P3/_ychun-4_host` | Host IP assignment (no config — host image) |
| `P3/P3.gns3project` | GNS3 ZIP export including base images |

---

## Export

GNS3 → File → Export portable project → ZIP with base images → `P3/P3.gns3project`
