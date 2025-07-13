#!/usr/bin/env python3
"""
AI-Avatarka LoRA Download Script
Only downloads LoRA files - base models are pre-downloaded in GitHub Actions
"""

import os
import sys
import subprocess
from pathlib import Path
import time

# LoRA files configuration with your Google Drive IDs
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

def check_base_models():
    """Check if base models are present (should be pre-downloaded)"""
    models_path = Path("/workspace/ComfyUI/models")
    
    required_models = [
        "diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors",
        "vae/wan_2.1_vae.safetensors",
        "text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
        "clip_vision/clip_vision_h.safetensors"
    ]
    
    missing_models = []
    for model_path in required_models:
        full_path = models_path / model_path
        if not full_path.exists():
            missing_models.append(model_path)
        else:
            size_gb = full_path.stat().st_size / (1024**3)
            print_info(f"Found: {model_path} ({size_gb:.1f}GB)")
    
    if missing_models:
        print_error("Missing base models:")
        for model in missing_models:
            print_error(f"  ❌ {model}")
        return False
    else:
        print_info("✅ All base models present")
        return True

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

def download_lora_files():
    """Download all LoRA files from Google Drive"""
    lora_path = Path("/workspace/ComfyUI/models/loras")
    lora_path.mkdir(parents=True, exist_ok=True)
    
    success_count = 0
    failed_count = 0
    skipped_count = 0
    
    print_info("\n🎭 Downloading LoRA files from Google Drive...")
    
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
            failed_count += 1
    
    print_info(f"\n=== LoRA Download Summary ===")
    print_info(f"Successful: {success_count}")
    print_info(f"Failed: {failed_count}")
    print_info(f"Skipped: {skipped_count}")
    
    return failed_count == 0

def main():
    """Main download function - LoRA files only"""
    print_info("AI-Avatarka LoRA Download Script")
    print_info("Base models pre-downloaded in GitHub Actions")
    print_info("===============================================")
    
    try:
        # Check if base models are present
        print_info("\n🔍 Phase 1: Checking base models...")
        if not check_base_models():
            print_error("Base models missing! Build may have failed.")
            # Continue anyway in case models are elsewhere
        
        # Download LoRA files
        print_info("\n🎭 Phase 2: Downloading LoRA files...")
        if not download_lora_files():
            print_warning("Some LoRA files failed to download")
        
        print_info("\n✅ LoRA download completed!")
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