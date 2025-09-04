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
  done # Fixed: added 'done' for the while loop
}

# Start chisel in the background
run_chisel &

# Set webBasePath
/usr/local/x-ui/x-ui setting -webBasePath /

# Start x-ui in the foreground
cd /usr/local/x-ui # Reverted to /usr/local/x-ui
./x-ui
