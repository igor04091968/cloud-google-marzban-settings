# Reverse Tunnel Docker Container with Chisel, iperf3, and WARP

## Automated Installation

A convenience script `install_tunnel.sh` is provided in the `scripts/` directory of this repository to automate the setup of this container.

**Usage:**

1.  **Clone the repository** (if you haven't already):
    ```bash
    git clone https://github.com/igor04091968/cloud-google-marzban-settings.git
    ```
2.  **Navigate to the repository root:**
    ```bash
    cd cloud-google-marzban-settings
    ```
3.  **Ensure your `id_rsa_vds1` private key is in `~/.ssh/`** on the machine where you are running the script.
4.  **Run the installer script:**
    ```bash
    sudo scripts/install_tunnel.sh
    ```
    The script will check for Docker and Git, clone/update the repository, build the Docker image, and run the container. It will prompt you if Docker is not installed or if your user is not in the `docker` group.

---

## Container Services and Tunneling

This container establishes a persistent tunnel to a remote server (`vds1.iri1968.dpdns.org`). All outgoing traffic from this container is routed through the Cloudflare WARP network.

### Services running inside the container:

- **SSH Server:** Listens on port `22` (for internal container access).
- **iperf3 Server:** Listens on port `8088` (for speed tests).
- **Privoxy (HTTP Proxy):** Listens on port `8888`. This proxy uses an upstream SOCKS5 proxy provided by `chisel client`.
- **Chisel Client:** Connects to `vds1` (on port `21`) and establishes a SOCKS5 proxy locally within the container (default `localhost:1080`).

### Exposed Services on `vds1` (via main SSH tunnel):

When this container is running, the following services are exposed on the remote VDS (`vds1.iri1968.dpdns.org`) via the main **SSH tunnel**:

- **Reverse SSH Access:** `localhost:2222` on the VDS is tunneled to the container's internal SSH server.
- **iperf3 Server:** `localhost:8088` on the VDS is tunneled to the container's internal `iperf3` server.

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

### Speed Test (via main SSH tunnel)

Test the main SSH tunnel speed at any time by logging into your VDS and running:

```bash
iperf3 -c localhost -p 8088
```

### HTTP Proxy (for laptop traffic)

The HTTP proxy (`Privoxy`) inside the container listens on port `8888`. To access it from your laptop, you need to use the `chisel client` on the VDS to create a tunnel from the VDS to the proxy inside the container.

**This command must be run on the VDS:**

```bash
# This command connects to the chisel server (exposed on vds1:9001 via the SSH tunnel)
# and creates a new tunnel: vds1:8888 -> container:8888
chisel client localhost:21 8888:localhost:8888
```
*Note: This `chisel client` command will run in the foreground. You may want to run it in a `screen` or `tmux` session to keep it alive.*

Once the chisel client is running, you can use the HTTP proxy on `vds1` at `localhost:8888`.

**To route your laptop's traffic through this proxy:**

1.  **Create a local tunnel from your laptop to `vds1`:**
    ```bash
    ssh -L 8888:localhost:8888 root@vds1.iri1968.dpdns.org
    ```
    This will make the HTTP proxy available on `localhost:8888` on your laptop.
2.  **Configure your laptop's browser/system proxy settings:**
    *   **Type:** HTTP
    *   **Address:** `127.0.0.1` (or `localhost`)
    *   **Port:** `8888`