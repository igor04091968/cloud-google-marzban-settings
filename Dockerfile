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

# Create the startup script to run both x-ui and chisel client
RUN cat <<'EOF' > /usr/local/bin/start.sh
#!/bin/bash

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER=/tmp

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client..."
    /usr/local/bin/chisel client -v --auth "cloud:2025" vds1.iri1968.dpdns.org:80 R:8443:localhost:2053
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start chisel in the background
run_chisel &

# Set webBasePath
/usr/local/x-ui/x-ui setting -webBasePath /

# Start x-ui in the foreground
cd /usr/local/x-ui
./x-ui
EOF

# Make the script executable
RUN chmod +x /usr/local/bin/start.sh

# Expose the x-ui port
EXPOSE 2053

# Set the entrypoint to our startup script
ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/start.sh"]
