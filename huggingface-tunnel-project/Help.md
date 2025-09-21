# Help: Architecture of the Advanced Tunnel

This document describes the components, configurations, and data flow of the advanced tunneling solution.

## 1. Overview

The primary goal of this setup is to create a stable, secure, and multi-purpose connection between a sandboxed environment (like Google Cloud Shell, referred to as **cs**) and a publicly accessible Virtual Dedicated Server (**vds1**).

This is achieved by running a specialized Docker container within **cs** that initiates a persistent, reverse SSH tunnel to **vds1**.

## 2. Participating Hosts (Nodes)

There are three main components in this architecture:

1.  **Cloud Shell (cs)**
    *   **Role**: The host environment where the Docker container runs.
    *   **Characteristics**: Can have a dynamic IP address, may have restricted inbound traffic.

2.  **Docker Container (tunnel-container)**
    *   **Role**: The core of the solution. It runs all the necessary software to establish and maintain the tunnels.
    *   **Runs On**: **cs**

3.  **VDS1 (vds1.iri1968.dpdns.org)**
    *   **Role**: The public-facing anchor point and remote server.
    *   **Characteristics**: Has a static IP address and open ports. It runs a service on port `993` that `stunnel` from the container connects to.

## 3. Container Configuration

The container is built from the `Dockerfile` and runs the following key software:

*   **`openssh` (sshd)**: Runs an SSH server to allow access into the container itself.
*   **`stunnel`**: Runs as a client. It connects to **vds1** on port `993` and creates a secure TLS tunnel, which is then exposed locally within the container on `127.0.0.1:2222`.
*   **`iperf3`**: A network performance testing tool.
*   **`ssh` (client)**: This is the final and most critical piece. It performs two main functions:
    1.  It connects to the local SSH server (`sshd`) *through* the `stunnel` tunnel (`ssh root@127.0.0.1 -p 2222`).
    2.  Once connected, it establishes several **reverse tunnels** (`-R`) back to **vds1**.

## 4. Data Flow and Relationships

The connection is established in a "reverse" direction, from the inside (**cs**) to the outside (**vds1**).

```mermaid
graph TD
    subgraph "Cloud Shell (cs) / Hugging Face Space"
        A[Container: tunnel-container]
    end

    subgraph "Internet"
        B(vds1.iri1968.dpdns.org)
    end

    A -- 1. stunnel client connects --> B[:993]
    A -- "2. ssh client connects to self via stunnel" --> A
    B -- "3. Reverse Tunnels Established" --> A

```

**Step-by-step flow:**

1.  The `entrypoint.sh` script starts inside the container.
2.  `stunnel` connects to `vds1:993`, creating a secure link. This link is presented as `localhost:2222` inside the container.
3.  The `ssh` client inside the container connects to `localhost:2222`, using the private key for **vds1** (`id_rsa_vds1`). The traffic is routed through the `stunnel` tunnel to the SSH server (`sshd`) running in the *same* container.
4.  Once this SSH session is active, the `-R` flags create the following pathways:
    *   Any traffic sent to `localhost:1080` on **vds1** is forwarded to the container.
    *   Any traffic sent to `localhost:5201` on **vds1** is forwarded to the container (used for the `iperf3` test).
    *   Any traffic sent to `localhost:2222` on **vds1** is forwarded to the container's SSH server on port 22.

This architecture effectively makes services running inside the sandboxed **cs** container accessible from the public **vds1** server.

## 5. Hugging Face Deployment

To deploy this container on a Hugging Face Space, you must configure one **Space Secret**:

*   **Name**: `ID_RSA_VDS1`
*   **Value**: The entire content of your private SSH key file (`id_rsa_vds1`), including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines.

The `entrypoint.sh` script will read this secret and create the necessary key file for the SSH connection to work.