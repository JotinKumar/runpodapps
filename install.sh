#!/bin/bash
set -e

echo "=========================================="
echo "  ComfyUI Installation for RunPod"
echo "=========================================="
echo ""

# Install system dependencies
echo "[1/8] Installing system dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    ffmpeg
apt-get clean
rm -rf /var/lib/apt/lists/*
echo "✓ System dependencies installed"
echo ""

# Clone ComfyUI
echo "[2/8] Cloning ComfyUI..."
cd /workspace
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git
else
    echo "ComfyUI already exists, skipping clone"
fi
cd ComfyUI
echo "✓ ComfyUI ready"
echo ""

# Create virtual environment
echo "[3/8] Creating virtual environment..."
python3 -m venv comfyvenv
source comfyvenv/bin/activate
echo "✓ Virtual environment created"
echo ""

# Install PyTorch
echo "[4/8] Installing PyTorch (5-10 minutes)..."
pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
echo "✓ PyTorch installed"
echo ""

# Install ComfyUI requirements
echo "[5/8] Installing ComfyUI requirements..."
pip install --no-cache-dir -r requirements.txt
pip install --no-cache-dir xformers --index-url https://download.pytorch.org/whl/cu124
echo "✓ Requirements installed"
echo ""

# Clone custom nodes
echo "[6/8] Cloning custom nodes..."
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
        git clone "$repo" 2>&1 | grep -q "fatal" && echo "  ⚠ Failed: $node_name" || echo "  ✓ $node_name"
    fi
done
echo "✓ Custom nodes ready"
echo ""

# Install custom node requirements
echo "[7/8] Installing custom node dependencies..."
for node_dir in */; do
    if [ -f "$node_dir/requirements.txt" ]; then
        pip install --no-cache-dir -r "$node_dir/requirements.txt" > /dev/null 2>&1 || true
    fi
done
echo "✓ Dependencies installed"
echo ""

# Configure ffmpeg for was-node-suite
echo "[8/8] Configuring custom nodes..."
if [ -d "was-node-suite-comfyui" ]; then
    echo '{"ffmpeg_bin_path": "/usr/bin/ffmpeg"}' > was-node-suite-comfyui/was_suite_config.json
fi

echo "✓ Configuration complete"

deactivate

echo ""
echo "=========================================="
echo "  ✓ Installation Complete!"
echo "=========================================="
echo ""
echo "Location: /workspace/ComfyUI"
echo "Venv: /workspace/ComfyUI/comfyvenv"
echo ""
echo "Start ComfyUI:"
echo "  wget https://raw.githubusercontent.com/JotinKumar/runpodapps/main/start.sh && chmod +x start.sh && ./start.sh"
echo "=========================================="
