#!/bin/bash
# Sign Helm chart with Cosign
# Usage: ./10-sign-helm-chart.sh

set -e
source "$(dirname "$0")/config.sh"

log_info "========== SIGNING HELM CHART =========="

# Step 1: Package Helm chart
log_info "Packaging Helm chart..."
cd helm/serviceexample
helm lint .
helm package .
CHART_FILE=$(ls serviceexample-*.tgz | head -1)
log_success "Chart packaged: $CHART_FILE"

# Step 2: Install Cosign if needed
if ! command -v cosign &> /dev/null; then
    curl -sLO https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign-linux-amd64
    chmod +x cosign-linux-amd64
    sudo mv cosign-linux-amd64 /usr/local/bin/cosign
fi

# Step 3: Check for cosign key
if [ ! -f "../../cosign.key" ]; then
    log_error "cosign.key not found in repository root"
    exit 1
fi

# Step 4: Sign chart
log_info "Signing Helm chart: $CHART_FILE"
cd ../..
cosign sign-blob --key cosign.key helm/serviceexample/$CHART_FILE > helm/serviceexample/${CHART_FILE}.sig

log_success "========== HELM CHART SIGNED =========="

# Display signature file
log_info "Signature file: helm/serviceexample/${CHART_FILE}.sig"
log_info "Commit both files to repository"