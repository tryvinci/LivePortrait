FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-devel

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    wget \
    build-essential \
    ninja-build \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# copy the code
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Download pretrained weights from HuggingFace
RUN pip install --no-cache-dir -U "huggingface_hub[cli]" && \
    huggingface-cli download KwaiVGI/LivePortrait --local-dir pretrained_weights --exclude "*.git*" "README.md" "docs"

# Create a startup script
RUN echo '#!/bin/bash\n\
# Build the MultiScaleDeformableAttention operator if not already built\n\
if [ ! -f "/app/src/utils/dependencies/XPose/models/UniPose/ops/build/lib.*/*.so" ]; then\n\
    echo "Building MultiScaleDeformableAttention operator..."\n\
    cd /app/src/utils/dependencies/XPose/models/UniPose/ops\n\
    python setup.py build install\n\
    cd /app\n\
fi\n\
# Start the application\n\
exec python app_animals.py --server_name 0.0.0.0 --server_port 3000' > /app/start.sh

RUN chmod +x /app/start.sh

# Expose port for Gradio app
EXPOSE 3000

# Set entrypoint
ENTRYPOINT ["/app/start.sh"]
