# Checklist



---

# P1 | GNS3 + Docker + Routing Stack Validation Checklist

## 1️⃣ Environment Validation

### Docker

- [ ] `docker ps` runs without error
- [ ] `docker build` works successfully
- [ ] Container starts without crashing
- [ ] No permission issues

### GNS3

- [ ] GNS3 GUI connects to local server
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