#!/bin/bash

# ==============================================================================
# WARP + X-UI & Chisel Start Script (Improved by Gemini)
# ==============================================================================

# --- WARP SOCKS5 Proxy Setup ---
run_warp() {
    echo "[INFO] Setting up WARP..."
    if [ ! -f "/config/wgcf-account.toml" ]; then
        echo "[INFO] WARP account not found. Registering a new one..."
        wgcf register --accept-tos --config /config/wgcf-account.toml
    else
        echo "[INFO] Using existing WARP account."
    fi

    echo "[INFO] Generating WireProxy config..."
    wgcf generate --config /config/wgcf-account.toml --profile /config/wgcf-profile.conf > /dev/null 2>&1
    
    PRIVATE_KEY=$(grep "PrivateKey" /config/wgcf-profile.conf | cut -d' ' -f3)
    PUBLIC_KEY=$(grep "PublicKey" /config/wgcf-profile.conf | cut -d' ' -f3)
    RESERVED=$(grep "Reserved" /config/wgcf-profile.conf | cut -d' ' -f3)
    ENDPOINT=$(grep "Endpoint" /config/wgcf-profile.conf | cut -d' ' -f3)

    cat > /config/wireproxy.conf <<EOF
[WireGuard]
PrivateKey = $PRIVATE_KEY
Address = 172.16.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = $PUBLIC_KEY
Reserved = $RESERVED
Endpoint = $ENDPOINT
PersistentKeepalive = 25

[Socks5]
BindAddress = 127.0.0.1:40000
EOF

    echo "[INFO] Starting WireProxy in the background..."
    /usr/local/bin/wireproxy --config /config/wireproxy.conf &
    sleep 2
    echo "[INFO] WARP SOCKS5 proxy should be running on 127.0.0.1:40000"
}


# --- Chisel Client Configuration ---
run_chisel() {
  while true; do
    echo "[INFO] Starting chisel client..."
    /usr/local/bin/chisel client -v --auth "cloud:2025" "https://vds1.iri1968.dpdns.org/chisel-ws" R:8001:127.0.0.1:2053
    
    echo "[ERROR] Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# --- Main Execution ---

echo "[INFO] Container entrypoint started."

# 1. Start the cron daemon in the background
echo "[INFO] Starting cron daemon..."
cron
echo "[INFO] Cron daemon started."

# 2. Start WARP
run_warp

# 3. Start chisel client in the background.
echo "[INFO] Forking chisel client to background..."
run_chisel &

sleep 3 # Give chisel a moment to establish the tunnel.

# 4. Configure X-UI Panel
echo "[INFO] Configuring x-ui panel..."
/usr/local/x-ui/x-ui setting -port 2023
/usr/local/x-ui/x-ui setting -webBasePath /
/usr/local/x-ui/x-ui setting -username prog10 -password 04091968
echo "[INFO] x-ui configuration complete."

# 5. Start X-UI Panel (This is the main foreground process that keeps the container alive)
echo "[INFO] Starting x-ui panel. This will be the final command."
cd /usr/local/x-ui
./x-ui