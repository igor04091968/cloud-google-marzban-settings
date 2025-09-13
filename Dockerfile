# Use a lightweight base image
FROM debian:bullseye-slim

# Install necessary packages and clean up
RUN apt-get update && apt-get install -y \
    dos2unix \
    wget \
    curl \
    tar \
    ca-certificates \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install wgcf
RUN wget -O /usr/local/bin/wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.29/wgcf_2.2.29_linux_amd64 && \
    chmod +x /usr/local/bin/wgcf

# Install wireproxy
RUN wget -O /tmp/wireproxy.tar.gz https://github.com/whyvl/wireproxy/releases/download/v1.0.9/wireproxy_linux_amd64.tar.gz && \
    tar -xzf /tmp/wireproxy.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/wireproxy && \
    rm /tmp/wireproxy.tar.gz

# Install chisel
ARG CHISEL_VERSION=1.9.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# Download and install x-ui
RUN LATEST_XUI_URL=$(curl -sL "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"browser_download_url":' | grep 'linux-amd64.tar.gz' | sed -E 's/.*"([^"]+)".*/\1/') && \
    wget -O /tmp/x-ui.tar.gz "${LATEST_XUI_URL}" && \
    mkdir -p /opt/x-ui && \
    tar -zxvf /tmp/x-ui.tar.gz -C /opt/x-ui && \
    rm /tmp/x-ui.tar.gz && \
    chmod +x /opt/x-ui/x-ui/x-ui

# Force rebuild by adding a changing ARG
ARG CACHE_BUSTER=20250903050820

# Copy the startup script and fix line endings
COPY start.sh /usr/local/bin/start.sh
RUN dos2unix /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

RUN mkdir -p /data /var/log && chmod 777 /data /var/log

RUN mkdir -p /config && touch /config/cron.log && chmod 777 /config /config/cron.log

# Expose the x-ui port (default is 2053, can be changed in config)
EXPOSE 2023

WORKDIR /usr/local/x-ui

# Set the entrypoint to execute with bash
ENTRYPOINT ["/bin/bash", "/usr/local/bin/start.sh"]