#!/bin/bash

echo "========================================="
echo "Starting ComfyUI"
echo "========================================="

# Navigate to ComfyUI directory
cd /workspace/ComfyUI

# Activate virtual environment
echo "Activating virtual environment..."
source comfyvenv/bin/activate

# Start ComfyUI
echo "Starting ComfyUI on port 8188..."
echo "Access ComfyUI at: http://your-pod-ip:8188"
echo "========================================="

python main.py --listen 0.0.0.0 --port 8188
