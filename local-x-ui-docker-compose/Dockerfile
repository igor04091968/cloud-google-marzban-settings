# Use a lightweight base image
FROM debian:bullseye-slim

# Install necessary packages and clean up
RUN apt-get update && apt-get install -y \
    dos2unix \
    wget \
    curl \
    tar \
    bash \
    ca-certificates \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Install chisel
ARG CHISEL_VERSION=1.9.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# Download, extract, and configure 3x-ui
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    wget -O /usr/local/x-ui-linux-${ARCH}.tar.gz \
    "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz" && \
    mkdir -p /usr/local/x-ui/ && \
    tar -zxvf /usr/local/x-ui-linux-*.tar.gz -C /usr/local/x-ui/ --strip-components=1 && \
    rm /usr/local/x-ui-linux-*.tar.gz && \
    chmod +x /usr/local/x-ui/x-ui && \
    cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui && \
    /usr/local/x-ui/x-ui setting -port 2053

# Create data directory and set permissions
# Using user 'nobody' (UID 65534) as a common practice for non-root execution
RUN mkdir -p /etc/x-ui && \
    chown -R 65534:65534 /etc/x-ui && \
    chown -R 65534:65534 /usr/local/x-ui

# Create the startup script for the entrypoint
RUN echo '#!/bin/bash' > /usr/local/bin/start.sh && \
    echo '/usr/local/x-ui/x-ui' >> /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

# Expose the x-ui port
EXPOSE 2053

# Set the entrypoint to our startup script
ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/start.sh"]