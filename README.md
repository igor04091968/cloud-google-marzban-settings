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

---

## Обход ограничений Cloud Shell для SSH-туннелей

При работе в Google Cloud Shell стандартные утилиты для создания туннелей, такие как `chisel`, могут не работать из-за ограничений безопасности "песочницы". В частности, они не могут открыть локальный порт для прослушивания.

Эта проблема была решена с помощью стандартной утилиты `ssh`.

### Проблема

Попытки создать локальный проброс порта (`-L`) с помощью `ssh` могут завершаться ошибкой привязки к IPv6-адресу:
```
bind [::1]:5201: Cannot assign requested address
```

### Решение

Ключевым решением является использование флага `-4`, который принудительно заставляет `ssh` работать через IPv4.

**Рабочая команда для создания туннеля:**
```bash
# -4: Использовать только IPv4
# -f: Уйти в фон после аутентификации
# -N: Не выполнять удаленных команд (только проброс портов)
# -L: <локальный_порт>:<цель_на_сервере>:<порт_на_сервере>
ssh -4 -f -N -L 5201:localhost:5201 root@vds1.iri1968.dpdns.org
```

После выполнения этой команды `ssh` успешно создает фоновый процесс, который слушает указанный локальный порт и пробрасывает трафик через туннель. Это позволяет использовать `iperf`, `scp` и другие утилиты через созданный канал.

---

## Docker-based Dual SSH & iperf3 Tunnel

This section describes the method for creating a persistent, multi-port reverse SSH tunnel using a Docker container. The container runs its own SSH server and an iperf3 server, and establishes a reverse tunnel to a remote VDS, forwarding ports for both services.

### 1. Overview

-   **Local Environment:** A Docker container running on a host (e.g., Google Cloud Shell).
-   **Container Services:**
    -   `sshd`: To allow SSH access *into* the container.
    -   `iperf3 -s`: To run a speed test server.
-   **Remote Server:** A VDS (`vds1.iri1968.dpdns.org`) that acts as the tunnel endpoint.
-   **Tunnel:** A reverse SSH tunnel initiated from the container to the VDS.
    -   Forwards VDS port `2224` to the container's `sshd` on port `22`.
    -   Forwards VDS port `5201` to the container's `iperf3` server on port `5201`.

### 2. Deployment Sequence

**Step 1: Build the Docker Image**

All source files are located in the `tunnel_docker/` directory. Build the image from the project root:

```bash
docker build -t tunnel_final:v4 -f /home/frad84435/cloud-google-marzban-settings/tunnel_docker/Dockerfile /home/frad84435/cloud-google-marzban-settings/tunnel_docker
```

**Step 2: Run the Container**

Run the container in detached mode, mounting the VDS private key. This key is used by the container to authenticate with the VDS.

```bash
docker run --name tunnel_cloud_instance -d -v /home/frad84435/.ssh/id_rsa_vds1:/root/.ssh/id_rsa_vds1:ro tunnel_final:v4
```

### 3. Verification and Usage

All verification commands are run from your local machine, but execute commands on `vds1`.

**Step 1: Verify Tunnel Ports on VDS**

Check that the `sshd` process on the VDS is listening on both forwarded ports.

```bash
ssh -i /home/frad84435/.ssh/id_rsa_vds1 root@vds1.iri1968.dpdns.org "ss -tlpn | grep -E '2224|5201'"
```
*Expected Output: You should see lines for both port `2224` and `5201` being listened to by the same `sshd` process.*

**Step 2: Test SSH Access to Container**

SSH from the VDS into the container to confirm the first tunnel works.

```bash
ssh -i /home/frad84435/.ssh/id_rsa_vds1 root@vds1.iri1968.dpdns.org 'ssh -p 2224 -o "StrictHostKeyChecking=no" root@localhost "hostname"'
```
*Expected Output: The container's ID/hostname.*

**Step 3: Test iperf3 Speed**

Run the iperf3 client on the VDS to connect to the iperf3 server in the container.

```bash
ssh -i /home/frad84435/.ssh/id_rsa_vds1 root@vds1.iri1968.dpdns.org "iperf3 -c localhost -p 5201"
```
*Expected Output: A standard iperf3 speed test result.*

### 4. Troubleshooting Summary

-   **`port forwarding failed` in container logs:** A process on the VDS is already using the port. Find it with `ss -tlpn` and `kill` it.
-   **`Permission denied (publickey)` when connecting:** The public key in the `Dockerfile` does not match the private key used for connection. Update the `Dockerfile` with the output of `ssh-keygen -y` for the correct private key.
