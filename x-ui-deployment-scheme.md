# X-UI Deployment Scheme

This document outlines the architecture for deploying x-ui with a reverse tunnel.

## Architecture v1 (Local Host Mount)

1.  **X-UI Container**: A Docker container running the 3x-ui panel on a local machine.
2.  **Chisel Client**: Runs inside the X-UI container, initiating a connection to the chisel server.
3.  **Chisel Server**: Runs on `vds1.iri1968.dpdns.org`, accepting client connections.
4.  **Reverse Tunnel**: The chisel client establishes a reverse tunnel, forwarding a port from `vds1` to the local x-ui process within the container.
5.  **Nginx**: Runs on `vds1`, handling HTTPS and proxying requests to the local port opened by the chisel server.

## Architecture v2 (Portable Container) - CURRENT PLAN

This revised plan creates a self-contained, portable Docker image that does not depend on the host machine's file system. All necessary components are built directly into the image.

**Build Process Modifications (`Dockerfile`):**

1.  **Inject SSH Key**: Instead of mounting the host's `.ssh` directory, the specific deploy key for GitHub (e.g., `id_rsa_huggingface`) will be securely copied into the image's `/root/.ssh/` directory during the build.
2.  **Set Key Permissions**: The permissions for the SSH key inside the image will be set to `600` (`chmod 600 /root/.ssh/id_rsa`). This is mandatory for SSH to use the key.
3.  **Authorize GitHub Host**: The GitHub host key will be pre-scanned and added to the image's `known_hosts` file (`ssh-keyscan github.com >> /root/.ssh/known_hosts`). This prevents interactive prompts on the first connection.
4.  **Clone Repository**: The project repository (`cloud-google-marzban-settings`) will be cloned from GitHub into the `/git` directory inside the image during the build process. This will use the injected SSH key for authentication.

## Key Requirement (Discovered during local test setup)

- **Port Mismatch Correction**: The `start.sh` script for the container must have matching ports.
  - The `x-ui` panel is configured to run on port **2023** (`x-ui setting -port 2023`).
  - Therefore, the `chisel` client command **must** forward to this same port.
  - **Incorrect:** `chisel ... R:8001:127.0.0.1:2053`
  - **Correct:** `chisel ... R:8000:127.0.0.1:2023`

## Build Failures & Debugging

1.  **`git clone` via SSH Failure**: The build process failed with a `Permission denied (publickey)` error when using the `id_rsa_huggingface` key. The hypothesis is that this key does not have permissions for the `cloud-google-marzban-settings` repository.
2.  **`git-lfs` Failure**: Switching to the main `id_rsa` key for SSH clone also failed. The build process then failed during the `git-lfs` checkout stage with a `Bad credentials` error. This indicates that LFS requires separate HTTPS authentication.
3.  **`git-lfs` PAT Failure**: A subsequent attempt using a GitHub Personal Access Token (PAT) via an HTTPS clone URL also failed with `Resource not accessible by personal access token`. This indicates the PAT provided was likely a "fine-grained" token that did not have explicit access granted to this repository.

**Current Blocker:** We are currently blocked on the Docker build, pending the creation of a **"classic"** GitHub PAT with full `repo` scope.