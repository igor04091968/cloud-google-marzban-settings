FROM debian:bullseye-slim

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    dos2unix \
    wget \
    tar \
    bash \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Create a non-root user
RUN useradd -m appuser
USER appuser
WORKDIR /home/appuser

# Install tools (sing-box, chisel, x-ui)
# Note: These tools will be installed in the user's home directory or /tmp if specified,
# as the root filesystem will be read-only.
ARG SINGBOX_VERSION=1.12.8
RUN wget -O /tmp/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64.tar.gz" && \
    tar -zxvf /tmp/sing-box.tar.gz -C /tmp && \
    mv /tmp/sing-box-${SINGBOX_VERSION}-linux-amd64/sing-box /home/appuser/sing-box && \
    chmod +x /home/appuser/sing-box && \
    rm -rf /tmp/sing-box*

ARG CHISEL_VERSION=1.10.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /home/appuser/chisel && \
    chmod +x /home/appuser/chisel

# Install x-ui
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    wget -O /tmp/x-ui-linux-${ARCH}.tar.gz \
    "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz" && \
    mkdir -p /home/appuser/x-ui/ && \
    tar -zxvf /tmp/x-ui-linux-*.tar.gz -C /home/appuser/x-ui/ --strip-components=1 && \
    rm /tmp/x-ui-linux-*.tar.gz && \
    chmod +x /home/appuser/x-ui/x-ui && \
    cp /home/appuser/x-ui/x-ui.sh /home/appuser/x-ui/x-ui-wrapper.sh && \
    # Backup original bin contents (if needed, but for read-only, we'll manage this in start.sh)
    mkdir -p /home/appuser/xray-backup && \
    cp -r /home/appuser/x-ui/bin/. /home/appuser/xray-backup/

# Copy all files from the build context into the work directory
COPY . /home/appuser/

# Make scripts executable
RUN chmod +x /home/appuser/warp_proxy.sh && \
    chmod +x /home/appuser/start.sh

# Expose the x-ui port
EXPOSE 2023

# Set the entrypoint to our startup script
ENTRYPOINT ["/bin/bash", "-c", "/home/appuser/start.sh"]
