---
title: Marzban Kubernetes Deployment
emoji: 🚀
colorFrom: blue
colorTo: green
sdk: docker
pinned: false
---

# Marzban Deployment on Kubernetes with Chisel Tunnel

This project sets up a Marzban instance in a Kubernetes cluster and exposes it to a remote VDS using a chisel tunnel.

## 1. Prerequisites

- A Kubernetes cluster (e.g., Minikube).
- A remote VDS with root access.
- `kubectl` configured to connect to your Kubernetes cluster.
- `ssh` access to your VDS.

## 2. Setup Chisel Server on VDS

1.  SSH into your VDS as root.
2.  Run the following command to start the chisel server:
    ```bash
    nohup /usr/local/bin/chisel server --port 993 --reverse --socks5 --auth cloud:2025 > /dev/null 2>&1 &
    ```

## 3. Deploy Marzban and Chisel Client to Kubernetes

1.  Apply the Kubernetes manifests in the `kubernetes` directory:
    ```bash
    kubectl apply -f kubernetes/
    ```
2.  This will deploy:
    - Marzban controller and node.
    - A SOCKS5 proxy.
    - A chisel client that connects to your VDS and creates the following tunnels:
        - Marzban controller UI on VDS port `8443`.
        - Kubernetes API server on VDS port `8444`.
        - SOCKS5 proxy on VDS port `1080`.

## 4. Accessing Services

### Marzban UI

-   The Marzban UI is accessible on your VDS at `http://localhost:8443`.
-   You can access it from your local machine using an SSH tunnel:
    ```bash
    ssh -L 8443:localhost:8443 root@vds1.iri1968.dpdns.org
    ```
-   Then open `http://localhost:8443` in your browser.

### Kubernetes API Server

-   The Kubernetes API server is accessible on your VDS at `https://localhost:8444`.
-   The `vds_kube_config` directory contains a `kubeconfig` file that is pre-configured to use this tunnel.
-   You can use this `kubeconfig` file on your VDS to manage your cluster.

### SOCKS5 Proxy

-   A SOCKS5 proxy is running in the cluster and is accessible on your VDS at `localhost:1080`.
-   You can use this proxy to route traffic from your VDS through the Kubernetes cluster.

---

## VDS1 Server Setup for Hugging Face X-UI Tunnel

This section describes the server-side setup on `vds1.iri1968.dpdns.org` required to tunnel traffic to the X-UI application running on Hugging Face.

### 1. Chisel Server

The chisel server listens for incoming connections from the chisel client running in the Hugging Face container.

**Start command:**
```bash
# Kill any old server process first
pkill chisel

# Start the new server in the background
nohup chisel server --port 80 --reverse > /dev/null 2>&1 &
```

### 2. Socat Port Forwarding for Web UI

The X-UI web panel is exposed on `vds1` via a chisel reverse tunnel on port `8443`. The following `socat` command forwards traffic from the public-facing port `2096` to the tunnel endpoint.

**Start command:**
```bash
nohup socat TCP-LISTEN:2096,fork TCP:localhost:8443 > /dev/null 2>&1 &
```
*Note: Ensure `socat` is installed: `apt-get update && apt-get install -y socat`*

### 3. Firewall (iptables) Configuration

The following `iptables` rules are required to allow traffic to the public-facing ports.

**Commands to add rules:**
```bash
# Allow Web UI traffic
iptables -A INPUT -p tcp --dport 2096 -j ACCEPT

# Allow Proxy traffic
iptables -A INPUT -p tcp --dport 38652 -j ACCEPT
iptables -A INPUT -p tcp --dport 27081 -j ACCEPT
iptables -A INPUT -p tcp --dport 36955 -j ACCEPT
```

### 4. Making Firewall Rules Persistent

To ensure the firewall rules survive a reboot, they must be saved.

**Commands to save rules:**
```bash
# Install the persistence package
apt-get install -y iptables-persistent

# Save the current IPv4 rules
iptables-save > /etc/iptables/rules.v4
```
