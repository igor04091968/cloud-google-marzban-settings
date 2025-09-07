# Gemini SSHD Container

This container provides a secure and isolated SSH server within the Gemini Cloud Shell environment, allowing the user to connect for administrative or debugging purposes.

## How it Works

The setup consists of three main components:

1.  **The SSHD Container (Gemini's Side):** A Docker container running a clean, minimal SSH server. It is built from the provided `Dockerfile`.
2.  **The Reverse SSH Tunnel (Gemini's Side):** An SSH process running on the Gemini Cloud Shell host that connects to the `vds1` server and creates a reverse tunnel. This tunnel forwards a port from `vds1` to the SSHD container.
3.  **The VDS1 Server (Bridge):** The central server acts as a bridge. It listens on a public port (`2223`) and forwards all traffic through the tunnel to the Gemini environment.

## Deployment and Usage

### 1. Build the Docker Image (Gemini's Side)

Navigate to this directory and run the build command:

```bash
docker build -t gemini-sshd .
```

### 2. Run the Container and Tunnel (Gemini's Side)

First, run the container:

```bash
docker run -d -p 127.0.0.1:2224:22 --name sshd-container gemini-sshd
```

Next, establish the reverse tunnel to `vds1`. **Note:** The path to the private key for `vds1` may need to be adjusted.

```bash
ssh -N -f -R 2223:localhost:2224 -i /path/to/your/id_rsa_vds1 -o "StrictHostKeyChecking=no" root@vds1.iri1968.dpdns.org
```

### 3. Connect to Gemini (User's Side)

First, SSH into the `vds1` server as `root`.

```bash
ssh root@vds1.iri1968.dpdns.org
```

From `vds1`, connect to the tunnel endpoint. **Note:** This requires the private key `id_ed25519_gemini` to be present in `/root/.ssh/` on `vds1`.

```bash
ssh -p 2223 -i /root/.ssh/id_ed25519_gemini igor04091968@localhost
```

You will be connected to the SSH server inside the Gemini environment.
