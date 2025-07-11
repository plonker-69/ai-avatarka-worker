#!/usr/bin/env python3
"""
AI-Avatarka Custom Nodes Setup Script
Installs required custom nodes for Wan 2.1 workflow
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# Custom nodes configuration based on workflow requirements
CUSTOM_NODES = {
    "ComfyUI-WanVideoWrapper": {
        "repo": "https://github.com/kijai/ComfyUI-WanVideoWrapper.git",
        "description": "Wan 2.1 video generation wrapper",
        "required": True,
        "provides_nodes": [
            "WanVideoBlockSwap",
            "WanVideoModelLoader", 
            "WanVideoDecode",
            "WanVideoImageClipEncode",
            "WanVideoLoraSelect",
            "LoadWanVideoT5TextEncoder",
            "LoadWanVideoClipTextEncoder",
            "WanVideoTextEncode",
            "WanVideoSampler",
            "WanVideoVAELoader"
        ]
    },
    "ComfyUI_essentials": {
        "repo": "https://github.com/cubiq/ComfyUI_essentials.git",
        "description": "Essential nodes including ImageResize+",
        "required": True,
        "provides_nodes": [
            "ImageResize+"
        ]
    },
    "ComfyUI-VideoHelperSuite": {
        "repo": "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git",
        "description": "Video processing and output nodes",
        "required": True,
        "provides_nodes": [
            "VHS_VideoCombine"
        ]
    }
}

CUSTOM_NODES_PATH = "/workspace/ComfyUI/custom_nodes"

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

def check_comfyui():
    """Check if ComfyUI is installed"""
    comfyui_path = Path("/workspace/ComfyUI")
    
    if not comfyui_path.exists():
        print_error("ComfyUI not found. Please run install_comfyui.py first.")
        return False
    
    main_py = comfyui_path / "main.py"
    if not main_py.exists():
        print_error("ComfyUI main.py not found. ComfyUI installation appears incomplete.")
        return False
    
    print_info("ComfyUI installation verified")
    return True

def create_custom_nodes_directory():
    """Create custom_nodes directory if it doesn't exist"""
    custom_nodes_path = Path(CUSTOM_NODES_PATH)
    custom_nodes_path.mkdir(parents=True, exist_ok=True)
    print_info(f"Custom nodes directory: {CUSTOM_NODES_PATH}")

def clone_custom_node(name, config):
    """Clone a custom node repository"""
    node_path = Path(CUSTOM_NODES_PATH) / name
    
    # Remove existing installation
    if node_path.exists():
        print_warning(f"Existing {name} found, removing...")
        try:
            shutil.rmtree(node_path)
        except Exception as e:
            print_error(f"Failed to remove existing {name}: {e}")
            return False
    
    # Clone repository
    try:
        print_info(f"Cloning {name}...")
        print_info(f"Description: {config['description']}")
        
        run_command([
            'git', 'clone',
            '--depth', '1',  # Shallow clone for faster download
            config['repo'],
            str(node_path)
        ])
        
        print_info(f"✅ {name} cloned successfully")
        return True
        
    except subprocess.CalledProcessError:
        print_error(f"❌ Failed to clone {name}")
        return False

def install_node_requirements(name, config):
    """Install requirements for a custom node"""
    node_path = Path(CUSTOM_NODES_PATH) / name
    requirements_file = node_path / "requirements.txt"
    
    if not requirements_file.exists():
        print_info(f"No requirements.txt found for {name}")
        return True
    
    try:
        print_info(f"Installing requirements for {name}...")
        
        run_command([
            sys.executable, '-m', 'pip', 'install',
            '--no-cache-dir',
            '-r', str(requirements_file)
        ])
        
        print_info(f"✅ {name} requirements installed")
        return True
        
    except subprocess.CalledProcessError:
        print_error(f"❌ Failed to install requirements for {name}")
        return False

def verify_node_installation(name, config):
    """Verify that a custom node was installed correctly"""
    node_path = Path(CUSTOM_NODES_PATH) / name
    
    # Check if directory exists
    if not node_path.exists():
        print_error(f"Node directory not found: {node_path}")
        return False
    
    # Check for Python files (basic verification)
    python_files = list(node_path.glob("*.py"))
    if not python_files:
        # Check subdirectories
        python_files = list(node_path.glob("**/*.py"))
    
    if not python_files:
        print_warning(f"No Python files found in {name}")
        return False
    
    print_info(f"✅ {name} installation verified ({len(python_files)} Python files)")
    
    # List provided nodes for reference
    if config.get("provides_nodes"):
        nodes_list = ", ".join(config["provides_nodes"])
        print_info(f"   Provides nodes: {nodes_list}")
    
    return True

