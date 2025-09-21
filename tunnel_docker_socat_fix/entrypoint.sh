#!/bin/sh

# Exit on any error
set -e

# --- Configuration ---
# The remote VDS server that acts as the bridge
VDS_HOST="vds1.iri1968.dpdns.org"
# The port on the VDS that the masked stunnel is listening on
VDS_PORT="110"

# The local port that socat will listen on for the SSH client to connect to
SOCAT_LISTEN_PORT="2222"
# The source port socat will use for its outgoing connection (< 443)
# This requires the container to be run with --cap-add=NET_BIND_SERVICE
SOURCE_PORT="109"

# The port on the VDS for the reverse SSH tunnel endpoint
REMOTE_TUNNEL_PORT="2222"
# The local SSH server port inside this container
LOCAL_SSH_PORT="22"


# --- Script ---

# 1. Start the container's own SSH server in the background
/usr/sbin/sshd

# 2. Start socat to create the TLS tunnel, forcing the source port
echo "Starting socat: listening on $SOCAT_LISTEN_PORT, connecting to $VDS_HOST:$VDS_PORT, using source port $SOURCE_PORT"
socat TCP-LISTEN:$SOCAT_LISTEN_PORT,fork,reuseaddr OPENSSL:$VDS_HOST:$VDS_PORT,bind=0.0.0.0:$SOURCE_PORT &

# 3. Wait a moment for socat to establish the connection
sleep 3

# 4. Execute the main reverse SSH tunnel command through socat
# This connects to our local socat, which forwards it over the TLS tunnel to the VDS.
# On the VDS, it establishes a reverse tunnel back to this container's sshd.
echo "Starting reverse SSH tunnel..."
ssh -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -o "ExitOnForwardFailure=yes" \
    -R 0.0.0.0:$REMOTE_TUNNEL_PORT:localhost:$LOCAL_SSH_PORT \
    -p $SOCAT_LISTEN_PORT root@127.0.0.1 \
    -i /root/.ssh/id_rsa_vds1

echo "SSH tunnel process exited."
