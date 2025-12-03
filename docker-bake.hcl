variable "TAG" {
  default = "slim"
}

# Common settings for all targets
target "common" {
  context = "."
  platforms = ["linux/amd64"]
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
}

# Regular ComfyUI image (CUDA 12.4)
target "regular" {
  inherits = ["common"]
  dockerfile = "Dockerfile"
  tags = [
    "yourusername/runpodapps:${TAG}",
    "yourusername/runpodapps:latest",
  ]
}

# Dev image for local testing
target "dev" {
  inherits = ["common"]
  dockerfile = "Dockerfile"
  tags = ["runpod/comfyui:dev"]
  output = ["type=docker"]
}

# Dev push target (for CI pushing dev tags, without overriding latest)
target "devpush" {
  inherits = ["common"]
  dockerfile = "Dockerfile"
  tags = ["runpod/comfyui:dev"]
}
