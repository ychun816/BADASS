FROM alpine:latest

RUN apk add --no-cache \
    frr frr-openrc \
    frr-pythontools \
    iproute2 \
    iputils \
    tcpdump \
    bind-tools

RUN sed -i \
    -e 's/^bgpd=no/bgpd=yes/' \
    -e 's/^ospfd=no/ospfd=yes/' \
    -e 's/^isisd=no/isisd=yes/' \
    -e 's/^staticd=no/staticd=yes/' \
    /etc/frr/daemons

COPY vxlan-unicast.sh /usr/local/bin/
COPY vxlan-multicast.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/vxlan-unicast.sh
RUN chmod +x /usr/local/bin/vxlan-multicast.sh

# Démarre FRR puis lance un shell interactif
CMD ["/bin/sh", "-c", "/usr/lib/frr/frrinit.sh start && exec /bin/sh"]
