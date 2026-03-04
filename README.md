# BADASS (Bgp At Doors of Autonomous Systems is Simple)

- simulate a network and configure it using GNS3 with docker images.
- BGP EVPN is based on BGP (RFC 4271) and its extensions, MP-BGP (RFC 4760).
- BGP is the routing protocol that drives the Internet. 
- Through MP-BGP extensions, it can be used to carry reachability information (NLRI) for various protocols (IPv4, IPv6, L3
VPN and in this case, EVPN). 
- EVPN is a special family used for publishing information about MAC addresses and the end devices that access them.


---

# index 
- P1
- P2
- P3 


---


# P1 | GNS3 + Docker + Routing Stack

## P1 structure

```bash
BADASS/
├── P1/
│   ├── README.md
│   │
│   ├── docker-images/
│   │   ├── host/
│   │   │   ├── Dockerfile
│   │   │   └── entrypoint.sh (optional)
│   │   │
│   │   └── router/
│   │       ├── Dockerfile
│   │       ├── daemons
│   │       ├── frr.conf
│   │       └── sysctl.conf (optional)
│   │
│   ├── configs/
│   │   ├── router1.conf
│   │   ├── router2.conf
│   │   └── topology-explanation.md
│   │
│   ├── diagrams/
│   │   └── topology.png
│   │
│   ├── gns3-project/
│   │   ├── project.gns3
│   │   └── project-files/
│   │
│   └── exported/
│       └── P1_portable_project.zip
│
└── .gitignore
```


---

# P2 | VXLAN

## P2 structure 
```bash
P2/
├── configs/
│   ├── static_mode/
│   │   ├── router_yilin1.conf
│   │   ├── router_yilin2.conf
│   │   ├── host_yilin1.conf
│   │   └── host_yilin2.conf
│   │
│   └── dynamic_multicast/
│       ├── router_yilin1.conf
│       ├── router_yilin2.conf
│       ├── host_yilin1.conf
│       └── host_yilin2.conf
│
├── P2_exported_project_static.zip
└── P2_exported_project_dynamic.zip
```

---

# P3