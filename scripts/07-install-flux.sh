#!/bin/bash
# Run on master-01
# Usage: ./07-install-flux.sh <github-username> <github-token>

set -e
source "$(dirname "$0")/config.sh"

check_node "master-01"

if [ -z "$1" ] || [ -z "$2" ]; then
    log_error "Usage: ./07-install-flux.sh <github-username> <github-token>"
    log_error "Get token from: https://github.com/settings/tokens"
    exit 1
fi

GITHUB_USER=$1
GITHUB_TOKEN=$2
GITHUB_REPO="ServiceExample-DevOps"

log_info "========== INSTALLING FLUX CD =========="

# Step 1: Install Flux CLI
log_info "Installing Flux CLI..."
curl -s https://fluxcd.io/install.sh | sudo bash
flux version

# Step 2: Pre-create namespace for FluxCD
kubectl create namespace flux-system || log_warn "Namespace already exists"

# Step 3: Bootstrap Flux
log_info "Bootstrapping FluxCD with GitHub..."
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repo=$GITHUB_REPO \
  --path=k8s/gitops/infrastructure \
  --personal \
  --private=false \
  --token-auth

log_success "Waiting for Flux to be ready..."
kubectl rollout status deployment/source-controller -n flux-system --timeout=300s
kubectl rollout status deployment/helm-controller -n flux-system --timeout=300s

log_success "========== FLUX CD INSTALLATION COMPLETE =========="

# Verify
log_info "Checking Flux sources..."
flux get sources all -A