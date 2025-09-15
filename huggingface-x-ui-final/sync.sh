#!/bin/bash

# This script assumes that start.sh has already cloned the repo and set up SSH.

# --- Paths ---
# The git repo is cloned into /tmp/repo by start.sh
GIT_REPO_DIR="/tmp/repo"
LOG_FILE="/tmp/sync.log"

# Live files to be backed up
XUI_DB_PATH="/tmp/x-ui.db"
XRAY_CONFIG_PATH="/usr/local/x-ui/bin/config.json"

# Destination for the backed up files inside the git repo
TARGET_DIR="${GIT_REPO_DIR}/x-ui-configs"

# Git commit message
COMMIT_MESSAGE="Automatic sync of x-ui configs"

# --- Functions ---

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Main ---

log "--- Starting Hourly Sync ---"

# Navigate to the Git repository
if [ ! -d "$GIT_REPO_DIR/.git" ]; then
  log "Error: Git repository not found at $GIT_REPO_DIR. Exiting sync."
  exit 1
fi
cd "$GIT_REPO_DIR" || exit 1

# Configure git user for this operation
git config user.email "igor04091968@gmail.com"
git config user.name "igor04091968"

# Pull latest changes first to avoid conflicts
log "Pulling latest changes from remote..."
git pull --rebase

# Ensure the target directory for configs exists
mkdir -p "$TARGET_DIR"

# Copy live files into the git repo
log "Copying live db from ${XUI_DB_PATH} and config from ${XRAY_CONFIG_PATH} into git repo..."
cp -f "${XUI_DB_PATH}" "${TARGET_DIR}/x-ui.db"
cp -f "${XRAY_CONFIG_PATH}" "${TARGET_DIR}/config.json"

# Add, commit, and push
log "Adding changes to git..."
git add "$TARGET_DIR/x-ui.db" "$TARGET_DIR/config.json"

# Commit only if there are changes
if ! git diff-index --quiet HEAD; then
  log "Found changes, committing..."
  git commit -m "$COMMIT_MESSAGE"
  log "Committed changes."
  
  log "Pushing changes to remote..."
  if git push; then
    log "Successfully pushed changes to the remote repository."
  else
    log "Error: Failed to push changes."
  fi
else
  log "No changes to commit."
fi

log "--- Hourly Sync Finished ---"