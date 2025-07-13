# AI-Avatarka RunPod Serverless Worker - GitHub Actions Compatible
FROM hearmeman/comfyui-wan-template:v2

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install additional dependencies
RUN pip install --no-cache-dir runpod~=1.7.9 gdown>=5.0.0

# Create all necessary directories
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/models/loras \
             /workspace/ComfyUI/workflow \
             /workspace/prompts

# Copy requirements and install
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Copy project files (order matters for caching)
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY src/handler.py /handler.py

# Copy builder scripts
COPY builder/ /workspace/builder/
RUN chmod +x /workspace/builder/*.py

# Copy lora directory (create empty if doesn't exist)
COPY lora/ /workspace/ComfyUI/models/loras/ 2>/dev/null || mkdir -p /workspace/ComfyUI/models/loras

# Download models in single RUN command for better layer efficiency
RUN echo "📦 Starting model downloads..." && \
    \
    echo "Downloading diffusion model..." && \
    wget --progress=dot:giga --timeout=900 --tries=2 \
    -O /workspace/ComfyUI/models/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors" && \
    \
    echo "Downloading VAE..." && \
    wget --progress=dot:giga --timeout=300 --tries=2 \
    -O /workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" && \
    \
    echo "Downloading text encoder..." && \
    wget --progress=dot:giga --timeout=300 --tries=2 \
    -O /workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" && \
    \
    echo "Downloading CLIP vision..." && \
    wget --progress=dot:giga --timeout=300 --tries=2 \
    -O /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" && \
    \
    echo "✅ Core models downloaded" && \
    ls -la /workspace/ComfyUI/models/*/

# Download LoRA files (allow partial failures)
RUN echo "🎭 Downloading LoRA files..." && \
    python /workspace/builder/download_models.py || \
    echo "⚠️ Some LoRA downloads failed - continuing anyway"

# Cleanup to reduce image size
RUN rm -rf /workspace/builder/ /tmp/* /var/tmp/* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Start the serverless worker
CMD ["python", "-u", "/handler.py"]