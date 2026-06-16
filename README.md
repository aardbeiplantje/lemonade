# Lemonade

Lemonade is a Docker-based AI inference server that bundles multiple AI backends into a single container image. It supports LLM inference, text-to-speech, speech recognition, and image generation on a single unified API.

## Backends

- **LLM inference** via llama.cpp (CPU, Vulkan, ROCm backends)
- **Text-to-speech** via Kokoro (CPU)
- **Speech recognition** via whisper.cpp (Vulkan, CPU)
- **Image generation** via stable-diffusion.cpp (CPU, ROCm, Vulkan)
- **FastFlowLM** for additional inference capabilities
- **Ryzen AI** NPU support

## Build

```
docker buildx bake -f docker-bake.hcl
```

Release builds (pushes to registry with provenance and SBOM attestations):

```
docker buildx bake -f docker-bake.hcl release
```

## Run

### Quick start with run.sh

```
./run.sh
```

### Manual docker run

```
docker run --pull=always \
    --rm \
    -it \
    -p 8000:8000 \
    -v $HF_HOME:/huggingface \
    --device=/dev/kfd \
    --device=/dev/dri \
    --group-add=video \
    --group-add=render \
    --group-add=992 \
    --ipc=host \
    --cap-add=SYS_PTRACE \
    --security-opt \
    seccomp=unconfined \
    ghcr.com/aardbeiplantje/lemonade:latest
```

### Configuration

Run the setup script to configure the server:

```
./lemonade_setup.sh
```

Or edit `config.json` directly. Key settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `ctx_size` | 1000000 | Context window size |
| `port` | 9000 | Server port |
| `host` | :: | Bind address (IPv6 all interfaces) |
| `max_loaded_models` | 1 | Maximum models loaded simultaneously |
| `log_level` | debug | Logging verbosity |
| `llamacpp.backend` | rocm | Default LLM backend |
| `sdcpp.backend` | rocm | Default image generation backend |
| `whispercpp.backend` | vulkan | Default speech recognition backend |
| `models_dir` | auto | Primary model directory |
| `extra_models_dir` | /models | Extra model directory |
| `huggingface_cache` | /hf/hub | Hugging Face Hub cache location |

## Hardware Requirements

- **AMD GPU** recommended (gfx1151 / Radeon 7900 series with ROCm)
- Vulkan and CPU backends available as alternatives
- ROCm device access (`/dev/kfd`, `/dev/dri`, `/dev/accel`) required for GPU usage
- Host kernel with ROCm support

## Model Management

Models are stored in `/models` (extra) and the Hugging Face cache at `/hf/hub`. Place `.gguf` model files in these directories for automatic discovery.

`llamacpp_presets.ini` provides optimized inference presets for supported models including GLM-4.7, Qwen3, gemma-3, and Nemotron variants.

## Entrypoint

The container entrypoint (`lemonade.sh`) supports three modes:

- `./lemonade.sh` -- Starts the Lemonade server (`/usr/bin/lemond --host :: --port 13305`)
- `./lemonade.sh bash` -- Drops into an interactive shell
- `./lemonade.sh <cmd>` -- Executes the given command

## License

Public domain -- [Unlicense](LICENSE). No restrictions, free for any use.
