# RunPod Multi-App Setup Guide

This guide shows you how to set up all applications on RunPod using the PyTorch base image and an installation script.

## Quick Start

### Option 1: Use Docker Hub Template (Recommended)

1. Go to [RunPod Templates](https://www.runpod.io/console/serverless/user/templates)
2. Click "New Template"
3. Configure:
   - **Template Name**: Multi-App Workspace
   - **Container Image**: `jotinkumar/runpodapps:v1.0.0`
   - **Container Disk**: 50 GB
   - **Volume Path**: `/workspace`
   - **Expose HTTP Ports**: 8188, 42424, 11434, 3000, 8080, 8888
   - **Expose TCP Ports**: 22
4. Save and deploy

### Option 2: Install on RunPod PyTorch Base Image

If you prefer to install on the RunPod PyTorch base image instead of using a pre-built Docker image:

#### Step 1: Create RunPod Pod

1. Go to [RunPod Pods](https://www.runpod.io/console/pods)
2. Click "Deploy"
3. Select **GPU**: Choose your preferred GPU
4. Select **Template**: `RunPod PyTorch 2.4.0`
   - Full image name: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
5. Configure:
   - **Container Disk**: 50 GB minimum
   - **Volume Disk**: 100 GB recommended
   - **Expose Ports**: 8188, 42424, 11434, 3000, 8080, 8888, 22
6. Click "Deploy"

#### Step 2: Connect to Pod

Once the pod is running:

```bash
# SSH into your pod
ssh root@<your-pod-ip> -p <ssh-port>
```

Or use the web terminal in RunPod console.

#### Step 3: Download and Run Installation Script

```bash
# Navigate to workspace
cd /workspace

# Download the installation script
wget https://raw.githubusercontent.com/JotinKumar/runpodapps/main/install.sh

# Make it executable
chmod +x install.sh

# Run the installation
./install.sh
```

The installation will take approximately 10-15 minutes depending on network speed.

#### Step 4: Start All Services

After installation completes:

```bash
# Start all services
/workspace/start.sh
```

The start script will:

- Start SSH server (port 22)
- Start JupyterLab (port 8888)
- Start FileBrowser (port 8080)
- Start ComfyUI (port 8188)
- Start Pinokio (port 42424)
- Start Ollama (port 11434)
- Start Open WebUI (port 3000)

#### Step 5: Access Services

Access your services through RunPod's port forwarding:

| Service | Port | URL |
|---------|------|-----|
| ComfyUI | 8188 | `https://<pod-id>-8188.proxy.runpod.net` |
| Pinokio | 42424 | `https://<pod-id>-42424.proxy.runpod.net` |
| Ollama | 11434 | `https://<pod-id>-11434.proxy.runpod.net` |
| Open WebUI | 3000 | `https://<pod-id>-3000.proxy.runpod.net` |
| FileBrowser | 8080 | `https://<pod-id>-8080.proxy.runpod.net` |
| JupyterLab | 8888 | `https://<pod-id>-8888.proxy.runpod.net` |

## Environment Variables

You can set these environment variables in RunPod template or pod settings:

```bash
# SSH Password (default: runpod123)
RUNPOD_POD_PASSWORD=your_secure_password

# FileBrowser Settings
FB_USERNAME=admin
FB_PASSWORD=admin
```

## Automatic Startup on RunPod

To make services start automatically when the pod starts:

### Method 1: Use start.sh as Docker CMD

1. In RunPod template settings, set:
   - **Docker Command**: `/workspace/start.sh`

### Method 2: Add to RunPod Volume

If you're using a persistent volume:

```bash
# Copy start.sh to volume
cp /workspace/start.sh /runpod-volume/start.sh

# Create autostart script
cat > /runpod-volume/autostart.sh << 'EOF'
#!/bin/bash
/runpod-volume/start.sh
EOF

chmod +x /runpod-volume/autostart.sh
```

Then configure RunPod to run `/runpod-volume/autostart.sh` on startup.

## Persistence

All application data is stored in `/workspace`:

```text
/workspace/
├── comfy/              # ComfyUI installation
│   └── ComfyUI/
│       ├── models/     # Store your models here
│       ├── input/      # Input images
│       └── output/     # Generated images
├── pinokio/            # Pinokio installation
├── ollama/             # Ollama models
├── open-webui/         # Open WebUI data
└── filebrowser.db      # FileBrowser database
```

**Important**: Use a RunPod network volume mounted at `/workspace` to persist your data across pod restarts.

## Troubleshooting

### Services Not Starting

Check logs:

```bash
# ComfyUI logs
cat /workspace/comfy/comfyui.log

# Pinokio logs
cat /workspace/pinokio/pinokio.log

# Ollama logs
cat /workspace/ollama/ollama.log

# Open WebUI logs
cat /workspace/open-webui/open-webui.log
```

### Port Already in Use

If a port is already in use, you can modify the start.sh script:

```bash
nano /workspace/start.sh
```

Find the service configuration and change the port number.

### Out of Disk Space

1. Check disk usage: `df -h`
2. Clean up Docker: `docker system prune -a`
3. Remove unused models from `/workspace/comfy/ComfyUI/models/`
4. Increase container disk in RunPod settings

### Installation Failed

If the installation script fails:

```bash
# Re-run the installation
cd /workspace
./install.sh

# Or install components individually
# See the install.sh script for individual commands
```

## Manual Installation Commands

If you prefer to install components individually:

### ComfyUI Only

```bash
cd /workspace/comfy
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
python3 -m venv --system-site-packages comfyvenv
source comfyvenv/bin/activate
pip install -r requirements.txt
```

### Pinokio Only

```bash
cd /workspace/pinokio
git clone https://github.com/pinokiocomputer/pinokio.git
cd pinokio
npm install
```

### Ollama Only

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Open WebUI Only

```bash
cd /workspace/open-webui
python3 -m venv --system-site-packages openwebuivenv
source openwebuivenv/bin/activate
pip install open-webui
```

## Resources

- **Repository**: <https://github.com/JotinKumar/runpodapps>
- **Docker Hub**: <https://hub.docker.com/r/jotinkumar/runpodapps>
- **RunPod Documentation**: <https://docs.runpod.io>
- **ComfyUI**: <https://github.com/comfyanonymous/ComfyUI>
- **Pinokio**: <https://github.com/pinokiocomputer/pinokio>
- **Ollama**: <https://ollama.com>
- **Open WebUI**: <https://github.com/open-webui/open-webui>

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review logs in `/workspace/*/logs/`
3. Open an issue on [GitHub](https://github.com/JotinKumar/runpodapps/issues)

## License

This project uses the MIT License. See LICENSE file for details.
