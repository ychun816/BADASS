#!/bin/sh
# Configuration VXLAN en mode multicast

# Exit on error
set -e

echo "=== Configuration VXLAN MULTICAST ==="
echo ""

# Show available interfaces (brief) excluding loopback, existing bridge and vxlan interfaces
echo "Interfaces disponibles :"
ip -br link show | grep -v "lo\|br0\|vxlan" | awk '{print "  - " $1 " (" $3 ")"}'
echo ""

# Host-facing interface (attached to host VMs/containers)
read -p "Interface vers le HOST (ex: eth0) : " IF_HOST
# Underlay interface used for multicast underlay traffic
read -p "Interface vers le SWITCH (ex: eth1) : " IF_UNDER
# Local IP with prefix to assign to underlay interface
read -p "IP LOCALE avec masque (ex: 10.1.1.1/24) : " IP_LOCAL
# Multicast group to be used by vxlan for BUM traffic, default 239.1.1.1
read -p "Groupe multicast (defaut: 239.1.1.1) : " MGROUP
MGROUP=${MGROUP:-239.1.1.1}
# VNI defaults to 10
read -p "VXLAN ID (defaut: 10) : " VNI
VNI=${VNI:-10}
# UDP destination port used for VXLAN (standard 4789)
read -p "Port UDP VXLAN (defaut: 4789) : " DSTPORT
DSTPORT=${DSTPORT:-4789}

echo ""
echo "=== Recapitulatif ==="
echo "  Host       : $IF_HOST"
echo "  Underlay   : $IF_UNDER ($IP_LOCAL)"
echo "  Multicast  : $MGROUP"
echo "  VNI        : $VNI"
echo "  Port       : $DSTPORT"
echo ""
# Confirm before changing network configuration
read -p "Confirmer ? (o/N) : " CONFIRM
[ "$CONFIRM" != "o" ] && echo "Annule." && exit 1

echo ""
echo "=== Nettoyage d'une eventuelle ancienne config ==="
# Try to shutdown and delete previous vxlan and bridge if present (ignore errors)
ip link set vxlan${VNI} down 2>/dev/null || true
ip link del vxlan${VNI} 2>/dev/null || true
ip link set br0 down 2>/dev/null || true
ip link del br0 2>/dev/null || true

echo "=== Application de la config ==="
# Create bridge and bring it up
ip link add br0 type bridge
ip link set dev br0 up

# Assign the local underlay IP and bring the underlay interface up
ip addr add ${IP_LOCAL} dev ${IF_UNDER}
ip link set ${IF_UNDER} up

# Create vxlan interface in multicast mode using the group address
# - group: multicast group used for BUM traffic
# - dstport: UDP port for encapsulation
ip link add vxlan${VNI} type vxlan id ${VNI} dev ${IF_UNDER} \
    group ${MGROUP} dstport ${DSTPORT}
ip link set vxlan${VNI} up

# Attach the host interface and vxlan to the bridge
brctl addif br0 ${IF_HOST}
brctl addif br0 vxlan${VNI}
ip link set ${IF_HOST} up

echo ""
echo "=== Config terminee ==="
# Show detailed vxlan state and bridge table
ip -d link show vxlan${VNI}
echo ""
brctl show br0
echo ""
echo "Abonnement multicast :"
# Show multicast memberships on the underlay interface
ip maddr show dev ${IF_UNDER} | grep -A1 inet || echo "(verifier avec 'ip maddr show')"