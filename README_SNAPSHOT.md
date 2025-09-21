# How to Run the X-UI Snapshot

This guide explains how to run the `x-ui` container from the provided snapshot (`x-ui-snapshot.tar`). This image contains all necessary fixes and tools.

## Prerequisites

1.  **Docker:** Docker must be installed on the new machine.
2.  **Configuration Files:** You need the `x-ui-configs` directory (containing `x-ui.db` and `config.json`) from this repository.
3.  **SSH Keys:** You need your `.ssh` directory with the correct keys for GitHub access, placed in your home directory (`~/.ssh`).

## Step 1: Load the Image

Load the Docker image from the `.tar` file. Make sure you are in the same directory as `x-ui-snapshot.tar`.

```bash
docker load -i x-ui-snapshot.tar
```
This will load the `x-ui-snapshot:latest` image into your local Docker daemon.

## Step 2: Prepare Directories

Place the `x-ui-configs` directory (from this repository) in a known location. The command below assumes it's in your current working directory.

## Step 3: Run the Container

Execute the following command to start the container. This command mounts the necessary directories for configuration, git sync, and SSH authentication.

```bash
docker run -d --name x-ui-container --restart=unless-stopped --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
-v "$(pwd)/x-ui-configs":/etc/x-ui \
-v "$(pwd)":/git \
-v "$HOME/.ssh":"/root/.ssh:ro" \
x-ui-snapshot:latest
```
**Note:** The command above assumes your current directory (`pwd`) is the root of this git repository.

Your `x-ui` instance should now be running and accessible according to the project's architecture.

