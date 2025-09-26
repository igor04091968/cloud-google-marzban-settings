#!/bin/bash
echo "Architecture: $(uname -m)"

# --- Restore Configs from baked-in repo files ---
CONFIG_DIR_IN_REPO="/opt/app/x-ui-configs"
LIVE_XUI_DB_PATH="/tmp/x-ui.db"
LIVE_XRAY_CONFIG_PATH="/usr/local/x-ui/bin/config.json"

echo "Restoring configs from baked-in files..."
if [ -f "${CONFIG_DIR_IN_REPO}/config.json" ]; then
    cp -f "${CONFIG_DIR_IN_REPO}/config.json" "${LIVE_XRAY_CONFIG_PATH}"
    echo "Restored config.json"
fi
if [ -f "${CONFIG_DIR_IN_REPO}/x-ui.db" ]; then
    cp -f "${CONFIG_DIR_IN_REPO}/x-ui.db" "${LIVE_XUI_DB_PATH}"
    echo "Restored x-ui.db"
fi
# --- End Restore ---

# --- WARP SOCKS Proxy Setup ---
echo "Starting WARP SOCKS5 proxy via sing-box..."
nohup /opt/app/warp_proxy.sh > /tmp/warp.log 2>&1 &
echo "WARP SOCKS5 proxy started in background. Log at /tmp/warp.log"
# --- End WARP SOCKS Proxy Setup ---

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER=/tmp

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client..."
    # This is the line from the user's last instruction
    /usr/local/bin/chisel client -v --auth "cloud:2025" --keepalive 25s "https://vds1.iri1968.dpdns.org/chisel-ws" R:8080:127.0.0.1:2023 R:8081:127.0.0.1:20001
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start chisel in the background
run_chisel &

# Wait a moment for the background process to start
sleep 2

# --- ADDED USER SETTINGS ---
echo "Configuring x-ui web base path..."
/usr/local/x-ui/x-ui setting -webBasePath /

echo "Resetting x-ui admin credentials..."
/usr/local/x-ui/x-ui setting -username prog10 -password 04091968

# This command is from a previous step, it is needed for the port
/usr/local/x-ui/x-ui setting -port 2023
# --- END ADDED SETTINGS ---

# Start x-ui in the foreground
echo "Starting x-ui panel..."
cd /usr/local/x-ui
exec ./x-ui