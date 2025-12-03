#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

COMFYUI_DIR="/workspace/comfy/ComfyUI"
COMFYUI_VENV="$COMFYUI_DIR/comfyvenv"
FILEBROWSER_CONFIG="/root/.config/filebrowser/config.json"
DB_FILE="/workspace/comfy/filebrowser.db"
PINOKIO_DIR="/workspace/pinokio"
OLLAMA_DIR="/workspace/ollama"
OPEN_WEBUI_DIR="/workspace/open-webui"
OPEN_WEBUI_VENV="$OPEN_WEBUI_DIR/openwebuivenv"

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                  #
# ---------------------------------------------------------------------------- #

# Setup SSH with optional key or random password
setup_ssh() {
    mkdir -p ~/.ssh
    
    # Generate host keys if they don't exist
    for type in rsa dsa ecdsa ed25519; do
        if [ ! -f "/etc/ssh/ssh_host_${type}_key" ]; then
            ssh-keygen -t ${type} -f "/etc/ssh/ssh_host_${type}_key" -q -N ''
            echo "${type^^} key fingerprint:"
            ssh-keygen -lf "/etc/ssh/ssh_host_${type}_key.pub"
        fi
    done

    # If PUBLIC_KEY is provided, use it
    if [[ $PUBLIC_KEY ]]; then
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh
    else
        # Generate random password if no public key
        RANDOM_PASS=$(openssl rand -base64 12)
        echo "root:${RANDOM_PASS}" | chpasswd
        echo "Generated random SSH password for root: ${RANDOM_PASS}"
    fi

    # Configure SSH to preserve environment variables
    echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

    # Start SSH service
    /usr/sbin/sshd
}

# Export environment variables
export_env_vars() {
    echo "Exporting environment variables..."
    
    # Create environment files
    ENV_FILE="/etc/environment"
    PAM_ENV_FILE="/etc/security/pam_env.conf"
    SSH_ENV_DIR="/root/.ssh/environment"
    
    # Backup original files
    cp "$ENV_FILE" "${ENV_FILE}.bak" 2>/dev/null || true
    cp "$PAM_ENV_FILE" "${PAM_ENV_FILE}.bak" 2>/dev/null || true
    
    # Clear files
    > "$ENV_FILE"
    > "$PAM_ENV_FILE"
    mkdir -p /root/.ssh
    > "$SSH_ENV_DIR"
    
    # Export to multiple locations for maximum compatibility
    printenv | grep -E '^RUNPOD_|^PATH=|^_=|^CUDA|^LD_LIBRARY_PATH|^PYTHONPATH' | while read -r line; do
        # Get variable name and value
        name=$(echo "$line" | cut -d= -f1)
        value=$(echo "$line" | cut -d= -f2-)
        
        # Add to /etc/environment (system-wide)
        echo "$name=\"$value\"" >> "$ENV_FILE"
        
        # Add to PAM environment
        echo "$name DEFAULT=\"$value\"" >> "$PAM_ENV_FILE"
        
        # Add to SSH environment file
        echo "$name=\"$value\"" >> "$SSH_ENV_DIR"
        
        # Add to current shell
        echo "export $name=\"$value\"" >> /etc/rp_environment
    done
    
    # Add sourcing to shell startup files
    echo 'source /etc/rp_environment' >> ~/.bashrc
    echo 'source /etc/rp_environment' >> /etc/bash.bashrc
    
    # Set permissions
    chmod 644 "$ENV_FILE" "$PAM_ENV_FILE"
    chmod 600 "$SSH_ENV_DIR"
}

# Start Jupyter Lab server for remote access
start_jupyter() {
    mkdir -p /workspace
    echo "Starting Jupyter Lab on port 8888..."
    nohup jupyter lab \
        --allow-root \
        --no-browser \
        --port=8888 \
        --ip=0.0.0.0 \
        --FileContentsManager.delete_to_trash=False \
        --FileContentsManager.preferred_dir=/workspace \
        --ServerApp.root_dir=/workspace \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --IdentityProvider.token="${JUPYTER_PASSWORD:-}" \
        --ServerApp.allow_origin=* &> /jupyter.log &
    echo "Jupyter Lab started"
}

# Setup and start Pinokio
setup_pinokio() {
    echo "Setting up Pinokio..."
    
    # Check if Pinokio is already installed
    if [ ! -d "$PINOKIO_DIR/pinokio" ]; then
        echo "First time setup: Installing Pinokio..."
        cd "$PINOKIO_DIR"
        
        # Clone Pinokio repository
        git clone https://github.com/pinokiocomputer/pinokio.git
        cd pinokio
        
        # Install dependencies
        npm install
        
        echo "Pinokio installation completed"
    else
        echo "Pinokio already installed"
    fi
}

