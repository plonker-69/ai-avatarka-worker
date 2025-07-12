#!/usr/bin/env python3
"""
AI-Avatarka Model Download Script - FIXED VERSION
Downloads Wan 2.1 models and LoRA files for ComfyUI
"""

import os
import sys
import urllib.request
import urllib.error
import subprocess
from pathlib import Path
import time

# FIXED MODEL CONFIGURATION with correct URLs
MODELS_CONFIG = {
    "diffusion_models": {
        "wan2.1_i2v_480p_14B_bf16.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/wan2.1_i2v_480p_14B_bf16.safetensors",
            "size_gb": 27.8,
            "required": True
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
        }
    },
    "clip_vision": {
        "open-clip-xlm-roberta-large-vit-huge-14_visual_fp16.safetensors": {
            "url": "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/open-clip-xlm-roberta-large-vit-huge-14_visual_fp16.safetensors",
            "size_gb": 1.8,
            "required": True
        }
    }
}

# LoRA files configuration - ADD YOUR ACTUAL GOOGLE DRIVE IDs HERE
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

def install_gdown():
    """Install gdown for Google Drive downloads"""
    try:
        import gdown
        print_info("gdown already installed")
        return gdown
    except ImportError:
        print_info("Installing gdown...")
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
        "loras"
    ]
    
    for directory in directories:
        dir_path = base_path / directory
        dir_path.mkdir(parents=True, exist_ok=True)
        print_info(f"Created directory: {dir_path}")

def download_with_progress(url, filepath, expected_size_gb=None):
    """Download file with progress bar"""
    try:
        print_info(f"Downloading: {filepath.name}")
        
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
                    if downloaded % (100 * 1024 * 1024) == 0:
                        if total_size > 0:
                            progress = (downloaded / total_size) * 100
                            print_info(f"Progress: {progress:.1f}% ({downloaded / (1024**3):.2f}GB)")
        
        print_info(f"Downloaded successfully: {filepath.name}")
        return True
        
    except Exception as e:
        print_error(f"Failed to download {filepath.name}: {e}")
        return False

def download_from_gdrive(file_id, destination, filename):
    """Download file from Google Drive using gdown"""
    gdown = install_gdown()
    
    print_info(f"Downloading {filename} from Google Drive...")
    
    url = f"https://drive.google.com/uc?id={file_id}"
    
    try:
        gdown.download(url, str(destination), quiet=False)
        
        if destination.exists():
            size_mb = destination.stat().st_size / (1024 * 1024)
            print_info(f"Downloaded successfully: {filename} ({size_mb:.1f} MB)")
            return True
        else:
            print_error(f"Download failed: {filename}")
            return False
            
    except Exception as e:
        print_error(f"Failed to download {filename}: {str(e)}")
        return False

def main():
    """Main download function"""
    print_info("AI-Avatarka Model Download Script")
    print_info("================================")
    
    try:
        # Create directories
        create_directories()
        
        # Download base models from HuggingFace
        print_info("🔄 Downloading base models from HuggingFace...")
        base_path = Path("/workspace/ComfyUI/models")
        
        for category, models in MODELS_CONFIG.items():
            category_path = base_path / category
            for filename, model_info in models.items():
                filepath = category_path / filename
                
                if filepath.exists():
                    print_info(f"Skipping {filename} (already exists)")
                    continue
                
                if download_with_progress(model_info["url"], filepath, model_info["size_gb"]):
                    print_info(f"✅ {filename} downloaded successfully")
                else:
                    print_error(f"❌ Failed to download {filename}")
                    if model_info["required"]:
                        return False
        
        # Download LoRA files from Google Drive
        print_info("🎭 Downloading LoRA files from Google Drive...")
        lora_path = base_path / "loras"
        success_count = 0
        
        for filename, file_id in LORA_FILES.items():
            filepath = lora_path / filename
            
            if filepath.exists():
                print_info(f"Skipping {filename} (already exists)")
                continue
            
            if download_from_gdrive(file_id, filepath, filename):
                success_count += 1
        
        print_info(f"🎉 Download complete! {success_count}/{len(LORA_FILES)} LoRA files downloaded")
        return True
        
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        return False

if __name__ == "__main__":
    if not main():
        sys.exit(1)