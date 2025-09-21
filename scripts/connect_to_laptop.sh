#!/bin/bash

# Script to connect to the user's laptop via the vds1 tunnel.
# This script assumes you are running it from the root of the cloud-google-marzban-settings-repo repository.

# Private key for accessing vds1
VDS1_KEY="id_rsa_vds1"

# Private key for accessing the container on the laptop
LAPTOP_TUNNEL_KEY="id_rsa_tunnel"

# Check if keys exist
if [ ! -f "$VDS1_KEY" ] || [ ! -f "$LAPTOP_TUNNEL_KEY" ]; then
    echo "Error: Private keys not found. Make sure '$VDS1_KEY' and '$LAPTOP_TUNNEL_KEY' are in the repository root."
    exit 1
fi

# The command to execute on the laptop can be passed as arguments to this script.
# If no arguments are given, it will start an interactive shell.
REMOTE_COMMAND="${@:-/bin/bash}"

echo "Connecting to laptop..."

# Use ssh-agent to handle the multiple keys required for the multi-hop connection.
ssh-agent bash -c " \
    ssh-add '$VDS1_KEY'; \
    ssh-add '$LAPTOP_TUNNEL_KEY'; \
    ssh -A -o StrictHostKeyChecking=no root@vds1.iri1968.dpdns.org \
        ssh -p 2222 -o StrictHostKeyChecking=no -t igor@localhost "$REMOTE_COMMAND" \
"
