#!/bin/bash

# Torizon Development Environment Setup Script for Ubuntu
# This script installs all required tools for Torizon OS development in VS Code

set -e

echo "================================================"
echo "Torizon Development Environment Setup"
echo "================================================"
echo ""

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "Warning: This script is designed for Ubuntu. Your system may not be supported."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root or with sudo."
    echo "The script will prompt for sudo password when needed."
    exit 1
fi

echo "Step 1: Updating system packages..."
sudo apt update
sudo apt upgrade -y

echo ""
echo "Step 2: Installing essential build tools..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

echo ""
echo "Step 3: Installing Docker..."
# Remove old Docker versions if they exist
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "Step 4: Configuring Docker permissions..."
# Add current user to docker group
sudo usermod -aG docker $USER

echo ""
echo "Step 5: Installing Docker Compose (standalone)..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo ""
echo "Step 6: Installing Visual Studio Code..."
# Add Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

# Install VS Code
sudo apt update
sudo apt install -y code

echo ""
echo "Step 7: Installing VS Code extensions for Torizon..."
code --install-extension toradex.toradex-torizon-toolkit
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.cmake-tools
code --install-extension twxs.cmake

echo ""
echo "Step 8: Installing additional development tools..."
sudo apt install -y \
    python3 \
    python3-pip \
    cmake \
    ninja-build \
    gdb \
    gdb-multiarch \
    device-tree-compiler

echo ""
echo "Step 9: Installing Torizon CLI tools..."
# Install torizoncore-builder
pip3 install --user torizoncore-builder

# Add ~/.local/bin to PATH if not already present
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

echo ""
echo "Step 10: Configuring Git (optional)..."
read -p "Would you like to configure Git now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    echo "Git configured successfully."
fi

echo ""
echo "================================================"
echo "Installation Complete!"
echo "================================================"
echo ""
echo "Please note the following:"
echo "1. Log out and log back in for Docker group permissions to take effect"
echo "   (or run: newgrp docker)"
echo "2. VS Code has been installed with Torizon extensions"
echo "3. Docker and Docker Compose are installed and configured"
echo "4. torizoncore-builder is installed via pip3"
echo ""
echo "To verify the installation:"
echo "  docker --version"
echo "  docker-compose --version"
echo "  code --version"
echo "  torizoncore-builder --version"
echo ""
echo "To start developing:"
echo "1. Open VS Code: 'code'"
echo "2. Open or create a Torizon project"
echo "3. Use the Torizon extension to configure your target device"
echo ""
echo "For more information, visit:"
echo "https://developer.toradex.com/torizon"
