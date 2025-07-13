# AI-Avatarka - Build-time model downloads (proper approach)
FROM hearmeman/comfyui-wan-template:v2

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install dependencies
RUN pip install --no-cache-dir runpod~=1.7.9 gdown>=5.0.0

# Copy and install requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Create model directories
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/models/loras

# Copy project files first (small files)
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY lora/ /workspace/ComfyUI/models/loras/
COPY builder/ /workspace/builder/
COPY src/handler.py /workspace/src/handler.py

# Download models in separate layers (Hearmeman approach) - each RUN = separate layer
# This prevents the space issue by creating cacheable layers

# Download main diffusion model (largest first)
RUN echo "📦 Downloading diffusion model..." && \
    wget --progress=dot:giga --timeout=1800 --tries=3 \
    -O /workspace/ComfyUI/models/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors" && \
    echo "✅ Diffusion model downloaded" && \
    ls -lh /workspace/ComfyUI/models/diffusion_models/

# Download VAE
RUN echo "📦 Downloading VAE..." && \
    wget --progress=dot:giga --timeout=600 --tries=3 \
    -O /workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" && \
    echo "✅ VAE downloaded"

# Download text encoder
RUN echo "📦 Downloading text encoder..." && \
    wget --progress=dot:giga --timeout=600 --tries=3 \
    -O /workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" && \
    echo "✅ Text encoder downloaded"

# Download CLIP vision
RUN echo "📦 Downloading CLIP vision..." && \
    wget --progress=dot:giga --timeout=600 --tries=3 \
    -O /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" && \
    echo "✅ CLIP vision downloaded"

# Download LoRA files (non-critical, allow failures)
RUN echo "🎭 Downloading LoRA files..." && \
    python /workspace/builder/download_models.py || \
    echo "⚠️ Some LoRA downloads failed - continuing"

# Verify all critical models are present
RUN echo "🔍 Verifying models..." && \
    ls -lh /workspace/ComfyUI/models/diffusion_models/ && \
    ls -lh /workspace/ComfyUI/models/vae/ && \
    ls -lh /workspace/ComfyUI/models/text_encoders/ && \
    ls -lh /workspace/ComfyUI/models/clip_vision/ && \
    echo "✅ Model verification complete"

# Clean up build files
RUN rm -rf /workspace/builder/ /tmp/* /var/tmp/*

# Create simple startup script that just starts the handler
RUN echo '#!/usr/bin/env python3\n\
import sys\n\
sys.path.append("/workspace/src")\n\
from handler import handler\n\
import runpod\n\
print("🚀 Starting AI-Avatarka handler...")\n\
runpod.serverless.start({"handler": handler})\n\
' > /workspace/start.py && chmod +x /workspace/start.py

WORKDIR /workspace
CMD ["python", "/workspace/start.py"]