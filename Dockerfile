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

# Create virtual environment (the key fix from working system analysis)
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /workspace

# Upgrade pip first
RUN pip install --upgrade pip

# Install basic packages
RUN pip install runpod pillow numpy requests websocket-client \
                aiohttp aiofiles safetensors transformers

# Use STABLE PyTorch with CUDA 12.1 (works perfectly with 12.8.1 runtime)
RUN pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

# Verify it works
RUN python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')"

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