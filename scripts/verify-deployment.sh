#!/bin/bash
# Verify complete deployment
# Usage: ./verify-deployment.sh

set -e
source "$(dirname "$0")/config.sh"

log_info "========== VERIFYING DEPLOYMENT =========="

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed"
    exit 1
fi

# 1. Check cluster connectivity
log_info "Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    log_success "✓ Cluster connected"
else
    log_error "✗ Cannot connect to cluster"
    exit 1
fi

# 2. Check all nodes
log_info "Checking nodes..."
NODES_READY=$(kubectl get nodes --no-headers | grep -c "Ready" || true)
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
if [ $NODES_READY -eq $TOTAL_NODES ]; then
    log_success "✓ All nodes ready ($NODES_READY/$TOTAL_NODES)"
    kubectl get nodes -o wide
else
    log_warn "⚠ Not all nodes ready ($NODES_READY/$TOTAL_NODES)"
fi

# 3. Check storage
log_info "Checking storage..."
if kubectl get storageclass longhorn &> /dev/null; then
    log_success "✓ Longhorn storage configured"
    kubectl get pvc -A
else
    log_warn "⚠ Longhorn not found"
fi

# 4. Check monitoring
log_info "Checking monitoring stack..."
if kubectl get deployment -n monitoring prometheus-stack-kube-prom-operator &> /dev/null; then
    log_success "✓ Monitoring stack deployed"
    kubectl get pods -n monitoring
else
    log_warn "⚠ Monitoring stack not deployed"
fi

# 5. Check Flux
log_info "Checking FluxCD..."
if kubectl get pods -n flux-system &> /dev/null; then
    log_success "✓ FluxCD installed"
    flux get sources all -A
    flux get helmreleases -A
else
    log_warn "⚠ FluxCD not installed"
fi

# 6. Check Sealed Secrets
log_info "Checking Sealed Secrets..."
if kubectl get deployment -n kube-system sealed-secrets-sealed-secrets &> /dev/null; then
    log_success "✓ Sealed Secrets controller running"
else
    log_warn "⚠ Sealed Secrets not installed"
fi

# 7. Check application
log_info "Checking application deployment..."
if kubectl get deployment serviceexample &> /dev/null; then
    READY=$(kubectl get deployment serviceexample -o jsonpath='{.status.readyReplicas}' || echo "0")
    DESIRED=$(kubectl get deployment serviceexample -o jsonpath='{.spec.replicas}' || echo "0")
    log_success "✓ Application deployed ($READY/$DESIRED replicas)"
    kubectl get pods -l app.kubernetes.io/name=serviceexample
else
    log_warn "⚠ Application not deployed"
fi

# 8. Check Cloudflare Tunnel
log_info "Checking Cloudflare Tunnel..."
if kubectl get deployment -n cloudflare-tunnel cloudflare-tunnel &> /dev/null; then
    log_success "✓ Cloudflare Tunnel running"
    kubectl get pods -n cloudflare-tunnel
else
    log_warn "⚠ Cloudflare Tunnel not deployed"
fi

# 9. Check persistent volumes
log_info "Checking persistent volumes..."
PVCS=$(kubectl get pvc -A --no-headers 2>/dev/null | wc -l || echo "0")
if [ $PVCS -gt 0 ]; then
    log_success "✓ Persistent volumes configured ($PVCS found)"
    kubectl get pvc -A
else
    log_warn "⚠ No persistent volumes found"
fi

# 10. Check services
log_info "Checking services..."
kubectl get svc -A --no-headers | head -20

# 11. Check events
log_info "Recent cluster events (last 10):"
kubectl get events -A --sort-by='.lastTimestamp' | tail -10

# Summary
log_success "========== VERIFICATION COMPLETE =========="
log_info ""
log_info "Access Points:"
log_info "  Grafana: kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80"
log_info "  Prometheus: kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090"
log_info "  App: kubectl port-forward svc/serviceexample 5000:5000"
log_info ""
log_info "Check logs:"
log_info "  kubectl logs -f deployment/serviceexample"
log_info "  flux logs --all-namespaces --follow"
log_info ""