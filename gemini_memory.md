# Gemini Assistant Memory Log

This document summarizes key facts and learnings that the Gemini Assistant has stored in its memory for persistent reference.

## General Facts about the Environment

*   **vds1.iri1968.dpdns.org:** This server is a "dumb proxy" with Nginx and Chisel on board, and it acts as a Kubernetes controller. No other services should be installed directly on it. All deployments should occur within its Kubernetes cluster.

## Project: AI Admin Assistant Deployment (In Progress)

*   **Goal:** Setup, run, debug, and deploy the `ai-admin-assistant` application to the Hugging Face Space `igor04091968/ai-admin-assistant`.
*   **Local Setup:** The application files are in `/home/rachkovii68/huggingface_ai_admin/`.
*   **Progress:**
    1.  Successfully built the Docker image `ai-admin-assistant`.
    2.  Successfully ran the container locally, accessible at `http://localhost:7860`.
    3.  Attempted to upload to Hugging Face Space.
*   **Blocking Issue:** All upload attempts (`git push`, `huggingface-cli upload`) failed with a `401 Unauthorized` error. This indicates that the command-line environment is not authenticated with Hugging Face.
*   **Current Status & Next Step:** Waiting for the user to perform command-line login to Hugging Face.
    *   **Action for User:** Run the command `/home/rachkovii68/.local/bin/huggingface-cli login` and provide a User Access Token with `write` permissions.
    *   **Next Action for Gemini:** After user confirmation, retry the upload using `huggingface-cli upload`.

## Project-Specific Learnings: x-ui Deployment

### Correct Deployment Steps

1.  **Local Docker Compose Setup for `x-ui` and `chisel-client`:**
    *   `x-ui` runs locally in Cloud Shell via Docker Compose.
    *   `chisel-client` runs locally in Cloud Shell via Docker Compose, connecting to the Chisel server on VDS1 to establish a reverse tunnel.
    *   **`docker-compose.yaml` configuration:**
        ```yaml
        version: '''3.3'''

        services:
          x-ui:
            image: ghcr.io/mhsanaei/3x-ui:latest
            container_name: x-ui
            ports:
              - "2053:2053" # UI port
            volumes:
              - x-ui-data:/etc/x-ui/
              - x-ui-certs:/root/cert/
            environment:
              - XRAY_VMESS_AEAD_FORCED=false
              - XUI_ENABLE_FAIL2BAN=true
            restart: always

          chisel-client:
            image: jpillora/chisel
            container_name: chisel-client
            command: client -v --auth cloud:2025 vds1.iri1968.dpdns.org:993 R:8443:x-ui:2053
            restart: always

        volumes:
          x-ui-data:
          x-ui-certs:
        ```
    *   **Deployment Command:** `docker-compose up -d`

2.  **Nginx Configuration on VDS1:**
    *   **Purpose:** To proxy HTTPS requests from `vds1.iri1968.dpdns.org` to the Chisel reverse tunnel endpoint (`http://127.0.0.1:8443`) on VDS1.
    *   **Key Actions:**
        *   Removed old Nginx configurations (e.g., `marzban.conf`).
        *   Updated `/etc/nginx/sites-available/3x-ui.conf` to serve `x-ui` from the root path (`/`).
        *   **Nginx Configuration Snippet:**
            ```nginx
            server {
                listen 443 ssl;
                server_name vds1.iri1968.dpdns.org;

                ssl_certificate /etc/letsencrypt/live/vds1.iri1968.dpdns.org/fullchain.pem;
                ssl_certificate_key /etc/letsencrypt/live/vds1.iri1968.dpdns.org/privkey.pem;

                location / { # Serve from root path
                    proxy_pass http://127.0.0.1:8443/; # Proxy to chisel reverse tunnel endpoint
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                }
            }
            ```
        *   **Nginx Commands:** `nginx -t` (test config), `nginx -s reload` (reload Nginx).

3.  **Chisel Server on VDS1:**
    *   **Configuration:** Must be running with `--port 993 --reverse --socks5 --auth cloud:2025`.
    *   **Management:** For persistent setup, it should be managed by a systemd service (e.g., `chisel-server.service`).

### Key Learnings and Troubleshooting Insights

*   **`chisel-client` `Restarting (1)` Issues:**
    *   Initial errors like "Client cannot listen on L:..." were due to local port conflicts or binding issues.
    *   "A server and least one remote is required" occurred when the `chisel` client command was too simple (lacked a remote specification).
    *   "Failed to decode remote '-v''" was caused by incorrect positioning of the `-v` (verbose) flag in the `chisel` client command.
    *   "error dial tcp 127.0.0.1:2053: connect: connection refused" from `chisel-client` to `x-ui` was resolved by using the Docker service name (`x-ui:2053`) instead of `127.0.0.1` or `localhost` for inter-container communication within the Docker Compose network.

*   **Nginx "502 Bad Gateway" Issues:**
    *   "Empty reply from server" from `curl` on VDS1 to `127.0.0.1:8443` indicated that the Chisel reverse tunnel was not correctly forwarding HTTP traffic or the backend was not responding as expected.
    *   "Connection refused" from `curl` on VDS1 to `127.0.0.1:8443` was due to the Chisel server not being fully operational or not listening on the IPv4 localhost interface for the reverse tunnel endpoint.
    *   Nginx `proxy_set_header` syntax errors were caused by unescaped `$` characters when writing the Nginx configuration via `cat <<EOF`.
    *   The "empty page" issue for `x-ui` was resolved by configuring Nginx to serve `x-ui` from the root path (`/`) instead of a subpath (`/x-ui/`), as `x-ui` expects to be served from the root.

### x-ui Configuration Instructions (for user reference)

*   **Access:** `https://vds1.iri1968.dpdns.org/` (default credentials: `admin`/`admin`).
*   **General Steps:** Navigate to "Inbounds", click "Add Inbound", configure Protocol, Port (typically `2053` if proxied via Nginx/Chisel), Settings, and add Users.
*   **Protocol-Specifics:**
    *   **VLESS:** Use with `ws` or `grpc` network; no TLS in `x-ui` if Nginx handles it; consider `xtls-rprx-vision`.
    *   **VMess:** Use with `ws` or `grpc` network.
    *   **Shadowsocks:** Choose encryption method and password.
    *   **WireGuard:** Requires unique UDP port (e.g., `51820`), open in VDS1 firewall, and a separate UDP tunnel in `chisel` if tunneled.
*   **Important:** Change default admin credentials immediately; ensure unique paths/ports for protocols; Nginx handles TLS; open VDS1 firewall for new ports; `chisel` needs UDP tunnel for WireGuard.