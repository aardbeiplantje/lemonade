FROM debian:trixie-slim AS runtime
WORKDIR /tmp
ARG LEMONADE_VERSION=9.3.4
ADD https://github.com/lemonade-sdk/lemonade/releases/latest/download/lemonade-server-minimal_${LEMONADE_VERSION}_amd64.deb lemonade.deb
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

RUN useradd -N -M -d /lemonade-server/ -u 1000 lemonade-runtime
RUN mkdir -p /models      && chown -R lemonade-runtime:users /models
RUN mkdir -p /hf          && chown -R lemonade-runtime:users /hf

WORKDIR /lemonade
USER root
RUN    mkdir -p /lemonade-server/.cache \
    && ln -s /lemonade /lemonade-server/.cache/lemonade \
    && chown -R lemonade-runtime:users /lemonade-server/.cache \
    && chown -R lemonade-runtime:users /lemonade

WORKDIR /lemonade
USER root
ARG LEMONADE_LLAMACPP_VULKAN_VERSION=b8088
ADD https://github.com/ggml-org/llama.cpp/releases/download/${LEMONADE_LLAMACPP_VULKAN_VERSION}/llama-${LEMONADE_LLAMACPP_VULKAN_VERSION}-bin-ubuntu-vulkan-x64.tar.gz llama.tar.gz
RUN    mkdir -p /lemonade/bin/llamacpp/vulkan \
    && tar -xvf llama.tar.gz --strip-components=1 -C /lemonade/bin/llamacpp/vulkan \
    && chown -R lemonade-runtime:users /lemonade/bin/llamacpp/vulkan \
    && rm -f llama.tar.gz

USER root
ARG LEMONADE_LLAMACPP_VERSION=b1190
ADD https://github.com/lemonade-sdk/llamacpp-rocm/releases/download/${LEMONADE_LLAMACPP_VERSION}/llama-${LEMONADE_LLAMACPP_VERSION}-ubuntu-rocm-gfx1151-x64.zip llama-rocm.zip
RUN    mkdir -p /lemonade/bin/llamacpp/rocm \
    && unzip llama-rocm.zip -d /lemonade/bin/llamacpp/rocm \
    && chmod +x /lemonade/bin/llamacpp/rocm/llama* \
    && chown -R lemonade-runtime:users /lemonade/bin/llamacpp/rocm \
    && rm -f llama-rocm.zip

USER root
RUN    mkdir -p /lemonade/bin/whisper \
    && chown -R lemonade-runtime:users /lemonade/bin/whisper

USER root
ARG LEMONADE_STABLEDIFFUSIONCPP_VERSION=636d3cb
ADD https://github.com/leejet/stable-diffusion.cpp/releases/download/master-504-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}/sd-master-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}-bin-Linux-Ubuntu-24.04-x86_64.zip sd-cpp.zip
RUN    mkdir -p /lemonade/bin/sd-cpp \
    && chown -R lemonade-runtime:users /lemonade/bin/sd-cpp \
    && unzip sd-cpp.zip -d /lemonade/bin/sd-cpp \
    && chmod +x /lemonade/bin/sd-cpp/sd* \
    && rm -f sd-cpp.zip

COPY llamacpp_presets.ini /lemonade/llamacpp_presets.ini

USER lemonade-runtime
WORKDIR /lemonade-server
ENV LEMONADE_LLAMACPP_ARGS="--models-preset /lemonade/llamacpp_presets.ini --models-dir /models/ --no-webui"
ENV LEMONADE_LLAMACPP=rocm
ENV LEMONADE_STABLEDIFFUSIONCPP=vulkan
ENV LEMONADE_HOST=::
ENV LEMONADE_PORT=8000
ENV LEMONADE_LOG_LEVEL=info
ENV LEMONADE_CTX_SIZE=0
ENV LEMONADE_ENABLE_DGPU_GTT=1
ENV LEMONADE_DISABLE_MODEL_FILTERING=0
ENV LEMONADE_EXTRA_MODELS_DIR=/models
ENV TMPDIR=/dev/shm
ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV HF_HUB_ENABLE_HF_TRANSFER=0
ENV HF_HUB_DISABLE_XET=1
ENV HF_HUB_CACHE=/hf/hub
ENV HF_HOME=/hf
ENV HSA_OVERRIDE_GFX_VERSION=11.5.1
ENV AMD_SERIALIZE_KERNEL=1
ENV GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
ENTRYPOINT ["/usr/bin/lemonade-server", "serve", "--max-loaded-models", "5"]
ENTRYPOINT ["/lemonade-server//.cache/lemonade/bin/llamacpp/rocm/llama-server", "--models-preset", "/lemonade/llamacpp_presets.ini", "--models-dir", "/models/", "--no-webui", "--host", "::", "--port", "8000"]
