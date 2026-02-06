FROM debian:trixie-slim AS runtime
WORKDIR /tmp
ADD https://github.com/lemonade-sdk/lemonade/releases/latest/download/lemonade-server-minimal_9.3.0_amd64.deb lemonade.deb
RUN apt update && apt install -y --no-install-recommends \
    ca-certificates \
    libcurl4 \
    libssl3 \
    unzip \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libatspi2.0-0 \
    libsecret-1-0 \
    fonts-katex \
    && rm -rf /var/lib/apt/lists/*
RUN dpkg -i lemonade.deb && rm -f lemonade.deb

ARG CACHEBUST=1
RUN apt update && apt upgrade -y \
    && rm -rf /var/lib/apt/lists/*


RUN useradd -N -M -d /dev/shm/ -u 1000 lemonade-runtime
USER lemonade-runtime
RUN mkdir -p /models
WORKDIR /dev/shm
ENV LEMONADE_LLAMACPP_ARGS="--no-mmap --prio 3 --no-kv-offload --context-shift --no-warmup --batch-size 2048 --flash-attn on --ubatch-size 1024"
ENV LEMONADE_LLAMACPP_BACKEND="rocm"
ENV LEMONADE_HOST="0.0.0.0"
ENV LEMONADE_PORT="8000"
ENV LEMONADE_LOG_LEVEL="info"
ENV LEMONADE_CTX_SIZE="4096"
ENV LEMONADE_ENABLE_DGPU_GTT="1"
ENV LEMONADE_DISABLE_MODEL_FILTERING="1"
ENV LEMONADE_EXTRA_MODELS_DIR="/models"
ENTRYPOINT ["/usr/bin/lemonade-server", "serve"]
