# ComfyUI Multi-App Template for RunPod

Complete AI workspace with ComfyUI, Pinokio, Ollama, and Open WebUI - optimized for RunPod deployment.

## 🚀 Features

- **ComfyUI**: Node-based Stable Diffusion UI with 10+ pre-installed custom nodes
- **Pinokio**: AI application installer and manager
- **Ollama**: Local LLM server (models stored persistently)
- **Open WebUI**: Modern web interface for Ollama
- **FileBrowser**: Web-based file management
- **JupyterLab**: Interactive Python environment
- **SSH Access**: Full terminal access with key or password auth

All apps run simultaneously with isolated virtual environments and persistent storage.

## 📋 Quick Start

First startup takes 5-10 minutes to clone repositories and set up environments. Subsequent starts are near-instant as everything persists in `/workspace`.

### Environment Variables (Optional)

- `PUBLIC_KEY`: Your SSH public key for key-based authentication
- `JUPYTER_PASSWORD`: Password/token for JupyterLab access

## 🌐 Service Access

| Port | Service | Credentials |
|------|---------|-------------|
| `8188` | ComfyUI | No auth |
| `42424` | Pinokio | No auth |
| `11434` | Ollama API | No auth |
| `3000` | Open WebUI | Create account on first visit |
| `8080` | FileBrowser | `admin` / `adminadmin12` |
| `8888` | JupyterLab | Token via `JUPYTER_PASSWORD` |
| `22` | SSH | Key via `PUBLIC_KEY` or check logs |

## 📦 Pre-installed ComfyUI Custom Nodes

1. **ComfyUI-Manager** - Package manager for custom nodes
2. **ComfyUI-KJNodes** - Utility nodes collection
3. **Civicomfy** - CivitAI integration
4. **ComfyUI-RunpodDirect** - RunPod-specific utilities
5. **ComfyUI-Model-Manager** - Model management tools
6. **was-node-suite-comfyui** - WAS suite utilities
7. **ComfyUI_essentials** - Essential node collection
8. **ComfyUI-Impact-Pack** - Advanced processing nodes
9. **rgthree-comfy** - Quality of life improvements
10. **ComfyUI_Comfyroll_CustomNodes** - Creative tools

## ⚙️ ComfyUI Custom Arguments

Edit `/workspace/comfy/comfyui_args.txt` (one argument per line):

```text
--max-batch-size 8
--preview-method auto
--highvram
```

Restart ComfyUI for changes to take effect.

## 📁 Directory Structure

```text
/workspace/
├── comfy/
│   ├── ComfyUI/          # ComfyUI installation
│   ├── comfyui_args.txt  # Custom arguments
│   └── filebrowser.db    # FileBrowser database
├── pinokio/              # Pinokio installation
├── ollama/
│   └── models/           # Ollama models storage
└── open-webui/
    └── data/             # Open WebUI data
```

All data persists across container restarts when using volume mounts.

---

## 🔨 Building & Deployment

### Prerequisites

- Docker with BuildKit enabled
- Docker Hub account (for pushing images)
- RunPod account (for template deployment)

### Build Commands

#### 1. Build for Local Testing

```bash
# Build dev image locally
docker buildx bake -f docker-bake.hcl dev

# Run locally for testing
docker run --rm -it --gpus all \
  -p 8188:8188 -p 42424:42424 -p 11434:11434 \
  -p 3000:3000 -p 8080:8080 -p 8888:8888 -p 2222:22 \
  -v comfyui-workspace:/workspace \
  -e PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  -e JUPYTER_PASSWORD=yourtoken \
  yourusername/runpodapps:dev
```

#### 2. Build & Push Production Image

```bash
# Login to Docker Hub
docker login

# Build and push with version tag
TAG=v1.0.0 docker buildx bake -f docker-bake.hcl regular --push

# Or build and push latest
docker buildx bake -f docker-bake.hcl regular --push
```

This creates two tags:

- `yourusername/runpodapps:v1.0.0` (or your TAG value)
- `yourusername/runpodapps:latest`

**Note:** Update `docker-bake.hcl` to use your Docker Hub username instead of `yourusername/runpodapps`.

#### 3. Build Multi-Platform (Optional)

```bash
# Build for both amd64 and arm64
docker buildx create --use --name multiplatform
docker buildx bake -f docker-bake.hcl regular --push --set "*.platform=linux/amd64,linux/arm64"
```

### Alternative: Manual Build

```bash
# Build the image
docker build -t yourusername/runpodapps:latest .

# Tag with version
docker tag yourusername/runpodapps:latest yourusername/runpodapps:v1.0.0

# Push to Docker Hub
docker push yourusername/runpodapps:latest
docker push yourusername/runpodapps:v1.0.0
```

---

