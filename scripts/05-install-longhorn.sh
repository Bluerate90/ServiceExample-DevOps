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

# Note: Ensure open-iscsi is installed on all nodes BEFORE running this script
# On each node, run:
#   sudo apt-get install -y open-iscsi
#   sudo systemctl start iscsid
#   sudo systemctl enable iscsid
# Step 2: Add Helm repository
log_info "Adding Longhorn Helm repository..."
helm repo add longhorn https://charts.longhorn.io
helm repo update
# Step 3: Create namespace
log_info "Creating longhorn-system namespace..."
# Wait for any previous namespace deletion to complete
while kubectl get namespace longhorn-system &>/dev/null; do
  log_info "Waiting for namespace to be deleted..."
  sleep 5
done
kubectl create namespace longhorn-system || log_warn "Namespace already exists"
# Step 4: Check if Longhorn is already installed
log_info "Checking if Longhorn is already installed..."
if helm list -n longhorn-system | grep -q "longhorn"; then
  log_warn "Longhorn is already installed, skipping installation"
else
  log_info "Installing Longhorn..."
  helm install longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --set persistence.defaultClassReplicaCount=2 \
    --set defaultSettings.replicaAutoBalance=best-effort
fi
log_success "Waiting for Longhorn to be ready..."
kubectl rollout status daemonset/longhorn-manager -n longhorn-system --timeout=300s
log_success "========== LONGHORN INSTALLATION COMPLETE =========="
# Verify
kubectl get storageclass
kubectl get pods -n longhorn-system