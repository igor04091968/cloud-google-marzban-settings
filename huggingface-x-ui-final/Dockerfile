FROM debian:bullseye-slim

# Install necessary packages and clean up
RUN apt-get update && apt-get install -y     dos2unix     wget     curl     tar     bash     ca-certificates     cron     git     git-lfs     openssh-client     --no-install-recommends &&     rm -rf /var/lib/apt/lists/*

# Install wgcf
RUN wget -O /usr/local/bin/wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.29/wgcf_2.2.29_linux_amd64 && \
    chmod +x /usr/local/bin/wgcf

# Install wireproxy
RUN wget -O /tmp/wireproxy.tar.gz https://github.com/whyvl/wireproxy/releases/download/v1.0.9/wireproxy_linux_amd64.tar.gz && \
    tar -xzf /tmp/wireproxy.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/wireproxy && \
    rm /tmp/wireproxy.tar.gz

SHELL ["/bin/bash", "-c"]

# Install chisel
ARG CHISEL_VERSION=1.10.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz &&     gunzip /tmp/chisel.gz &&     mv /tmp/chisel /usr/local/bin/chisel &&     chmod +x /usr/local/bin/chisel

# Download and extract 3x-ui
RUN ARCH=$(uname -m) &&     if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi &&     if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi &&     wget -O /usr/local/x-ui-linux-${ARCH}.tar.gz     "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz" &&     mkdir -p /usr/local/x-ui/ &&     tar -zxvf /usr/local/x-ui-linux-*.tar.gz -C /usr/local/x-ui/ --strip-components=1 &&     rm /usr/local/x-ui-linux-*.tar.gz &&     chmod +x /usr/local/x-ui/x-ui &&     cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

# --- Setup for Git Sync (HTTPS Method) ---

# Define build argument for the GitHub PAT
ARG GITHUB_PAT

# Clone the repository using HTTPS with the PAT for LFS authentication
RUN git clone https://oauth2:${GITHUB_PAT}@github.com/igor04091968/cloud-google-marzban-settings.git /git

# --- End of Git Sync Setup ---

# Create directory for chisel certs and copy them
RUN mkdir -p /etc/chisel
COPY client.crt /etc/chisel/client.crt
COPY client.key /etc/chisel/client.key
COPY ca.crt /etc/chisel/ca.crt

# Copy the startup script
COPY start.sh /usr/local/bin/start.sh
RUN dos2unix /usr/local/bin/start.sh

# Make the script executable
RUN chmod +x /usr/local/bin/start.sh

RUN mkdir /config
RUN chmod 777 /config

# Expose the x-ui port
EXPOSE 2023

# Copy sync script and crontab from the cloned repo
RUN cp /git/huggingface-x-ui-final/sync.sh /usr/local/bin/sync.sh && \
    chmod +x /usr/local/bin/sync.sh && \
    cp /git/huggingface-x-ui-final/crontab /etc/cron.d/sync-cron && \
    chmod 0644 /etc/cron.d/sync-cron && \
    crontab /etc/cron.d/sync-cron

# Set the entrypoint to our startup script
RUN chmod -R 777 /usr/local/x-ui/
ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/start.sh"]
