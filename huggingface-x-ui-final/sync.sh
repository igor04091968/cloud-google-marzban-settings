#!/bin/bash
set -e # Exit on error

LOG_FILE="/var/log/sync.log"
echo "--- Starting sync at $(date) ---" >> $LOG_FILE

GIT_REPO_URL="git@github.com:igor04091968/cloud-google-marzban-settings.git"
LOCAL_REPO_PATH="/tmp/config_repo"
CONFIG_DIR_IN_REPO="x-ui_configs"

XUI_DB_PATH="/usr/local/x-ui/db/x-ui.db"
XRAY_CONFIG_PATH="/usr/local/x-ui/bin/config.json"

SSH_KEY_SOURCE_PATH="/ssh_key_ro/id_rsa"
SSH_KEY_PATH="/root/.ssh/id_rsa"

# 1. Setup SSH
echo "Setting up SSH..." >> $LOG_FILE
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Copy the read-only key to a writable location
if [ -f "$SSH_KEY_SOURCE_PATH" ]; then
    cp "$SSH_KEY_SOURCE_PATH" "$SSH_KEY_PATH"
else
    echo "Source SSH key not found at $SSH_KEY_SOURCE_PATH" >> $LOG_FILE
    exit 1
fi

# Set correct permissions on the writable copy
chmod 600 "$SSH_KEY_PATH"

ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

# Use an SSH wrapper to specify the key
export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH"

# 2. Setup Git
echo "Setting up Git..." >> $LOG_FILE
git config --global user.name "Gemini Assistant"
git config --global user.email "igor04091968@gmail.com"

# 3. Clone or Pull Repo
if [ -d "$LOCAL_REPO_PATH/.git" ]; then
  echo "Pulling existing repo..." >> $LOG_FILE
  cd $LOCAL_REPO_PATH
  git pull
else
  echo "Cloning new repo..." >> $LOG_FILE
  git clone "$GIT_REPO_URL" "$LOCAL_REPO_PATH"
  cd $LOCAL_REPO_PATH
fi

# 4. Copy current configs to repo (WRITE)
echo "Copying configs to local repo..." >> $LOG_FILE
TARGET_DIR="$LOCAL_REPO_PATH/$CONFIG_DIR_IN_REPO"
mkdir -p "$TARGET_DIR"

# Check if source files exist before copying
if [ -f "$XUI_DB_PATH" ]; then
    cp "$XUI_DB_PATH" "$TARGET_DIR/x-ui.db"
else
    echo "Warning: x-ui.db not found." >> $LOG_FILE
fi

if [ -f "$XRAY_CONFIG_PATH" ]; then
    cp "$XRAY_CONFIG_PATH" "$TARGET_DIR/config.json"
else
    echo "Warning: config.json not found." >> $LOG_FILE
fi


# 5. Commit and Push
echo "Committing and pushing changes..." >> $LOG_FILE
git add .
if git diff --staged --quiet; then
  echo "No changes to commit." >> $LOG_FILE
else
  git commit -m "Automatic x-ui config sync: $(date)"
  echo "Pushing to remote..." >> $LOG_FILE
  git push origin master
fi

echo "--- Sync finished at $(date) ---" >> $LOG_FILE
