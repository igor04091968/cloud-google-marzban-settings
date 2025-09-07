# Reverse Tunnel Docker Container with Chisel, iperf3, and WARP

This container establishes a persistent reverse SSH tunnel to a remote server, wrapping the connection in stunnel for obfuscation. All outgoing traffic from this container is routed through the Cloudflare WARP network.

It includes an `iperf3` server for bandwidth testing and a `chisel` server to bypass restrictive SSH server configurations for port forwarding.

## Primary Services Exposed via SSH Tunnel

When this container is running, the following services are exposed on the remote VDS (`vds1.iri1968.dpdns.org`) via the main **SSH tunnel**:

- **Reverse SSH Access:** `localhost:2222` on the VDS is tunneled to the container's internal SSH server.
- **iperf3 Server:** `localhost:8088` on the VDS is tunneled to the container's internal `iperf3` server.
- **Chisel Server:** `localhost:9001` on the VDS is tunneled to the container's internal `chisel` server. This is the entry point for creating more flexible sub-tunnels.

## Build

To build the container image, navigate to the `tunnel_docker` directory and run:

```bash
sudo docker build -t tunnel_final .
```

## Run

To run the container, you must provide the path to the private SSH key (`id_rsa_vds1`) that is authorized on the remote VDS.

```bash
# Stop and remove any old container
sudo docker stop tunnel_cloud_instance || true
sudo docker rm tunnel_cloud_instance || true

# Run the new container
# IMPORTANT: This container requires elevated privileges to manage network settings for WARP.
# The command assumes the private key 'id_rsa_vds1' is located in /root/.ssh/ on the host machine.
sudo docker run -d --restart=unless-stopped --name tunnel_cloud_instance \
    --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
    -v /root/.ssh/id_rsa_vds1:/root/.ssh/id_rsa_vds1:ro \
    tunnel_final
```

## Usage Examples

### Speed Test

Test the main SSH tunnel speed at any time by logging into your VDS and running:

```bash
iperf3 -c localhost -p 8088
```

### HTTP Proxy via Chisel

The HTTP proxy (`tinyproxy`) inside the container listens on port `8888`. To access it, you need to use the `chisel client` on the VDS to create a tunnel from the VDS to the proxy inside the container.

**This command must be run on the VDS:**

```bash
# This command connects to the chisel server (exposed on vds1:9001 via the SSH tunnel)
# and creates a new tunnel: vds1:8888 -> container:8888
chisel client localhost:9001 R:8888:localhost:8888
```
*Note: This `chisel client` command will run in the foreground. You may want to run it in a `screen` or `tmux` session to keep it alive.*

Once the chisel client is running, you can use the HTTP proxy on `vds1` at `localhost:8888`.

```