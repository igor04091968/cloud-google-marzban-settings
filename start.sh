#!/bin/bash

# Start x-ui in the background
/opt/x-ui/x-ui &

# Check if auth variables are set
if [ -z "${CHISEL_AUTH_USER}" ] || [ -z "${CHISEL_AUTH_PASS}" ]; then
  echo "Error: CHISEL_AUTH_USER and CHISEL_AUTH_PASS environment variables must be set."
  exit 1
fi

# Start chisel client in the foreground
# It connects to your VDS and forwards the remote port 8443 to the local x-ui port 2053
/usr/local/bin/chisel client -v --auth "${CHISEL_AUTH_USER}:${CHISEL_AUTH_PASS}" vds1.iri1968.dpdns.org:993 R:8443:localhost:2053