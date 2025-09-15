# Help: Architecture of the Advanced Tunnel

This document describes the components, configurations, and data flow of the advanced tunneling solution.

## 1. Overview

The primary goal of this setup is to create a stable, secure, and multi-purpose connection between a sandboxed environment (like Google Cloud Shell or a Hugging Face Space, referred to as **cs**) and a publicly accessible Virtual Dedicated Server (**vds1**).

This is achieved by running a specialized Docker container within **cs** that initiates a persistent, reverse SSH tunnel to **vds1**.

## 2. Participating Hosts (Nodes)

There are three main components in this architecture:

1.  **Cloud Shell (cs) / Hugging Face Space**
    *   **Role**: The host environment where the Docker container runs.
    *   **Characteristics**: Can have a dynamic IP address, may have restricted inbound traffic.

2.  **Docker Container (tunnel-container)**
    *   **Role**: The core of the solution. It runs all the necessary software to establish and maintain the tunnels.
    *   **Runs On**: **cs**

3.  **VDS1 (vds1.iri1968.dpdns.org)**
    *   **Role**: The public-facing anchor point and remote server.
    *   **Characteristics**: Has a static IP address and open ports. It runs a service on port `143` that `stunnel` from the container connects to.

## 3. Container Configuration

The container is built from the `Dockerfile` and runs the following key software:

*   **`stunnel`**: Runs as a client. It connects to **vds1** on port `143` and creates a secure TLS tunnel, which is then exposed locally within the container on `127.0.0.1:2222`.
*   **`ssh` (client)**: This is the final and most critical piece. It connects to the local `stunnel` endpoint (`127.0.0.1:2222`) and authenticates on **vds1** as the `root` user. Once connected, it establishes several **reverse tunnels** (`-R`) back to **vds1**.
*   **`iperf3`**: A network performance testing tool.

## 4. Data Flow and Relationships

The connection is established in a "reverse" direction, from the inside (**cs**) to the outside (**vds1**).

```mermaid
graph TD
    subgraph "Cloud Shell (cs) / Hugging Face Space"
        A[Container: ssh client] -- "connects to" --> B[local stunnel endpoint: 127.0.0.1:2222]
    end

    subgraph "Internet"
        C(vds1.iri1968.dpdns.org)
    end

    B -- "TLS Tunnel" --> C[:143]
    C -- "Reverse Tunnels Established" --> A

```

**Step-by-step flow:**

1.  The `entrypoint.sh` script starts inside the container.
2.  `stunnel` connects to `vds1:143`, creating a secure link. This link is presented as `localhost:2222` inside the container.
3.  The `ssh` client inside the container connects to `localhost:2222`, using the private key for **vds1** (`id_rsa_vds1`) and authenticating as `root`. The traffic is routed through the `stunnel` tunnel to the `stunnel` server on `vds1`, which in turn forwards it to the main `sshd` server on `vds1`.
4.  Once this SSH session is active, the `-R` flags create the pathways back from `vds1` to the container. For example, `-R 0.0.0.0:2222:localhost:22` on `vds1` would forward traffic to port 22 inside the container's network.

This architecture effectively makes services running inside the sandboxed **cs** container accessible from the public **vds1** server.

## 5. Hugging Face Deployment

To deploy this container on a Hugging Face Space, you must configure one **Space Secret**:

*   **Name**: `ID_RSA_VDS1`
*   **Value**: The entire content of your private SSH key file (`id_rsa_vds1`), including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines.

The `entrypoint.sh` script will read this secret and create the necessary key file for the SSH connection to work.
