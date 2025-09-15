# Hugging Face X-UI Deployment Log

This document summarizes the attempts to deploy the X-UI Docker image to Hugging Face Space `rachkovii68/x-ui`, including encountered issues and debugging steps.

## Initial Setup and Goals:
*   **Goal:** Deploy a Dockerized X-UI instance to Hugging Face Spaces.
*   **Architecture:** X-UI container runs a `chisel` client to establish a reverse tunnel to `vds1.iri1968.dpdns.org` (port 80 for client connection, 8443 for reverse tunnel to X-UI's 2053). Nginx on `vds1` handles HTTPS and proxies to the `chisel` tunnel.
*   **Local Files:** `Dockerfile` and `start.sh` were prepared for the deployment.

## Deployment Attempts and Issues:

### 1. `README.md` Configuration Errors (`CONFIG_ERROR`)
*   **Issue:** The Hugging Face Space consistently reported "Missing configuration in README" (`CONFIG_ERROR` stage).
*   **Debugging Steps:**
    *   Attempted various `README.md` YAML front matter formats, including:
        *   Adding `app_port: 2053`.
        *   Removing `sdk_version`.
        *   Changing `app_file` to `Dockerfile`.
        *   Reverting to the exact template provided by Hugging Face.
        *   Using a single-line YAML format (inspired by a working `static` SDK example).
    *   **Conclusion:** Despite numerous attempts and variations, the `CONFIG_ERROR` persisted. This suggests the error message might be a red herring, or there's an undocumented, very specific `README.md` requirement for this Space, or the Space itself is problematic.

### 2. Container Runtime Errors (Observed in Logs)
Even when the `CONFIG_ERROR` was present on the UI, logs indicated the container was attempting to start, revealing further issues:

*   **Error 1: `/bin/bash: c: No such file or directory`**
    *   **Cause:** Typo in `ENTRYPOINT ["/bin/bash", "c", "/usr/local/bin/start.sh"]`. The second argument should be `"-c"`.
    *   **Resolution:** Corrected `ENTRYPOINT` to `ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/start.sh"]`.

*   **Error 2: `Failure in running xray-core process: Failed to write configuration file: open bin/config.json: permission denied`**
    *   **Cause:** X-UI's `xray-core` component attempts to write `config.json` to its installation directory (`/usr/local/x-ui/bin/`), but Hugging Face Spaces have a read-only filesystem by default.
    *   **Debugging Steps:**
        *   Attempted `RUN chmod -R 777 /usr/local/x-ui/` in Dockerfile (ineffective due to read-only filesystem).
        *   Attempted to modify `start.sh` to `cd /data/x-ui` and `export XUI_DB_FOLDER=/data/x-ui` (failed with `mkdir: cannot create directory '/data': Permission denied`).
    *   **Conclusion:** The `/data` directory, despite Hugging Face documentation suggesting it for persistent storage, was not writable in the free tier environment. This indicates that writing configuration files at runtime is a significant challenge in the free Hugging Face Spaces environment. If `xray-core` *must* write its config, this deployment is not feasible without a paid persistent storage upgrade or a custom `x-ui` build that doesn't require runtime config writing.

*   **Error 3: `client: Connection error: server: Server cannot listen on R:8443=>localhost:2053`**
    *   **Cause:** The `chisel` server on `vds1.iri1968.dpdns.org` is unable to establish the reverse tunnel on port `8443`. This is an external issue to the Hugging Face Space itself. It could be due to port `8443` being in use, firewall rules, or `chisel` server configuration on `vds1`.
    *   **Status:** This issue remains external and requires debugging on `vds1.iri1968.dpdns.org`.

## Current Status of Hugging Face Space (`rachkovii68/x-ui`):
*   The Space is currently in `APP_STARTING` stage (or similar, indicating it's trying to run).
*   The `README.md` configuration error is no longer explicitly reported as the primary issue in the `runtime` stage.
*   The `start.sh` script has been updated to include a command to reset x-ui admin credentials to `admin`/`admin` upon startup.

## Final Conclusion on Hugging Face Deployment:
Due to the persistent `CONFIG_ERROR` (despite `README.md` fixes) and the fundamental `permission denied` issues related to the read-only filesystem in the free tier of Hugging Face Spaces, reliable deployment of X-UI (which requires writing configuration at runtime) to this specific Space is not feasible without further investigation into Hugging Face's environment limitations or a paid persistent storage upgrade.

## Working Files Saved Locally:
The latest working versions of `Dockerfile` and `start.sh` (which were pushed to the Hugging Face Space) have been saved to your local `cloud-google-marzban-settings` directory.

## GitHub Synchronization Issue:
I am unable to push these local changes to your GitHub repository (`git@github.com:igor04091968/cloud-google-marzban-settings.git`) due to a `git-lfs` issue in this environment. You may need to manually push these changes from your local machine if you wish to update the GitHub repository.

**Login for X-UI (if it starts successfully):**
*   **Username:** `admin`
*   **Password:** `admin`
(Please change these credentials immediately via the X-UI web interface after successful login.)
