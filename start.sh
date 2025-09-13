#!/bin/bash
# ==============================================================================
# WARP + X-UI & Chisel Tunnel Start Script
# ==============================================================================

# --- WARP SOCKS5 Proxy Setup ---
run_warp() {
    echo "Setting up WARP..."
    # Check if an account file already exists
    if [ ! -f "/config/wgcf-account.toml" ]; then
        echo "WARP account not found. Registering a new one..."
        wgcf register --accept-tos --config /config/wgcf-account.toml
    else
        echo "Using existing WARP account."
    fi

    echo "Generating WireProxy config..."
    # Generate WireGuard profile from account
    wgcf generate --config /config/wgcf-account.toml --profile /config/wgcf-profile.conf
    
    # Extract info from the WireGuard profile to create wireproxy.conf
    PRIVATE_KEY=$(grep "PrivateKey" /config/wgcf-profile.conf | cut -d' ' -f3)
    PUBLIC_KEY=$(grep "PublicKey" /config/wgcf-profile.conf | cut -d' ' -f3)
    ENDPOINT=$(grep "Endpoint" /config/wgcf-profile.conf | cut -d' ' -f3)

    # Create wireproxy.conf
    cat > /config/wireproxy.conf <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 172.16.0.2/32
DNS = 1.1.1.1
[Peer]
PublicKey = $PUBLIC_KEY
Endpoint = $ENDPOINT
PersistentKeepalive = 25
[Socks5]
BindAddress = 127.0.0.1:40000
EOF

    echo "Starting WireProxy in the background..."
    # Run wireproxy in the background
    /usr/local/bin/wireproxy --config /config/wireproxy.conf &
    sleep 2 # Give it a moment to start
    echo "WARP SOCKS5 proxy should be running on 127.0.0.1:40000"
}


# --- Chisel Client Configuration ---
run_chisel() {
  while true; do
    echo "Starting chisel client..."
    /usr/local/bin/chisel client -v --auth "cloud:2025" "https://vds1.iri1968.dpdns.org/chisel-ws" R:8000:127.0.0.1:2023
    
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  done
}

# --- Main Execution ---
# 1. Start sync job in a background loop (replaces cron)
echo "Starting sync job in a background loop..."
(
while true; do
/usr/local/bin/sync.sh >> /config/cron.log 2>&1
sleep 60
done
) &
echo "Sync job started."

# 2. Start WARP
run_warp

# 2. Start chisel client in the background.
echo "Forking chisel client to background..."
run_chisel &

# Wait a moment for the background process to establish the tunnel.
sleep 3



# 3. Configure X-UI Panel
cd /opt/x-ui/x-ui

echo "Configuring x-ui panel port..."
/opt/x-ui/x-ui/x-ui setting -port 2023

echo "Configuring x-ui web base path..."
/opt/x-ui/x-ui/x-ui setting -webBasePath /

echo "Resetting x-ui admin credentials..."
/opt/x-ui/x-ui/x-ui setting -username prog10 -password 04091968

# 4. Start X-UI Panel
echo "Starting x-ui panel..."
cd /opt/x-ui/x-ui
./x-ui