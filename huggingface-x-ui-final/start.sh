#!/bin/bash

# Set a writable, persistent directory for the x-ui database
export XUI_DB_PATH=/data/x-ui.db

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client, forwarding to internal port 2025..."
    /usr/local/bin/chisel client -v --auth "cloud:2025" vds1.iri1968.dpdns.org:8443 R:8000:127.0.0.1:2025
    
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start chisel in the background
run_chisel &

# Wait a moment for the background process to start
sleep 2

# Check if the database file exists. If not, it's the first run.
if [ ! -f "$XUI_DB_PATH" ]; then
  echo "First run detected. Initializing settings..."
  /usr/local/x-ui/x-ui setting -port 2025
  /usr/local/x-ui/x-ui setting -webBasePath /
  /usr/local/x-ui/x-ui setting -username prog10 -password 04091968
else
  echo "Database found. Skipping initialization."
fi

# Start x-ui in the foreground
echo "Starting x-ui panel..."
cd /usr/local/x-ui
./x-ui
