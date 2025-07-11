#!/usr/bin/env python3
"""
AI-Avatarka ComfyUI Installation Script
Installs the latest version of ComfyUI
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# Configuration
COMFYUI_REPO = "https://github.com/comfyanonymous/ComfyUI.git"
COMFYUI_PATH = "/workspace/ComfyUI"

def print_info(message):
    """Print info message with timestamp"""
    print(f"[INFO] {message}")

def print_error(message):
    """Print error message with timestamp"""
    print(f"[ERROR] {message}")

def print_warning(message):
    """Print warning message with timestamp"""
    print(f"[WARNING] {message}")

def run_command(cmd, cwd=None, check=True):
    """Run shell command with proper error handling"""
    try:
        print_info(f"Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
        result = subprocess.run(
            cmd,
            cwd=cwd,
            shell=isinstance(cmd, str),
            check=check,
            capture_output=True,
            text=True
        )
        
        if result.stdout:
            print(result.stdout.strip())
        
        return result
    except subprocess.CalledProcessError as e:
        print_error(f"Command failed: {e}")
        if e.stdout:
            print_error(f"STDOUT: {e.stdout}")
        if e.stderr:
            print_error(f"STDERR: {e.stderr}")
        raise

def check_git():
    """Check if git is available"""
    try:
        result = subprocess.run(['git', '--version'], capture_output=True, text=True)
        print_info(f"Git version: {result.stdout.strip()}")
        return True
    except FileNotFoundError:
        print_error("Git is not installed or not in PATH")
        return False

def check_python():
    """Check Python version and pip"""
    try:
        result = subprocess.run([sys.executable, '--version'], capture_output=True, text=True)
        print_info(f"Python version: {result.stdout.strip()}")
        
        result = subprocess.run([sys.executable, '-m', 'pip', '--version'], capture_output=True, text=True)
        print_info(f"Pip version: {result.stdout.strip()}")
        
        return True
    except Exception as e:
        print_error(f"Python/pip check failed: {e}")
        return False

def cleanup_existing():
    """Remove existing ComfyUI installation if present"""
    comfyui_path = Path(COMFYUI_PATH)
    
    if comfyui_path.exists():
        print_warning(f"Existing ComfyUI installation found at {COMFYUI_PATH}")
        try:
            shutil.rmtree(comfyui_path)
            print_info("Removed existing installation")
        except Exception as e:
            print_error(f"Failed to remove existing installation: {e}")
            return False
    
    return True

def clone_comfyui():
    """Clone ComfyUI repository"""
    workspace_path = Path("/workspace")
    workspace_path.mkdir(parents=True, exist_ok=True)
    
    print_info(f"Cloning ComfyUI to {COMFYUI_PATH}")
    
    try:
        run_command([
            'git', 'clone', 
            '--depth', '1',  # Shallow clone for faster download
            COMFYUI_REPO,
            COMFYUI_PATH
        ])
        
        print_info("ComfyUI cloned successfully")
        return True
        
    except subprocess.CalledProcessError:
        print_error("Failed to clone ComfyUI repository")
        return False

def get_comfyui_version():
    """Get ComfyUI version/commit info"""
    try:
        result = run_command(['git', 'log', '-1', '--format=%H %s'], cwd=COMFYUI_PATH)
        commit_info = result.stdout.strip()
        print_info(f"ComfyUI version: {commit_info}")
        
        result = run_command(['git', 'log', '-1', '--format=%cd', '--date=short'], cwd=COMFYUI_PATH)
        commit_date = result.stdout.strip()
        print_info(f"Commit date: {commit_date}")
        
        return True
    except Exception as e:
        print_warning(f"Could not get version info: {e}")
        return True

def install_comfyui_dependencies():
    """Install ComfyUI Python dependencies"""
    requirements_file = Path(COMFYUI_PATH) / "requirements.txt"
    
    if not requirements_file.exists():
        print_error(f"Requirements file not found: {requirements_file}")
        return False
    
    print_info("Installing ComfyUI dependencies...")
    
    try:
        run_command([
            sys.executable, '-m', 'pip', 'install',
            '--no-cache-dir',
            '-r', str(requirements_file)
        ])
        
        print_info("ComfyUI dependencies installed successfully")
        return True
        
    except subprocess.CalledProcessError:
        print_error("Failed to install ComfyUI dependencies")
        return False

def create_directory_structure():
    """Create necessary ComfyUI directories"""
    base_path = Path(COMFYUI_PATH)
    
    directories = [
        "models/checkpoints",
        "models/vae", 
        "models/lora",
        "models/embeddings",
        "models/hypernetworks",
        "models/controlnet",
        "models/clip_vision",
        "models/diffusion_models",
        "models/text_encoders",
        "custom_nodes",
        "input",
        "output",
        "temp",
        "workflow"
    ]
    
    for directory in directories:
        dir_path = base_path / directory
        dir_path.mkdir(parents=True, exist_ok=True)
        print_info(f"Created directory: {dir_path}")

def verify_installation():
    """Verify ComfyUI installation"""
    comfyui_path = Path(COMFYUI_PATH)
    
    # Check main files
    required_files = [
        "main.py",
        "requirements.txt",
        "nodes.py",
        "execution.py"
    ]
    
    for file in required_files:
        file_path = comfyui_path / file
        if not file_path.exists():
            print_error(f"Required file missing: {file}")
            return False
        print_info(f"Verified: {file}")
    
    # Check if we can import ComfyUI modules
    try:
        sys.path.append(str(comfyui_path))
        
        # Test basic imports
        print_info("Testing ComfyUI imports...")
        
        # This should work if ComfyUI is properly installed
        import nodes
        print_info("✅ Basic ComfyUI imports successful")
        
        # Check available nodes
        from nodes import NODE_CLASS_MAPPINGS
        node_count = len(NODE_CLASS_MAPPINGS)
        print_info(f"✅ ComfyUI loaded {node_count} node types")
        
        return True
        
    except Exception as e:
        print_error(f"ComfyUI import test failed: {e}")
        return False

def main():
    """Main installation function"""
    print_info("AI-Avatarka ComfyUI Installation Script")
    print_info("======================================")
    
    try:
        # Pre-installation checks
        print_info("Performing pre-installation checks...")
        
        if not check_git():
            sys.exit(1)
            
        if not check_python():
            sys.exit(1)
        
        # Clean up existing installation
        if not cleanup_existing():
            sys.exit(1)
        
        # Clone ComfyUI
        if not clone_comfyui():
            sys.exit(1)
        
        # Get version info
        get_comfyui_version()
        
        # Install dependencies
        if not install_comfyui_dependencies():
            sys.exit(1)
        
        # Create directory structure
        create_directory_structure()
        
        # Verify installation
        if not verify_installation():
            sys.exit(1)
        
        print_info("ComfyUI installation completed successfully!")
        print_info(f"Installation path: {COMFYUI_PATH}")
        
    except KeyboardInterrupt:
        print_error("Installation interrupted by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()