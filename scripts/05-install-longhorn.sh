#!/bin/bash
# Run on master-01
# Usage: ./05-install-longhorn.sh

set -e
source "$(dirname "$0")/config.sh"

check_node "master-01"

log_info "========== INSTALLING LONGHORN =========="

# Step 1: Check prerequisites
log_info "Checking prerequisites..."
check_prerequisites helm kubectl

# Step 2: Add Helm repository
log_info "Adding Longhorn Helm repository..."
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Step 3: Create namespace
log_info "Creating longhorn-system namespace..."
kubectl create namespace longhorn-system || log_warn "Namespace already exists"

# Step 4: Install Longhorn
log_info "Installing Longhorn..."
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set persistence.defaultClassReplicaCount=2 \
  --set defaultSettings.replicaAutoBalance=best-effort \
  --wait

log_success "Waiting for Longhorn to be ready..."
kubectl rollout status deployment/longhorn-manager -n longhorn-system --timeout=300s

log_success "========== LONGHORN INSTALLATION COMPLETE =========="

# Verify
kubectl get storageclass
kubectl get pods -n longhorn-system