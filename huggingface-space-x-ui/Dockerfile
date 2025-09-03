# Use a lightweight base image
FROM debian:bullseye-slim

# Install necessary packages and clean up
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    tar \
    ca-certificates \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

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
    chmod +x /opt/x-ui/x-ui

# Copy the startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose the x-ui port (default is 2053, can be changed in config)
EXPOSE 2053

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]