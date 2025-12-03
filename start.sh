#!/bin/bash

echo "==========================================="
echo "  Starting ComfyUI"
echo "==========================================="
echo ""

cd /workspace/ComfyUI || { echo "Error: ComfyUI not found"; exit 1; }

source /workspace/ComfyUI/comfyvenv/bin/activate || { echo "Error: Virtual environment not found"; exit 1; }

# Ensure ComfyUI root is importable for custom nodes (e.g., folder_paths)
export PYTHONPATH="/workspace/ComfyUI:${PYTHONPATH}"

# Get RunPod Pod ID from environment
POD_ID=${RUNPOD_POD_ID:-"unknown"}

echo "✓ Environment activated"
echo ""
echo "Starting ComfyUI on port 8188..."
echo "==========================================="

if [ "$POD_ID" != "unknown" ]; then
    COMFY_URL="https://${POD_ID}-8188.proxy.runpod.net"
    echo ""
    echo "🌐 Access ComfyUI at:"
    echo "   $COMFY_URL"
    echo ""
    echo "==========================================="
fi

echo ""

# Start ComfyUI with logs in foreground
python main.py --listen 0.0.0.0 --port 8188
