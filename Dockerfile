FROM ubuntu:24.04 AS runtime
RUN \
    apt update && apt install -y --no-install-recommends \
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
    libmbedcrypto7t64 \
    && rm -rf /var/lib/apt/lists/*
ADD --chmod=0644 https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x3BF36CFA0BD50AEC /usr/share/keyrings/lemonade-stable.asc
RUN \
    echo "deb [signed-by=/usr/share/keyrings/lemonade-stable.asc] https://ppa.launchpadcontent.net/lemonade-team/stable/ubuntu noble main" \
        > /etc/apt/sources.list.d/lemonade-stable.list \
    && apt update \
    && apt install -y --no-install-recommends lemonade-server \
    && rm -rf /var/lib/apt/lists/*

# embeddable
ARG LEMONADE_VERSION=10.7.0
ADD https://github.com/lemonade-sdk/lemonade/releases/download/v${LEMONADE_VERSION}/lemonade-embeddable-${LEMONADE_VERSION}-ubuntu-x64.tar.gz /tmp/lemonade.tgz
RUN tar xvzf /tmp/lemonade.tgz --strip-components=1 && rm -f /tmp/lemonade.tgz

ARG CACHEBUST=1
RUN apt update && apt upgrade -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /abc
WORKDIR /lemonade-server
RUN useradd -N -M -d /lemonade-server/ -u 1001 lemonade-runtime
RUN mkdir -p /models      && chown -R lemonade-runtime:users /models
RUN mkdir -p /hf          && chown -R lemonade-runtime:users /hf

USER root
RUN    mkdir -p .cache \
    && ln -s /abc .cache/lemonade \
    && chown -R lemonade-runtime:users .cache \
    && chown -R lemonade-runtime:users /lemonade-server \
    && chown -R lemonade-runtime:users /abc

WORKDIR /abc
USER root
ARG LEMONADE_LLAMACPP_VULKAN_VERSION=b9585
ADD https://github.com/ggml-org/llama.cpp/releases/download/${LEMONADE_LLAMACPP_VULKAN_VERSION}/llama-${LEMONADE_LLAMACPP_VULKAN_VERSION}-bin-ubuntu-vulkan-x64.tar.gz llama.tar.gz
RUN    mkdir -p bin/llamacpp/vulkan \
    && tar -xzf llama.tar.gz --strip-components=1 -C bin/llamacpp/vulkan \
    && chown -R lemonade-runtime:users bin/llamacpp/vulkan \
    && rm -f llama.tar.gz

USER root
ARG LEMONADE_LLAMACPP_VERSION=b1292
ADD https://github.com/lemonade-sdk/llamacpp-rocm/releases/download/${LEMONADE_LLAMACPP_VERSION}/llama-${LEMONADE_LLAMACPP_VERSION}-ubuntu-rocm-gfx1151-x64.zip llama-rocm.zip
RUN    mkdir -p bin/llamacpp/rocm-stable \
    && unzip llama-rocm.zip -d bin/llamacpp/rocm-stable \
    && chmod +x bin/llamacpp/rocm-stable/llama* \
    && chown -R lemonade-runtime:users bin/llamacpp/rocm-stable \
    && rm -f llama-rocm.zip

USER root
ARG LLAMACPP_CPU_VERSION=b9585
ADD https://github.com/ggml-org/llama.cpp/releases/download/${LLAMACPP_CPU_VERSION}/llama-${LLAMACPP_CPU_VERSION}-bin-ubuntu-x64.tar.gz llama-cpu.tar.gz
RUN    mkdir -p bin/llamacpp/cpu \
    && tar -xzf llama-cpu.tar.gz --strip-components=1 -C bin/llamacpp/cpu \
    && chmod +x bin/llamacpp/cpu/llama* \
    && chown -R lemonade-runtime:users bin/llamacpp/cpu \
    && rm -f llama-cpu.tar.gz

USER root
ARG LEMONADE_WHISPER_VERSION=v1.8.4
ADD https://github.com/lemonade-sdk/whisper.cpp-builds/releases/download/${LEMONADE_WHISPER_VERSION}/whisper-${LEMONADE_WHISPER_VERSION}-linux-vulkan-x86_64.tar.gz  whisper-vulkan.tar.gz
RUN    mkdir -p bin/whispercpp/vulkan \
    && chown -R lemonade-runtime:users bin/whispercpp/vulkan \
    && tar -xzf whisper-vulkan.tar.gz --strip-components=1 -C bin/whispercpp/vulkan \
    && chmod +x bin/whispercpp/vulkan/whisper* \
    && rm -f whisper-vulkan.tar.gz
ADD https://github.com/lemonade-sdk/whisper.cpp-builds/releases/download/${LEMONADE_WHISPER_VERSION}/whisper-${LEMONADE_WHISPER_VERSION}-linux-cpu-x86_64.tar.gz  whisper-cpu.tar.gz
RUN    mkdir -p bin/whispercpp/cpu \
    && chown -R lemonade-runtime:users bin/whispercpp/cpu \
    && tar -xzf whisper-cpu.tar.gz --strip-components=1 -C bin/whispercpp/cpu \
    && chmod +x bin/whispercpp/cpu/whisper* \
    && rm -f whisper-cpu.tar.gz

USER root
ARG LEMONADE_STABLEDIFFUSIONCPP_VERSION=1f9ee88
ADD https://github.com/leejet/stable-diffusion.cpp/releases/download/master-672-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}/sd-master-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}-bin-Linux-Ubuntu-24.04-x86_64.zip sd-cpp-cpu.zip
RUN    mkdir -p bin/sd-cpp/cpu \
    && chown -R lemonade-runtime:users bin/sd-cpp/cpu \
    && unzip sd-cpp-cpu.zip -d bin/sd-cpp/cpu \
    && chmod +x bin/sd-cpp/cpu/* \
    && rm -f sd-cpp-cpu.zip

USER root
ARG LEMONADE_STABLEDIFFUSIONCPP_VERSION=1f9ee88
ADD https://github.com/leejet/stable-diffusion.cpp/releases/download/master-672-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}/sd-master-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}-bin-Linux-Ubuntu-24.04-x86_64-rocm-7.13.0.zip sd-cpp-rocm.zip
RUN    mkdir -p bin/sd-cpp/rocm-stable \
    && chown -R lemonade-runtime:users bin/sd-cpp/rocm-stable \
    && unzip sd-cpp-rocm.zip -d bin/sd-cpp/rocm-stable \
    && chmod +x bin/sd-cpp/rocm-stable/* \
    && rm -f sd-cpp-rocm.zip

USER root
ARG LEMONADE_STABLEDIFFUSIONCPP_VERSION=1f9ee88
ADD https://github.com/leejet/stable-diffusion.cpp/releases/download/master-672-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}/sd-master-${LEMONADE_STABLEDIFFUSIONCPP_VERSION}-bin-Linux-Ubuntu-24.04-x86_64-vulkan.zip sd-cpp-vulkan.zip
RUN    mkdir -p bin/sd-cpp/vulkan  \
    && chown -R lemonade-runtime:users bin/sd-cpp/vulkan \
    && unzip sd-cpp-vulkan.zip -d bin/sd-cpp/vulkan \
    && chmod +x bin/sd-cpp/vulkan/* \
    && rm -f sd-cpp-vulkan.zip

USER root
ARG LEMONADE_KOKOROS_VERSION=b17
ADD https://github.com/lemonade-sdk/Kokoros/releases/download/${LEMONADE_KOKOROS_VERSION}/kokoros-linux-x86_64.tar.gz kokoro-cpu.tar.gz
RUN    mkdir -p bin/kokoro/cpu  \
    && chown -R lemonade-runtime:users bin/kokoro/cpu \
    && tar -xzf kokoro-cpu.tar.gz --strip-components=1 -C bin/kokoro/cpu \
    && chmod +x bin/kokoro/cpu/* \
    && rm -f kokoro-cpu.tar.gz

USER root
RUN apt update -y && apt install -y \
        libavcodec60 \
        libavformat60 \
        libavutil58 \
        libboost-program-options1.83.0 \
        libfftw3-single3 \
        libreadline8t64 \
        libswresample4 \
        libswscale7 \
        libxrt2 \
        libxrt-npu2 \
    && rm -rf /var/lib/apt/lists/*

ADD https://github.com/FastFlowLM/FastFlowLM/releases/download/v0.9.43/fastflowlm_0.9.43_ubuntu24.04_amd64.deb flm.deb
RUN dpkg -i flm.deb

RUN apt-get update && apt-get install -y strace curl socat \
    && rm -rf /var/lib/apt/lists/*

COPY llamacpp_presets.ini llamacpp_presets.ini

COPY lemonade.sh /lemonade.sh
USER lemonade-runtime
WORKDIR /lemonade-server
ENV LEMONADE_LLAMACPP_ARGS="--models-preset /lemonade/llamacpp_presets.ini --models-dir /models/ --no-webui"
ENV LEMONADE_LLAMACPP=rocm
ENV LEMONADE_STABLEDIFFUSIONCPP=vulkan
ENV LEMONADE_HOST=::
ENV LEMONADE_PORT=9000
ENV LEMONADE_LOG_LEVEL=debug
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
ENTRYPOINT ["/lemonade.sh"]
