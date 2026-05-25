FROM debian:trixie-slim

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		busybox \
		iproute2 \
		iputils-ping \
		bash \
	&& rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]