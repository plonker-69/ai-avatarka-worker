FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS base

# Consolidated environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install system dependencies with cache mount for faster builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-pip \
    python3.12-dev \
    python3.12-venv \
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
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/python3.12 /usr/bin/python3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create virtual environment for better isolation
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install core Python dependencies with cache
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip setuptools wheel

# Install your requirements with cache
COPY requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /requirements.txt --no-cache-dir

# Copy and run build scripts
COPY builder/ /builder/
RUN python /builder/install_comfyui.py && \
    python /builder/setup_custom_nodes.py && \
    python /builder/download_models.py

FROM base AS final
# Ensure virtual environment is used
ENV PATH="/opt/venv/bin:$PATH"

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

# Start the worker
CMD python -u /handler.py