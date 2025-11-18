#!/bin/bash

git --version || sudo apt install git-all
docker version || sudo apt install docker
jq version || sudo apt install jq -y

# 1. Update and Upgrade Existing Packages
echo -e "\n--- Updating and upgrading existing packages ---"
sudo apt update && sudo apt upgrade -y || { echo "Failed to update/upgrade packages. Exiting."; exit 1; }

# --- Docker Installation ---

# 2. Install Required Dependencies for Docker (already good)
echo -e "\n--- Installing required dependencies for Docker ---"
sudo apt install -y ca-certificates curl gnupg lsb-release || { echo "Failed to install Docker dependencies. Exiting."; exit 1; }


# 3. Add Docker's Official GPG Key
# This command directly adds the GPG key to the trusted.gpg.d directory for apt.
echo -e "\n--- Adding Docker's official GPG key ---"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || { echo "Failed to download/add Docker GPG key. Exiting."; exit 1; }
sudo chmod a+r /etc/apt/keyrings/docker.gpg # Set permissions to be readable by all

# 4. Add the Docker APT Repository
# This command adds the repository using the new 'signed-by' syntax with the direct GPG key file path.
echo -e "\n--- Adding the Docker APT repository ---"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Failed to add Docker repository. Exiting."; exit 1; }

# 5. Update apt Package Index Again
echo -e "\n--- Updating apt package index again for Docker ---"
sudo apt update || { echo "Failed to update apt index for Docker. Exiting."; exit 1; }

# 6. Install Docker Engine, CLI, and Containerd
echo -e "\n--- Installing Docker Engine, CLI, and Containerd ---"
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { echo "Failed to install Docker components. Exiting."; exit 1; }

# 7. Add Your User to the 'docker' Group
echo -e "\n--- Adding current user ($USER) to the 'docker' group ---"
sudo groupadd docker
sudo usermod -aG docker $USER || { echo "Failed to add user to docker group. Exiting."; exit 1; }
sudo chmod 666 /var/run/docker.sock

# 8. (Optional) Configure Docker Service to Start Automatically
echo -e "\n--- (Optional) Adding Docker service start command to ~/.bashrc ---"
if ! grep -q "sudo service docker start" ~/.bashrc; then
    echo 'sudo service docker start > /dev/null 2>&1 || true' >> ~/.bashrc
    echo "Added 'sudo service docker start' to ~/.bashrc."
else
    echo "Line already exists in ~/.bashrc. Skipping."
fi

# --- kubectl Installation ---

echo -e "\n--- Installing kubectl ---"
# Download the kubectl binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || { echo "Failed to download kubectl. Exiting."; exit 1; }
# Validate the kubectl binary (optional but recommended)
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" || { echo "Failed to download kubectl checksum. Exiting."; exit 1; }
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check || { echo "kubectl checksum validation failed. Proceeding with caution or exiting."; } # Note: Added exit after check if you want it strict

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl || { echo "Failed to install kubectl. Exiting."; exit 1; }
# Clean up downloaded files
rm kubectl kubectl.sha256

# Verify kubectl installation
kubectl version --client || { echo "kubectl installation verification failed."; }


# --- Minikube Installation ---

echo -e "\n--- Installing Minikube ---"
# Download the Minikube binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 || { echo "Failed to download Minikube. Exiting."; exit 1; }
# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube || { echo "Failed to install Minikube. Exiting."; exit 1; }
# Clean up downloaded file
rm minikube-linux-amd64

# Verify Minikube installation
minikube version || { echo "Minikube installation verification failed."; }

# --- Kompose Installation ---

echo -e "\n--- Installing Kompose ---"
# Find the latest Kompose release (this is a more robust way to get the latest)
KOMPOSE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kompose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "Detected Kompose version: $KOMPOSE_VERSION"

# Download the Kompose binary
curl -L https://github.com/kubernetes/kompose/releases/download/${KOMPOSE_VERSION}/kompose-linux-amd64 -o kompose || { echo "Failed to download Kompose. Exiting."; exit 1; }
# Make it executable
chmod +x kompose || { echo "Failed to make Kompose executable. Exiting."; exit 1; }
# Move it to a directory in your PATH
sudo mv ./kompose /usr/local/bin/kompose || { echo "Failed to move Kompose to /usr/local/bin. Exiting."; exit 1; }

# Verify Kompose installation
kompose version || { echo "Kompose installation verification failed."; }

docker --version || { echo "Docker command not detected, install failed."; exit 1; }
docker compose version || { echo "Docker compose command not detected, install failed."; exit 1; }

PORT1=3000
PORT2=5000

if ss -tuln | grep ":$PORT1" > /dev/null; then
    echo "Port $PORT1 is in use."
    exit 1;
else
    echo "Port $PORT1 is free."
fi

if ss -tuln | grep ":$PORT2" > /dev/null; then
    echo "Port $PORT2 is in use."
    exit 1;
else
    echo "Port $PORT2 is free."
fi

cd ~

DIR="COMP-4001_assignment3_pt3"
if [ ! -d "$DIR" ]; then
    git clone https://github.com/icollett/COMP-4001_assignment3_pt3.git
else
    echo "Project directory already exists."
fi

sleep 1s

echo "Moving into project repo directory"
cd COMP-4001_assignment3_pt3
ls -l
head -n 5 docker-compose.yml

docker compose up --build -d
sleep 2s
curl http://localhost:3000
curl http://localhost:5000

docker image ls

NGINX_ID=$(docker ps -q --filter "ancestor=nginx:alpine")

if [ -n "$NGINX_ID" ]; then
    echo "The nginx container is: $NGINX_ID"
else
    echo "No nginx container running."
fi

docker inspect nginx:alpine | jq '.' > nginx_logs.json

LOG_FILE="nginx_logs.json"

REPO_TAGS=$(jq -r '.[0].RepoTags' "$LOG_FILE")
CREATED=$(jq -r '.[0].Created' "$LOG_FILE")
NGINX_OS=$(jq -r '.[0].Os' "$LOG_FILE")
NGINX_CONFIG=$(jq -r '.[0].Config' "$LOG_FILE")
EXPO_PORTS=$(jq -r '.[0].Config.ExposedPorts' "$LOG_FILE")

echo "RepoTags: $REPO_TAGS"
echo "Created: $CREATED"
echo "OS: $NGINX_OS"
echo "Config: $NGINX_CONFIG"
echo "Exposed ports: $EXPO_PORTS"

