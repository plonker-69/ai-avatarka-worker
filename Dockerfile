FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Set python3.12 as default (Ubuntu 24.04 uses Python 3.12)
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv && \
    ln -sf $(which python3) /usr/local/bin/python && \
    ln -sf $(which python3) /usr/local/bin/python3

# Install system dependencies
RUN apt-get install -y \
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

# Create virtual environment to handle Ubuntu 24.04 PEP 668
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies in virtual environment
COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip && \
    pip install --upgrade -r /requirements.txt --no-cache-dir

# Copy project files
COPY builder/ /builder/
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY src/handler.py /handler.py

# Install ComfyUI during build
RUN python /builder/install_comfyui.py

# Setup custom nodes during build  
RUN python /builder/setup_custom_nodes.py

# Download models during build
RUN python /builder/download_models.py

# Set working directory
WORKDIR /workspace

# Start the worker
CMD ["python", "-u", "/handler.py"]