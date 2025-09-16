#!/bin/bash

# --- Configuration ---
CONTAINER_NAME="proxy-x-ui-container" # <<< IMPORTANT: Change this if your container has a different name
GIT_REPO_DIR="/home/igor/gemini_projects/cloud-google-marzban-settings"
LOG_FILE="${GIT_REPO_DIR}/huggingface-x-ui-final/sync_local.log"

# Paths inside the container
CONTAINER_XUI_DB_PATH="/tmp/x-ui.db"
CONTAINER_XRAY_CONFIG_PATH="/usr/local/x-ui/bin/config.json"

# Destination for the backed up files on the host
TARGET_DIR="${GIT_REPO_DIR}/huggingface-x-ui-final/x-ui-configs"

# Git commit message
COMMIT_MESSAGE="Sync x-ui configs from local container"

# --- Functions ---
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Main ---
log "--- Starting Local Config Sync ---"

# Check if container is running
if ! docker ps -f "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    log "Error: Container '${CONTAINER_NAME}' is not running. Exiting."
    exit 1
fi

# Navigate to the Git repository
if [ ! -d "${GIT_REPO_DIR}/.git" ]; then
  log "Error: Git repository not found at ${GIT_REPO_DIR}. Exiting sync."
  exit 1
fi
cd "${GIT_REPO_DIR}" || exit 1

# Pull latest changes first
log "Pulling latest changes from remote..."
if ! git pull --rebase; then
    log "Error: git pull failed. Please resolve conflicts manually. Exiting."
    exit 1
fi

# Ensure the target directory for configs exists
mkdir -p "${TARGET_DIR}"

# Copy live files from the container
log "Copying configs from container '${CONTAINER_NAME}'..."
if ! docker cp "${CONTAINER_NAME}:${CONTAINER_XUI_DB_PATH}" "${TARGET_DIR}/x-ui.db"; then
    log "Error: Failed to copy x-ui.db from container."
    # Decide if we should exit or continue
fi
if ! docker cp "${CONTAINER_NAME}:${CONTAINER_XRAY_CONFIG_PATH}" "${TARGET_DIR}/config.json"; then
    log "Error: Failed to copy config.json from container."
    # Decide if we should exit or continue
fi

# Add, commit, and push
log "Adding changes to git..."
git add "${TARGET_DIR}/x-ui.db" "${TARGET_DIR}/config.json"

# Commit only if there are changes
if ! git diff-index --quiet HEAD; then
  log "Found changes, committing..."
  git commit -m "$COMMIT_MESSAGE"
  log "Committed changes."

  log "Pushing changes to remote..."
  if git push; then
    log "Successfully pushed changes to the remote repository."
  else
    log "Error: Failed to push changes. Please push manually."
  fi
else
  log "No changes to commit."
fi

log "--- Local Config Sync Finished ---"
