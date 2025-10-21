#!/bin/bash
# Run on master-01
# Usage: ./08-setup-sealed-secrets.sh

set -e
source "$(dirname "$0")/config.sh"

check_node "master-01"

log_info "========== SETTING UP SEALED SECRETS =========="

# Step 1: Add Helm repository
log_info "Adding Sealed Secrets Helm repository..."
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

# Step 2: Install Sealed Secrets Controller
log_info "Installing Sealed Secrets Controller..."
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --wait

log_success "Waiting for Sealed Secrets to be ready..."
kubectl rollout status deployment/sealed-secrets -n kube-system --timeout=300s

# Step 3: Create application secret
log_info "Creating application secrets..."
cat > /tmp/app-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
type: Opaque
stringData:
  MONGODB_URI: "mongodb://${MONGODB_USER}:${MONGODB_PASS}@mongodb-0.databases.svc.cluster.local:27017,mongodb-1.databases.svc.cluster.local:27017,mongodb-2.databases.svc.cluster.local:27017/?replicaSet=rs0"
  REDIS_URL: "redis://:${REDIS_PASS}@redis-master.databases.svc.cluster.local:6379"
  NATS_URL: "nats://${NATS_USER}:${NATS_PASS}@nats.databases.svc.cluster.local:4222"
EOF

# Step 4: Seal the secret
log_info "Sealing secret..."
kubeseal -f /tmp/app-secret.yaml -w ../k8s/gitops/apps/serviceexample/sealed-secret.yaml \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  --format yaml

log_success "========== SEALED SECRETS SETUP COMPLETE =========="

# Display sealed secret
log_info "Sealed secret created at: ../k8s/gitops/apps/serviceexample/sealed-secret.yaml"
log_info "Commit and push to GitHub for FluxCD to deploy"