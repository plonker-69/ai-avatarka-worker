FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

# Exact environment variables from working system
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    CMAKE_BUILD_PARALLEL_LEVEL=8

# Install exact system packages from working system
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip \
        curl ffmpeg git wget vim \
        libgl1 libglib2.0-0 build-essential gcc && \
    \
    # Create symlinks exactly like working system
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    \
    # Create virtual environment at exact same path
    python3.12 -m venv /opt/venv && \
    \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Use the virtual environment (exact PATH from working system)
ENV PATH="/opt/venv/bin:$PATH"

# THE KEY: Install PyTorch NIGHTLY with CUDA 12.8 support (not stable!)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/cu128

# Core Python tooling
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install packaging setuptools wheel

# Your required packages
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install runpod pillow numpy requests websocket-client \
                aiohttp aiofiles safetensors transformers

# Install ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install -r requirements.txt

# Copy your files
COPY src/handler.py /handler.py
COPY prompts/ /workspace/prompts/
COPY workflow/ /workspace/ComfyUI/workflow/

# Create directories
RUN mkdir -p /workspace/ComfyUI/models/lora \
             /workspace/ComfyUI/models/checkpoints \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/input \
             /workspace/ComfyUI/output

WORKDIR /workspace
CMD python -u /handler.py