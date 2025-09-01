#!/bin/bash

# Start x-ui (adjust command based on how x-ui is started)
# Example: python3 main.py or a specific x-ui startup command
# You'll need to replace this with the actual x-ui startup command
nohup python3 main.py > /var/log/x-ui.log 2>&1 &

# Start chisel-client
# Ensure CHISEL_AUTH_USER and CHISEL_AUTH_PASS are set as environment variables in Hugging Face Space
/usr/local/bin/chisel client -v --auth ${CHISEL_AUTH_USER}:${CHISEL_AUTH_PASS} vds1.iri1968.dpdns.org:80 R:8443:localhost:2053 > /var/log/chisel_client.log 2>&1 &

# Keep the container running
tail -f /var/log/x-ui.log /var/log/chisel_client.log
