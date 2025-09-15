#!/bin/bash
echo "Architecture: $(uname -m)"

# --- WARP SOCKS Proxy Setup ---
echo "Starting WARP SOCKS5 proxy via sing-box..."
nohup /usr/local/bin/warp_proxy.sh > /tmp/warp.log 2>&1 &
echo "WARP SOCKS5 proxy started in background. Log at /tmp/warp.log"
# --- End WARP SOCKS Proxy Setup ---

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER=/tmp

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client, connecting to the correct /chisel-ws endpoint..."
    # Corrected URL to point to the websocket endpoint defined in Nginx
    /usr/local/bin/chisel client -v --auth "cloud:2025" "https://vds1.iri1968.dpdns.org/chisel-ws" R:8000:127.0.0.1:2053
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start chisel in the background
run_chisel &

# Wait a moment for the background process to start
sleep 2

# Set webBasePath
/usr/local/x-ui/x-ui setting -webBasePath /

# Reset x-ui admin credentials
/usr/local/x-ui/x-ui setting -username prog10 -password 04091968

# Start x-ui in the foreground
echo "Starting x-ui panel..."
cd /usr/local/x-ui
./x-ui