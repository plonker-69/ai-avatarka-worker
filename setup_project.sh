#!/bin/bash

# AI-Avatarka RunPod Serverless Worker - Project Setup Script
# Run this script to create the complete project structure

echo "🚀 Setting up AI-Avatarka Worker project structure..."

# Create main project directory
PROJECT_NAME="ai-avatarka-worker"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create directory structure
echo "📁 Creating directories..."
mkdir -p src
mkdir -p builder
mkdir -p workflow
mkdir -p lora
mkdir -p prompts
mkdir -p .github/workflows

echo "✅ Directory structure created!"

# Create placeholder files with basic content
echo "📄 Creating configuration files..."

# Dockerfile
cat > Dockerfile << 'EOF'
# AI-Avatarka RunPod Serverless Worker
# CUDA 12.8 Base Image
FROM runpod/pytorch:2.1.0-py3.10-cuda12.1.1-devel-ubuntu22.04

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Install ComfyUI and models during build
RUN python builder/install_comfyui.py
RUN python builder/download_models.py
RUN python builder/setup_custom_nodes.py

# Expose port for ComfyUI
EXPOSE 8188

# Set the handler as the entry point
CMD ["python", "src/handler.py"]
EOF

# test_input.json
cat > test_input.json << 'EOF'
{
  "input": {
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...",
    "effect": "ghostrider",
    "prompt": "Transform into an epic Ghost Rider with flaming skull",
    "negative_prompt": "bad quality, blurry, distorted",
    "steps": 10,
    "cfg": 6,
    "frames": 85,
    "fps": 16,
    "width": 720,
    "height": 720,
    "seed": -1
  }
}
EOF

# builder/download_models.py
cat > builder/download_models.py << 'EOF'
#!/usr/bin/env python3
"""
Download Wan 2.1 models and LoRA files for AI-Avatarka
Downloads from Google Drive during container build
"""

import os
import requests
import subprocess
import sys
from pathlib import Path
import time