start_pinokio() {
    echo "Starting Pinokio on port 42424..."
    cd "$PINOKIO_DIR/pinokio"
    
    # Start Pinokio in the background
    nohup npx electron . &> /workspace/pinokio/pinokio.log &
    
    echo "Pinokio started"
}

# Setup and start Ollama
setup_ollama() {
    echo "Setting up Ollama..."
    
    # Set Ollama home directory for models storage
    export OLLAMA_MODELS="$OLLAMA_DIR/models"
    mkdir -p "$OLLAMA_MODELS"
    
    echo "Ollama configured to store models in $OLLAMA_MODELS"
}

start_ollama() {
    echo "Starting Ollama on port 11434..."
    
    # Start Ollama server in the background
    export OLLAMA_MODELS="$OLLAMA_DIR/models"
    export OLLAMA_HOST="0.0.0.0:11434"
    nohup ollama serve &> /workspace/ollama/ollama.log &
    
    echo "Ollama started"
    
    # Wait a moment for Ollama to start
    sleep 3
}

# Setup and start Open WebUI
setup_open_webui() {
    echo "Setting up Open WebUI..."
    
    # Create virtual environment if not present
    if [ ! -d "$OPEN_WEBUI_VENV" ]; then
        echo "Creating virtual environment for Open WebUI..."
        python3.12 -m venv --system-site-packages "$OPEN_WEBUI_VENV"
        source "$OPEN_WEBUI_VENV/bin/activate"
        
        # Ensure pip is available
        python -m ensurepip --upgrade
        python -m pip install --upgrade pip
        
        # Install Open WebUI in venv (already pre-installed in system, but keep isolated)
        pip install --no-cache-dir open-webui
        
        echo "Open WebUI virtual environment created"
    else
        echo "Open WebUI virtual environment already exists"
    fi
}

start_open_webui() {
    echo "Starting Open WebUI on port 3000..."
    
    # Activate venv
    source "$OPEN_WEBUI_VENV/bin/activate"
    
    # Set environment variables
    export DATA_DIR="$OPEN_WEBUI_DIR/data"
    export OLLAMA_BASE_URL="http://127.0.0.1:11434"
    mkdir -p "$DATA_DIR"
    
    # Start Open WebUI in the background
    cd "$OPEN_WEBUI_DIR"
    nohup open-webui serve --host 0.0.0.0 --port 3000 &> /workspace/open-webui/open-webui.log &
    
    echo "Open WebUI started"
}

# ---------------------------------------------------------------------------- #
#                               Main Program                                     #
# ---------------------------------------------------------------------------- #

# Setup environment
setup_ssh
export_env_vars

# Initialize FileBrowser if not already done
if [ ! -f "$DB_FILE" ]; then
    echo "Initializing FileBrowser..."
    filebrowser config init
    filebrowser config set --address 0.0.0.0
    filebrowser config set --port 8080
    filebrowser config set --root /workspace
    filebrowser config set --auth.method=json
    filebrowser users add admin adminadmin12 --perm.admin
else
    echo "Using existing FileBrowser configuration..."
fi

# Start FileBrowser
echo "Starting FileBrowser on port 8080..."
nohup filebrowser &> /filebrowser.log &

start_jupyter

# Setup and start Pinokio
setup_pinokio
start_pinokio

# Setup and start Ollama
setup_ollama
start_ollama

# Setup and start Open WebUI
setup_open_webui
start_open_webui

# Create default comfyui_args.txt if it doesn't exist
ARGS_FILE="/workspace/comfy/comfyui_args.txt"
if [ ! -f "$ARGS_FILE" ]; then
    echo "# Add your custom ComfyUI arguments here (one per line)" > "$ARGS_FILE"
    echo "Created empty ComfyUI arguments file at $ARGS_FILE"
fi

