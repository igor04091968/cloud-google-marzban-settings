#!/bin/bash

# Ensure necessary directories are writable (e.g., for x-ui.db and logs)
mkdir -p /home/appuser/.config/x-ui/
mkdir -p /home/appuser/x-ui-logs/
mkdir -p /tmp/

# Restore original xray binaries and data files from the backup location
# to the tmpfs-mounted bin directory.
# For read-only filesystem, we assume x-ui will manage its own binaries in its working dir
# or that they are already correctly placed.
# If x-ui needs to write to its bin directory, this will fail.
# We will rely on x-ui's internal mechanisms or ensure it writes to /tmp or /home/appuser/.config

echo "Architecture: $(uname -m)"

# --- Restore Configs from baked-in repo files ---
CONFIG_DIR_IN_REPO="/home/appuser/x-ui-configs"
LIVE_XUI_DB_PATH="/home/appuser/.config/x-ui/x-ui.db" # Changed to a writable location
LIVE_XRAY_CONFIG_PATH="/home/appuser/x-ui/bin/config.json" # This might be problematic if /home/appuser/x-ui/bin is read-only

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
nohup /home/appuser/warp_proxy.sh > /home/appuser/x-ui-logs/warp.log 2>&1 &
echo "WARP SOCKS5 proxy started in background. Log at /home/appuser/x-ui-logs/warp.log"
# --- End WARP SOCKS Proxy Setup ---

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER="/home/appuser/.config/x-ui/" # Changed to a writable location

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client..."
    # This is the line from the user's last instruction
    /home/appuser/chisel client -v --auth "cloud:2025" --keepalive 25s "https://vds1.iri1968.dpdns.org/chisel-ws" R:8080:127.0.0.1:2023 R:8081:127.0.0.1:20001
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
/home/appuser/x-ui/x-ui setting -webBasePath /

echo "Resetting x-ui admin credentials..."
/home/appuser/x-ui/x-ui setting -username prog10 -password 04091968

# This command is from a previous step, it is needed for the port
/home/appuser/x-ui/x-ui setting -port 2023
# --- END ADDED SETTINGS ---

# Start x-ui in the foreground
echo "Starting x-ui panel..."
cd /home/appuser/x-ui
exec ./x-ui