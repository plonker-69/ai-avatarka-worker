# AI-Avatarka - Minimal build, runtime model download
FROM hearmeman/comfyui-wan-template:v2

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install only essential dependencies
RUN pip install --no-cache-dir runpod~=1.7.9 gdown>=5.0.0

# Copy requirements and install
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Create directories
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/models/loras

# Copy project files (small files only)
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY lora/ /workspace/ComfyUI/models/loras/
COPY builder/ /workspace/builder/

# Create startup script that downloads models on first run
RUN cat > /startup.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
import subprocess
import urllib.request
from pathlib import Path

def download_model(url, path):
    """Download model if it doesn't exist"""
    if Path(path).exists():
        print(f"✅ {Path(path).name} already exists")
        return True
    
    print(f"⬇️ Downloading {Path(path).name}...")
    try:
        urllib.request.urlretrieve(url, path)
        print(f"✅ Downloaded {Path(path).name}")
        return True
    except Exception as e:
        print(f"❌ Failed to download {Path(path).name}: {e}")
        return False

def ensure_models():
    """Download required models if they don't exist"""
    models = {
        "/workspace/ComfyUI/models/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors": 
            "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors",
        "/workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors":
            "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors",
        "/workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors":
            "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
        "/workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors":
            "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
    }
    
    print("🚀 Checking/downloading required models...")
    for path, url in models.items():
        download_model(url, path)
    
    # Download LoRA files
    try:
        subprocess.run([sys.executable, "/workspace/builder/download_models.py"], check=False)
    except:
        print("⚠️ LoRA download had issues")

if __name__ == "__main__":
    ensure_models()
    
    # Start the handler
    sys.path.append("/workspace/src")
    from handler import handler
    import runpod
    runpod.serverless.start({"handler": handler})
EOF

# Copy handler
COPY src/handler.py /workspace/src/handler.py

RUN chmod +x /startup.py

WORKDIR /workspace
CMD ["python", "/startup.py"]