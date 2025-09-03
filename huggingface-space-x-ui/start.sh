#!/bin/bash

# Start x-ui in the background
/opt/x-ui/x-ui/x-ui setting -show
# /opt/x-ui/x-ui/x-ui &

# Wait a moment for x-ui to initialize
sleep 3

# Start chisel client in the foreground with debug logging
# This is the main process for the container
# exec /usr/local/bin/chisel client -vv --auth "${CHISEL_AUTH_USER}:${CHISEL_AUTH_PASS}" vds1.iri1968.dpdns.org:80 R:8443:localhost:2053
