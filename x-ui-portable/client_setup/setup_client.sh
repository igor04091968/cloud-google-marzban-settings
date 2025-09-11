#!/bin/bash
# Script to set up the client-side components for the x-ui tunnel

set -e

# Load the Docker image
echo "Loading Docker image..."
docker load -i x-ui-tunnel.tar

# Run docker-compose
echo "Starting containers..."
docker-compose up -d

echo "Client setup complete."
