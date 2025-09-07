#!/bin/bash

# --- Configuration ---
REPO_URL="https://github.com/igor04091968/cloud-google-marzban-settings.git"
REPO_DIR="cloud-google-marzban-settings"
TUNNEL_DIR="tunnel_docker"
CONTAINER_NAME="tunnel_cloud_instance"
IMAGE_NAME="tunnel_final"
KEY_PATH_IN_HOST="$HOME/.ssh/id_rsa_vds1" # Assumes key is in user's home .ssh dir

# --- Functions ---
log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || { error "$1 is not installed. Please install it and try again."; }
}

install_docker() {
    log "Docker not found. Attempting to install Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh || error "Failed to install Docker."
    sudo usermod -aG docker "$USER" || error "Failed to add user to docker group. Please log out and log back in."
    log "Docker installed. Please log out and log back in for changes to take effect, then re-run this script."
    exit 0
}

# --- Main Script ---
log "Starting tunnel container installer..."

# 1. Check for Docker
check_command docker
if ! sudo docker info >/dev/null 2>&1; then
    log "Docker daemon not running or user not in docker group. Attempting to fix..."
    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo is not installed. Please install sudo or run this script as root."
    fi
    if ! sudo systemctl is-active docker >/dev/null 2>&1; then
        sudo systemctl start docker || error "Failed to start Docker daemon."
    fi
    if ! sudo docker info >/dev/null 2>&1; then
        # User not in docker group
        sudo usermod -aG docker "$USER" || error "Failed to add user to docker group. Please log out and log back in, then re-run this script."
        log "Added $USER to docker group. Please log out and log back in, then re-run this script."
        exit 0
    fi
fi
log "Docker is running and accessible."

# 2. Check for Git
check_command git

# 3. Clone or update repository
if [ -d "$REPO_DIR" ]; then
    log "Repository already exists. Pulling latest changes..."
    (cd "$REPO_DIR" && git pull) || error "Failed to pull latest changes."
else
    log "Cloning repository..."
    git clone "$REPO_URL" || error "Failed to clone repository."
fi
log "Repository is up to date."

# 4. Navigate to tunnel_docker directory
TUNNEL_PATH="$REPO_DIR/$TUNNEL_DIR"
if [ ! -d "$TUNNEL_PATH" ]; then
    error "Tunnel directory not found: $TUNNEL_PATH. Please check repository structure."
fi
log "Navigated to $TUNNEL_PATH."

# 5. Check for private key
if [ ! -f "$KEY_PATH_IN_HOST" ]; then
    error "Private key not found: $KEY_PATH_IN_HOST. Please ensure it exists and has correct permissions (chmod 600)."
fi
log "Private key found: $KEY_PATH_IN_HOST."

# 6. Build Docker image
log "Building Docker image $IMAGE_NAME..."
(cd "$TUNNEL_PATH" && sudo docker build -t "$IMAGE_NAME" .) || error "Failed to build Docker image."
log "Docker image $IMAGE_NAME built successfully."

# 7. Stop and remove old container
log "Stopping and removing old container (if any)..."
sudo docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
sudo docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
log "Old container removed."

# 8. Run new container
log "Running new container $CONTAINER_NAME..."
sudo docker run -d --restart=unless-stopped --name "$CONTAINER_NAME" \
    --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
    -v "$KEY_PATH_IN_HOST":/root/.ssh/id_rsa_vds1:ro \
    "$IMAGE_NAME" || error "Failed to run container."
log "Container $CONTAINER_NAME started successfully."

log "Installation complete. The tunnel container is running."
log "You can check its status with: sudo docker ps -a"
log "Logs can be viewed with: sudo docker logs $CONTAINER_NAME"
log "Remember to ensure port 2222, 8088, and 9001 (for chisel) are not blocked by firewall on vds1."
