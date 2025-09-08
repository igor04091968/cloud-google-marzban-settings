#!/bin/sh

# 0. Generate SSH host keys
# This needs to be run as root, so we use sudo. First, we need to ensure sudo is installed.
# The Dockerfile should be modified to install sudo and configure sudoers.
# For now, we assume this script is run with enough permissions or sudo is configured.

# A better approach is to handle this in the Dockerfile if possible, 
# but runtime generation ensures keys are always present.
# We will attempt to run it directly. If it fails, we'll need to adjust the Dockerfile.
/usr/bin/ssh-keygen -A

# 1. Create private key from secret in the user's home directory
if [ -z "$ID_RSA_VDS1" ]; then
  echo "Error: ID_RSA_VDS1 secret is not set."
  exit 1
fi
echo "$ID_RSA_VDS1" > /home/user/.ssh/id_rsa_vds1
chmod 600 /home/user/.ssh/id_rsa_vds1

# 2. Start the container's SSH server
# It will be run by the 'user' but needs to access the generated host keys.
# The sshd daemon itself will handle permissions.
/usr/sbin/sshd

# 3. Start stunnel client
stunnel /etc/stunnel/stunnel.conf

sleep 2

# 4. Execute the reverse SSH tunnel command as the 'user'
ssh -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -R 0.0.0.0:1080 \
    -R 0.0.0.0:2222:localhost:22 \
    -R 0.0.0.0:110:localhost:110 -R 0.0.0.0:5201:localhost:5201 \
    -p 2222 user@127.0.0.1 \
    -i /home/user/.ssh/id_rsa_vds1
