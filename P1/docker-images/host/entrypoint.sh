#!/bin/sh
# Minimal entrypoint: keep container alive when started by GNS3
# If arguments are provided, exec them; otherwise sleep forever.
set -e

if [ "$#" -gt 0 ]; then
  exec "$@"
else
  # keep the container running so GNS3 can attach a console
  tail -f /dev/null
fi
