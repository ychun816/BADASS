FROM alpine:latest

RUN apk update && apk add --no-cache frr busybox iproute2 bash

COPY daemons /etc/frr/daemons
COPY frr.conf /etc/frr/frr.conf
COPY sysctl.conf /etc/sysctl.d/99-frr.conf

CMD ["/usr/lib/frr/docker-start"]
