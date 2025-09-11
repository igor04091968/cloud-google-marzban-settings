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
    gpg \
    lsb-release \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Install chisel
ARG CHISEL_VERSION=1.9.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# Install Cloudflare WARP
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
RUN apt-get update && apt-get install -y cloudflare-warp

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
RUN mkdir -p /etc/x-ui && \
    chown -R 65534:65534 /etc/x-ui && \
    chown -R 65534:65534 /usr/local/x-ui

# Copy the new entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the x-ui port
EXPOSE 2053

# Set the entrypoint to our new startup script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]