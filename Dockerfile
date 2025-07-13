# AI-Avatarka - RunPod Network Storage Approach
FROM hearmeman/comfyui-wan-template:v2

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI" \
    RUNPOD_VOLUME_PATH="/runpod-volume"

# Install dependencies
RUN pip install --no-cache-dir runpod~=1.7.9 gdown>=5.0.0

# Copy and install requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Create local model directories (will be symlinked to network storage)
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/models/loras

# Copy project files
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY lora/ /workspace/ComfyUI/models/loras/
COPY builder/ /workspace/builder/
COPY src/handler.py /workspace/src/handler.py

# Create the network storage startup script
RUN cat > /workspace/network_storage_startup.py << 'EOF'
#!/usr/bin/env python3
"""
AI-Avatarka RunPod Network Storage Smart Startup
Downloads models to network storage once, then reuses them forever
"""
import os
import sys
import json
import subprocess
import urllib.request
import time
import shutil
from pathlib import Path

# RunPod network volume path (mounted automatically)
VOLUME_PATH = Path(os.environ.get("RUNPOD_VOLUME_PATH", "/runpod-volume"))
MODELS_CACHE_PATH = VOLUME_PATH / "ai-avatarka-models"
COMFYUI_MODELS_PATH = Path("/workspace/ComfyUI/models")

# Model configuration
MODELS_CONFIG = {
    "diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors",
        "size_gb": 27.8,
        "critical": True
    },
    "vae/wan_2.1_vae.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors",
        "size_gb": 0.254,
        "critical": True
    },
    "text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
        "size_gb": 2.5,
        "critical": True
    },
    "clip_vision/clip_vision_h.safetensors": {
        "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors",
        "size_gb": 1.26,
        "critical": True
    }
}

