# ComfyUI Installation for RunPod

Simple, reliable ComfyUI setup for RunPod PyTorch base image.

## Requirements

- RunPod Pod with GPU
- Base Image: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- Network Volume mounted at `/workspace` (recommended)

## Installation

SSH into your RunPod pod and run:

```bash
cd /workspace
wget https://raw.githubusercontent.com/JotinKumar/runpodapps/main/install.sh
chmod +x install.sh
./install.sh
```

Installation takes approximately 10-15 minutes.

## Start ComfyUI

```bash
/workspace/start.sh
```

Access ComfyUI at: `https://<pod-id>-8188.proxy.runpod.net`

## What Gets Installed

- ComfyUI with PyTorch 2.4.0 + CUDA 12.4
- Isolated virtual environment at `/workspace/ComfyUI/comfyvenv`
- PyTorch and all dependencies installed inside venv
- 9 popular custom nodes:
  - ComfyUI-Manager
  - ComfyUI-KJNodes
  - Civicomfy
  - ComfyUI-Model-Manager
  - was-node-suite-comfyui
  - ComfyUI_essentials
  - ComfyUI-Impact-Pack
  - rgthree-comfy
  - ComfyUI_Comfyroll_CustomNodes

## Directory Structure

```text
/workspace/
└── ComfyUI/
    ├── comfyvenv/          # Virtual environment
    ├── custom_nodes/       # Custom nodes
    ├── models/             # Store your models here
    ├── input/              # Input images
    ├── output/             # Generated images
    └── main.py             # ComfyUI entry point
```

## Troubleshooting

### Check if ComfyUI is running

```bash
ps aux | grep main.py
```

### View ComfyUI logs

```bash
cd /workspace/ComfyUI
source comfyvenv/bin/activate
python main.py --listen 0.0.0.0 --port 8188
```

### Restart ComfyUI

```bash
pkill -f "python.*main.py"
/workspace/start.sh
```

## Persistence

Use a RunPod network volume mounted at `/workspace` to keep:

- ComfyUI installation
- All models
- Generated images
- Custom node configurations

Without a network volume, you'll need to reinstall after each pod restart.
