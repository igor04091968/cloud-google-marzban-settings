# Firewall-Bypassing SSH Tunnel Client (socat version)

This directory contains the necessary files to build a Docker container that acts as a client for a sophisticated, firewall-bypassing SSH tunnel.

## The Problem

We need to establish a persistent SSH connection from a client (your laptop) that is inside a restrictive network zone. The firewall in this zone has two specific rules for outgoing traffic:

1.  The **destination port** must be a well-known service port (e.g., 110 for POP3).
2.  The **source port** of the connection must be a privileged port (less than 1024).

Standard SSH and `stunnel` clients cannot fulfill the second requirement.

## The Solution

This solution uses `socat` to create the TLS tunnel, as it allows forcing a specific source port.

### How it Works

1.  **Server (`vds1`):** A `stunnel` service on `vds1` listens on a standard port (e.g., **110** for POP3). It accepts TLS connections and forwards them to the real SSH server running on `vds1` (port 22).
2.  **Client (This Docker Container):**
    a.  An SSH server (`sshd`) is run inside the container so that the remote administrator (Gemini) can connect back to you.
    b.  `socat` starts and connects to `vds1` on port **110**. Crucially, it binds its own outgoing connection to a specific low-numbered source port (e.g., **109**), satisfying the firewall rule.
    c.  A final `ssh` command runs, connecting *through the local socat tunnel*. This `ssh` command establishes the **reverse tunnel**, opening up port `2222` on `vds1`, which allows Gemini to connect back to the `sshd` server in this container.

### Files

-   `Dockerfile`: Builds the container, installing `socat` and `openssh`.
-   `sshd_config`: A minimal configuration for the SSH server that runs inside the container.
-   `entrypoint.sh`: The main script that orchestrates the startup of `sshd`, `socat`, and the final reverse `ssh` tunnel.

### How to Use

1.  **Add your public keys:** Edit the `Dockerfile` and add the public keys for any users who should be allowed to SSH into this container (e.g., Gemini's keys).
2.  **Build the image:** From this directory, run:
    ```bash
    docker build -t firewall-tunnel-client .
    ```
3.  **Run the container:** This is the most critical step. You must mount your private key for `vds1` into the container, and you **must** give the container the `NET_BIND_SERVICE` capability so `socat` can use a privileged source port.

    ```bash
    docker run -d --restart=always \
      --name ssh-tunnel-client \
      -v /path/to/your/id_rsa_vds1:/root/.ssh/id_rsa_vds1:ro \
      --cap-add=NET_BIND_SERVICE \
      firewall-tunnel-client
    ```
    *(Replace `/path/to/your/id_rsa_vds1` with the actual path to your private key)*
