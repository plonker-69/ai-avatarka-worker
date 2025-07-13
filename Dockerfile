# AI-Avatarka - RunPod Network Volume Approach
FROM hearmeman/comfyui-wan-template:v2

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install minimal dependencies  
RUN pip install --no-cache-dir runpod~=1.7.9 gdown>=5.0.0

# Copy and install requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Create local model directories (will be symlinked to volume)
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/models/loras

# Copy project files (small files only - no models!)
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY lora/ /workspace/ComfyUI/models/loras/
COPY builder/ /workspace/builder/
COPY src/handler.py /workspace/src/handler.py

# Create the smart startup script
RUN cat > /workspace/volume_startup.py << 'EOF'
#!/usr/bin/env python3
"""
AI-Avatarka RunPod Volume Startup
Downloads models to network volume on first run, then uses cached versions
"""
import os
import sys
import json
import subprocess
import urllib.request
import time
import hashlib
from pathlib import Path

# RunPod volume paths
VOLUME_PATH = Path("/runpod-volume")
MODELS_CACHE = VOLUME_PATH / "ai-avatarka-models"
COMFYUI_MODELS = Path("/workspace/ComfyUI/models")

# Model definitions
MODELS = {
    "diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors",
        "size": 27.8
    },
    "vae/wan_2.1_vae.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors",
        "size": 0.254
    },
    "text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
        "size": 2.5
    },
    "clip_vision/clip_vision_h.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors",
        "size": 1.26
    }
}

def log(msg, level="INFO"):
    print(f"[{time.strftime('%H:%M:%S')}] [{level}] {msg}")

def check_volume():
    """Check if RunPod volume is mounted"""
    if not VOLUME_PATH.exists():
        log("❌ RunPod volume not found! Make sure you mounted network storage to /runpod-volume", "ERROR")
        return False
    
    # Test write access
    try:
        test_file = VOLUME_PATH / "test_write"
        test_file.write_text("test")
        test_file.unlink()
        log(f"✅ RunPod volume accessible at {VOLUME_PATH}")
        return True
    except Exception as e:
        log(f"❌ Volume not writable: {e}", "ERROR") 
        return False

def download_model(url, dest_path, expected_size):
    """Download model with progress"""
    log(f"⬇️ Downloading {dest_path.name} ({expected_size}GB)...")
    
    try:
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        
        def progress(block, block_size, total):
            if total > 0:
                percent = (block * block_size / total) * 100
                gb_downloaded = (block * block_size) / (1024**3)
                if block % 1000 == 0:  # Log every ~8MB
                    log(f"Progress: {percent:.1f}% ({gb_downloaded:.2f}GB)")
        
        urllib.request.urlretrieve(url, dest_path, progress)
        
        # Verify download
        actual_size = dest_path.stat().st_size / (1024**3)
        if abs(actual_size - expected_size) / expected_size < 0.1:
            log(f"✅ Downloaded {dest_path.name} ({actual_size:.2f}GB)")
            return True
        else:
            log(f"❌ Size mismatch: {actual_size:.2f}GB vs {expected_size:.2f}GB")
            dest_path.unlink()
            return False
            
    except Exception as e:
        log(f"❌ Download failed: {e}", "ERROR")
        if dest_path.exists():
            dest_path.unlink()
        return False

def setup_models():
    """Setup models - download to volume if needed, create symlinks"""
    log("🚀 Setting up AI-Avatarka models...")
    
    if not check_volume():
        return False
    
    # Create cache directory
    MODELS_CACHE.mkdir(parents=True, exist_ok=True)
    
    success = True
    for model_path, config in MODELS.items():
        cached_file = MODELS_CACHE / model_path
        local_file = COMFYUI_MODELS / model_path
        
        # Check if already cached
        if cached_file.exists():
            size_gb = cached_file.stat().st_size / (1024**3)
            expected_gb = config["size"]
            
            if abs(size_gb - expected_gb) / expected_gb < 0.1:
                log(f"✅ {cached_file.name} cached ({size_gb:.2f}GB)")
            else:
                log(f"⚠️ {cached_file.name} corrupted, re-downloading...")
                cached_file.unlink()
                if not download_model(config["url"], cached_file, config["size"]):
                    success = False
                    continue
        else:
            # Download to cache
            if not download_model(config["url"], cached_file, config["size"]):
                success = False
                continue
        
        # Create symlink
        local_file.parent.mkdir(parents=True, exist_ok=True)
        if local_file.exists() or local_file.is_symlink():
            local_file.unlink()
        
        try:
            local_file.symlink_to(cached_file)
            log(f"🔗 Linked {local_file.name}")
        except Exception as e:
            log(f"❌ Symlink failed: {e}", "ERROR")
            success = False
    
    if success:
        # Show cache stats
        total_gb = sum(config["size"] for config in MODELS.values())
        log(f"📊 Total models cached: {total_gb:.1f}GB")
        log("✅ All models ready!")
    
    return success

def download_loras():
    """Download LoRA files (non-critical)"""
    try:
        log("🎭 Downloading LoRA files...")
        if Path("/workspace/builder/download_models.py").exists():
            result = subprocess.run([
                sys.executable, "/workspace/builder/download_models.py"
            ], timeout=1800, capture_output=True, text=True)
            
            if result.returncode == 0:
                log("✅ LoRA files downloaded")
            else:
                log("⚠️ Some LoRA downloads failed")
        else:
            log("⚠️ LoRA download script not found")
    except Exception as e:
        log(f"⚠️ LoRA download error: {e}")

def start_handler():
    """Start the RunPod handler"""
    log("🎬 Starting AI-Avatarka handler...")
    
    try:
        sys.path.append("/workspace/src")
        from handler import handler
        import runpod
        
        log("✅ Handler loaded")
        log("🚀 Starting RunPod serverless...")
        runpod.serverless.start({"handler": handler})
        
    except Exception as e:
        log(f"❌ Handler error: {e}", "ERROR")
        raise

if __name__ == "__main__":
    log("=" * 50)
    log("AI-AVATARKA VOLUME STARTUP")
    log("=" * 50)
    
    try:
        # Setup models (download to volume if needed)
        if not setup_models():
            log("❌ Model setup failed", "ERROR")
            sys.exit(1)
        
        # Download LoRAs
        download_loras()
        
        # Start handler
        start_handler()
        
    except KeyboardInterrupt:
        log("Interrupted")
        sys.exit(1)
    except Exception as e:
        log(f"❌ Fatal error: {e}", "ERROR")
        sys.exit(1)
EOF

RUN chmod +x /workspace/volume_startup.py

WORKDIR /workspace
CMD ["python", "/workspace/volume_startup.py"]