#!/usr/bin/env python3
"""
AI-Avatarka Model Download Script - CORRECTED VERSION
Downloads Wan 2.1 models and LoRA files for ComfyUI
"""

import os
import sys
import urllib.request
import urllib.error
import subprocess
from pathlib import Path
import time

# CORRECTED MODEL CONFIGURATION - using the exact URL you specified
MODELS_CONFIG = {
    "diffusion_models": {
        # Use the exact BF16 model you specified
        "wan2.1_i2v_480p_14B_bf16.safetensors": {
            "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors",
            "size_gb": 27.8,
            "required": True
        }
    },
    "vae": {
        # Use Comfy-Org repackaged VAE
        "wan_2.1_vae.safetensors": {
            "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors",
            "size_gb": 0.254,
            "required": True
        }
    },
    "text_encoders": {
        # Use the fp8 scaled version as recommended
        "umt5_xxl_fp8_e4m3fn_scaled.safetensors": {
            "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
            "size_gb": 2.5,
            "required": True
        }
    },
    "clip_vision": {
        # Use Comfy-Org clip vision model
        "clip_vision_h.safetensors": {
            "url": "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors",
            "size_gb": 1.26,
            "required": True
        }
    }
}

# LoRA files configuration - YOUR ACTUAL GOOGLE DRIVE IDs
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
        print_info("Installing gdown...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "gdown", "--no-cache-dir"])
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
        "loras"
    ]
    
    for directory in directories:
        dir_path = base_path / directory
        dir_path.mkdir(parents=True, exist_ok=True)
        print_info(f"Created directory: {dir_path}")

def download_with_progress(url, filepath, expected_size_gb=None):
    """Download file with progress bar and retries"""
    max_retries = 3
    
    for attempt in range(max_retries):
        try:
            print_info(f"Downloading: {filepath.name} (attempt {attempt + 1}/{max_retries})")
            
            req = urllib.request.Request(url)
            req.add_header('User-Agent', 'AI-Avatarka/1.0')
            
            with urllib.request.urlopen(req, timeout=30) as response:
                total_size = int(response.headers.get('Content-Length', 0))
                downloaded = 0
                chunk_size = 1024 * 1024  # 1MB chunks for better progress
                
                with open(filepath, 'wb') as f:
                    while True:
                        chunk = response.read(chunk_size)
                        if not chunk:
                            break
                        
                        f.write(chunk)
                        downloaded += len(chunk)
                        
                        # Progress reporting every 500MB
                        if downloaded % (500 * 1024 * 1024) == 0:
                            if total_size > 0:
                                progress = (downloaded / total_size) * 100
                                print_info(f"Progress: {progress:.1f}% ({downloaded / (1024**3):.2f}GB / {total_size / (1024**3):.2f}GB)")
                            else:
                                print_info(f"Downloaded: {downloaded / (1024**3):.2f}GB")
            
            # Verify file size
            actual_size = filepath.stat().st_size
            print_info(f"Downloaded successfully: {filepath.name} ({actual_size/(1024**3):.2f}GB)")
            return True
            
        except Exception as e:
            print_error(f"Attempt {attempt + 1} failed for {filepath.name}: {e}")
            if filepath.exists():
                filepath.unlink()  # Remove partial download
            
            if attempt < max_retries - 1:
                print_info("Retrying in 10 seconds...")
                time.sleep(10)
    
    return False

def download_from_gdrive(file_id, destination, filename):
    """Download file from Google Drive using gdown with retries"""
    gdown = install_gdown()
    
    print_info(f"Downloading {filename} from Google Drive...")
    
    url = f"https://drive.google.com/uc?id={file_id}"
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            # Try gdown download with fuzzy matching for large files
            success = gdown.download(url, str(destination), quiet=False, fuzzy=True)
            
            if destination.exists() and destination.stat().st_size > 1024:  # At least 1KB
                size_mb = destination.stat().st_size / (1024 * 1024)
                print_info(f"Downloaded successfully: {filename} ({size_mb:.1f} MB)")
                return True
            else:
                print_error(f"Download failed or file too small: {filename}")
                if destination.exists():
                    destination.unlink()
                
        except Exception as e:
            print_error(f"Attempt {attempt + 1} failed for {filename}: {str(e)}")
            if destination.exists():
                destination.unlink()
        
        if attempt < max_retries - 1:
            print_info("Retrying in 5 seconds...")
            time.sleep(5)
    
    return False

