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
    sqlite3 \
    jq \
    openssl \
    unzip \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Create a non-root user
RUN useradd -m appuser

# Create a writable directory for x-ui's /etc/x-ui configuration
# This will be the target of a symbolic link from /etc/x-ui
RUN mkdir -p /var/lib/x-ui-config && \
    chown appuser:appuser /var/lib/x-ui-config

# Install tools (sing-box, chisel, x-ui) directly into appuser's home directory
# This ensures they are accessible and owned by appuser later.
WORKDIR /tmp # Use /tmp for downloads during installation

ARG SINGBOX_VERSION=1.12.8
RUN wget -O sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64.tar.gz" && \
    tar -zxvf sing-box.tar.gz && \
    mv sing-box-${SINGBOX_VERSION}-linux-amd64/sing-box /home/appuser/sing-box && \
    chmod +x /home/appuser/sing-box && \
    rm -rf sing-box*

ARG CHISEL_VERSION=1.10.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O chisel.gz && \
    gunzip chisel.gz && \
    mv chisel /home/appuser/chisel && \
    chmod +x /home/appuser/chisel

# Install x-ui (MHSanaei/3x-ui)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    wget -O x-ui-linux-${ARCH}.tar.gz \
    "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz" && \
    mkdir -p /home/appuser/x-ui/ && \
    tar -zxvf x-ui-linux-*.tar.gz -C /home/appuser/x-ui/ --strip-components=1 && \
    rm x-ui-linux-*.tar.gz && \
    chmod +x /home/appuser/x-ui/x-ui && \
    cp /home/appuser/x-ui/x-ui.sh /home/appuser/x-ui/x-ui-wrapper.sh && \
    mkdir -p /home/appuser/xray-backup && \
    cp -r /home/appuser/x-ui/bin/. /home/appuser/xray-backup/

# Create symbolic link for /etc/x-ui to a writable location
# This must be done *after* x-ui is installed, but before switching user.
# Remove existing /etc/x-ui if it's a directory created by x-ui.
RUN rm -rf /etc/x-ui && \
    ln -s /var/lib/x-ui-config /etc/x-ui

# Set ownership of installed tools to appuser
RUN chown -R appuser:appuser /home/appuser/sing-box \
    /home/appuser/chisel \
    /home/appuser/x-ui \
    /home/appuser/xray-backup

# Copy custom scripts and configs to appuser's home directory
COPY --chown=appuser:appuser . /home/appuser/

# Switch to non-root user
USER appuser
WORKDIR /home/appuser

# Make scripts executable (already done during installation, but good to re-confirm for copied scripts)
RUN chmod +x /home/appuser/start.sh

# Expose the x-ui port
EXPOSE 2023

# Set the entrypoint to our startup script
ENTRYPOINT ["/bin/bash", "-c", "/home/appuser/start.sh"]