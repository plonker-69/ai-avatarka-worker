FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

# Install system packages and clean up in same layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3-pip \
        git wget curl \
        libgl1 libglib2.0-0 && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create virtual environment
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /workspace

# Test basic pip functionality
RUN echo "=== Testing pip ===" && \
    pip --version && \
    python --version

# Upgrade pip first
RUN echo "=== Upgrading pip ===" && \
    pip install --upgrade pip --no-cache-dir

# Test PyTorch index accessibility
RUN echo "=== Testing PyTorch index ===" && \
    pip index versions torch --index-url https://download.pytorch.org/whl/cu121 || \
    echo "cu121 index failed, will try fallback"

# Install PyTorch first (most likely to fail)
RUN echo "=== Installing PyTorch ===" && \
    pip install --no-cache-dir torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu121

# Test PyTorch works
RUN echo "=== Testing PyTorch ===" && \
    python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"

# Install basic packages
RUN echo "=== Installing basic packages ===" && \
    pip install --no-cache-dir pillow numpy requests

# Install networking packages
RUN echo "=== Installing networking packages ===" && \
    pip install --no-cache-dir websocket-client aiohttp aiofiles

# Install AI packages
RUN echo "=== Installing AI packages ===" && \
    pip install --no-cache-dir safetensors transformers

# Install runpod last
RUN echo "=== Installing runpod ===" && \
    pip install --no-cache-dir runpod

# Install ComfyUI with minimal footprint
RUN echo "=== Installing ComfyUI ===" && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf .git

# Install required custom nodes for Wan 2.1 workflow
RUN echo "=== Installing Custom Nodes ===" && \
    cd ComfyUI/custom_nodes && \
    \
    echo "Installing WanVideoWrapper..." && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && \
    (pip install --no-cache-dir -r requirements.txt 2>/dev/null || echo "No requirements for WanVideoWrapper") && \
    cd .. && \
    \
    echo "Installing VideoHelperSuite..." && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    (pip install --no-cache-dir -r requirements.txt 2>/dev/null || echo "No requirements for VideoHelperSuite") && \
    cd .. && \
    \
    echo "Installing ComfyUI_essentials..." && \
    git clone --depth 1 https://github.com/cubiq/ComfyUI_essentials.git && \
    cd ComfyUI_essentials && \
    (pip install --no-cache-dir -r requirements.txt 2>/dev/null || echo "No requirements for ComfyUI_essentials") && \
    cd .. && \
    \
    echo "Custom nodes installation completed!"

# Copy only essential files
COPY src/handler.py /handler.py
COPY prompts/ /workspace/prompts/
COPY workflow/ /workspace/ComfyUI/workflow/

# Create minimal directories
RUN mkdir -p /workspace/ComfyUI/models/lora \
             /workspace/ComfyUI/input \
             /workspace/ComfyUI/output

CMD python -u /handler.py