# Use a base image that has Python and a shell (e.g., Ubuntu or Alpine)
FROM ubuntu:latest

# Install necessary packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    wget \
    gzip \
    netcat \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install x-ui dependencies (assuming x-ui is a Python application)
# You might need to adjust these based on actual x-ui requirements
RUN pip3 install flask # Example, replace with actual x-ui dependencies

# Download and install chisel
ARG CHISEL_VERSION=1.10.1
ARG CHISEL_ARCH=amd64
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_${CHISEL_ARCH}.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# Copy x-ui application files (assuming x-ui is in the current directory)
# You'll need to replace this with the actual path to your x-ui files
COPY . /app/x-ui/
WORKDIR /app/x-ui/

# Create a startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose the x-ui port
EXPOSE 2053

# Set the entrypoint to the startup script
ENTRYPOINT ["/usr/local/bin/start.sh"]
