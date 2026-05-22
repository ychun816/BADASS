# Part 1 — GNS3 configuration with Docker

[← Back to main README](README.md)

---

## Goal

Build two Docker images and wire them together in a GNS3 topology:
- **Image 1 (host)**: lightweight Alpine + busybox — simulates an end-host
- **Image 2 (router)**: Alpine + FRR with bgpd, ospfd, isisd, zebra active — simulates a full routing stack

Both images must have **no IP configured by default** — they will be reused in P2 and P3.

---

## Concepts

### Docker image pipeline
```
Dockerfile → docker build → docker image → GNS3 appliance → container node
```

### FRR daemon hierarchy
```
bgpd  ─┐
ospfd ─┤──► zebra ──► Linux kernel routing table ──► network interface
isisd ─┘
```
- `zebra`: mandatory base daemon; translates routing protocol decisions into kernel routes via Netlink
- `bgpd`: handles BGP sessions and route advertisements
- `ospfd`: runs OSPF link-state routing within an AS
- `isisd`: runs IS-IS — a link-state protocol similar to OSPF, used in large ISP networks
- `daemons` file: tells FRR's init script which daemons to start (`bgpd=yes`, etc.)

### GNS3 Docker integration
- GNS3 pulls the image by name and starts it as a container per node
- Each node gets a separate network namespace — interfaces are `eth0`, `eth1`, ... depending on how many links you add in GNS3
- Console access is via telnet to a port GNS3 allocates (shown in the topology panel)
- **No persistent storage**: every container restart resets to image state — configurations must be in startup scripts or the image itself

---

## Files to implement

### `docker-images/host/Dockerfile`
```dockerfile
FROM alpine:latest
RUN apk update && apk add --no-cache busybox iproute2 iputils bash
CMD ["sh"]
```

### `docker-images/router/Dockerfile`
```dockerfile
FROM alpine:latest
RUN apk update && apk add --no-cache frr busybox iproute2 bash
COPY daemons /etc/frr/daemons
COPY frr.conf /etc/frr/frr.conf
COPY sysctl.conf /etc/sysctl.d/99-frr.conf
CMD ["/usr/lib/frr/docker-start"]
```

### `docker-images/router/daemons`
```
bgpd=yes
ospfd=yes
isisd=yes
zebra=yes
ospf6d=no
ripd=no
ripngd=no
pimd=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=no
fabricd=no
```

### `docker-images/router/frr.conf`
```
frr version 8.x
frr defaults traditional
hostname routeur_ychun
no ipv6 forwarding
!
line vty
!
```

### `docker-images/router/sysctl.conf`
```
net.ipv4.ip_forward=1
```

---

## GNS3 setup steps

1. **Add Docker image to GNS3**: Edit → Preferences → Docker containers → New → image name
2. **Set console type**: `telnet` (not `vnc`)
3. **Set adapters**: 1 for host, 2+ for router (one per link you'll connect)
4. **Drag nodes** onto the canvas, link `host_ychun-1` ↔ `routeur_ychun`
5. **Start nodes**, right-click → Console to open terminal
6. Verify router: `ps` should show `zebra`, `bgpd`, `ospfd`, `isisd`

---

## Export

GNS3 → File → **Export portable project**
- Compression: Zip (deflate)
- Check **Include base images**
- Save as `P1/P1.gns3project`

---

## Config files (for evaluators)

`P1/_ychun-1_host` and `P1/_ychun-2_routeur` — plain text files explaining each container's setup with comments. No IP addresses assigned.

Example `_ychun-1_host`:
```sh
# host_ychun-1 — Alpine busybox host
# Image: ychun_host (docker-images/host/Dockerfile)
# Adapters: 1 (eth0)
# No IP configured — assigned manually per topology
# hostname: host_ychun-1
```
