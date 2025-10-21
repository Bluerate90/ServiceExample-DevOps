#!/bin/bash
# Run on master-01
# Usage: ./06-install-observability.sh

set -e
source "$(dirname "$0")/config.sh"

check_node "master-01"

log_info "========== INSTALLING OBSERVABILITY STACK =========="

# Step 1: Add Helm repositories
log_info "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Step 2: Create namespace
log_info "Creating monitoring namespace..."
kubectl create namespace monitoring || log_warn "Namespace already exists"

# Step 3: Install Prometheus Stack
log_info "Installing Prometheus Stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=${PROMETHEUS_RETENTION} \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=${STORAGE_CLASS} \
  --set grafana.adminPassword=${GRAFANA_PASS} \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=${STORAGE_CLASS} \
  --set grafana.persistence.size=10Gi \
  --wait

log_success "Waiting for Prometheus to be ready..."
kubectl rollout status deployment/prometheus-stack-kube-prom-operator -n monitoring --timeout=300s

# Step 4: Install Loki
log_info "Installing Loki..."
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.storageClassName=${STORAGE_CLASS} \
  --set loki.persistence.size=10Gi \
  --set promtail.enabled=true \
  --wait

log_success "========== OBSERVABILITY STACK INSTALLATION COMPLETE =========="

# Port forward for testing
log_info "To access Grafana, run:"
log_info "  kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80"
log_info "Then open: http://localhost:3000 (admin/${GRAFANA_PASS})"