# AI-Avatarka - Using Hearmeman's approach with correct base image
FROM hearmeman/comfyui-wan-template:v2

# Keep the environment variables you need
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_PATH="/workspace/ComfyUI"

# Install AI-Avatarka specific dependencies
RUN pip install --no-cache-dir \
    runpod~=1.7.9 \
    gdown>=5.0.0

# Install additional requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Create model directories (following Hearmeman pattern)
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models \
             /workspace/ComfyUI/models/vae \
             /workspace/ComfyUI/models/text_encoders \
             /workspace/ComfyUI/models/clip_vision \
             /workspace/ComfyUI/models/loras

# Copy project files
COPY workflow/ /workspace/ComfyUI/workflow/
COPY prompts/ /workspace/prompts/
COPY src/handler.py /handler.py
COPY builder/ /workspace/builder/
COPY lora/ /workspace/ComfyUI/models/loras/

# Download Wan 2.1 models in separate layers (Hearmeman approach)
RUN wget -P /workspace/ComfyUI/models/diffusion_models \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors

RUN wget -P /workspace/ComfyUI/models/vae \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors

RUN wget -P /workspace/ComfyUI/models/text_encoders \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

RUN wget -P /workspace/ComfyUI/models/clip_vision \
    https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors

# Download LoRA files using your script (allow partial failures)
RUN python /workspace/builder/download_models.py || echo "⚠️ Some LoRA downloads failed - continuing"

# Cleanup
RUN rm -rf /workspace/builder/ /tmp/* /var/tmp/*

# Set working directory
WORKDIR /workspace

# Start the RunPod serverless worker
CMD ["python", "-u", "/handler.py"]