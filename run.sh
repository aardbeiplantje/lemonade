#!/bin/bash
HF_HOME=${HF_HOME:-lemonade-huggingface}
DOCKER_IMAGE=${DOCKER_IMAGE:-local/ai/lemonade-gfx1151:latest}
extra_args=""
if [ ! -z "$LEMONADE_MODELS_PRESETS" ]; then
    extra_args="$extra_args -v $LEMONADE_MODELS_PRESETS:/lemonade/llamacpp_presets.ini:ro"
fi
if [ ! -z "$LEMONADE_MODELS_DIR" ]; then
    extra_args="$extra_args -v $LEMONADE_MODELS_DIR:/models:rw"
else
    extra_args="$extra_args -v lemonade-models:/models:rw"
fi
if [ ! -z "$LEMONADE_FLM_MODELS_DIR" ]; then
    extra_args="$extra_args -v $LEMONADE_FLM_MODELS_DIR:/lemonade-server/.config/flm/models:rw"
else
    extra_args="$extra_args -v lemonade-flm-models:/lemonade-server/.config/flm/models:rw"
fi
ROCM_PATH=${ROCM_PATH:-/opt/rocm}
docker stop lemonade >/dev/null 2>&1 || true
docker rm   lemonade >/dev/null 2>&1 || true
exec docker run --rm \
    --detach \
    --name lemonade \
    --network=host \
    -v $HF_HOME:/hf:rw \
    $extra_args \
    --device=/dev/kfd \
    --device=/dev/dri \
    --device=/dev/accel \
    --group-add=video \
    --group-add=226 \
    --ipc=host \
    --ulimit memlock=-1:-1 \
    --ulimit stack=67108864:67108864 \
    --cap-add=SYS_PTRACE \
    --cap-add=SYS_ADMIN \
    --security-opt seccomp=unconfined \
    --group-add=109 \
    --group-add=986 \
    --group-add=992 \
    --group-add=$(id -g) \
    --tmpfs /tmp:rw,suid,exec,size=1G \
    --tmpfs /var/tmp:rw,suid,exec,size=1G \
    -e ROCM_PATH=/opt/rocm \
    -v llama.cpp-data:/llama.cpp:rw \
    -v $ROCM_PATH:/opt/rocm:ro \
    ${DOCKER_IMAGE} \
        $*

