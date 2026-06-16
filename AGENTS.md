# AGENTS.md

## Project: Lemonade

Lemonade is a Docker-based AI inference server bundling multiple AI backends (llama.cpp, whisper.cpp, stable-diffusion.cpp, Kokoro TTS, FastFlowLM, Ryzen AI) into a single container image for AMD GPU hardware.

## Build System

- **Docker Buildx Bake** is the primary build tool (`docker-bake.hcl`)
- Main image target: `local/ai/lemonade-gfx1151:latest`
- Release target pushes to registry with provenance and SBOM attestations
- Base image: Ubuntu 24.04

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage Docker image definition (Ubuntu 24.04 base) |
| `docker-bake.hcl` | Docker Buildx Bake orchestration (local + release targets) |
| `config.json` | Lemonade server configuration (backends, ports, model dirs) |
| `lemonade.sh` | Container entrypoint script |
| `lemonade_setup.sh` | CLI configuration setup script |
| `run.sh` | Convenience Docker run script with GPU mounts |
| `llamacpp_presets.ini` | llama.cpp model inference presets |
| `.dockerignore` | Docker build exclusions |
| `.gitignore` | Git ignore (backup files) |

## Conventions

- **No new .md files** unless explicitly requested by the user
- **Do not create documentation files (README, CHANGELOG, etc.)** unless explicitly asked
- Backup files (`*~`) are in `.dockerignore` and `.gitignore` -- safe to ignore
- ROCm is the primary GPU backend; Vulkan and CPU are fallbacks
- Models directory: `/models` (extra), Hugging Face cache: `/hf/hub`
- All config goes through `config.json` and/or `lemonade_setup.sh`
- GPU device mounts: `/dev/kfd`, `/dev/dri`, `/dev/accel`
- `run.sh` uses host networking with `SYS_PTRACE` capability

## Dockerfile Guidelines

- Uses PPA for lemonade-server: `ppa:lemonade-team/stable`
- Version pinning: Lemonade Embeddable 10.7.0, llama.cpp b9585, whisper.cpp v1.8.4
- Environment variables for ROCm, GGML, Hugging Face are already set
- Rock AMD GPU driver symlink is commented out (known issue)
- Entry point: `/lemonade.sh`

## Agent Behavior

- When editing `config.json`, also check if `lemonade_setup.sh` needs updating
- When modifying GPU-related configs, verify `run.sh` device mounts are consistent
- When adding new backends, update `llamacpp_presets.ini` for compatible models
- Never commit secrets or API keys
- Always run `git status` before committing to verify staged changes
