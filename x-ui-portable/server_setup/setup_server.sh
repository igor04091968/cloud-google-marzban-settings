#!/bin/bash
# Script to set up the server-side components for the x-ui tunnel

set -e

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Copy service and config files
echo "Copying service and config files..."
cp chisel.service /etc/systemd/system/chisel.service
cp x-ui.conf /etc/nginx/conf.d/x-ui.conf

# Reload systemd and restart services
echo "Reloading systemd and restarting services..."
systemctl daemon-reload
systemctl restart chisel.service
systemctl restart nginx

echo "Server setup complete."
