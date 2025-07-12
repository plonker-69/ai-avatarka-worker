FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev \
        python3-pip \
        git wget curl ffmpeg \
        libgl1 libglib2.0-0 libsm6 libxext6 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# THE KEY FIX: Create and use virtual environment
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Now pip will work!
RUN pip install --upgrade pip

WORKDIR /workspace

# Install packages (now using venv pip)
RUN pip install runpod pillow numpy requests websocket-client \
                aiohttp aiofiles safetensors transformers

# Install PyTorch with CUDA 12.1 support (works with 12.8.1 runtime)
RUN pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

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

CMD python -u /handler.py