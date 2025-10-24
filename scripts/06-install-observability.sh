#!/bin/bash
# Run on master-01
# Usage: ./06-install-observability.sh
set -e
source "$(dirname "$0")/config.sh"
check_node "master-01"
log_info "========== INSTALLING OBSERVABILITY STACK =========="

# Step 1: Add Helm repositories (re-add to ensure they exist)
log_info "Adding Helm repositories..."
helm repo remove prometheus-community 2>/dev/null || true
helm repo remove grafana 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Step 2: Create namespace
log_info "Creating monitoring namespace..."
kubectl create namespace monitoring || log_warn "Namespace already exists"

# Step 3: Install Prometheus Stack (without persistent storage, without --wait)
log_info "Installing Prometheus Stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec=null \
  --set grafana.persistence.enabled=false \
  --set grafana.adminPassword=${GRAFANA_PASS}

log_info "Waiting for Prometheus operator to be ready..."
kubectl rollout status deployment/prometheus-kube-prometheus-operator -n monitoring --timeout=300s || log_warn "Operator rollout timeout"

log_info "Waiting for Grafana to be ready..."
kubectl rollout status deployment/prometheus-grafana -n monitoring --timeout=300s || log_warn "Grafana rollout timeout"

log_info "Checking pod status..."
kubectl get pods -n monitoring

# Step 4: Install Loki (without persistent storage)
log_info "Installing Loki..."
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=false \
  --set promtail.enabled=true \
  --wait

log_success "========== OBSERVABILITY STACK INSTALLATION COMPLETE =========="

# Port forward for testing
log_info "To access Grafana, run:"
log_info "  kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80"
log_info "Then open: http://localhost:3000 (admin/${GRAFANA_PASS})"