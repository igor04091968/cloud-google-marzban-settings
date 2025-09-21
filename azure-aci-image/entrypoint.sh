#!/bin/bash
set -m

# Start Marzban service in the background
marzban-cli start &

# Use socat to relay Marzban's port (8000) to a port accessible on all interfaces (8001)
socat TCP-LISTEN:8001,fork TCP:localhost:8000 &

# Start Chisel client in the foreground. It will keep the container running.
# It uses environment variables for configuration.
# R:80:localhost:8001 means "forward port 80 from the remote chisel server to localhost:8001 inside this container"
/usr/local/bin/chisel client --auth "$CHISEL_AUTH" "$CHISEL_SERVER" R:80:localhost:8001
