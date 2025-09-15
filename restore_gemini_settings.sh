#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Gemini settings restoration..."

# 1. Clone the GitHub repository
REPO_DIR="cloud-google-marzban-settings"
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists. Pulling latest changes..."
    cd "$REPO_DIR"
    git pull
else
    echo "Cloning GitHub repository..."
    git clone git@github.com:igor04091968/cloud-google-marzban-settings.git
    cd "$REPO_DIR"
fi

# 2. Restore Gemini settings
echo "Restoring Gemini settings..."
mkdir -p ~/.gemini
cp -r gemini_settings/* ~/.gemini/

# 3. Restore Gemini logs
echo "Restoring Gemini logs..."
mkdir -p ~/.gemini/gemini_logs
cp -r gemini_logs/* ~/.gemini/gemini_logs/

# 4. Restore VDS kubeconfig
echo "Restoring VDS kubeconfig..."
mkdir -p ~/.kube
cp -r vds_kube_config/* ~/.kube/

# 5. Install necessary tools (kubectl, minikube)
echo "Installing kubectl and minikube..."
# Install kubectl
if ! command -v kubectl &> /dev/null
then
    echo "kubectl not found, installing..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
fi

# Install minikube
if ! command -v minikube &> /dev/null
then
    echo "minikube not found, installing..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
fi

echo "Gemini settings restoration complete."
echo "Please ensure you have SSH keys configured for GitHub access."
echo "You may need to run 'minikube start' to start your Kubernetes cluster."
