#!/bin/bash

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER=/tmp

# Start socat proxy
socat TCP-LISTEN:9000,fork,reuseaddr TCP:vds1.iri1968.dpdns.org:443 &

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client..."
    /usr/local/bin/chisel client -v --auth "cloud:2025" --proxy http://127.0.0.1:9000 wss://vds1.iri1968.dpdns.org R:2023:127.0.0.1:2023
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start chisel in the background
run_chisel &

# Wait a moment for the background process to start
sleep 2

# Set x-ui port
/usr/local/x-ui/x-ui setting -port 2023

# Set webBasePath
/usr/local/x-ui/x-ui setting -webBasePath /

# Reset x-ui admin credentials
/usr/local/x-ui/x-ui setting -username prog10 -password 04091968

# Start x-ui in the foreground
echo "Starting x-ui panel..."
cd /usr/local/x-ui
./x-ui
