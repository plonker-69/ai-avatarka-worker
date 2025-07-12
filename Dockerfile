# Build stage
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3-pip git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
        runpod torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir \
        pillow numpy requests websocket-client aiohttp aiofiles safetensors transformers

# Install ComfyUI
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI && \
    cd /tmp/ComfyUI && \
    pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 \
        libgl1 libglib2.0-0 && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy ComfyUI
COPY --from=builder /tmp/ComfyUI /workspace/ComfyUI

WORKDIR /workspace

# Copy your files
COPY src/handler.py /handler.py
COPY prompts/ /workspace/prompts/
COPY workflow/ /workspace/ComfyUI/workflow/

# Create minimal directories
RUN mkdir -p /workspace/ComfyUI/models/lora \
             /workspace/ComfyUI/input \
             /workspace/ComfyUI/output

CMD python -u /handler.py