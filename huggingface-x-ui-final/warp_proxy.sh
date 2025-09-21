#!/bin/bash
# Based on the entrypoint from Mon-ius/Docker-Warp-Socks v5

set -e
sleep 3

# Get WARP configuration
RESPONSE=$(curl -fsSL bit.ly/create-cloudflare-warp | sh -s)

# Extract variables
CF_CLIENT_ID=$(echo "$RESPONSE" | grep -oP '(?<=CLIENT_ID = ).*$')
CF_PRIVATE_KEY=$(echo "$RESPONSE" | grep -oP '(?<=PRIVATE_KEY = ).*$')
CF_ADDR_V4=$(echo "$RESPONSE" | grep -oP '(?<=V4 = ).*$')
CF_ADDR_V6=$(echo "$RESPONSE" | grep -oP '(?<=V6 = ).*$')

# Generate sing-box config
cat > /tmp/sing-box-config.json <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "socks",
      "tag": "socks-in",
      "listen": "0.0.0.0",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "wireguard",
      "tag": "warp-out",
      "server": "engage.cloudflareclient.com",
      "server_port": 2408,
      "local_address": [
        "${CF_ADDR_V4}/32",
        "${CF_ADDR_V6}/128"
      ],
      "private_key": "${CF_PRIVATE_KEY}",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [${reserved_bytes}],
      "mtu": 1280
    }
  ]
}
EOF

# Replace reserved_bytes placeholder
# od -An -t u1 formats the bytes as unsigned decimal integers
reserved_bytes=$(echo "$CF_CLIENT_ID" | base64 -d | od -An -t u1 | awk 
'{print $1", "$2", "$3}')
sed -i "s/\[${reserved_bytes}\]/\[${reserved_bytes}\]/" /tmp/sing-box-config.json


echo "Starting sing-box WARP proxy..."
exec /usr/local/bin/sing-box run -c /tmp/sing-box-config.json