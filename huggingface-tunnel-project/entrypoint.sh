#!/bin/sh

# 0. Generate host keys if they don't exist
ssh-keygen -A

# 1. Create private key from secret in the user's home directory
if [ -z "$ID_RSA_VDS1" ]; then
  echo "Error: ID_RSA_VDS1 secret is not set."
  exit 1
fi
echo "$ID_RSA_VDS1" > /home/user/.ssh/id_rsa_vds1
chmod 600 /home/user/.ssh/id_rsa_vds1

# 2. Start the container's SSH server
/usr/sbin/sshd

# 3. Start stunnel client
stunnel /etc/stunnel/stunnel.conf

sleep 2

# 4. Execute the reverse SSH tunnel command as the 'user'
ssh -v -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -R 0.0.0.0:1080 \
    -R 0.0.0.0:2222:localhost:22 \
    -R 0.0.0.0:110:localhost:110 -R 0.0.0.0:5201:localhost:5201 \
    -p 22 user@127.0.0.1 \
    -i /home/user/.ssh/id_rsa_vds1
