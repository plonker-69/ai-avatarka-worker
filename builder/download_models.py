#!/usr/bin/env python3
"""
AI-Avatarka Model Download Script
Downloads Wan 2.1 models and dependencies for ComfyUI
"""

import os
import sys
import urllib.request
import urllib.error
from pathlib import Path
import hashlib
import time

# Model configuration
MODELS_CONFIG = {
    "diffusion_models": {
        "wan2.1_i2v_480p_14B_bf16.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan2.1_i2v_480p_14B_bf16.safetensors",
            "size_gb": 27.8,
            "required": True
        },
        "wan2.1_i2v_480p_14B_fp16.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan2.1_i2v_480p_14B_fp16.safetensors", 
            "size_gb": 27.8,
            "required": False
        }
    },
    "vae": {
        "wan_2.1_vae.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan_2.1_vae.safetensors",
            "size_gb": 0.3,
            "required": True
        }
    },
    "text_encoders": {
        "umt5-xxl-enc-bf16.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors",
            "size_gb": 4.9,
            "required": True
        },
        "umt5_xxl_fp8_e4m3fn_scaled.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
            "size_gb": 2.5,
            "required": False
        }
    },
    "clip_vision": {
        "clip_vision_h.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/clip_vision_h.safetensors",
            "size_gb": 2.5,
            "required": True
        },
        "open-clip-xlm-roberta-large-vit-huge-14_visual_fp16.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/open-clip-xlm-roberta-large-vit-huge-14_visual_fp16.safetensors",
            "size_gb": 1.8,
            "required": True
        }
    }
}

def print_info(message):
    """Print info message with timestamp"""
    print(f"[INFO] {message}")

def print_error(message):
    """Print error message with timestamp"""
    print(f"[ERROR] {message}")

def print_warning(message):
    """Print warning message with timestamp"""
    print(f"[WARNING] {message}")

def create_directories():
    """Create necessary model directories"""
    base_path = Path("/workspace/ComfyUI/models")
    
    directories = [
        "diffusion_models",
        "vae", 
        "text_encoders",
        "clip_vision"
    ]
    
    for directory in directories:
        dir_path = base_path / directory
        dir_path.mkdir(parents=True, exist_ok=True)
        print_info(f"Created directory: {dir_path}")

def check_disk_space():
    """Check available disk space"""
    try:
        stat = os.statvfs("/workspace")
        available_gb = (stat.f_bavail * stat.f_frsize) / (1024**3)
        
        # Calculate total required space
        total_required = 0
        for category in MODELS_CONFIG.values():
            for model_info in category.values():
                if model_info["required"]:
                    total_required += model_info["size_gb"]
        
        print_info(f"Available disk space: {available_gb:.1f} GB")
        print_info(f"Required space for models: {total_required:.1f} GB")
        
        if available_gb < total_required + 5:  # 5GB buffer
            print_warning(f"Low disk space! Available: {available_gb:.1f}GB, Required: {total_required:.1f}GB")
            return False
        
        return True
    except Exception as e:
        print_warning(f"Could not check disk space: {e}")
        return True

def download_with_progress(url, filepath, expected_size_gb=None):
    """Download file with progress bar"""
    try:
        print_info(f"Downloading: {filepath.name}")
        print_info(f"From: {url}")
        
        # Create request with headers
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'AI-Avatarka/1.0')
        
        with urllib.request.urlopen(req) as response:
            total_size = int(response.headers.get('Content-Length', 0))
            downloaded = 0
            chunk_size = 8192 * 16  # 128KB chunks
            
            with open(filepath, 'wb') as f:
                while True:
                    chunk = response.read(chunk_size)
                    if not chunk:
                        break
                    
                    f.write(chunk)
                    downloaded += len(chunk)
                    
                    # Progress reporting every 100MB
                    if downloaded % (100 * 1024 * 1024) == 0 or not chunk:
                        if total_size > 0:
                            progress = (downloaded / total_size) * 100
                            print_info(f"Progress: {progress:.1f}% ({downloaded / (1024**3):.2f}GB / {total_size / (1024**3):.2f}GB)")
                        else:
                            print_info(f"Downloaded: {downloaded / (1024**3):.2f}GB")
        
        # Verify file size
        actual_size = filepath.stat().st_size
        if expected_size_gb:
            expected_bytes = expected_size_gb * (1024**3)
            size_diff = abs(actual_size - expected_bytes) / expected_bytes
            if size_diff > 0.1:  # More than 10% difference
                print_warning(f"Size mismatch for {filepath.name}: expected ~{expected_size_gb}GB, got {actual_size/(1024**3):.2f}GB")
        
        print_info(f"Downloaded successfully: {filepath.name} ({actual_size/(1024**3):.2f}GB)")
        return True
        
    except urllib.error.HTTPError as e:
        print_error(f"HTTP Error {e.code}: {e.reason} for {url}")
        return False
    except urllib.error.URLError as e:
        print_error(f"URL Error: {e.reason} for {url}")
        return False
    except Exception as e:
        print_error(f"Unexpected error downloading {url}: {e}")
        return False

