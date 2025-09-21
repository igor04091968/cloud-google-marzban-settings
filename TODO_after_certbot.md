# TODO for Gemini after user completes certbot

**User has taken over to perform the interactive `certbot` DNS-01 challenge.**

When the session resumes, the following steps are required:

1.  **Verify new certificates:** Check that the Let's Encrypt certificate files exist in `/etc/letsencrypt/live/vds1.iri1968.dpdns.org/`. The key files are `fullchain.pem` and `privkey.pem`.

2.  **Update `chisel-server` systemd service:** Modify the `/etc/systemd/system/chisel-server.service` file. The `ExecStart` command needs to be updated to point to the new Let's Encrypt certificate and key.
    *   **Old path:** `/etc/chisel/cert.pem` & `/etc/chisel/key.pem`
    *   **New path:** `/etc/letsencrypt/live/vds1.iri1968.dpdns.org/fullchain.pem` & `/etc/letsencrypt/live/vds1.iri1968.dpdns.org/privkey.pem`

3.  **Reload and Restart:** Run `systemctl daemon-reload` and `systemctl restart chisel-server.service`.

4.  **Verify:** Check `systemctl status chisel-server.service` to ensure it started correctly with the new certificates.

5.  **Inform User:** Let the user know the server is ready and that the client command on Hugging Face should work without any special flags (no `--insecure`). The final client command should be: `/usr/local/bin/chisel client -v --auth "cloud:2025" https://vds1.iri1968.dpdns.org:80 R:8000:127.0.0.1:2053`
