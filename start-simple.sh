#!/bin/bash

echo "========================================="
echo "Starting ComfyUI"
echo "========================================="

# Navigate to ComfyUI directory
cd /workspace/ComfyUI

# Start ComfyUI (using system Python)
echo "Starting ComfyUI on port 8188..."
echo "Access ComfyUI at: http://your-pod-ip:8188"
echo "========================================="

python3 main.py --listen 0.0.0.0 --port 8188
