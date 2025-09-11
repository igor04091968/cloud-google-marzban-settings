#!/bin/bash
set -e

# Start warp daemon in the background
warp-svc &
sleep 3 # Give it a moment to start

# Debugging warp-cli
echo "--- WARP CLI Version ---"
warp-cli --version
echo "--- WARP CLI Help ---"
warp-cli --help
echo "--- End Debugging ---"

# Setup warp
echo "Deleting old registration (if any)..."
warp-cli registration delete || true # Use || true to ignore errors if no registration exists
echo "Registering new client..."
warp-cli --accept-tos registration new
echo "Setting mode to proxy..."
warp-cli set-mode proxy
echo "Connecting to WARP..."
warp-cli connect

echo "WARP SOCKS5 proxy started."

# Start x-ui in the foreground
echo "Starting x-ui panel..."
/usr/local/x-ui/x-ui