def check_existing_models():
    """Check what models already exist (useful for hearmeman base image)"""
    base_path = Path("/workspace/ComfyUI/models")
    print_info("Checking existing models...")
    
    found_models = []
    for category, models in MODELS_CONFIG.items():
        category_path = base_path / category
        if category_path.exists():
            for filename in models.keys():
                filepath = category_path / filename
                if filepath.exists():
                    size_gb = filepath.stat().st_size / (1024**3)
                    found_models.append(f"{category}/{filename} ({size_gb:.2f}GB)")
                    print_info(f"Found existing: {category}/{filename}")
    
    if found_models:
        print_info(f"Found {len(found_models)} existing models - will skip downloads")
    else:
        print_info("No existing models found - will download all")
    
    return found_models

def main():
    """Main download function"""
    print_info("AI-Avatarka Model Download Script - CORRECTED VERSION")
    print_info("===================================================")
    
    try:
        # Create directories
        create_directories()
        
        # Check existing models
        existing = check_existing_models()
        
        # Download base models from HuggingFace
        print_info("\n🔄 Phase 1: Downloading base models from HuggingFace...")
        base_path = Path("/workspace/ComfyUI/models")
        
        for category, models in MODELS_CONFIG.items():
            category_path = base_path / category
            for filename, model_info in models.items():
                filepath = category_path / filename
                
                if filepath.exists():
                    existing_size = filepath.stat().st_size / (1024**3)
                    expected_size = model_info["size_gb"]
                    
                    # Check if size is reasonable (within 10% of expected)
                    if abs(existing_size - expected_size) / expected_size < 0.1:
                        print_info(f"Skipping {filename} (already exists, {existing_size:.2f}GB)")
                        continue
                    else:
                        print_warning(f"Re-downloading {filename} (size mismatch)")
                        filepath.unlink()
                
                print_info(f"Downloading {filename} ({model_info['size_gb']}GB expected)...")
                if download_with_progress(model_info["url"], filepath, model_info["size_gb"]):
                    print_info(f"✅ {filename} downloaded successfully")
                else:
                    print_error(f"❌ Failed to download {filename}")
                    if model_info["required"]:
                        print_error("This is a required model - build may fail")
        
        # Download LoRA files from Google Drive
        print_info("\n🎭 Phase 2: Downloading LoRA files from Google Drive...")
        lora_path = base_path / "loras"
        success_count = 0
        failed_count = 0
        
        for filename, file_id in LORA_FILES.items():
            filepath = lora_path / filename
            
            if filepath.exists() and filepath.stat().st_size > 1024 * 1024:  # > 1MB
                size_mb = filepath.stat().st_size / (1024 * 1024)
                print_info(f"Skipping {filename} (already exists, {size_mb:.1f}MB)")
                continue
            
            if download_from_gdrive(file_id, filepath, filename):
                success_count += 1
            else:
                failed_count += 1
        
        print_info(f"\n🎉 Download Summary:")
        print_info(f"LoRA files successful: {success_count}/{len(LORA_FILES)}")
        print_info(f"LoRA files failed: {failed_count}")
        
        # Final verification
        print_info("\n🔍 Phase 3: Final verification...")
        
        # Check required base models
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
                print_error(f"  ❌ {model}")
            return False
        else:
            print_info("✅ All required base models present")
        
        # Check LoRA files
        lora_count = sum(1 for f in LORA_FILES.keys() if (lora_path / f).exists())
        print_info(f"✅ {lora_count}/{len(LORA_FILES)} LoRA files present")
        
        print_info("\n🎉 Download completed successfully!")
        return True
        
    except KeyboardInterrupt:
        print_error("Download interrupted by user")
        return False
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        return False

if __name__ == "__main__":
    if not main():
        sys.exit(1)