# ComfyUI Multi-App Workspace – Developer Conventions

This document outlines how to work in this repository from a developer point of view: build targets, runtime behavior, environment, dependency management, customization points, quality gates, and troubleshooting.

## Stack Overview

- **Base OS**: Ubuntu 22.04
- **GPU stack**: CUDA 12.4, stable PyTorch via upstream requirements
- **Python**: 3.12 (set as system default inside the image)
- **Package manager**: pip (dependencies pre-installed in Docker, apps installed at runtime)
- **Node.js**: 20.x (for Pinokio)
- **Tools bundled**: FileBrowser (port 8080), JupyterLab (port 8888), OpenSSH server (port 22), FFmpeg (NVENC), common CLI tools
- **Primary apps**: 
  - ComfyUI with 10 pre-configured custom nodes (port 8188)
  - Pinokio AI installer (port 42424)
  - Ollama local LLM server (port 11434)
  - Open WebUI for Ollama (port 3000)

## Repository Layout

**Repository**: `runpodapps`

- `Dockerfile` – Main image (CUDA 12.4)
- `start.sh` – Runtime bootstrap and app initialization
- `docker-bake.hcl` – Buildx bake targets (`regular`, `dev`, `devpush`)
- `README.md` – User-facing overview with build and deployment guide
- `docs/context.md` – This document

At runtime, the container uses:

- `/workspace/comfy/ComfyUI` – ComfyUI checkout and virtual environment (comfyvenv)
- `/workspace/comfy/comfyui_args.txt` – Optional line-delimited ComfyUI args
- `/workspace/comfy/filebrowser.db` – FileBrowser DB
- `/workspace/pinokio` – Pinokio installation
- `/workspace/ollama` – Ollama models and data
- `/workspace/open-webui` – Open WebUI installation and virtual environment (openwebuivenv)

## Build Targets

Use Docker Buildx Bake with the provided HCL file.

- `regular` (default production):
  - Dockerfile: `Dockerfile`
  - Tags: `jotinkumar/runpodapps:${TAG}` and `jotinkumar/runpodapps:latest` (TAG defaults to `slim`)
  - Platform: `linux/amd64`
  - Output: Pushes to registry
- `dev` (local testing):
  - Dockerfile: `Dockerfile`
  - Tag: `jotinkumar/runpodapps:dev`
  - Output: local docker image (not pushed)
- `devpush` (development push):
  - Dockerfile: `Dockerfile`
  - Tag: `jotinkumar/runpodapps:dev`
  - Output: Pushes to registry

Example commands:

```bash
# Build dev image locally for testing
docker buildx bake -f docker-bake.hcl dev

# Build and push production image with version tag
TAG=v1.0.0 docker buildx bake -f docker-bake.hcl regular --push

# Build and push dev image
docker buildx bake -f docker-bake.hcl devpush
```

Build args and env:

- `TAG` variable in `docker-bake.hcl` controls the tag suffix (default `slim`).
- Build uses BuildKit inline cache via `BUILDKIT_INLINE_CACHE=1` ARG.

## Runtime Behavior

Startup is handled by `start.sh`:

**Infrastructure Services:**
- Initializes SSH server. If `PUBLIC_KEY` is set, it is added to `~/.ssh/authorized_keys`; otherwise a random root password is generated and printed to logs.
- Exports selected env vars broadly to `/etc/environment`, PAM, and `~/.ssh/environment` for non-interactive shells.
- Initializes and starts FileBrowser on port 8080 (root `/workspace`). Default admin user is created on first run.
- Starts JupyterLab on port 8888, root at `/workspace`. Token set via `JUPYTER_PASSWORD` if provided.

**ComfyUI Setup:**
- Ensures `comfyui_args.txt` exists.
- Clones ComfyUI and 10 preselected custom nodes on first run into `/workspace/comfy`.
- Creates a Python 3.12 virtual environment (`comfyvenv`) with `--system-site-packages` to access pre-installed dependencies.
- Installs ComfyUI and custom node requirements using `pip`.
- Starts ComfyUI with fixed args `--listen 0.0.0.0 --port 8188` plus any custom args from `comfyui_args.txt`.

