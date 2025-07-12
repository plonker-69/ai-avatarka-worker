# AI-Avatarka RunPod Serverless Worker
# Built on hearmeman's ComfyUI + Wan template
FROM hearmeman/comfyui-wan-template:v2

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install minimal additional system dependencies if needed
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python dependencies for our handler
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy our project files
COPY builder/ /builder/
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY src/handler.py /handler.py

# Download our specific LoRA files and any missing models
RUN python /builder/download_models.py

# Copy any local LoRA files (if you have them)
COPY lora/ /workspace/ComfyUI/models/loras/

# Set working directory
WORKDIR /workspace

# Health check to ensure ComfyUI can start
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://127.0.0.1:8188/', timeout=5)" || exit 1

# Start the serverless worker
CMD python -u /handler.py