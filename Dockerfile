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

# Test basic pip functionality
RUN echo "=== Python Version ===" && \
    python --version && \
    echo "=== Pip Version ===" && \
    pip --version

# Install packages one by one to see which fails
RUN echo "=== Installing pip upgrade ===" && \
    pip install --upgrade pip

RUN echo "=== Installing runpod ===" && \
    pip install runpod

RUN echo "=== Installing basic packages ===" && \
    pip install pillow numpy requests

RUN echo "=== Installing PyTorch (this might fail) ===" && \
    pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu121 || \
    echo "PyTorch install failed, trying different version..."

# If PyTorch fails, try CPU version as fallback
RUN pip list | grep torch || \
    (echo "Installing CPU PyTorch as fallback..." && \
     pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu)

CMD echo "Build completed - check which packages installed successfully"