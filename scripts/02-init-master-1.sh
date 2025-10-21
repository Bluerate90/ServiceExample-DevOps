#!/bin/bash
# Run ONLY on master-01 (10.0.1.10)
# Usage: ./02-init-master-1.sh

set -e
source "$(dirname "$0")/config.sh"

check_node "master-01"

log_info "========== INITIALIZING KUBERNETES CLUSTER (MASTER-01) =========="

# Step 1: Create kubeadm config
log_info "Creating kubeadm configuration..."
cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v${K8S_VERSION}.0
controlPlaneEndpoint: "${CONTROL_PLANE_ENDPOINT}"
networking:
  podSubnet: "${POD_CIDR}"
  serviceSubnet: "${SERVICE_CIDR}"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "10.0.1.10"
  bindPort: 6443
EOF

# Step 2: Initialize cluster
log_info "Initializing Kubernetes cluster..."
sudo kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs 2>&1 | tee /tmp/kubeadm-init.log

# Extract join commands
log_info "Extracting join commands..."
MASTER_JOIN=$(grep "kubeadm join" /tmp/kubeadm-init.log | grep "certificate-key" | head -1)
WORKER_JOIN=$(grep "kubeadm join" /tmp/kubeadm-init.log | grep -v "certificate-key" | head -1)

# Save to file for other nodes
mkdir -p $HOME/.kube
echo "$MASTER_JOIN" > /tmp/master-join-command.sh
echo "$WORKER_JOIN" > /tmp/worker-join-command.sh
chmod +x /tmp/*-join-command.sh

log_success "Join commands saved to /tmp/"

# Step 3: Configure kubectl
log_info "Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
log_success "kubectl configured"

# Step 4: Install Flannel CNI
log_info "Installing Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
log_success "Flannel installed"

# Step 5: Wait for nodes to be ready
log_info "Waiting for cluster to be ready..."
sleep 10
kubectl wait --for=condition=Ready node/k8s-master-01 --timeout=300s 2>/dev/null || log_warn "Node not ready yet"

log_success "========== CLUSTER INITIALIZATION COMPLETE =========="
log_info "Next steps:"
log_info "1. Copy join commands to other nodes"
log_info "2. Run 03-join-masters.sh on master-02 and master-03"
log_info "3. Run 04-join-workers.sh on worker nodes"