FROM debian:trixie-slim

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		frr \
		busybox \
		iproute2 \
		iputils-ping \
		bash \
	&& rm -rf /var/lib/apt/lists/*

COPY daemons /etc/frr/daemons
COPY frr.conf /etc/frr/frr.conf
COPY sysctl.conf /etc/sysctl.d/99-frr.conf

CMD ["/usr/lib/frr/docker-start"]
