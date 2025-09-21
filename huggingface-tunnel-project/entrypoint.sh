#!/bin/sh

# Generate host keys if they don't exist
ssh-keygen -A

# Start the container's SSH server
/usr/sbin/sshd -d &

# Execute the reverse SSH tunnel command
if [ -z "$VDS1_PASSWORD" ]; then
  echo "Error: VDS1_PASSWORD is not set."
  exit 1
fi

sshpass -p "$VDS1_PASSWORD" ssh -v -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -R 0.0.0.0:2222:localhost:22 \
    root@vds1.iri1968.dpdns.org
