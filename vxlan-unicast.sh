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

# Extraire l'IP locale sans le masque pour le parametre 'local'
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
ip link set dev br0 up

ip addr add ${IP_LOCAL} dev ${IF_UNDER}
ip link set ${IF_UNDER} up

ip link add vxlan${VNI} type vxlan id ${VNI} dev ${IF_UNDER} \
    remote ${IP_REMOTE} local ${LOCAL_ONLY} dstport ${DSTPORT}
ip link set vxlan${VNI} up

brctl addif br0 ${IF_HOST}
brctl addif br0 vxlan${VNI}
ip link set ${IF_HOST} up

# Optionnel : entree FDB par defaut pour BUM traffic
echo ""
echo "=== Config terminee ==="
ip -d link show vxlan${VNI}
echo ""
brctl show br0
