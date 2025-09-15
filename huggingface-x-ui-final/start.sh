#!/bin/bash
echo "Architecture: $(uname -m)"

# --- Restore Configs, Start Hourly Sync ---
GIT_REPO_DIR="/app" # The git repo is the root directory in Hugging Face spaces
CONFIG_DIR_IN_REPO="${GIT_REPO_DIR}/x-ui-configs"
LIVE_XUI_DB_PATH="/tmp/x-ui.db"
LIVE_XRAY_CONFIG_PATH="/usr/local/x-ui/bin/config.json"

# Pull latest changes
echo "Pulling latest configs from Git..."
cd "$GIT_REPO_DIR"
git pull

# Restore files if they exist in the repo
echo "Restoring configs from Git..."
if [ -f "${CONFIG_DIR_IN_REPO}/x-ui.db" ]; then
    cp -f "${CONFIG_DIR_IN_REPO}/x-ui.db" "${LIVE_XUI_DB_PATH}"
    echo "Restored x-ui.db"
fi
if [ -f "${CONFIG_DIR_IN_REPO}/config.json" ]; then
    cp -f "${CONFIG_DIR_IN_REPO}/config.json" "${LIVE_XRAY_CONFIG_PATH}"
    echo "Restored config.json"
fi

# Background function for hourly sync
run_hourly_sync() {
  while true; do
    echo "SYNC_LOOP: Waiting 1 hour before next sync."
    sleep 3600
    echo "SYNC_LOOP: Starting hourly sync to GitHub."
    # Assuming sync.sh is in the git repo root /app
    "${GIT_REPO_DIR}/sync.sh"
  done
}

echo "Starting hourly sync process in background..."
run_hourly_sync &
# --- End Restore & Sync ---

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