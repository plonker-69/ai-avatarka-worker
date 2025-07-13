# AI-Avatarka RunPod Serverless Worker - Hearmeman-Inspired Multi-Stage Build
# Based on hearmeman's approach with separate model downloads
FROM hearmeman/comfyui-wan-template:v2 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install minimal additional dependencies
RUN pip install --no-cache-dir runpod~=1.7.9 gdown>=5.0.0

# Copy project files
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY builder/ /builder/
COPY src/handler.py /handler.py

# Create model directories structure
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/models/loras

# Copy any local LoRA files (if you have them)
COPY lora/ /workspace/ComfyUI/models/loras/

# Set working directory
WORKDIR /workspace

# Multi-stage approach - models will be downloaded separately
FROM base AS models

# Download models in separate layers to optimize caching and space usage
# Split downloads to avoid massive single layers

# Download main diffusion model
RUN wget --progress=dot:giga \
    -O /workspace/ComfyUI/models/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors

# Download VAE
RUN wget --progress=dot:giga \
    -O /workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors

# Download text encoder
RUN wget --progress=dot:giga \
    -O /workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

# Download CLIP vision
RUN wget --progress=dot:giga \
    -O /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors

# Download LoRA files using our script
RUN python /builder/download_models.py

# Clean up downloads and caches to reduce final image size
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /root/.cache/* && \
    rm -rf /builder/

# Final stage - copy everything together
FROM base AS final

# Copy all downloaded models from the models stage
COPY --from=models /workspace/ComfyUI/models/ /workspace/ComfyUI/models/

# Verify models are present
RUN ls -la /workspace/ComfyUI/models/diffusion_models/ && \
    ls -la /workspace/ComfyUI/models/vae/ && \
    ls -la /workspace/ComfyUI/models/text_encoders/ && \
    ls -la /workspace/ComfyUI/models/clip_vision/ && \
    ls -la /workspace/ComfyUI/models/loras/

# Set working directory
WORKDIR /workspace

# Start the serverless worker
CMD ["python", "-u", "/handler.py"]