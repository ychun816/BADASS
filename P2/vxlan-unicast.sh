#!/bin/sh

set -e

echo "=== Configuration VXLAN UNICAST ==="
echo ""
echo "Interfaces disponibles :"
ip -br link show | grep -v "lo\|br0\|vxlan" | awk '{print "  - " $1 " (" $3 ")"}'
echo ""

read -p "Interface vers le HOST (ex: eth0) : " IF_HOST
read -p "Interface vers le SWITCH (ex: eth1) : " IF_UNDER
read -p "IP LOCALE avec masque (ex: 10.1.1.1/24) : " IP_LOCAL
read -p "IP DISTANTE sans masque (ex: 10.1.1.2) : " IP_REMOTE
read -p "VXLAN ID (defaut: 10) : " VNI
VNI=${VNI:-10}
read -p "Port UDP VXLAN (defaut: 4789) : " DSTPORT
DSTPORT=${DSTPORT:-4789}

# Extraire l'IP locale sans le masque pour le p
| Concept | Explanation | Why It Matters in BADASS |
|---|---|---|
| **BGP** | EGP that exchanges routes between Autonomous Systems | Needed to simulate AS-level routing between Docker routers |
| **Autonomous System (AS)** | A network under a single admin domain with a unique AS number | Each router belongs to an AS (e.g., 65001) |
| **eBGP vs iBGP** | eBGP – between different AS; iBGP – inside same AS | Determines neighbor config in topology |
| **Neighbor / Peer** | BGP router with which you exchange routes | Must configure properly in `bgpd` for route propagation |
| **AS Path** | List of AS numbers a route has passed | Prevents routing loops; shows the route path |
| **Next-Hop** | IP address for packet forwarding | Must be reachable for routes to work |
| **BGP FSM States** | Idle → Connect → Active → OpenSent → OpenConfirm → Established | "Established" is required for routing to work |


incoporarametre 'local'
LOCAL_ONLY=$(echo "$IP_LOCAL" | cut -d'/' -f1)

echo ""
echo "=== Recapitulatif ==="
echo "  Host       : $IF_HOST"
echo "  Underlay   : $IF_UNDER ($IP_LOCAL)"
echo "  Peer       : $IP_REMOTE"
echo "  VNI        : $VNI"
echo "  Port       : $DSTPORT"
echo ""
read -p "Confirmer ? (o/N) : " CONFIRM
[ "$CONFIRM" != "o" ] && echo "Annule." && exit 1

echo ""
echo "=== Application de la config ==="
ip link add br0 type bridge
#!/bin/sh

# Exit immediately if any command fails
set -e

# Short header shown to the user
echo "=== Configuration VXLAN UNICAST ==="
echo ""

# List available network interfaces (brief format) excluding loopback, bridges and vxlan
echo "Interfaces disponibles :"
ip -br link show | grep -v "lo\|br0\|vxlan" | awk '{print "  - " $1 " (" $3 ")"}'
echo ""

# Ask user for the host-facing interface (attached to host VMs/containers)
read -p "Interface vers le HOST (ex: eth0) : " IF_HOST
# Ask for the underlay interface (connected to physical or VM network)
read -p "Interface vers le SWITCH (ex: eth1) : " IF_UNDER
# Local IP with prefix used for assigning to the underlay interface
read -p "IP LOCALE avec masque (ex: 10.1.1.1/24) : " IP_LOCAL
# Remote peer IP (unicast VXLAN endpoint)
read -p "IP DISTANTE sans masque (ex: 10.1.1.2) : " IP_REMOTE
# VXLAN Network Identifier (VNI) defaults to 10
read -p "VXLAN ID (defaut: 10) : " VNI
VNI=${VNI:-10}
# UDP destination port used for VXLAN (standard 4789)
read -p "Port UDP VXLAN (defaut: 4789) : " DSTPORT
DSTPORT=${DSTPORT:-4789}

# Extract the IP part without CIDR prefix for the 'local' parameter
LOCAL_ONLY=$(echo "$IP_LOCAL" | cut -d'/' -f1)

echo ""
echo "=== Recapitulatif ==="
echo "  Host       : $IF_HOST"
echo "  Underlay   : $IF_UNDER ($IP_LOCAL)"
echo "  Peer       : $IP_REMOTE"
echo "  VNI        : $VNI"
echo "  Port       : $DSTPORT"
echo ""
# Confirm before making changes
read -p "Confirmer ? (o/N) : " CONFIRM
[ "$CONFIRM" != "o" ] && echo "Annule." && exit 1

echo ""
echo "=== Application de la config ==="
# Create a bridge 'br0' to attach host and vxlan interfaces
ip link add br0 type bridge
ip link set dev br0 up

# Assign local underlay IP and bring the underlay interface up
ip addr add ${IP_LOCAL} dev ${IF_UNDER}
ip link set ${IF_UNDER} up

# Create the VXLAN interface in unicast mode pointing to remote peer
# - id: VNI
# - dev: underlay device used to send/receive encapsulated traffic
# - remote/local: remote peer IP and local source IP for UDP encapsulation
# - dstport: UDP port number (usually 4789)
ip link add vxlan${VNI} type vxlan id ${VNI} dev ${IF_UNDER} \
    remote ${IP_REMOTE} local ${LOCAL_ONLY} dstport ${DSTPORT}
ip link set vxlan${VNI} up

# Attach host interface and vxlan interface to the bridge so traffic is bridged into VXLAN
brctl addif br0 ${IF_HOST}
brctl addif br0 vxlan${VNI}
ip link set ${IF_HOST} up

# (Optional) A default FDB entry can be added for BUM traffic if needed
echo ""
echo "=== Config terminee ==="
# Show detailed vxlan interface state and bridge membership
ip -d link show vxlan${VNI}
echo ""
brctl show br0