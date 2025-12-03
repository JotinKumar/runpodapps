#!/bin/bash
set -e

echo "========================================="
echo "ComfyUI Installation Script"
echo "Base: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04"
echo "========================================="

# 0. Install required system dependencies
echo "Step 0: Installing system dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    ffmpeg
apt-get clean
rm -rf /var/lib/apt/lists/*

# 1. Set default path to /workspace
echo "Step 1: Setting up workspace..."
cd /workspace

# 2. Clone ComfyUI
echo "Step 2: Cloning ComfyUI..."
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git
    echo "✓ ComfyUI cloned"
else
    echo "✓ ComfyUI already exists"
fi

cd ComfyUI

# 3. Install ComfyUI requirements (no venv - use system Python)
echo "Step 3: Installing ComfyUI requirements..."
pip install --no-cache-dir -r requirements.txt
pip install --no-cache-dir xformers
echo "✓ ComfyUI requirements installed"

# 4. Install compatible torchaudio
echo "Step 4: Installing compatible torchaudio..."
pip install --no-cache-dir torchaudio --index-url https://download.pytorch.org/whl/cu124
echo "✓ Torchaudio installed"

# 5. Install custom nodes
echo "Step 7: Installing custom nodes..."
cd custom_nodes

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
        echo "  Cloning $node_name..."
        git clone "$repo" || echo "  Warning: Failed to clone $node_name"
    else
        echo "  ✓ $node_name already exists"
    fi
done

echo "✓ Custom nodes installed"

# 6. Install custom node requirements
echo "Step 6: Installing custom node requirements..."
for node_dir in */; do
    if [ -f "$node_dir/requirements.txt" ]; then
        echo "  Installing requirements for $node_dir"
        pip install --no-cache-dir -r "$node_dir/requirements.txt" || echo "  Warning: Some packages failed for $node_dir"
    fi
done

echo "========================================="
echo "✓ Installation Complete!"
echo "========================================="
echo ""
echo "ComfyUI installed at: /workspace/ComfyUI"
echo "Using system Python with pre-installed PyTorch"
echo ""
echo "To start ComfyUI, run:"
echo "  /workspace/start.sh"
echo "========================================="
