FROM debian:bullseye-slim

# Install prerequisites for adding repositories, then WARP, then other tools
RUN apt-get update && apt-get install -y curl gnupg ca-certificates --no-install-recommends && \
    # Add Cloudflare GPG key
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    # Add Cloudflare repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bullseye main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    # Update and install warp + other tools
    apt-get update && \
    apt-get install -y \
    cloudflare-warp \
    dos2unix \
    wget \
    tar \
    bash \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Install chisel
ARG CHISEL_VERSION=1.10.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# Download and extract 3x-ui
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    wget -O /usr/local/x-ui-linux-${ARCH}.tar.gz \
    "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz" && \
    mkdir -p /usr/local/x-ui/ && \
    tar -zxvf /usr/local/x-ui-linux-*.tar.gz -C /usr/local/x-ui/ --strip-components=1 && \
    rm /usr/local/x-ui-linux-*.tar.gz && \
    chmod +x /usr/local/x-ui/x-ui && \
    cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

# Copy the startup script
COPY start.sh /usr/local/bin/start.sh

# Make the script executable
RUN chmod +x /usr/local/bin/start.sh

# Expose the x-ui port
EXPOSE 2053

# Set the entrypoint to our startup script
RUN chmod -R 777 /usr/local/x-ui/
ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/start.sh"]