# Setup ComfyUI if needed
if [ ! -d "$COMFYUI_DIR" ] || [ ! -d "$COMFYUI_VENV" ]; then
    echo "First time setup: Installing ComfyUI and dependencies..."
    
    # Clone ComfyUI if not present
    if [ ! -d "$COMFYUI_DIR" ]; then
        cd /workspace/comfy
        git clone https://github.com/comfyanonymous/ComfyUI.git
    fi
    
    # Install ComfyUI-Manager if not present
    if [ ! -d "$COMFYUI_DIR/custom_nodes/ComfyUI-Manager" ]; then
        echo "Installing ComfyUI-Manager..."
        mkdir -p "$COMFYUI_DIR/custom_nodes"
        cd "$COMFYUI_DIR/custom_nodes"
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git
    fi

    # Install additional custom nodes
    CUSTOM_NODES=(
        "https://github.com/kijai/ComfyUI-KJNodes"
        "https://github.com/MoonGoblinDev/Civicomfy"
        "https://github.com/MadiatorLabs/ComfyUI-RunpodDirect"
        "https://github.com/hayden-fr/ComfyUI-Model-Manager"
        "https://github.com/WASasquatch/was-node-suite-comfyui"
        "https://github.com/cubiq/ComfyUI_essentials"
        "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
        "https://github.com/rgthree/rgthree-comfy"
        "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes"
    )

    for repo in "${CUSTOM_NODES[@]}"; do
        repo_name=$(basename "$repo")
        if [ ! -d "$COMFYUI_DIR/custom_nodes/$repo_name" ]; then
            echo "Installing $repo_name..."
            cd "$COMFYUI_DIR/custom_nodes"
            git clone "$repo"
        fi
    done
    
    # Create and setup virtual environment if not present
    if [ ! -d "$COMFYUI_VENV" ]; then
        cd $COMFYUI_DIR
        # Create venv with access to system packages (torch, numpy, etc. pre-installed in image)
        python3.12 -m venv --system-site-packages $COMFYUI_VENV
        source $COMFYUI_VENV/bin/activate

        # Ensure pip is available in the venv (needed for ComfyUI-Manager)
        python -m ensurepip --upgrade
        python -m pip install --upgrade pip

        echo "Base packages (torch, numpy, etc.) available from system site-packages"
        echo "Installing custom node dependencies..."

        # Install dependencies for all custom nodes
        cd "$COMFYUI_DIR/custom_nodes"
        for node_dir in */; do
            if [ -d "$node_dir" ]; then
                echo "Checking dependencies for $node_dir..."
                cd "$COMFYUI_DIR/custom_nodes/$node_dir"
                
                # Check for requirements.txt
                if [ -f "requirements.txt" ]; then
                    echo "Installing requirements.txt for $node_dir"
                    pip install --no-cache-dir -r requirements.txt
                fi

                # Check for install.py
                if [ -f "install.py" ]; then
                    echo "Running install.py for $node_dir"
                    python install.py
                fi

                # Check for setup.py
                if [ -f "setup.py" ]; then
                    echo "Running setup.py for $node_dir"
                    pip install --no-cache-dir -e .
                fi
            fi
        done
    fi
else
    # Just activate the existing venv
    source $COMFYUI_VENV/bin/activate

    echo "Checking for custom node dependencies..."

    # Install dependencies for all custom nodes
    cd "$COMFYUI_DIR/custom_nodes"
    for node_dir in */; do
        if [ -d "$node_dir" ]; then
            echo "Checking dependencies for $node_dir..."
            cd "$COMFYUI_DIR/custom_nodes/$node_dir"
            
            # Check for requirements.txt
            if [ -f "requirements.txt" ]; then
                echo "Installing requirements.txt for $node_dir"
                pip install --no-cache-dir -r requirements.txt
            fi
            
            # Check for install.py
            if [ -f "install.py" ]; then
                echo "Running install.py for $node_dir"
                python install.py
            fi
            
            # Check for setup.py
            if [ -f "setup.py" ]; then
                echo "Running setup.py for $node_dir"
                pip install --no-cache-dir -e .
            fi
        fi
    done
fi

# Start ComfyUI with custom arguments if provided
cd $COMFYUI_DIR
FIXED_ARGS="--listen 0.0.0.0 --port 8188"
if [ -s "$ARGS_FILE" ]; then
    # File exists and is not empty, combine fixed args with custom args
    CUSTOM_ARGS=$(grep -v '^#' "$ARGS_FILE" | tr '\n' ' ')
    if [ ! -z "$CUSTOM_ARGS" ]; then
        echo "Starting ComfyUI with additional arguments: $CUSTOM_ARGS"
        nohup python main.py $FIXED_ARGS $CUSTOM_ARGS &> /workspace/comfy/comfyui.log &
    else
        echo "Starting ComfyUI with default arguments"
        nohup python main.py $FIXED_ARGS &> /workspace/comfy/comfyui.log &
    fi
else
    # File is empty, use only fixed args
    echo "Starting ComfyUI with default arguments"
    nohup python main.py $FIXED_ARGS &> /workspace/comfy/comfyui.log &
fi

# Tail the log file
tail -f /workspace/comfy/comfyui.log