def log(message, level="INFO"):
    """Timestamped logging"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{level}] {message}")

def check_network_storage():
    """Check if RunPod network storage is available"""
    if not VOLUME_PATH.exists():
        log(f"❌ Network storage not found at {VOLUME_PATH}", "ERROR")
        log("Make sure RunPod Network Storage is mounted!", "ERROR")
        return False
    
    # Test write access
    try:
        test_file = VOLUME_PATH / "test_write"
        test_file.write_text("test")
        test_file.unlink()
        log(f"✅ Network storage accessible at {VOLUME_PATH}")
        return True
    except Exception as e:
        log(f"❌ Network storage not writable: {e}", "ERROR")
        return False

def download_model(url, cache_path, expected_size_gb):
    """Download model with progress and retries"""
    max_retries = 3
    
    for attempt in range(max_retries):
        try:
            log(f"Downloading {cache_path.name} (attempt {attempt + 1}/{max_retries})")
            log(f"Size: {expected_size_gb}GB, URL: {url}")
            
            # Create parent directory
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Download with progress
            def progress_hook(block_num, block_size, total_size):
                if total_size > 0:
                    downloaded = block_num * block_size
                    percent = (downloaded / total_size) * 100
                    if downloaded % (500 * 1024 * 1024) == 0:  # Every 500MB
                        log(f"Progress: {percent:.1f}% ({downloaded / (1024**3):.2f}GB)")
            
            urllib.request.urlretrieve(url, cache_path, progress_hook)
            
            # Verify download
            if cache_path.exists():
                actual_size_gb = cache_path.stat().st_size / (1024**3)
                if abs(actual_size_gb - expected_size_gb) / expected_size_gb < 0.1:
                    log(f"✅ Downloaded {cache_path.name} ({actual_size_gb:.2f}GB)")
                    return True
                else:
                    log(f"❌ Size mismatch: {actual_size_gb:.2f}GB vs expected {expected_size_gb:.2f}GB")
                    cache_path.unlink()
            
        except Exception as e:
            log(f"❌ Download attempt {attempt + 1} failed: {e}", "ERROR")
            if cache_path.exists():
                cache_path.unlink()
        
        if attempt < max_retries - 1:
            log("Retrying in 10 seconds...")
            time.sleep(10)
    
    return False

def setup_models():
    """Download models to network storage and setup symlinks"""
    log("🚀 Setting up AI-Avatarka models with network storage")
    
    # Check network storage
    if not check_network_storage():
        log("❌ Network storage setup failed", "ERROR")
        return False
    
    # Create models cache directory
    MODELS_CACHE_PATH.mkdir(parents=True, exist_ok=True)
    log(f"📁 Models cache directory: {MODELS_CACHE_PATH}")
    
    # Check/download each model
    missing_critical = []
    
    for model_path, config in MODELS_CONFIG.items():
        cache_file = MODELS_CACHE_PATH / model_path
        local_file = COMFYUI_MODELS_PATH / model_path
        
        # Check if model exists in cache
        if cache_file.exists():
            actual_size_gb = cache_file.stat().st_size / (1024**3)
            expected_size_gb = config["size_gb"]
            
            if abs(actual_size_gb - expected_size_gb) / expected_size_gb < 0.1:
                log(f"✅ {cache_file.name} found in cache ({actual_size_gb:.2f}GB)")
            else:
                log(f"⚠️ {cache_file.name} corrupted, re-downloading...")
                cache_file.unlink()
                if not download_model(config["url"], cache_file, config["size_gb"]):
                    if config["critical"]:
                        missing_critical.append(model_path)
                    continue
        else:
            log(f"📦 {cache_file.name} not in cache, downloading...")
            if not download_model(config["url"], cache_file, config["size_gb"]):
                if config["critical"]:
                    missing_critical.append(model_path)
                continue
        
        # Create symlink from ComfyUI models to cache
        local_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Remove existing file/symlink
        if local_file.exists() or local_file.is_symlink():
            local_file.unlink()
        
        # Create symlink
        try:
            local_file.symlink_to(cache_file)
            log(f"🔗 Linked {local_file} -> {cache_file}")
        except Exception as e:
            log(f"❌ Failed to create symlink for {model_path}: {e}", "ERROR")
            # Fallback: copy file
            try:
                shutil.copy2(cache_file, local_file)
                log(f"📋 Copied {cache_file} -> {local_file}")
            except Exception as e2:
                log(f"❌ Failed to copy {model_path}: {e2}", "ERROR")
                if config["critical"]:
                    missing_critical.append(model_path)
    
    # Download LoRA files (non-critical)
    log("🎭 Processing LoRA files...")
    try:
        if Path("/workspace/builder/download_models.py").exists():
            subprocess.run([sys.executable, "/workspace/builder/download_models.py"], 
                         timeout=1800, check=False)
    except Exception as e:
        log(f"LoRA download failed: {e}", "WARNING")
    
    # Final check
    if missing_critical:
        log(f"❌ CRITICAL MODELS MISSING: {missing_critical}", "ERROR")
        return False
    else:
        log("✅ All critical models ready!")
        
        # Show cache stats
        total_size = sum(
            (MODELS_CACHE_PATH / model_path).stat().st_size 
            for model_path in MODELS_CONFIG.keys()
            if (MODELS_CACHE_PATH / model_path).exists()
        ) / (1024**3)
        log(f"📊 Total cached models: {total_size:.2f}GB")
        
        return True

def start_handler():
    """Start the RunPod handler"""
    log("🎬 Starting AI-Avatarka handler...")
    
    try:
        sys.path.append("/workspace/src")
        from handler import handler
        import runpod
        
        log("✅ Handler loaded successfully")
        log("🚀 Starting RunPod serverless worker...")
        runpod.serverless.start({"handler": handler})
        
    except Exception as e:
        log(f"❌ Handler startup failed: {e}", "ERROR")
        raise

if __name__ == "__main__":
    log("=" * 60)
    log("AI-AVATARKA NETWORK STORAGE STARTUP")
    log("=" * 60)
    
    try:
        # Setup models (download to network storage if needed)
        if not setup_models():
            log("❌ Model setup failed - cannot start", "ERROR")
            sys.exit(1)
        
        # Start handler
        start_handler()
        
    except KeyboardInterrupt:
        log("Startup interrupted", "WARNING")
        sys.exit(1)
    except Exception as e:
        log(f"❌ Fatal error: {e}", "ERROR")
        sys.exit(1)
EOF

RUN chmod +x /workspace/network_storage_startup.py

WORKDIR /workspace
CMD ["python", "/workspace/network_storage_startup.py"]