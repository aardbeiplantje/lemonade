build:
```
docker buildx bake -f docker-bake.hcl
```

run:
```
docker run --pull=always --rm -it -p 8000:8000 -v $HF_HOME:/huggingface  ghcr.com/aardbeiplantje/lemonade:latest
```
