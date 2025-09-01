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