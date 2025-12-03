#!/bin/bash

echo "==========================================="
echo "  Starting ComfyUI"
echo "==========================================="
echo ""

cd /workspace/ComfyUI || { echo "Error: ComfyUI not found"; exit 1; }

source comfyvenv/bin/activate || { echo "Error: Virtual environment not found"; exit 1; }

echo "✓ Environment activated"
echo ""
echo "Starting ComfyUI on port 8188..."
echo "Access at: https://<pod-id>-8188.proxy.runpod.net"
echo "==========================================="
echo ""

python main.py --listen 0.0.0.0 --port 8188