def download_models():
    """Download all required models"""
    base_path = Path("/workspace/ComfyUI/models")
    success_count = 0
    failure_count = 0
    skipped_count = 0
    
    print_info("Starting model downloads...")
    
    for category, models in MODELS_CONFIG.items():
        print_info(f"\n=== Downloading {category} models ===")
        category_path = base_path / category
        
        for filename, model_info in models.items():
            filepath = category_path / filename
            
            # Check if file already exists
            if filepath.exists():
                existing_size = filepath.stat().st_size / (1024**3)
                expected_size = model_info["size_gb"]
                
                # If size is reasonable, skip download
                if abs(existing_size - expected_size) / expected_size < 0.1:
                    print_info(f"Skipping {filename} (already exists, {existing_size:.2f}GB)")
                    skipped_count += 1
                    continue
                else:
                    print_warning(f"Re-downloading {filename} (size mismatch: {existing_size:.2f}GB vs expected {expected_size:.2f}GB)")
                    filepath.unlink()
            
            # Download the model
            if download_with_progress(model_info["url"], filepath, model_info["size_gb"]):
                success_count += 1
            else:
                failure_count += 1
                if model_info["required"]:
                    print_error(f"Failed to download required model: {filename}")
                else:
                    print_warning(f"Failed to download optional model: {filename}")
    
    print_info(f"\n=== Download Summary ===")
    print_info(f"Successful: {success_count}")
    print_info(f"Failed: {failure_count}")
    print_info(f"Skipped: {skipped_count}")
    
    # Check if all required models are present
    missing_required = []
    for category, models in MODELS_CONFIG.items():
        category_path = base_path / category
        for filename, model_info in models.items():
            if model_info["required"]:
                filepath = category_path / filename
                if not filepath.exists():
                    missing_required.append(f"{category}/{filename}")
    
    if missing_required:
        print_error("Missing required models:")
        for model in missing_required:
            print_error(f"  - {model}")
        return False
    
    print_info("All required models downloaded successfully!")
    return True

def verify_models():
    """Verify that all required models are present and readable"""
    print_info("Verifying model files...")
    base_path = Path("/workspace/ComfyUI/models")
    
    for category, models in MODELS_CONFIG.items():
        category_path = base_path / category
        for filename, model_info in models.items():
            if model_info["required"]:
                filepath = category_path / filename
                if not filepath.exists():
                    print_error(f"Required model missing: {filepath}")
                    return False
                
                try:
                    # Try to read first few bytes to verify file integrity
                    with open(filepath, 'rb') as f:
                        f.read(1024)
                    print_info(f"Verified: {filename}")
                except Exception as e:
                    print_error(f"Cannot read model file {filename}: {e}")
                    return False
    
    print_info("All required models verified!")
    return True

def main():
    """Main download function"""
    print_info("AI-Avatarka Model Download Script")
    print_info("================================")
    
    try:
        # Check disk space
        if not check_disk_space():
            print_warning("Continuing despite disk space warning...")
        
        # Create directories
        create_directories()
        
        # Download models
        if not download_models():
            print_error("Model download failed!")
            sys.exit(1)
        
        # Verify models
        if not verify_models():
            print_error("Model verification failed!")
            sys.exit(1)
        
        print_info("Model download completed successfully!")
        
    except KeyboardInterrupt:
        print_error("Download interrupted by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()