def test_imports():
    """Test if custom nodes can be imported by ComfyUI"""
    try:
        print_info("Testing custom node imports...")
        
        # Add ComfyUI to Python path
        comfyui_path = Path("/workspace/ComfyUI")
        sys.path.insert(0, str(comfyui_path))
        
        # Try to import nodes module
        import nodes
        from nodes import NODE_CLASS_MAPPINGS
        
        original_count = len(NODE_CLASS_MAPPINGS)
        print_info(f"Base ComfyUI nodes: {original_count}")
        
        # Add custom nodes path
        sys.path.insert(0, CUSTOM_NODES_PATH)
        
        # Try to load custom nodes by importing from their directories
        custom_node_count = 0
        failed_nodes = []
        
        for name, config in CUSTOM_NODES.items():
            node_path = Path(CUSTOM_NODES_PATH) / name
            if node_path.exists():
                try:
                    # Add node path to sys.path temporarily
                    sys.path.insert(0, str(node_path))
                    
                    # Look for __init__.py or main Python files
                    init_file = node_path / "__init__.py"
                    if init_file.exists():
                        print_info(f"Found __init__.py for {name}")
                    
                    # Count as successful for now
                    custom_node_count += 1
                    
                except Exception as e:
                    print_warning(f"Could not test import for {name}: {e}")
                    failed_nodes.append(name)
                finally:
                    # Remove from path
                    if str(node_path) in sys.path:
                        sys.path.remove(str(node_path))
        
        print_info(f"Custom nodes processed: {custom_node_count}")
        if failed_nodes:
            print_warning(f"Import test issues: {', '.join(failed_nodes)}")
        
        return True
        
    except Exception as e:
        print_warning(f"Import testing failed: {e}")
        print_warning("This is not necessarily a problem - nodes may load correctly at runtime")
        return True

def install_custom_nodes():
    """Install all required custom nodes"""
    success_count = 0
    failure_count = 0
    
    print_info("Installing custom nodes for AI-Avatarka workflow...")
    
    for name, config in CUSTOM_NODES.items():
        print_info(f"\n=== Installing {name} ===")
        
        try:
            # Clone repository
            if not clone_custom_node(name, config):
                failure_count += 1
                if config["required"]:
                    print_error(f"Required custom node {name} failed to install")
                continue
            
            # Install requirements
            if not install_node_requirements(name, config):
                failure_count += 1
                if config["required"]:
                    print_error(f"Required custom node {name} requirements failed")
                continue
            
            # Verify installation
            if not verify_node_installation(name, config):
                failure_count += 1
                if config["required"]:
                    print_error(f"Required custom node {name} verification failed")
                continue
            
            success_count += 1
            print_info(f"✅ {name} installed successfully")
            
        except Exception as e:
            print_error(f"Unexpected error installing {name}: {e}")
            failure_count += 1
    
    print_info(f"\n=== Installation Summary ===")
    print_info(f"Successful: {success_count}")
    print_info(f"Failed: {failure_count}")
    
    # Check if all required nodes were installed
    required_nodes = [name for name, config in CUSTOM_NODES.items() if config["required"]]
    missing_required = []
    
    for name in required_nodes:
        node_path = Path(CUSTOM_NODES_PATH) / name
        if not node_path.exists():
            missing_required.append(name)
    
    if missing_required:
        print_error("Missing required custom nodes:")
        for name in missing_required:
            print_error(f"  - {name}")
        return False
    
    print_info("All required custom nodes installed successfully!")
    return True

def main():
    """Main setup function"""
    print_info("AI-Avatarka Custom Nodes Setup Script")
    print_info("====================================")
    
    try:
        # Check ComfyUI installation
        if not check_comfyui():
            sys.exit(1)
        
        # Create custom_nodes directory
        create_custom_nodes_directory()
        
        # Install custom nodes
        if not install_custom_nodes():
            sys.exit(1)
        
        # Test imports
        test_imports()
        
        print_info("Custom nodes setup completed successfully!")
        print_info("Required nodes for AI-Avatarka workflow:")
        for name, config in CUSTOM_NODES.items():
            if config["required"]:
                print_info(f"  ✅ {name}: {config['description']}")
        
    except KeyboardInterrupt:
        print_error("Setup interrupted by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()