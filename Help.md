# Final Working Configuration

This repository contains the final, working configuration for the x-ui container project.

## Key Components:

- **Dockerfile**: The recipe for the main Docker image is located in `/huggingface-x-ui-final/Dockerfile`. This image includes `x-ui`, `chisel`, `wireproxy` for WARP, and `cron` for backups.
- **Configuration Volume**: The persistent configuration for x-ui is stored in `/x-ui-configs/`. This directory is mounted into the container at `/etc/x-ui`.
- **Sync Script**: The automatic backup of the configuration to this repository is handled by `/huggingface-x-ui-final/sync.sh`, which is executed by a cron job defined in `/huggingface-x-ui-final/crontab`.

## How to Run

1. Clone this repository.
2. Ensure `git-lfs` is installed and run `git lfs pull`.
3. Unpack `huggingface-x-ui-final-backup.tar.gz` and `x-ui-config.tar.gz` as described in `INSTRUCTIONS_FOR_RESTORE.md`.
4. Build the image: `docker build -t <image_name> ./huggingface-x-ui-final/`
5. Run the container with the correct volume mounts:
   ```bash
   docker run -d --name <container_name> --restart=unless-stopped --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -v "$(pwd)/x-ui-configs":/etc/x-ui -v "$(pwd)":/git -v "$HOME/.ssh":"/root/.ssh:ro" <image_name>
   ```
