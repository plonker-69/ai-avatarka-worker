#!/usr/bin/env python3
"""
AI-Avatarka Model Download Script
Downloads Wan 2.1 models and LoRA files for ComfyUI
"""

import os
import sys
import urllib.request
import urllib.error
import subprocess
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

# LoRA files configuration with Google Drive IDs
LORA_FILES = {
    "ghostrider.safetensors": "1fr-o0SOF2Ekqjjv47kXwpbtTyQ4bX67Q",
    "son_goku.safetensors": "1DQFMntN2D-7kGm5myeRzFXqW9TdckIen", 
    "westworld.safetensors": "1tK17DuwniI6wrFhPuoeBIb1jIdnn6xZv",
    "hulk.safetensors": "1LC-OF-ytSy9vnAkJft5QfykIW-qakrJg",
    "super_saian.safetensors": "1DdUdskRIFgb5td_DAsrRIJwdrK5DnkMZ",
    "jumpscare.safetensors": "15oW0m7sudMBpoGGREHjZAtC92k6dspWq",
    "kamehameha.safetensors": "1c9GAVuwUYdoodAcU5svvEzHzsJuE19mi",
    "melt_it.safetensors": "139fvofiYDVZGGTHDUsBrAbzNLQ0TFKJf",
    "mindblown.safetensors": "15Q3lQ9U_0TwWgf8pNmovuHB1VOo7js3A",
    "muscles.safetensors": "1_FxWR_fZnWaI3Etxr19BAfJGUtqLHz88",
    "crush_it.safetensors": "1q_xAeRppHGc3caobmAk4Cpi-3PBJA97i",
    "samurai.safetensors": "1-N3XS5wpRcI95BJUnRr3PnMp7oCVAF3u",
    "fus_ro_dah.safetensors": "1-ruIAhaVzHPCERvh6cFY-s1b-s5dxmRA",
    "360.safetensors": "1S637vBYR21UKmTM3KI-S2cxrwKu3GDDR",
    "vip_50_epochs.safetensors": "1NcnSdMO4zew5078T3aQTK9cfxcnoMtjN",
    "puppy.safetensors": "1DZokL-bwacMIggimUlj2LAme_f4pOWdv",
    "snow_white.safetensors": "1geUbpu-Q-N4VxM6ncbC2-Y9Tidqbpt8D"
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

def install_gdown():
    """Install gdown for Google Drive downloads"""
    try:
        import gdown
        print_info("gdown already installed")
        return gdown
    except ImportError:
        print_info("Installing gdown for Google Drive downloads...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "gdown"])
        import gdown
        return gdown

def create_directories():
    """Create necessary model directories"""
    base_path = Path("/workspace/ComfyUI/models")
    
    directories = [
        "diffusion_models",
        "vae", 
        "text_encoders",
        "clip_vision",
        "loras"  # Added LoRA directory
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
        
        # Calculate total required space (base models + LoRAs)
        total_required = 0
        for category in MODELS_CONFIG.values():
            for model_info in category.values():
                if model_info["required"]:
                    total_required += model_info["size_gb"]
        
        # Add space for LoRA files (~1.7GB for 17 files)
        total_required += 2.0  # Extra buffer for LoRAs
        
        print_info(f"Available disk space: {available_gb:.1f} GB")
        print_info(f"Required space (models + LoRAs): {total_required:.1f} GB")
        
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

def download_from_gdrive(file_id, destination, filename):
    """Download file from Google Drive using gdown"""
    gdown = install_gdown()
    
    print_info(f"Downloading {filename} from Google Drive...")
    
    # Google Drive direct download URL
    url = f"https://drive.google.com/uc?id={file_id}"
    
    try:
        gdown.download(url, str(destination), quiet=False)
        
        # Verify download
        if destination.exists():
            size_mb = destination.stat().st_size / (1024 * 1024)
            print_info(f"Downloaded successfully: {filename} ({size_mb:.1f} MB)")
            return True
        else:
            print_error(f"Download failed: {filename} - file not found after download")
            return False
            
    except Exception as e:
        print_error(f"Failed to download {filename}: {str(e)}")
        return False

def download_lora_files():
    """Download all LoRA files from Google Drive"""
    lora_path = Path("/workspace/ComfyUI/models/loras")
    success_count = 0
    failure_count = 0
    skipped_count = 0
    
    print_info("\n=== Downloading LoRA files from Google Drive ===")
    
    for filename, file_id in LORA_FILES.items():
        filepath = lora_path / filename
        
        # Check if file already exists with reasonable size
        if filepath.exists() and filepath.stat().st_size > 1024 * 1024:  # > 1MB
            existing_size = filepath.stat().st_size / (1024 * 1024)
            print_info(f"Skipping {filename} (already exists, {existing_size:.1f}MB)")
            skipped_count += 1
            continue
        
        # Download from Google Drive
        if download_from_gdrive(file_id, filepath, filename):
            success_count += 1
        else:
            failure_count += 1
    
    print_info(f"\n=== LoRA Download Summary ===")
    print_info(f"Successful: {success_count}")
    print_info(f"Failed: {failure_count}")
    print_info(f"Skipped: {skipped_count}")
    
    return failure_count == 0

def download_models():
    """Download all required models"""
    base_path = Path("/workspace/ComfyUI/models")
    success_count = 0
    failure_count = 0
    skipped_count = 0
    
    print_info("Starting base model downloads...")
    
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
    
    print_info(f"\n=== Base Model Download Summary ===")
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
        print_error("Missing required base models:")
        for model in missing_required:
            print_error(f"  - {model}")
        return False
    
    print_info("All required base models downloaded successfully!")
    return True

def verify_models():
    """Verify that all required models are present and readable"""
    print_info("Verifying model files...")
    base_path = Path("/workspace/ComfyUI/models")
    
    # Verify base models
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
    
    # Verify LoRA files
    lora_path = base_path / "loras"
    lora_count = 0
    for filename in LORA_FILES.keys():
        filepath = lora_path / filename
        if filepath.exists():
            try:
                with open(filepath, 'rb') as f:
                    f.read(1024)
                lora_count += 1
                print_info(f"Verified LoRA: {filename}")
            except Exception as e:
                print_warning(f"Cannot read LoRA file {filename}: {e}")
        else:
            print_warning(f"LoRA file missing: {filename}")
    
    print_info(f"Verified {lora_count}/{len(LORA_FILES)} LoRA files")
    print_info("Model verification completed!")
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
        
        # Download base models
        print_info("\n🔄 Phase 1: Downloading base models...")
        if not download_models():
            print_error("Base model download failed!")
            sys.exit(1)
        
        # Download LoRA files
        print_info("\n🎭 Phase 2: Downloading LoRA files...")
        if not download_lora_files():
            print_warning("Some LoRA files failed to download, but continuing...")
        
        # Verify models
        print_info("\n🔍 Phase 3: Verifying downloads...")
        verify_models()
        
        print_info("\n🎉 Model download completed successfully!")
        
    except KeyboardInterrupt:
        print_error("Download interrupted by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()