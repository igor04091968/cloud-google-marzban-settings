#!/bin/bash

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER=/tmp

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client with full port forwarding..."
    # This line is modified to include all necessary proxy ports
    /usr/local/bin/chisel client -v --auth "cloud:2025" vds1.iri1968.dpdns.org:80 R:8443:localhost:2053 R:38652:localhost:38652 R:27081:localhost:27081 R:36955:localhost:36955
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start chisel in the background
run_chisel &

# Set webBasePath
/usr/local/x-ui/x-ui setting -webBasePath /

# Reset x-ui admin credentials to admin/admin
/usr/local/x-ui/x-ui setting -username prog10 -password 04091968

# Start x-ui in the foreground
cd /usr/local/x-ui
./x-ui