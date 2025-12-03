#!/bin/bash

echo "==========================================="
echo "  Starting ComfyUI"
echo "==========================================="
echo ""

cd /workspace/ComfyUI || { echo "Error: ComfyUI not found"; exit 1; }

source comfyvenv/bin/activate || { echo "Error: Virtual environment not found"; exit 1; }

# Get RunPod Pod ID from environment
POD_ID=${RUNPOD_POD_ID:-"unknown"}

echo "✓ Environment activated"
echo ""
echo "Starting ComfyUI on port 8188..."
echo "==========================================="

# Start ComfyUI in background to get the URL
python main.py --listen 0.0.0.0 --port 8188 > /tmp/comfyui.log 2>&1 &
COMFY_PID=$!

# Wait for ComfyUI to start
sleep 3

if [ "$POD_ID" != "unknown" ]; then
    COMFY_URL="https://${POD_ID}-8188.proxy.runpod.net"
    echo ""
    echo "✓ ComfyUI is running!"
    echo ""
    echo "🌐 Access ComfyUI at:"
    echo "   $COMFY_URL"
    echo ""
    echo "==========================================="
else
    echo ""
    echo "✓ ComfyUI is running on port 8188"
    echo "==========================================="
fi

# Bring ComfyUI back to foreground
wait $COMFY_PID