## 🎯 Creating a RunPod Template

### Step 1: Prepare Your Image

1. Build and push your image to Docker Hub (see above)
2. Verify the image is public or accessible to RunPod
3. Note your full image name: `yourusername/runpodapps:latest`

### Step 2: Create Template on RunPod

1. Go to [RunPod Templates](https://www.runpod.io/console/user/templates)
2. Click **"New Template"**

### Step 3: Configure Template Settings

#### Basic Settings

- **Template Name**: `Multi-App Workspace`
- **Template Type**: Select **"Docker"**
- **Container Image**: `yourusername/runpodapps:v1.0.0`

#### Container Configuration

- **Container Disk**: `50 GB` (minimum, increase for models)
- **Volume Path**: `/workspace`

#### Expose HTTP Ports

Add these ports (format: `port/http` with name):

| Port | Name |
|------|------|
| `8188` | ComfyUI |
| `42424` | Pinokio |
| `11434` | Ollama |
| `3000` | OpenWebUI |
| `8080` | FileBrowser |
| `8888` | JupyterLab |

#### Expose TCP Ports

```text
22
```

#### Environment Variables (SSH/Jupyter)

| Variable | Value | Description |
|----------|-------|-------------|
| `JUPYTER_PASSWORD` | `your-token` | JupyterLab access token |
| `PUBLIC_KEY` | `ssh-rsa AAAA...` | Your SSH public key |

### Step 4: Advanced Settings (Optional)

- **Docker Command**: Leave empty (uses ENTRYPOINT from Dockerfile)
- **Registry Auth**: Add if using private Docker Hub registry
- **Start Jupyter**: No (already handled by start script)
- **Start SSH**: No (already handled by start script)

### Step 5: Save & Deploy

1. Click **"Save Template"**
2. Go to **"Pods"** → **"+ Deploy"**
3. Select your GPU type
4. Choose your template from **"My Templates"**
5. Set **"Volume Size"** (recommend 50GB+ for models)
6. Click **"Deploy"**

### Step 6: Access Your Pod

1. Wait for pod to reach "Running" state (first start: 5-10 min)
2. Click **"Connect"** on your pod
3. Access services via:
   - **HTTP Services**: Click port buttons (8188, 42424, etc.)
   - **SSH**: Use provided SSH command or connection details
   - **JupyterLab**: Port 8888 button

### Step 7: Verify Installation

Check logs for successful startup messages:

```text
✓ ComfyUI started
✓ Pinokio started
✓ Ollama started
✓ Open WebUI started
[ComfyUI-Manager] All startup tasks have been completed
```

---

## 🔧 Troubleshooting

### Services Not Starting

Check logs in `/workspace`:

- ComfyUI: `/workspace/comfy/comfyui.log`
- Pinokio: `/workspace/pinokio/pinokio.log`
- Ollama: `/workspace/ollama/ollama.log`
- Open WebUI: `/workspace/open-webui/open-webui.log`

### Port Already in Use

If running multiple pods, ensure ports don't conflict or use RunPod's automatic port mapping.

### Out of Disk Space

Increase volume size in pod settings. Models can be large (2-20GB each).

### SSH Connection Issues

- Check logs for generated password: `docker logs <container-id> | grep "SSH password"`
- Verify `PUBLIC_KEY` environment variable is set correctly
- Ensure port 22 is exposed in template

### ComfyUI Custom Nodes Failing

Some nodes may need additional dependencies. Install via:

1. SSH into pod
2. Activate venv: `source /workspace/comfy/ComfyUI/comfyvenv/bin/activate`
3. Install packages: `pip install <package-name>`

---

## 📝 Development

### Project Structure

```text
.
├── Dockerfile              # Multi-stage build
├── docker-bake.hcl        # Build configuration
├── start.sh               # Startup script
├── README.md              # This file
├── LICENSE                # GPLv3
└── docs/
    └── context.md         # Developer documentation
```

### Key Design Decisions

- **Multi-stage build**: Separates dependency installation from runtime
- **System-site-packages**: venvs access pre-installed PyTorch (2GB+)
- **Runtime cloning**: Apps cloned to `/workspace` for easy updates
- **Separate venvs**: Each Python app isolated (comfyvenv, openwebuivenv)

### Updating Custom Nodes List

Edit both files:

1. `Dockerfile` - Builder stage (for dependencies)
2. `start.sh` - CUSTOM_NODES array (for runtime installation)

---

## 📄 License

GPLv3 - See [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Issues and pull requests welcome! Please ensure:

- Dockerfile builds successfully
- start.sh passes `bash -n` syntax check
- All services start correctly in test pod

## 📞 Support

For issues specific to this template, open an issue on GitHub.
For RunPod platform issues, contact [RunPod Support](https://www.runpod.io/support).
