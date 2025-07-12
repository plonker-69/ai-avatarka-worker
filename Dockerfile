FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 python3-pip python3.12-dev \
        git wget curl && \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Install basic requirements only
RUN pip install --upgrade pip && \
    pip install runpod torch torchvision torchaudio \
                pillow numpy requests websocket-client \
                aiohttp aiofiles

# Install ComfyUI - minimal setup
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install -r requirements.txt

# Copy your handler and configs
COPY src/handler.py /handler.py
COPY prompts/ /workspace/prompts/
COPY workflow/ /workspace/ComfyUI/workflow/

# Create basic directories
RUN mkdir -p /workspace/ComfyUI/models/lora \
             /workspace/ComfyUI/input \
             /workspace/ComfyUI/output

CMD python -u /handler.py