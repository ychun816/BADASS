FROM alpine:3.19

RUN apk add --no-cache \
	frr \
	iproute2 \
	bash

COPY daemons /etc/frr/daemons
COPY frr.conf /etc/frr/frr.conf
COPY sysctl.conf /etc/sysctl.d/99-frr.conf

CMD ["/usr/lib/frr/docker-start"]
