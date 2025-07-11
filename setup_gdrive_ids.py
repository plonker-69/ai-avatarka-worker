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
