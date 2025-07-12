FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS base

# Consolidated environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    CMAKE_BUILD_PARALLEL_LEVEL=8 \
    COMFYUI_PATH="/workspace/ComfyUI"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip \
        curl ffmpeg git wget vim \
        libgl1 libglib2.0-0 build-essential gcc && \
    \
    # make Python3.12 the default python & pip
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    \
    python3.12 -m venv /opt/venv && \
    \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Use the virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Install your requirements
COPY requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install -r /requirements.txt --no-cache-dir

# Copy and run build scripts
COPY builder/ /builder/
RUN python /builder/install_comfyui.py && \
    python /builder/setup_custom_nodes.py && \
    python /builder/download_models.py

FROM base AS final
# Make sure to use the virtual environment here too
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