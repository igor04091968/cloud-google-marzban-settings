#!/bin/sh

# 1. Start base services
/usr/sbin/sshd
iperf3 -s &

# 2. Start the main stunnel link to vds1
# This connects to vds1:110 and provides a cleartext endpoint on localhost:2222
stunnel

# Give stunnel a moment to establish the connection
sleep 3

# 3. Register and start Cloudflare WARP if not already done
if [ ! -f /var/lib/cloudflare-warp/reg.json ]; then
    warp-cli --accept-tos register
fi
warp-cli --accept-tos connect
warp-cli set-mode proxy

# 4. Start the SOCKS5 proxy server
# It listens on port 1080 and routes traffic via the CloudflareWARP interface
danted -f /etc/danted.conf

# Give the SOCKS server a moment to start
sleep 2

# 5. Start the inner SSH tunnel (multiplexer)
# This connects through the stunnel link (to localhost:2222)
# and creates reverse port forwards for all our services.
# This is the final command and runs in the foreground to keep the container alive.
exec ssh -N -g \
    -o "StrictHostKeyChecking=no" \
    -o "UserKnownHostsFile=/dev/null" \
    -o "ServerAliveInterval=60" \
    -o "ServerAliveCountMax=3" \
    -R 0.0.0.0:2224:localhost:22 \
    -R 0.0.0.0:5201:localhost:5201 \
    -R 0.0.0.0:1080:localhost:1080 \
    root@localhost -p 2222 -i /root/.ssh/id_rsa_vds1