#!/bin/bash
echo "Architecture: $(uname -m)"

# --- Restore Configs from baked-in repo files ---
# The contents of huggingface-x-ui-final were copied to /src/config
CONFIG_DIR_IN_REPO="/src/config/x-ui-configs"
LIVE_XUI_DB_PATH="/tmp/x-ui.db" # Using /tmp as it's guaranteed to be writable
LIVE_XRAY_CONFIG_PATH="/usr/local/x-ui/bin/config.json"

# Restore files if they exist in the repo
echo "Restoring configs from baked-in files..."
if [ -f "${CONFIG_DIR_IN_REPO}/x-ui.db" ]; then
    cp -f "${CONFIG_DIR_IN_REPO}/x-ui.db" "${LIVE_XUI_DB_PATH}"
    echo "Restored x-ui.db"
fi
if [ -f "${CONFIG_DIR_IN_REPO}/config.json" ]; then
    cp -f "${CONFIG_DIR_IN_REPO}/config.json" "${LIVE_XRAY_CONFIG_PATH}"
    echo "Restored config.json"
fi
# --- End Restore ---

# --- WARP SOCKS Proxy Setup ---
echo "Starting WARP SOCKS5 proxy via sing-box..."
# The script is now at /src/config/warp_proxy.sh
nohup /src/config/warp_proxy.sh > /tmp/warp.log 2>&1 &
echo "WARP SOCKS5 proxy started in background. Log at /tmp/warp.log"
# --- End WARP SOCKS Proxy Setup ---

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER=/tmp

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client, connecting to the correct /chisel-ws endpoint..."
    /usr/local/bin/chisel client -v --auth "cloud:2025" --keepalive 25s "https://vds1.iri1968.dpdns.org/chisel-ws" R:8000:127.0.0.1:2053
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