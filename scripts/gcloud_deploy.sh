#!/bin/bash

# Script to deploy Marzban to a new Google Cloud VM.

set -e

# VM Configuration
INSTANCE_NAME="marzban-vm-$(date +%s)"
MACHINE_TYPE="e2-medium"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
ZONE="us-central1-a" # Or choose a zone closer to you

# Startup script to be executed on the VM
STARTUP_SCRIPT=$(cat <<'EOF'
#!/bin/bash
set -ex

# Install dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Clone the repository
git clone https://github.com/igor04091968/cloud-google-marzban-settings.git
cd cloud-google-marzban-settings

# Run the setup script
./scripts/setup_app.sh

EOF
)

# Create the VM with the startup script
gcloud compute instances create "$INSTANCE_NAME" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="$IMAGE_FAMILY" \
    --image-project="$IMAGE_PROJECT" \
    --zone="$ZONE" \
    --metadata=startup-script="$STARTUP_SCRIPT"

echo "VM '$INSTANCE_NAME' is being created with Marzban deployment in progress."
echo "You can check the progress by running: gcloud compute ssh $INSTANCE_NAME --zone $ZONE --command 'tail -f /var/log/syslog'"
