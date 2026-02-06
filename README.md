build:
```
docker buildx bake -f docker-bake.hcl
```

run:
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