def install_gdown():
    """Install gdown for Google Drive downloads"""
    try:
        import gdown
        print("✅ gdown already installed")
        return gdown
    except ImportError:
        print("📦 Installing gdown...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "gdown"])
        import gdown
        return gdown

def download_from_gdrive(file_id, destination, filename):
    """Download file from Google Drive using file ID"""
    gdown = install_gdown()
    
    print(f"🔄 Downloading {filename} from Google Drive...")
    
    # Google Drive direct download URL
    url = f"https://drive.google.com/uc?id={file_id}"
    
    try:
        gdown.download(url, str(destination), quiet=False)
        print(f"✅ Downloaded {filename}")
        return True
    except Exception as e:
        print(f"❌ Failed to download {filename}: {str(e)}")
        return False

def download_file_http(url, destination, filename):
    """Download file via HTTP with progress"""
    print(f"🔄 Downloading {filename}...")
    
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        downloaded = 0
        
        with open(destination, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\r📥 {filename}: {percent:.1f}%", end="")
        
        print(f"\n✅ Downloaded {filename}")
        return True
    except Exception as e:
        print(f"\n❌ Failed to download {filename}: {str(e)}")
        return False

def main():
    """Download all required models and LoRA files"""
    print("🚀 Setting up AI-Avatarka models and LoRA files...")
    
    # Create directories
    models_dir = Path("/workspace/ComfyUI/models")
    lora_dir = models_dir / "loras"
    checkpoints_dir = models_dir / "checkpoints"
    vae_dir = models_dir / "vae"
    text_encoder_dir = models_dir / "text_encoders"
    
    for directory in [models_dir, lora_dir, checkpoints_dir, vae_dir, text_encoder_dir]:
        directory.mkdir(parents=True, exist_ok=True)
    
    # Main Wan 2.1 Models (replace with your actual URLs)
    print("📦 Downloading Wan 2.1 base models...")
    
    base_models = {
        "wan2.1_i2v_480p_14B_bf16.safetensors": {
            "gdrive_id": "YOUR_WAN_MODEL_GDRIVE_ID",
            "destination": checkpoints_dir
        },
        "wan_2.1_vae.safetensors": {
            "gdrive_id": "YOUR_VAE_GDRIVE_ID", 
            "destination": vae_dir
        },
        "umt5-xxl-enc-bf16.safetensors": {
            "gdrive_id": "YOUR_T5_GDRIVE_ID",
            "destination": text_encoder_dir
        },
        "open-clip-xlm-roberta-large-vit-huge-14_visual_fp16.safetensors": {
            "gdrive_id": "YOUR_CLIP_GDRIVE_ID",
            "destination": text_encoder_dir
        }
    }
    
    # Download base models
    for filename, config in base_models.items():
        if config["gdrive_id"] != "YOUR_WAN_MODEL_GDRIVE_ID":  # Skip if not configured
            destination = config["destination"] / filename
            download_from_gdrive(config["gdrive_id"], destination, filename)
    
    # LoRA Files for Effects (Add your Google Drive file IDs here)
    print("🎭 Downloading LoRA effect files...")
    
    lora_files = {
        "ghostrider.safetensors": "YOUR_GHOSTRIDER_GDRIVE_ID",
        "son_goku.safetensors": "YOUR_SONGOKU_GDRIVE_ID", 
        "westworld.safetensors": "YOUR_WESTWORLD_GDRIVE_ID",
        "hulk.safetensors": "YOUR_HULK_GDRIVE_ID",
        "super_saian.safetensors": "YOUR_SUPERSAIAN_GDRIVE_ID",
        "jumpscare.safetensors": "YOUR_JUMPSCARE_GDRIVE_ID",
        "kamehameha.safetensors": "YOUR_KAMEHAMEHA_GDRIVE_ID",
        "melt_it.safetensors": "YOUR_MELTIT_GDRIVE_ID",
        "mindblown.safetensors": "YOUR_MINDBLOWN_GDRIVE_ID",
        "muscles.safetensors": "YOUR_MUSCLES_GDRIVE_ID",
        "crush_it.safetensors": "YOUR_CRUSHIT_GDRIVE_ID",
        "samurai.safetensors": "YOUR_SAMURAI_GDRIVE_ID",
        "fus_ro_dah.safetensors": "YOUR_FUSRODAH_GDRIVE_ID",
        "360.safetensors": "YOUR_360_GDRIVE_ID",
        "vip_50_epochs.safetensors": "YOUR_VIP_GDRIVE_ID",
        "puppy.safetensors": "YOUR_PUPPY_GDRIVE_ID",
        "snow_white.safetensors": "YOUR_SNOWWHITE_GDRIVE_ID"
    }
    
    # Download LoRA files
    success_count = 0
    total_count = len(lora_files)
    
    for filename, gdrive_id in lora_files.items():
        if gdrive_id and gdrive_id.startswith("YOUR_") == False:  # Skip placeholder IDs
            destination = lora_dir / filename
            if download_from_gdrive(gdrive_id, destination, filename):
                success_count += 1
        else:
            print(f"⚠️  Skipping {filename} - no Google Drive ID configured")
    
    print(f"\n🎉 Download complete! {success_count}/{total_count} LoRA files downloaded")
    
    # Verify downloads
    print("\n🔍 Verifying downloads...")
    for filename in lora_files.keys():
        file_path = lora_dir / filename
        if file_path.exists():
            size_mb = file_path.stat().st_size / (1024 * 1024)
            print(f"✅ {filename}: {size_mb:.1f} MB")
        else:
            print(f"❌ {filename}: Missing")
    
    print("\n✅ Model setup complete!")

if __name__ == "__main__":
    main()
EOF

# builder/install_comfyui.py
cat > builder/install_comfyui.py << 'EOF'
#!/usr/bin/env python3
"""
Install ComfyUI for AI-Avatarka
"""

import os
import subprocess
import sys
from pathlib import Path

def run_command(cmd, cwd=None):
    """Run shell command"""
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    print(result.stdout)

def main():
    """Install ComfyUI"""
    workspace = Path("/workspace")
    comfyui_path = workspace / "ComfyUI"
    
    print("🔄 Installing ComfyUI...")
    
    # Clone ComfyUI
    if not comfyui_path.exists():
        run_command(
            "git clone https://github.com/comfyanonymous/ComfyUI.git",
            cwd=workspace
        )
    
    # Install ComfyUI requirements
    requirements_path = comfyui_path / "requirements.txt"
    if requirements_path.exists():
        run_command(f"pip install -r {requirements_path}")
    
    # Create necessary directories
    (comfyui_path / "input").mkdir(exist_ok=True)
    (comfyui_path / "output").mkdir(exist_ok=True)
    (comfyui_path / "models").mkdir(exist_ok=True)
    (comfyui_path / "custom_nodes").mkdir(exist_ok=True)
    (comfyui_path / "workflow").mkdir(exist_ok=True)
    
    print("✅ ComfyUI installed successfully!")

if __name__ == "__main__":
    main()
EOF

# builder/setup_custom_nodes.py
cat > builder/setup_custom_nodes.py << 'EOF'
#!/usr/bin/env python3
"""
Setup custom nodes for ComfyUI
"""

import subprocess
import sys
from pathlib import Path

def install_custom_node(repo_url, node_name):
    """Install a custom node"""
    print(f"🔄 Installing {node_name}...")
    
    custom_nodes_dir = Path("/workspace/ComfyUI/custom_nodes")
    node_dir = custom_nodes_dir / node_name
    
    if not node_dir.exists():
        subprocess.run([
            "git", "clone", repo_url
        ], cwd=custom_nodes_dir, check=True)
    
    # Install requirements if they exist
    requirements_file = node_dir / "requirements.txt"
    if requirements_file.exists():
        subprocess.run([
            sys.executable, "-m", "pip", "install", "-r", str(requirements_file)
        ], check=True)
    
    print(f"✅ {node_name} installed!")

def main():
    """Install all required custom nodes"""
    custom_nodes = [
        ("https://github.com/kijai/ComfyUI-WanVideoWrapper.git", "ComfyUI-WanVideoWrapper"),
        ("https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git", "ComfyUI-VideoHelperSuite"),
        ("https://github.com/cubiq/ComfyUI_essentials.git", "ComfyUI_essentials")
    ]
    
    for repo_url, node_name in custom_nodes:
        install_custom_node(repo_url, node_name)
    
    print("✅ All custom nodes installed!")

if __name__ == "__main__":
    main()
EOF

# Create helper script for Google Drive setup
cat > setup_gdrive_ids.py << 'EOF'
#!/usr/bin/env python3
"""
Helper script to set up Google Drive file IDs in download_models.py
"""

import re
from pathlib import Path

def extract_file_id(url):
    """Extract file ID from Google Drive URL"""
    patterns = [
        r'/file/d/([a-zA-Z0-9_-]+)',
        r'id=([a-zA-Z0-9_-]+)',
        r'/d/([a-zA-Z0-9_-]+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None

def update_download_script(file_mapping):
    """Update the download_models.py script with actual file IDs"""
    script_path = Path("builder/download_models.py")
    
    if not script_path.exists():
        print("❌ builder/download_models.py not found!")
        return False
    
    # Read the current script
    with open(script_path, 'r') as f:
        content = f.read()
    
    # Update each file ID
    for filename, file_id in file_mapping.items():
        if file_id:
            # Replace the placeholder
            old_pattern = f'"{filename}": "YOUR_.*?"'
            new_replacement = f'"{filename}": "{file_id}"'
            content = re.sub(old_pattern, new_replacement, content)
    
    # Write back the updated script
    with open(script_path, 'w') as f:
        f.write(content)
    
    print("✅ download_models.py updated successfully!")
    return True

def main():
    """Interactive setup for Google Drive file IDs"""
    print("🔧 AI-Avatarka Google Drive Setup")
    print("=" * 50)
    print()
    print("This script will help you configure Google Drive downloads for LoRA files.")
    print("You'll need to provide Google Drive share URLs for each LoRA file.")
    print()
    
    lora_effects = [
        "ghostrider.safetensors",
        "son_goku.safetensors", 
        "westworld.safetensors",
        "hulk.safetensors",
        "super_saian.safetensors",
        "jumpscare.safetensors",
        "kamehameha.safetensors",
        "melt_it.safetensors",
        "mindblown.safetensors",
        "muscles.safetensors",
        "crush_it.safetensors",
        "samurai.safetensors",
        "fus_ro_dah.safetensors",
        "360.safetensors",
        "vip_50_epochs.safetensors",
        "puppy.safetensors",
        "snow_white.safetensors"
    ]
    
    file_mapping = {}
    
    print("📤 For each LoRA file, provide the Google Drive share URL:")
    print("Example: https://drive.google.com/file/d/1ABC123xyz456DEF/view")
    print("Or press Enter to skip...")
    print()
    
    for filename in lora_effects:
        effect_name = filename.replace('.safetensors', '').replace('_', ' ').title()
        url = input(f"🎭 {effect_name} ({filename}): ").strip()
        
        if url:
            file_id = extract_file_id(url)
            if file_id:
                file_mapping[filename] = file_id
                print(f"   ✅ File ID: {file_id}")
            else:
                print(f"   ❌ Could not extract file ID from URL")
                file_mapping[filename] = None
        else:
            print(f"   ⏭️  Skipping {filename}")
            file_mapping[filename] = None
        print()
    
    # Summary
    print("📋 Summary:")
    print("-" * 30)
    configured = sum(1 for fid in file_mapping.values() if fid)
    total = len(file_mapping)
    print(f"Configured: {configured}/{total} files")
    print()
    
    if configured > 0:
        proceed = input("🚀 Update download_models.py with these file IDs? (y/N): ").strip().lower()
        if proceed in ['y', 'yes']:
            if update_download_script(file_mapping):
                print()
                print("🎉 Setup complete!")
                print("You can now build your Docker container and the LoRA files will be downloaded automatically.")
            else:
                print("❌ Failed to update download script")
        else:
            print("❌ Setup cancelled")
    else:
        print("⚠️  No file IDs configured. Skipping update.")

if __name__ == "__main__":
    main()
EOF

chmod +x setup_gdrive_ids.py

# Create .gitignore to exclude large files
cat > .gitignore << 'EOF'
# Large model files - downloaded during build
*.safetensors
*.bin
*.ckpt
*.pth

# LoRA directory contents (downloaded from Google Drive)
lora/*.safetensors

# ComfyUI generated files
ComfyUI/
output/
input/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp

# Docker
.dockerignore

# Environment variables
.env
.env.local
EOF

# Create empty lora directory with README
mkdir -p lora
cat > lora/README.md << 'EOF'
# LoRA Files Directory

This directory contains LoRA (Low-Rank Adaptation) files for different transformation effects.

## How it works

LoRA files are downloaded automatically during Docker container build from Google Drive using the `builder/download_models.py` script.

## Available Effects

- `ghostrider.safetensors` - 🔥 Ghost Rider transformation
- `son_goku.safetensors` - ⚡ Son Goku Super Saiyan
- `westworld.safetensors` - 🤖 Westworld robot reveal
- `hulk.safetensors` - 💚 Hulk transformation
- And 13 more epic effects!

## Setup

1. Upload your LoRA files to Google Drive
2. Make them publicly accessible or use service account
3. Get the file IDs from the share URLs
4. Update `builder/download_models.py` with the correct Google Drive IDs

## File ID Format

Google Drive share URL: `https://drive.google.com/file/d/FILE_ID/view`
Use the `FILE_ID` part in the download script.

## Note

LoRA files are excluded from git (.gitignore) due to their large size (typically 100MB+ each).
EOF

# GitHub workflows
cat > .github/workflows/CI-test_handler.yml << 'EOF'
name: Test Handler

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Test handler imports
      run: |
        python -c "from src.handler import handler; print('✅ Handler imports successfully')"
    
    - name: Validate configurations
      run: |
        python -c "import json; json.load(open('worker-config.json')); print('✅ worker-config.json is valid')"
        python -c "import json; json.load(open('prompts/effects.json')); print('✅ effects.json is valid')"
EOF

cat > .github/workflows/CD-docker_dev.yml << 'EOF'
name: Build and Deploy Docker

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
EOF

# Create README
cat > README.md << 'EOF'
# 🎭 AI-Avatarka RunPod Serverless Worker

Transform portraits into stunning animated avatars with cinematic special effects using Wan 2.1.

## 🚀 Features

- **17 Epic Transformations**: Ghost Rider, Super Saiyan, Hulk, and more
- **Universal Workflow**: Single optimized pipeline for all effects
- **RunPod Serverless**: Scalable GPU-powered processing
- **High Quality Output**: 720x720 resolution, 16 FPS, 5-second videos
- **Smart Downloads**: LoRA files downloaded from Google Drive during build

## 📁 Project Structure

```
ai-avatarka-worker/
├── src/handler.py              # Main serverless handler
├── workflow/universal_i2v.json # Universal ComfyUI workflow
├── prompts/effects.json        # Effect configurations
├── lora/                       # LoRA files (downloaded during build)
├── builder/                    # Build-time setup scripts
└── .github/workflows/          # CI/CD pipelines
```

## 🛠️ Setup

### 1. Clone and Setup Project
```bash
git clone <your-repo>
cd ai-avatarka-worker
```

### 2. Configure Google Drive Downloads

The project downloads LoRA files from Google Drive during container build. You need to:

1. **Upload LoRA files to Google Drive**
2. **Make them publicly accessible** (Anyone with the link can view)
3. **Get the file IDs** from share URLs
4. **Update the download script**

#### Getting Google Drive File IDs

From a share URL like: `https://drive.google.com/file/d/1ABC123xyz456DEF/view`
The file ID is: `1ABC123xyz456DEF`

#### Update builder/download_models.py

Replace the placeholder IDs:

```python
lora_files = {
    "ghostrider.safetensors": "1ABC123xyz456DEF",  # Your actual file ID
    "son_goku.safetensors": "1XYZ789abc012GHI",    # Your actual file ID
    # ... etc
}
```

### 3. Build Docker Image
```bash
docker build -t ai-avatarka-worker:latest .
```

The build process will:
- Install ComfyUI and dependencies
- Download Wan 2.1 models 
- Download all LoRA files from Google Drive
- Set up custom nodes

### 4. Deploy to RunPod
- Upload to container registry (GHCR, Docker Hub, etc.)
- Create serverless endpoint
- Configure with `worker-config.json`

## 🎯 Usage

```json
{
  "input": {
    "image": "base64_encoded_image",
    "effect": "ghostrider",
    "prompt": "Epic transformation with flaming skull",
    "negative_prompt": "bad quality, artifacts"
  }
}
```

## 🔥 Available Effects

- 🔥 **Ghost Rider** - Flaming skull transformation
- ⚡ **Son Goku** - Super Saiyan power up
- 💚 **Hulk** - Green monster transformation
- 🤖 **Westworld** - Robotic face reveal
- ⚔️ **Samurai** - Warrior transformation
- 💪 **Muscles** - Show off physique
- 🌊 **Melt It** - Liquid transformation
- 💥 **Kamehameha** - Energy beam attack
- 👹 **Jumpscare** - Monster reveal
- 💣 **Mind Blown** - Head explosion
- 🏗️ **Crush It** - Hydraulic press effect
- 🌪️ **Fus Ro Dah** - Force push effect
- 🔄 **360 Rotation** - Spin around
- ⭐ **VIP** - Red carpet glamour
- 🐶 **Puppy** - Cute puppy swarm
- 🍎 **Snow White** - Disney princess
- 🌟 **Super Saiyan** - Golden energy aura

## 🏗️ Development

### Local Testing
```bash
python src/handler.py
```

### Add New Effects
1. Upload new LoRA file to Google Drive
2. Add Google Drive ID to `builder/download_models.py`
3. Add effect configuration to `prompts/effects.json`
4. Update `worker-config.json` options

### CI/CD
- Automated testing on push/PR
- Docker build and deployment on main branch
- Container registry integration

## 📋 Requirements

- **GPU**: CUDA 12.8+ 
- **VRAM**: 24GB+ recommended
- **Python**: 3.10+
- **Docker**: For containerization
- **RunPod**: Account for serverless deployment

## 🔧 Troubleshooting

### Google Drive Download Issues
- Ensure files are publicly accessible
- Check file IDs are correct
- Verify files aren't too large (>5GB limit)
- Use service account for private files

### Build Failures
- Check CUDA version compatibility
- Verify all dependencies in requirements.txt
- Ensure sufficient disk space for models

### Runtime Issues
- Check ComfyUI logs for errors
- Verify all LoRA files downloaded correctly
- Test with smaller images first

## 📦 File Sizes

- **Base Models**: ~14GB total
- **LoRA Files**: ~100MB each (17 effects = ~1.7GB)
- **Total Container**: ~20GB

---

Built with ❤️ for epic avatar transformations!
EOF

#!/bin/bash

# AI-Avatarka RunPod Serverless Worker - Project Setup Script
# Run this script to create the complete project structure

echo "🚀 Setting up AI-Avatarka Worker project structure..."

# Create main project directory
PROJECT_NAME="ai-avatarka-worker"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create directory structure
echo "📁 Creating directories..."
mkdir -p src
mkdir -p builder
mkdir -p workflow
mkdir -p lora
mkdir -p prompts
mkdir -p .github/workflows

echo "✅ Directory structure created!"

# Create placeholder files with basic content
echo "📄 Creating configuration files..."
