# Dockerfile to create a client-side SSH reverse tunnel
# This version uses 'socat' to force a specific source port to bypass restrictive firewalls.

FROM alpine:latest

# Install packages: openssh for sshd and ssh client, socat for the tunnel
RUN apk add --no-cache socat openssh

# Create SSH directories and generate host keys for the container's sshd
# This allows the admin (Gemini) to connect back to this container
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && ssh-keygen -A

# Copy sshd_config (a minimal config is provided in this directory)
COPY sshd_config /etc/ssh/sshd_config

# Copy entrypoint and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Add public keys that are allowed to connect to this container's SSH server
# IMPORTANT: This section should be populated with the public keys of the admin/Gemini
# You need to add your keys here, for example:
# RUN echo "ssh-ed25519 AAAA... gemini_key" >> /root/.ssh/authorized_keys


# The private key for vds1 will be mounted at /root/.ssh/id_rsa_vds1 at runtime.

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]