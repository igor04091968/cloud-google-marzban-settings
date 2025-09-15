#!/bin/sh

# 1. Create private key from secret in the user's home directory
if [ -z "$ID_RSA_VDS1" ]; then
  echo "Error: ID_RSA_VDS1 secret is not set."
  exit 1
fi
mkdir -p /home/user/.ssh
echo "$ID_RSA_VDS1" > /home/user/.ssh/id_rsa_vds1
chmod 600 /home/user/.ssh/id_rsa_vds1
chown -R user:user /home/user/.ssh

# 2. Start stunnel client in the background
stunnel /etc/stunnel/stunnel.conf &

# Give stunnel a moment to connect
sleep 3

# 3. Execute the reverse SSH tunnel command in the foreground
# This will keep the container alive
ssh -v -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -R 0.0.0.0:1080:localhost:1080 \
    -R 0.0.0.0:2222:localhost:22 \
    -R 0.0.0.0:5201:localhost:5201 \
    -p 2222 root@127.0.0.1 \
    -i /home/user/.ssh/id_rsa_vds1
