group "default" {
  targets = ["local"]
}
group "local" {
  targets = ["_local"]
}
group "release" {
  targets = ["containers"]
}
variable "DOCKER_REGISTRY" {
  default = "local"
}
variable "DOCKER_REPOSITORY" {
  default = "ai"
}
variable "DOCKER_IMAGE_NAME" {
  default = "lemonade"
}
variable "DOCKER_TAG" {
  default = "latest"
}
target "_common" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64"]
  networks = ["host"]
  buildkit = true
}

target "_local" {
  inherits = ["_common"]
  target = "runtime"
  tags = [
    "local/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG}",
  ]
  output = [
    "type=docker,name=local/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
  ]
}

target "containers" {
  pull = true
  name = "containers-${env}"
  matrix = {
    env = ["release"]
  }
  progress = ["plain", "tty"]
  tags = [
    "${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG}",
  ]
  output = [
    "type=image,name=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG},push=true"
  ]
  cache-to = [
    "type=registry,ref=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:cache,mode=max"
  ]
  cache-from = [
    "type=registry,ref=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:cache",
    "type=registry,ref=${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
  ]
  target = "runtime"
  buildkit = true
  attest = [
    "type=provenance,mode=max",
    "type=sbom",
  ]
  context = "."
  dockerfile = "Dockerfile"
  networks = ["host"]
  platforms = [
    "linux/amd64"
  ]
  args = {
    CACHEBUST = "1"
  }
}
