# Reverse Tunnel Docker Container with iperf3

This container establishes a persistent reverse SSH tunnel to a remote server, wrapping the connection in stunnel for obfuscation. It also includes an `iperf3` server for bandwidth testing.

## Services Exposed on the Remote VDS

When this container is running, the following services become available on the remote VDS (`vds1.iri1968.dpdns.org`):

- **Reverse SSH Access:** `localhost:2222` on the VDS is tunneled to the container's internal SSH server.
- **SOCKS5 Proxy:** `localhost:1080` on the VDS acts as a SOCKS5 proxy into the container's network.
- **iperf3 Server:** `localhost:8088` on the VDS is tunneled to the container's internal `iperf3` server for speed tests.

## Build

To build the container image, navigate to the `tunnel_docker` directory and run:

```bash
sudo docker build -t tunnel_iperf .
```

## Run

To run the container, you must provide the path to the private SSH key (`id_rsa_vds1`) that is authorized on the remote VDS.

```bash
# Stop and remove any old container
sudo docker stop tunnel_client || true
sudo docker rm tunnel_client || true

# Run the new container
# IMPORTANT: This container requires elevated privileges to manage network settings for WARP.
# IMPORTANT: Replace /path/to/your/key with the actual path to your id_rsa_vds1 file
sudo docker run -d --restart=unless-stopped --name tunnel_client \
    --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
    -v /path/to/your/key/id_rsa_vds1:/root/.ssh/id_rsa_vds1:ro \
    tunnel_iperf
```

## Usage Example: Speed Test

Once the container is running, you can test the tunnel speed at any time by logging into your VDS and running:

```bash
iperf3 -c localhost -p 8088
```
