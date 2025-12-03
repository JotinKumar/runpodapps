# ComfyUI for RunPod

Automated installation script for ComfyUI on RunPod with PyTorch and CUDA support.

## Features

- ✅ One-command installation
- ✅ Isolated Python virtual environment
- ✅ PyTorch 2.6.0 + CUDA 12.4
- ✅ 9 pre-configured custom nodes
- ✅ Auto-configured xformers and ffmpeg
- ✅ Persistent storage support

## Requirements

- RunPod Pod with NVIDIA GPU
- Base Image: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- Network Volume at `/workspace` (recommended for persistence)

## Quick Start

### Installation

SSH into your RunPod pod and run:

```bash
cd /workspace && wget https://raw.githubusercontent.com/JotinKumar/runpodapps/main/install.sh && chmod +x install.sh && ./install.sh
```

⏱️ Installation takes approximately 10-15 minutes.

### Starting ComfyUI

```bash
wget https://raw.githubusercontent.com/JotinKumar/runpodapps/main/start.sh && chmod +x start.sh && ./start.sh
```

🌐 Access ComfyUI at: `https://<pod-id>-8188.proxy.runpod.net`

## What's Included

### Core Components

- **ComfyUI** (latest from GitHub)
- **PyTorch 2.6.0** with CUDA 12.4 support
- **xformers** (optimized for memory efficiency)
- **Virtual Environment** at `/workspace/ComfyUI/comfyvenv`

### Custom Nodes (9 Pre-installed)

1. **ComfyUI-Manager** - Node package manager
2. **ComfyUI-KJNodes** - Essential utility nodes
3. **Civicomfy** - CivitAI integration
4. **ComfyUI-Model-Manager** - Model management
5. **was-node-suite-comfyui** - WAS Node Suite
6. **ComfyUI_essentials** - Essential nodes collection
7. **ComfyUI-Impact-Pack** - Advanced image processing
8. **rgthree-comfy** - Power user nodes
9. **ComfyUI_Comfyroll_CustomNodes** - Creative tools

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

💾 **Important**: Mount a RunPod network volume at `/workspace` to persist:

- ✅ ComfyUI installation
- ✅ Virtual environment and packages
- ✅ Models (checkpoints, LoRAs, etc.)
- ✅ Generated images and workflows
- ✅ Custom node configurations

⚠️ **Without a network volume**, all data is lost on pod restart and requires reinstallation.

## Support

- **Repository**: [github.com/JotinKumar/runpodapps](https://github.com/JotinKumar/runpodapps)
- **Issues**: [Report bugs or request features](https://github.com/JotinKumar/runpodapps/issues)
- **ComfyUI Docs**: [github.com/comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI)

## License

MIT License - See [LICENSE](LICENSE) file for details.

This project provides installation scripts for ComfyUI and related components. Each installed component retains its original license.
