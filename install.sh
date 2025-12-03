#!/bin/bash
set -e

# ============================================================================
# RunPod Multi-App Installation Script
# Base Image: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
# ============================================================================

echo "========================================="
echo "Starting Multi-App Installation"
echo "========================================="

# ============================================================================
# System Dependencies
# ============================================================================
echo "Installing system dependencies..."
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    ca-certificates \
    nano \
    htop \
    tmux \
    less \
    net-tools \
    iputils-ping \
    procps \
    golang \
    make \
    xz-utils \
    openssh-client \
    openssh-server \
    ffmpeg

# Install Node.js 20.x for Pinokio and Open WebUI
echo "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

# ============================================================================
# Install Ollama
# ============================================================================
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# ============================================================================
# Install FileBrowser
# ============================================================================
echo "Installing FileBrowser..."
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# ============================================================================
# Install Open WebUI
# ============================================================================
echo "Installing Open WebUI..."
pip install --no-cache-dir open-webui

# ============================================================================
# Install Jupyter (if not already present)
# ============================================================================
echo "Checking Jupyter installation..."
if ! command -v jupyter &> /dev/null; then
    echo "Installing Jupyter..."
    pip install --no-cache-dir jupyter
else
    echo "Jupyter already installed"
fi

# ============================================================================
# Remove uv (if present) to force pip usage
# ============================================================================
echo "Removing uv package manager..."
pip uninstall -y uv 2>/dev/null || true
rm -f /usr/local/bin/uv /usr/local/bin/uvx

# ============================================================================
# Create workspace directories
# ============================================================================
echo "Creating workspace directories..."
mkdir -p /workspace/comfy
mkdir -p /workspace/pinokio
mkdir -p /workspace/ollama
mkdir -p /workspace/open-webui

# ============================================================================
# Setup ComfyUI
# ============================================================================
echo "Setting up ComfyUI..."
cd /workspace/comfy

if [ ! -d "ComfyUI" ]; then
    echo "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi

cd ComfyUI

# Create virtual environment with system site packages
echo "Creating ComfyUI virtual environment..."
python3 -m venv --system-site-packages comfyvenv
source comfyvenv/bin/activate

# Install ComfyUI requirements
echo "Installing ComfyUI dependencies..."
pip install --no-cache-dir -r requirements.txt
pip install --no-cache-dir GitPython opencv-python

# Install custom nodes
echo "Installing ComfyUI custom nodes..."
cd custom_nodes

# Array of custom node repositories
declare -a custom_nodes=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/MoonGoblinDev/Civicomfy.git"
    "https://github.com/hayden-fr/ComfyUI-Model-Manager.git"
    "https://github.com/WASasquatch/was-node-suite-comfyui.git"
    "https://github.com/cubiq/ComfyUI_essentials.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
)

for repo in "${custom_nodes[@]}"; do
    node_name=$(basename "$repo" .git)
    if [ ! -d "$node_name" ]; then
        echo "Cloning $node_name..."
        git clone "$repo" || echo "Warning: Failed to clone $node_name"
    fi
done

# Install custom node requirements
echo "Installing custom node dependencies..."
for node_dir in */; do
    if [ -f "$node_dir/requirements.txt" ]; then
        echo "Installing requirements for $node_dir"
        pip install --no-cache-dir -r "$node_dir/requirements.txt" || echo "Warning: Some packages failed for $node_dir"
    fi
done

deactivate

# ============================================================================
# Setup Pinokio
# ============================================================================
echo "Setting up Pinokio..."
cd /workspace/pinokio

if [ ! -d "pinokio" ]; then
    echo "Cloning Pinokio..."
    git clone https://github.com/pinokiocomputer/pinokio.git
fi

cd pinokio

# Install Pinokio dependencies
echo "Installing Pinokio dependencies..."
npm install

# ============================================================================
# Setup Open WebUI
# ============================================================================
echo "Setting up Open WebUI..."
cd /workspace/open-webui

# Create virtual environment with system site packages
echo "Creating Open WebUI virtual environment..."
python3 -m venv --system-site-packages openwebuivenv
source openwebuivenv/bin/activate

# Verify Open WebUI is installed
pip install --no-cache-dir --upgrade open-webui

deactivate

# ============================================================================
# Configure SSH
# ============================================================================
echo "Configuring SSH..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
mkdir -p /run/sshd

# ============================================================================
# Download and setup start script
# ============================================================================
echo "Setting up start script..."
cd /workspace

# Download start.sh from repository
if [ ! -f "start.sh" ]; then
    echo "Downloading start.sh..."
    wget https://raw.githubusercontent.com/JotinKumar/runpodapps/main/start.sh -O start.sh
    chmod +x start.sh
fi

echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Services installed:"
echo "  - ComfyUI (port 8188)"
echo "  - Pinokio (port 42424)"
echo "  - Ollama (port 11434)"
echo "  - Open WebUI (port 3000)"
echo "  - FileBrowser (port 8080)"
echo "  - JupyterLab (port 8888)"
echo "  - SSH (port 22)"
echo ""
echo "To start all services, run:"
echo "  /workspace/start.sh"
echo ""
echo "Or on RunPod, the start.sh will run automatically if configured"
echo "========================================="
