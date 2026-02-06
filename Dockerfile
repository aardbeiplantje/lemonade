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
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*
RUN dpkg -i lemonade.deb && rm -f lemonade.deb

ARG CACHEBUST=1
RUN apt update && apt upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -N -M -d /lemonade-server/ -u 1000 lemonade-runtime \
    && mkdir -p /models      && chown -R lemonade-runtime:users /models \
    && mkdir -p /huggingface && chown -R lemonade-runtime:users /huggingface \
    && mkdir -p /lemonade    && chown -R lemonade-runtime:users /lemonade
ADD https://github.com/ggml-org/llama.cpp/releases/download/b7869/llama-b7869-bin-ubuntu-vulkan-x64.tar.gz llama.tar.gz
RUN    mkdir -p /lemonade-server/.cache \
    && mkdir -p /lemonade/bin/llama/vulkan \
    && tar -xvf llama.tar.gz --strip-components=1 -C /lemonade/bin/llama/vulkan \
    && rm -f llama.tar.gz \
    && ln -s /lemonade /lemonade-server/.cache/lemonade

USER lemonade-runtime
WORKDIR /lemonade-server
ENV LEMONADE_LLAMACPP_ARGS="--no-mmap --prio 3 --no-kv-offload --context-shift --no-warmup --batch-size 2048 --flash-attn on --ubatch-size 1024"
ENV LEMONADE_LLAMACPP="rocm"
ENV LEMONADE_HOST="0.0.0.0"
ENV LEMONADE_PORT="8000"
ENV LEMONADE_LOG_LEVEL="info"
ENV LEMONADE_CTX_SIZE="4096"
ENV LEMONADE_ENABLE_DGPU_GTT="1"
ENV LEMONADE_DISABLE_MODEL_FILTERING="1"
ENV LEMONADE_EXTRA_MODELS_DIR="/models"
ENV TMPDIR="/lemonade/tmp"
ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV HF_HUB_ENABLE_HF_TRANSFER=0
ENV HF_HUB_DISABLE_XET=1
ENV HF_HOME="/huggingface"
ENV HF_HUB_CACHE="/huggingface/hub"
ENTRYPOINT ["/usr/bin/lemonade-server", "serve"]
