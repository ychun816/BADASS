# Part 2 — Discovering a VXLAN

[← Back to main README](README.md)

---

## Goal

Configure a VXLAN overlay (VNI=10) between two routers, first with static remote VTEP addresses, then with dynamic multicast. Two hosts connected to the routers must be able to ping each other across the VXLAN tunnel.

---

## Topology

```
host_ychun-1
     │ eth0
     │
routeur_ychun-1 (eth0: 30.1.1.1/24, eth1: bridge br0)
     │ eth0
     │
Switch_ychun
     │ eth1
     │
routeur_ychun-2 (eth0: 30.1.1.2/24, eth1: bridge br0)
     │ eth0
     │
host_ychun-2
```

---

## Concepts

### What VXLAN does
```
host_ychun-1 sends L2 frame
       │
  routeur_ychun-1 (VTEP)
  wraps it: [ UDP | VXLAN header (VNI=10) | inner Ethernet frame ]
       │ UDP port 4789
  routeur_ychun-2 (VTEP)
  unwraps it → delivers inner frame to br0 → host_ychun-2
```
The hosts think they are on the same Ethernet segment. The tunnel is invisible to them.

### Key objects
| Object | Role |
|--------|------|
| `vxlan10` | VXLAN interface — VNI 10, UDP encap/decap |
| `br0` | Linux bridge — connects host-facing eth and vxlan10 |
| `eth0` | Underlay interface — carries the UDP tunnel between routers |
| `eth1` | Overlay interface — connects to host, added to br0 |

### Static vs multicast
| Mode | How remote VTEPs are discovered |
|------|--------------------------------|
| Static | `remote <peer_ip>` hardcoded — unicast tunnel between exactly 2 VTEPs |
| Multicast | `group 239.1.1.1` — VTEPs join a multicast group; BUM traffic floods to all members |

---

## Static mode configuration

On **routeur_ychun-1** (`eth0` = `30.1.1.1/24`):
```sh
# Assign underlay IP
ip addr add 30.1.1.1/24 dev eth0
ip link set eth0 up

# Create VXLAN interface pointing to peer VTEP
ip link add vxlan10 type vxlan id 10 remote 30.1.1.2 dstport 4789 dev eth0

# Create bridge and attach overlay eth + vxlan
ip link add br0 type bridge
ip link set eth1 master br0
ip link set vxlan10 master br0

# Bring everything up
ip link set vxlan10 up
ip link set br0 up
ip link set eth1 up
```

On **routeur_ychun-2** (`eth0` = `30.1.1.2/24`): same, with `remote 30.1.1.1`.

Assign IPs to hosts' `eth0` in the same subnet (e.g. `30.1.1.1/24` is the bridge side — give hosts `10.1.1.1/24` on a separate subnet, or same subnet bridged):

> Note: hosts connect to `br0` through `eth1` of the router — they are bridged, not routed. Assign host IPs in any subnet; they only need L2 reachability, not routing.

---

## Dynamic multicast configuration

Replace `remote <ip>` with `group` and point it to the underlay interface:
```sh
ip link add vxlan10 type vxlan id 10 group 239.1.1.1 dstport 4789 dev eth0
```
Both routers use the same multicast group — the kernel joins the group automatically.

---

## Verification

```sh
# Check VXLAN interface
ip -d link show vxlan10

# Check bridge membership
brctl show br0

# Check learned MACs
brctl showmacs br0

# Ping between hosts
ping <host2_ip>
```

In Wireshark on the link between routers: filter `vxlan` — you should see:
- Outer UDP packets to port 4789
- VXLAN header with VNI = 10
- Inner Ethernet frames (ICMP between hosts)

---

## Repo files

| File | Content |
|------|---------|
| `P2/_ychun-1_s` | Static VXLAN commands for routeur_ychun-1 with comments |
| `P2/_ychun-1_g` | Multicast VXLAN commands for routeur_ychun-1 with comments |
| `P2/_ychun-2_s` | Static VXLAN commands for routeur_ychun-2 |
| `P2/_ychun-2_g` | Multicast VXLAN commands for routeur_ychun-2 |
| `P2/_ychun-1_host` | Host config (just IP assignment) |
| `P2/_ychun-2_host` | Host config |
| `P2/P2.gns3project` | GNS3 ZIP export including base images |

---

## Export

GNS3 → File → Export portable project → ZIP with base images → `P2/P2.gns3project`
