#!/bin/bash
# Sign Docker image with Cosign
# Run locally or in CI/CD pipeline
# Usage: ./09-sign-image.sh <image-name:tag>

set -e
source "$(dirname "$0")/config.sh"

if [ -z "$1" ]; then
    log_error "Usage: ./09-sign-image.sh <image-name:tag>"
    log_error "Example: ./09-sign-image.sh mycontainerregistry.azurecr.io/serviceexample:latest"
    exit 1
fi

IMAGE=$1

log_info "========== SIGNING DOCKER IMAGE =========="

# Step 1: Install Cosign
log_info "Installing Cosign..."
if ! command -v cosign &> /dev/null; then
    curl -sLO https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign-linux-amd64
    chmod +x cosign-linux-amd64
    sudo mv cosign-linux-amd64 /usr/local/bin/cosign
fi

# Step 2: Check for cosign key
if [ ! -f "cosign.key" ]; then
    log_error "cosign.key not found. Generate with: cosign generate-key-pair"
    exit 1
fi

# Step 3: Sign image
log_info "Signing image: $IMAGE"
cosign sign --key cosign.key \
  -a git_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown") \
  -a build_time=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  $IMAGE

log_success "========== IMAGE SIGNED =========="

# Verify
log_info "Verifying signature..."
cosign verify --key cosign.pub $IMAGE