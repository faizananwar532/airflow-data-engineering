#!/bin/bash

# EC2 Docker Setup Script
# Run this script on a fresh Ubuntu EC2 instance
# Usage: chmod +x setup-docker.sh && ./setup-docker.sh
# you can copy it in ec2 or create a new one

set -e  # Exit on any error

echo "========================================="
echo "Starting Docker installation on EC2..."
echo "========================================="

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Add Docker's official GPG key
echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with Docker packages
echo "Updating package index..."
sudo apt-get update -y

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (avoid using sudo for docker commands)
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# Install Docker Compose (standalone version for compatibility)
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symbolic link for easier access
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installations
echo "========================================="
echo "Verifying installations..."
echo "========================================="

echo "Docker version:"
sudo docker --version

echo "Docker Compose version:"
docker-compose --version

echo "Docker service status:"
sudo systemctl status docker --no-pager -l

# Test Docker installation
echo "Testing Docker installation..."
sudo docker run hello-world

# Give Docker permission to execute without sudo
newgrp docker

echo "========================================="
echo "Docker installation completed successfully!"
echo "========================================="
echo ""
echo "IMPORTANT NOTES:"
echo "1. You've been added to the 'docker' group"
echo "2. Log out and log back in (or run 'newgrp docker') to use docker without sudo"
echo "3. Or simply reboot the instance: sudo reboot"
echo ""
echo "To verify everything works after relogging:"
echo "  docker run hello-world"
echo "  docker-compose --version"