#!/bin/sh

# 1. Start the container's SSH server
/usr/sbin/sshd

# 2. Start stunnel client
stunnel /etc/stunnel/stunnel.conf

# 3. Set correct permissions for the mounted private key
chmod 600 /root/.ssh/id_rsa_vds1

# 4. Execute the reverse SSH tunnel command
sleep 2

ssh -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -R 0.0.0.0:1080 \
    -R 0.0.0.0:2222:localhost:22 \
    -R 0.0.0.0:110:localhost:110 -R 0.0.0.0:5201:localhost:5201 \
    -p 2222 root@127.0.0.1 \
    -i /root/.ssh/id_rsa_vds1