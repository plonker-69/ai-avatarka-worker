FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu

# Set environment variables (simplified, no venv confusion)
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Set python3.11 as default
RUN ln -sf $(which python3.11) /usr/local/bin/python && \
    ln -sf $(which python3.11) /usr/local/bin/python3

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
RUN mkdir -p /workspace

# Install Python dependencies (no venv confusion)
COPY requirements.txt /requirements.txt
RUN uv pip install --upgrade -r /requirements.txt --no-cache-dir --system

# Copy and run build scripts
COPY builder/ /builder/
RUN python /builder/install_comfyui.py && \
    python /builder/setup_custom_nodes.py && \
    python /builder/download_models.py

# Copy universal workflow
COPY workflow/ /workspace/ComfyUI/workflow/

# Copy LoRA files
COPY lora/ /workspace/ComfyUI/models/lora/

# Copy effect prompts configuration
COPY prompts/ /workspace/prompts/

# Copy main handler
COPY src/handler.py /handler.py

# Set working directory
WORKDIR /workspace

# Start the worker (RunPod standard with -u flag)
CMD python -u /handler.py