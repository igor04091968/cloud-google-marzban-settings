# X-UI Deployment Scheme

This document outlines the architecture for deploying and accessing the X-UI web interface, leveraging Nginx for secure HTTPS access and Chisel for tunneling.

## Components:

1.  **X-UI Docker Container:**
    *   Runs the X-UI application, listening on port `2053`.
    *   Includes a `chisel` client that establishes a reverse tunnel.

2.  **Chisel Client (inside Docker Container):**
    *   Connects to `vds1.iri1968.dpdns.org` on port `80`.
    *   Establishes a reverse tunnel: `R:8443:localhost:2053`. This means any traffic sent to `localhost:8443` on `vds1.iri1968.dpdns.org` will be forwarded to `localhost:2053` inside the Docker container (where X-UI is running).

3.  **Nginx on `vds1.iri1968.dpdns.org`:**
    *   **HTTPS Listener (Port 443):**
        *   Listens for secure HTTPS traffic on `vds1.iri1968.dpdns.org`.
        *   Uses Let's Encrypt SSL certificates for secure communication.
        *   Proxies all incoming requests to `http://localhost:8443` on the `vds1` server.
        *   Includes WebSocket support headers (`Upgrade` and `Connection: upgrade`) for proper X-UI panel and proxy traffic handling.
    *   **HTTP Listener (Port 80):**
        *   Listens for insecure HTTP traffic on `vds1.iri1968.dpdns.org`.
        *   Redirects all HTTP traffic to HTTPS (`https://$host$request_uri;`).

## Access Flow:

1.  **User Access (Browser):**
    *   The user opens their web browser and navigates to `https://vds1.iri1968.dpdns.org`.

2.  **Nginx Processing (on `vds1.iri1968.dpdns.org`):**
    *   Nginx receives the HTTPS request on port `443`.
    *   It decrypts the SSL traffic using the configured certificates.
    *   Nginx then proxies this request internally to `http://localhost:8443` on the `vds1` server.

3.  **Chisel Server Processing (on `vds1.iri1968.dpdns.org`):**
    *   The `chisel` server (which is configured to listen on port `8443` due to the reverse tunnel initiated by the client in the Docker container) receives the request from Nginx.
    *   The `chisel` server forwards this request through the established `chisel` tunnel back to the `chisel` client running inside the Docker container.

4.  **Chisel Client & X-UI (inside Docker Container):**
    *   The `chisel` client inside the Docker container receives the request from the `chisel` server.
    *   It then forwards this request to `localhost:2053` within its own container, where the X-UI web interface is actively listening.
    *   X-UI processes the request and sends the response back through the same tunnel in reverse.

## Summary of Access Points:

*   **Primary Access (Recommended):** `https://vds1.iri1968.dpdns.org` (secure, external access via Nginx and Chisel tunnel).
*   **Direct Container Access (Local Only):** `http://localhost:2053` (if the container's port 2053 is mapped to the host's 2053, for local testing/development).

This setup ensures secure, encrypted communication from the user's browser to the Nginx server, and then leverages the `chisel` tunnel for secure and reliable internal communication to the X-UI application, even if the X-UI container is behind a NAT or firewall.