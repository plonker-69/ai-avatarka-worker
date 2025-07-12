FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip \
        curl ffmpeg git wget vim \
        libgl1 libglib2.0-0 build-essential gcc && \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    python3.12 -m venv /opt/venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/venv/bin:$PATH"

# Install requirements
COPY requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install -r /requirements.txt --no-cache-dir

# Copy build scripts
COPY builder/ /builder/

# Install ComfyUI and custom nodes only (skip model downloads)
RUN python /builder/install_comfyui.py && \
    python /builder/setup_custom_nodes.py

# Copy project files
COPY workflow/ /workspace/ComfyUI/workflow/
COPY lora/ /workspace/ComfyUI/models/lora/
COPY prompts/ /workspace/prompts/
COPY src/handler.py /handler.py

WORKDIR /workspace

# Download models at runtime instead of build time
CMD python /builder/download_models.py && python -u /handler.py