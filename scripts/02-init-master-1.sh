#!/bin/bash
# Run ONLY on master-01 (192.168.43.10)
# Complete initialization: prepare node + initialize cluster
# Usage: ./master-01-complete-init.sh
set -e

# Source config file
source "$(dirname "$0")/config.sh"

# Verify we're on master-01
check_node "master-01"

log_info "========== COMPLETE MASTER-01 INITIALIZATION =========="

# ==================== PHASE 1: NODE PREPARATION ====================
log_info "========== PHASE 1: PREPARING NODE FOR KUBERNETES =========="

# Step 1: Update system packages
log_info "Step 1: Updating system packages..."
sudo apt-get update || true
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git vim build-essential net-tools
log_success "System updated"

# Step 2: Disable swap
log_info "Step 2: Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
log_success "Swap disabled"

# Step 3: Configure hostname
log_info "Step 3: Setting hostname..."
sudo hostnamectl set-hostname master-01
log_success "Hostname set to master-01"

# Step 4: Load kernel modules
log_info "Step 4: Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
log_success "Kernel modules loaded"

# Step 5: Configure sysctl parameters
log_info "Step 5: Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
vm.overcommit_memory = 1
kernel.panic = 10
kernel.panic_on_oops = 1
EOF
sudo sysctl --system > /dev/null
log_success "Sysctl parameters configured"

# Step 6: Install containerd
log_info "Step 6: Installing containerd..."
sudo mkdir -p /usr/share/keyrings
if curl -fsSL https://download.docker.com/linux/ubuntu/gpg 2>/dev/null | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null; then
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
else
    log_warn "GPG key download failed, using unsigned repository"
    echo "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi
sudo apt-get update || true
sudo apt-get install -y containerd.io
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
log_success "Containerd installed and configured"

# Step 7: Install Kubernetes tools
log_info "Step 7: Installing Kubernetes tools (v${K8S_VERSION})..."
sudo mkdir -p /etc/apt/keyrings
if curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null; then
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
else
    log_warn "Kubernetes GPG key download failed, using unsigned repository"
    echo "deb https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
fi
sudo apt-get update || true
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl enable kubelet
log_success "Kubernetes tools installed"

# Step 8: Update /etc/hosts
log_info "Step 8: Updating /etc/hosts..."
MASTER_IP="${NODES[master-01]}"
if ! sudo grep -q "master-01" /etc/hosts; then
    echo "$MASTER_IP  master-01" | sudo tee -a /etc/hosts > /dev/null
fi
log_success "/etc/hosts updated"

# Step 9: Verify installation
log_info "Step 9: Verifying installation..."
echo ""
log_info "Containerd version:"
containerd --version
echo ""
log_info "Kubelet version:"
kubelet --version
echo ""
log_info "Kubeadm version:"
sudo kubeadm version
echo ""
log_success "Node preparation complete!"

# ==================== PHASE 2: CLUSTER INITIALIZATION ====================
log_info ""
log_info "========== PHASE 2: INITIALIZING KUBERNETES CLUSTER =========="

# Step 10: Create kubeadm configuration
log_info "Step 10: Creating kubeadm configuration..."
sudo mkdir -p /tmp
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
  advertiseAddress: "${NODES[master-01]}"
  bindPort: 6443
EOF
log_success "Kubeadm config created"

# Step 11: Initialize cluster
log_info "Step 11: Initializing Kubernetes cluster..."
sudo kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs 2>&1 | tee /tmp/kubeadm-init.log
log_success "Cluster initialization complete"

# Step 12: Extract and save join commands
log_info "Step 12: Extracting join commands..."
MASTER_JOIN=$(grep "kubeadm join" /tmp/kubeadm-init.log | grep "certificate-key" | head -1)
WORKER_JOIN=$(grep "kubeadm join" /tmp/kubeadm-init.log | grep -v "certificate-key" | head -1)

mkdir -p /tmp
echo "#!/bin/bash" > /tmp/master-join-command.sh
echo "$MASTER_JOIN" >> /tmp/master-join-command.sh
chmod +x /tmp/master-join-command.sh

echo "#!/bin/bash" > /tmp/worker-join-command.sh
echo "$WORKER_JOIN" >> /tmp/worker-join-command.sh
chmod +x /tmp/worker-join-command.sh

log_success "Join commands saved"

# Step 13: Configure kubectl
log_info "Step 13: Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
log_success "kubectl configured"

# Step 14: Install Flannel CNI
log_info "Step 14: Installing Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
log_success "Flannel CNI installed"

# Step 15: Wait for cluster to be ready
log_info "Step 15: Waiting for cluster to stabilize..."
sleep 15
kubectl get nodes
kubectl wait --for=condition=Ready node/master-01 --timeout=300s 2>/dev/null || log_warn "Node not ready yet, continuing anyway"
log_success "Cluster stabilized"

# ==================== SUMMARY ====================
log_info ""
log_success "========== MASTER-01 INITIALIZATION COMPLETE =========="
log_info ""
log_info "Cluster Information:"
kubectl cluster-info
echo ""
log_info "Node Status:"
kubectl get nodes
echo ""
log_info "Join Commands:"
log_info "Master join command saved to: /tmp/master-join-command.sh"
log_info "Worker join command saved to: /tmp/worker-join-command.sh"
echo ""
log_info "Next Steps:"
log_info "1. Copy join commands to other nodes:"
log_info "   - Master-02/03: Use master-join-command.sh"
log_info "   - Workers: Use worker-join-command.sh"
log_info "2. View join commands:"
log_info "   cat /tmp/master-join-command.sh"
log_info "   cat /tmp/worker-join-command.sh"
echo ""