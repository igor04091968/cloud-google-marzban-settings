#!/bin/bash

# Remove problematic chown commands for mounted volumes
# chown appuser:appuser /home/appuser/.config/x-ui/
# chown appuser:appuser /home/appuser/x-ui-logs/
# chown appuser:appuser /tmp/ # /tmp is tmpfs, always writable

# Ensure necessary directories are writable (if not already handled by volume mounts)
mkdir -p /home/appuser/.config/x-ui/
mkdir -p /home/appuser/x-ui-logs/
mkdir -p /tmp/

echo "Architecture: $(uname -m)"

# Populate the x-ui/bin volume with contents from xray-backup
# This needs to be done every time the container starts, as volumes are persistent.
# Only copy if the target directory is empty to avoid overwriting user data.
if [ -z "$(ls -A /home/appuser/x-ui/bin/)" ]; then
    echo "Populating /home/appuser/x-ui/bin/ from xray-backup..."
    cp -r /home/appuser/xray-backup/. /home/appuser/x-ui/bin/
    echo "/home/appuser/x-ui/bin/ populated."
fi

# --- Restore Configs from baked-in repo files ---
CONFIG_DIR_IN_REPO="/home/appuser/x-ui-configs"
LIVE_XUI_DB_PATH="/etc/x-ui/x-ui.db" # Symlinked writable location
LIVE_XRAY_CONFIG_PATH="/home/appuser/x-ui/bin/config.json" # This path is now writable via volume mount

echo "Restoring configs from baked-in files..."
# Copy config.json to the writable bin directory
if [ -f "${CONFIG_DIR_IN_REPO}/config.json" ]; then
    cp -f "${CONFIG_DIR_IN_REPO}/config.json" "${LIVE_XRAY_CONFIG_PATH}"
    echo "Restored config.json"
fi

# Initialize x-ui.db if it doesn't exist or is empty
if [ ! -f "${LIVE_XUI_DB_PATH}" ] || [ ! -s "${LIVE_XUI_DB_PATH}" ]; then
    echo "Initializing x-ui.db..."
    # Run x-ui once to create the default database structure
    # Ensure x-ui can write to /etc/x-ui (via volume mount) and /home/appuser/.config/x-ui/ (via volume mount)
    /home/appuser/x-ui/x-ui & 
    XUI_PID=$!
    sleep 5 # Give x-ui time to create the DB
    kill $XUI_PID
    wait $XUI_PID 2>/dev/null # Wait for x-ui to exit gracefully
    echo "x-ui.db initialized."
fi

# Configure x-ui.db using sqlite3 commands (extracted from x-ui-pro.sh logic)
echo "Configuring x-ui database..."
sqlite3 "${LIVE_XUI_DB_PATH}" "UPDATE settings SET value = '2023' WHERE key = 'port';"
sqlite3 "${LIVE_XUI_DB_PATH}" "UPDATE settings SET value = '/' WHERE key = 'webBasePath';"
sqlite3 "${LIVE_XUI_DB_PATH}" "UPDATE settings SET value = 'prog10' WHERE key = 'username';"
sqlite3 "${LIVE_XUI_DB_PATH}" "UPDATE settings SET value = '04091968' WHERE key = 'password';"
echo "x-ui database configured."

# --- End Restore ---

# --- Chisel Client Setup ---
run_chisel() {
  while true; do
    echo "Starting chisel client..."
    /home/appuser/chisel client -v --auth "cloud:2025" --keepalive 25s "https://vds1.iri1968.dpdns.org/chisel-ws" R:8080:127.0.0.1:2023 R:8081:127.0.0.1:20001
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# Start chisel in the background
run_chisel &

# Wait a moment for the background process to start
sleep 2
# --- End Chisel Client Setup ---

# --- Sing-box as core proxy ---
echo "Starting sing-box as core proxy..."
nohup /home/appuser/sing-box run -c /home/appuser/x-ui-configs/singbox_config.json > /home/appuser/x-ui-logs/singbox.log 2>&1 &
echo "Sing-box started in background. Log at /home/appuser/x-ui-logs/singbox.log"
# --- End Sing-box ---

# Start x-ui in the foreground
echo "Starting x-ui panel... (This will be the main process)"
cd /home/appuser/x-ui
exec ./x-ui