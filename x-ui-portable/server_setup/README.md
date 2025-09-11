# Server Setup

This script automates the setup of the server-side components for the x-ui tunnel.

## Prerequisites

1.  **Let's Encrypt Certificates:** This setup assumes that you have already generated Let's Encrypt certificates for your domain (`vds1.iri1968.dpdns.org` in the original setup) and they are located in `/etc/letsencrypt/live/your_domain/`.

2.  **Chisel and Nginx:** Chisel and Nginx must be installed on the server.

## Usage

1.  Copy the files from this directory to the server.
2.  Make the script executable: `chmod +x setup_server.sh`
3.  Run the script as root: `sudo ./setup_server.sh`