**Pinokio Setup:**
- Clones Pinokio repository to `/workspace/pinokio` on first run.
- Installs dependencies and starts Pinokio server on port 42424 (accessible at http://localhost:42424).

**Ollama Setup:**
- Verifies Ollama binary installation (pre-installed in Docker image).
- Sets `OLLAMA_MODELS` to `/workspace/ollama` for persistent model storage.
- Starts Ollama server on port 11434 in background.

**Open WebUI Setup:**
- Clones Open WebUI repository to `/workspace/open-webui` on first run.
- Creates a Python 3.12 virtual environment (`openwebuivenv`) with `--system-site-packages`.
- Installs Open WebUI requirements using `pip`.
- Starts Open WebUI on port 3000, connected to Ollama at http://localhost:11434.

## Ports

- 8188 – ComfyUI
- 42424 – Pinokio
- 11434 – Ollama API
- 3000 – Open WebUI
- 8080 – FileBrowser
- 8888 – JupyterLab
- 22 – SSH

All ports are exposed in the Dockerfile.

## Environment Variables

Recognized at runtime by the start scripts:

- `PUBLIC_KEY` – If provided, enables key-based SSH for root; otherwise a random password is generated and printed.
- `JUPYTER_PASSWORD` – If set, used as the JupyterLab token (no browser; root at `/workspace`).
- GPU/CUDA-related environment variables are propagated (`CUDA*`, `LD_LIBRARY_PATH`, `PYTHONPATH`, and `RUNPOD_*` vars if present in the environment).

## Dependency Management

**Architecture:**
- Dependencies are pre-installed in the Docker image (builder stage).
- Applications are cloned to `/workspace` at runtime for persistence and easy updates.

**Python Setup:**
- Python 3.12 is the default interpreter in the image.
- Virtual environments use `--system-site-packages` to access pre-installed dependencies while maintaining isolation.
- Package manager: `pip` (with `--no-cache-dir` for efficient installs).

**Virtual Environments:**
- ComfyUI: `/workspace/comfy/ComfyUI/comfyvenv`
- Open WebUI: `/workspace/open-webui/openwebuivenv`
- Both venvs have access to system-installed PyTorch and CUDA packages.

**Custom Nodes:**
- Repos are cloned into `ComfyUI/custom_nodes/`.
- On first run and subsequent starts, the script attempts to install each node's `requirements.txt`, run `install.py`, or `setup.py` if present.

**Pre-configured Custom Nodes (10 total):**

1. `ComfyUI-Manager` (ltdrdata/ComfyUI-Manager)
2. `ComfyUI-KJNodes` (kijai/ComfyUI-KJNodes)
3. `Civicomfy` (MoonGoblinDev/Civicomfy)
4. `ComfyUI-AnimateDiff-Evolved` (Kosinkadink/ComfyUI-AnimateDiff-Evolved)
5. `ComfyUI-VideoHelperSuite` (Kosinkadink/ComfyUI-VideoHelperSuite)
6. `ComfyUI_essentials` (cubiq/ComfyUI_essentials)
7. `ComfyUI-Impact-Pack` (ltdrdata/ComfyUI-Impact-Pack)
8. `ComfyUI_IPAdapter_plus` (cubiq/ComfyUI_IPAdapter_plus)
9. `ComfyUI-Advanced-ControlNet` (Kosinkadink/ComfyUI-Advanced-ControlNet)
10. `rgthree-comfy` (rgthree/rgthree-comfy)

## Customization Points

- **ComfyUI Args**: Edit `comfyui_args.txt` – add one CLI arg per line; comments starting with `#` are ignored. These are appended after fixed args.
- **Custom Nodes**: Add/remove by editing the `CUSTOM_NODES` array in `start.sh`, or pre-bake them into the Dockerfile.
- **System Packages**: Modify the Dockerfile `apt-get install` lines.
- **Python Packages**: 
  - Pre-install in Dockerfile builder stage for better performance.
  - Or extend installation blocks in `start.sh` after venv activation using `pip install --no-cache-dir`.
- **Additional Apps**: Follow the pattern used for Pinokio, Ollama, and Open WebUI:
  - Pre-install dependencies in Dockerfile.
  - Create setup and start functions in `start.sh`.
  - Clone app to `/workspace` for persistence.
  - Expose required ports in Dockerfile.

## Dev Conventions

- **Keep images lean**: Pre-install dependencies in Docker, but clone actual apps at runtime for easier updates and persistence.
- **Avoid changing ports**: They are referenced by external templates (RunPod/UI tooling).
- **Use Python 3.12**: Do not downgrade in scripts.
- **Virtual environments**: Use `--system-site-packages` to access pre-installed PyTorch/CUDA while maintaining app isolation.
- **Environment variables**: When adding new env vars needed by downstream processes, ensure they are exported in `export_env_vars()`.
- **Custom nodes**: Ensure idempotent installs - the loop checks for `requirements.txt`, `install.py`, and `setup.py`.
- **Shell scripting**: Keep `set -e` at top; prefer explicit guards; write idempotent steps safe to re-run.
- **Package manager**: Use `pip install --no-cache-dir` for runtime installs.

## Local Development Tips

- Use the `dev` target to build a locally loadable image without pushing:

  ```bash
  docker buildx bake -f docker-bake.hcl dev
  docker run --rm \
    -p 8188:8188 -p 42424:42424 -p 11434:11434 -p 3000:3000 \
    -p 8080:8080 -p 8888:8888 -p 2222:22 \
    -e PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
    -e JUPYTER_PASSWORD=yourtoken \
    -v "$PWD/workspace":/workspace \
    jotinkumar/runpodapps:dev
  ```

- Mount a host `workspace` directory to persist all apps, models, and configurations.
- Access services at:
  - ComfyUI: `http://localhost:8188`
  - Pinokio: `http://localhost:42424`
  - Ollama API: `http://localhost:11434`
  - Open WebUI: `http://localhost:3000`
  - FileBrowser: `http://localhost:8080`
  - JupyterLab: `http://localhost:8888`
  - SSH: `ssh -p 2222 root@localhost`

## Troubleshooting

**ComfyUI Issues:**
- Not reachable on port 8188:
  - Check `/workspace/comfy/comfyui.log` (tailing in foreground).
  - Ensure `comfyui_args.txt` doesn't contain invalid flags (comments with `#` are okay).
  - Verify custom nodes installed correctly - check logs for errors.

**Pinokio Issues:**
- Not starting:
  - Check Node.js installation: `node --version` should show v20.x.
  - Verify `/workspace/pinokio` exists and has write permissions.
  - Check logs for port conflicts on 42424.

**Ollama Issues:**
- Server not responding on port 11434:
  - Verify Ollama binary installed: `ollama --version`.
  - Check if process is running: `ps aux | grep ollama`.
  - Ensure `OLLAMA_MODELS=/workspace/ollama` is set.
  - Verify sufficient disk space for models.

**Open WebUI Issues:**
- Cannot connect on port 3000:
  - Check if Ollama is running first (Open WebUI depends on it).
  - Verify virtual environment created: `/workspace/open-webui/openwebuivenv`.
  - Check for Python package conflicts in logs.

**General Issues:**
- JupyterLab auth:
  - If `JUPYTER_PASSWORD` is unset, Jupyter may allow tokenless or default behavior. Set it explicitly if needed.
- SSH access:
  - If no `PUBLIC_KEY` is provided, a random root password is generated and printed to stdout. Check container logs.
  - Ensure port 22 is mapped from the host, e.g., `-p 2222:22`.
- GPU/CUDA issues:
  - Verify CUDA 12.4 compatibility with your GPU driver.
  - Check `nvidia-smi` output in container.
  - Ensure PyTorch can access GPU: `python -c "import torch; print(torch.cuda.is_available())"`.

## Release & Tagging

- Default tag base is `slim` via `TAG` in `docker-bake.hcl`.
- Regular builds create two tags: `jotinkumar/runpodapps:${TAG}` and `jotinkumar/runpodapps:latest`.
- Use semantic versioning for production releases: `TAG=v1.0.0 docker buildx bake -f docker-bake.hcl regular --push`.
- Keep `README.md` ports, features, and custom nodes list in sync when making changes.

## License

- GPLv3 as per `LICENSE`.
