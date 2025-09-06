#!/bin/sh

# 1. Start the container's SSH server
/usr/sbin/sshd

# 2. Start stunnel client
stunnel /etc/stunnel/stunnel.conf

# 3. Execute the reverse SSH tunnel command
# Connects to the local stunnel port (2222)
# Sets up reverse forwards on vds1
#   - Reverse SOCKS proxy on vds1:1080
#   - Reverse SSH access on vds1:2222 -> container:22

# Wait a moment for other services to start
sleep 2

ssh -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -R 0.0.0.0:1080 \
    -R 0.0.0.0:2222:localhost:22 \
    -p 2222 root@127.0.0.1 \
    -i /root/.ssh/id_rsa_vds1
