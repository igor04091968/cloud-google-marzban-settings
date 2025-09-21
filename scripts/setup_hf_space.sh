#!/bin/bash

# This script automates the setup of a Hugging Face Space for 3x-ui with a chisel tunnel.

# --- User Input ---
HF_USERNAME="rachkovii68"

read -p "Enter the name of your new Hugging Face Space: " HF_SPACENAME
if [ -z "$HF_SPACENAME" ]; then
    echo "Space name cannot be empty."
    exit 1
fi

# --- Git Clone ---
echo "--- Cloning the repository... ---"
git clone "https://huggingface.co/spaces/$HF_USERNAME/$HF_SPACENAME"
if [ $? -ne 0 ]; then
    echo "Failed to clone repository. Please check the username and space name."
    exit 1
fi

cd "$HF_SPACENAME"

# --- Create Dockerfile ---
echo "--- Creating Dockerfile... ---"
cat << 'EOF' > Dockerfile
# Use the official 3x-ui image as the base
FROM ghcr.io/mhsanaei/3x-ui:latest

# Switch to root to install new packages
USER root

# The base image uses apk package manager
RUN apk add --no-cache wget gzip

# Download and install chisel
ARG CHISEL_VERSION=1.9.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# Copy our custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set our custom script as the new entrypoint
ENTRYPOINT ["/entrypoint.sh"]
EOF

# --- Create entrypoint.sh ---
echo "--- Creating entrypoint.sh... ---"
cat << 'EOF' > entrypoint.sh
#!/bin/sh

# Start the original 3x-ui entrypoint in the background
# This will launch the x-ui panel
echo "Starting 3x-ui panel..."
/docker-entrypoint.sh &

# Wait a few seconds for the panel to initialize
sleep 5

# Now, start the chisel client in the foreground to keep the container running
echo "Starting chisel client tunnel..."

# These variables must be set as "Secrets" in your Hugging Face Space settings
# Example: CHISEL_SERVER_URL = vds1.iri1968.dpdns.org:443
#          CHISEL_AUTH = cloud:2025
/usr/local/bin/chisel client -v --auth "$CHISEL_AUTH" "$CHISEL_SERVER_URL" R:443:localhost:2053
EOF

# --- Git Push ---
echo "--- Uploading files to Hugging Face... ---"
git add Dockerfile entrypoint.sh
git commit -m "Add 3x-ui and chisel tunnel configuration"
git push

if [ $? -ne 0 ]; then
    echo "Failed to push to repository. Please check your git credentials."
    exit 1
fi

# --- Final Instructions ---
echo ""
echo "--- ✅ SUCCESS! ---"
echo ""
echo "Your configuration has been pushed to Hugging Face."
echo "The Space will now build. You can monitor the build in the 'Logs' tab on your Space page."
echo ""
echo "--- ⚠️ IMPORTANT FINAL STEP ⚠️ ---"
echo "You MUST add the following secrets in your Space settings on the Hugging Face website:"
echo "Go to: Settings -> Secrets -> New secret"
echo ""
echo "1. Name: CHISEL_AUTH"
echo "   Value: cloud:2025"
echo ""
echo "2. Name: CHISEL_SERVER_URL"
echo "   Value: vds1.iri1968.dpdns.org:993"
echo ""
echo "3. Name: XUI_USERNAME"
echo "   Value: admin"
echo ""
echo "4. Name: XUI_PASSWORD"
echo "   Value: BujhmBdfyjdb$"
echo ""
echo "After the build is complete and secrets are set, your x-ui panel should be available at https://vds1.iri1968.dpdns.org"
echo ""
