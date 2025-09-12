#!/bin/bash

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Git repository directory
GIT_REPO_DIR="/git"

# Log file
LOG_FILE="$SCRIPT_DIR/sync.log"

# Files to sync
XUI_DB_PATH="/etc/x-ui/x-ui.db"
XRAY_CONFIG_PATH="/usr/local/x-ui/bin/config.json"

# Target directory in the git repo
TARGET_DIR="$GIT_REPO_DIR/x-ui-configs"

# Git commit message
COMMIT_MESSAGE="Automatic sync of x-ui configs"

# --- Functions ---

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

sync_files() {
  log "Starting file synchronization..."

  # Git safe directory
  git config --global --add safe.directory /git

  # Setup Git
  echo "Setting up Git..." >> $LOG_FILE
  git config --global user.email "igor04091968@gmail.com"

  # The cp commands are removed because the volume mounts make them redundant.
  # The live database is already in the git repository on the host.

  # Git operations
  cd "$GIT_REPO_DIR" || exit 1
  git config --global user.email "igor04091968@gmail.com"
  git config --global user.name "igor04091968"
  
  git add .
  
  git commit -m "$COMMIT_MESSAGE"
  log "Committed changes."
  
  git pull
  if git push; then
    log "Pushed changes to the remote repository."
  else
    log "Error: Failed to push changes."
  fi
  
  log "Synchronization finished."
}

# --- Main ---

sync_files