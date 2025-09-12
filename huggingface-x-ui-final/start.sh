#!/bin/bash

# ==============================================================================
# X-UI & Chisel Tunnel Start Script for Hugging Face Spaces
# ==============================================================================

# Set a writable directory for the x-ui database, as the default is read-only.
export XUI_DB_FOLDER=/tmp

# --- Chisel Client Configuration ---
# This function runs the chisel client in a loop to ensure the tunnel
# to the main server (vds1) is always active.
run_chisel() {
  while true; do
    echo "Starting chisel client..."
    # Connects to the chisel server on vds1.iri1968.dpdns.org at port 8080.
    # -v : Verbose logging.
    # --auth "cloud:2025" : Authenticates with the server.
    # R:8000:127.0.0.1:2023 : Creates a REVERSE tunnel. It opens port 8000 on the
    #                        SERVER (vds1) and forwards all traffic from there
    #                        to port 2023 on THIS container (127.0.0.1:2023),
    #                        where the x-ui panel is running.
    /usr/local/bin/chisel client -v --auth "cloud:2025" vds1.iri1968.dpdns.org:8080 R:8000:127.0.0.1:2023
    
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start the chisel client in the background.
echo "Forking chisel client to background..."
run_chisel &

# Wait a moment for the background process to establish the tunnel.
sleep 3

# --- X-UI Panel Configuration ---
# Configure the x-ui panel settings.

# Set the internal port for the x-ui panel to listen on.
echo "Configuring x-ui panel port..."
/usr/local/x-ui/x-ui setting -port 2023

# Set the web base path to root (/).
echo "Configuring x-ui web base path..."
/usr/local/x-ui/x-ui setting -webBasePath /

# Reset x-ui admin credentials for consistency.
echo "Resetting x-ui admin credentials..."
/usr/local/x-ui/x-ui setting -username prog10 -password 04091968

# --- Start X-UI Panel ---
# Start the main x-ui application in the foreground.
echo "Starting x-ui panel..."
cd /usr/local/x-ui
./x-ui