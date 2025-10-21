#!/bin/bash

# Run on master-01 node
# Usage: ./01-prepare-nodes.sh

set -e

# Source config file
source "$(dirname "$0")/config.sh"

log_info "========== PREPARING MASTER-01 FOR KUBERNETES =========="

# Step 1: Check hostname
log_info "Step 1: Checking hostname..."
check_node "master-01"
log_success "Running on master-01"

# Step 2: Update system
log_info "Step 2: Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git vim build-essential net-tools
log_success "System updated"

# Step 3: Disable swap
log_info "Step 3: Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
log_success "Swap disabled"

# Step 4: Configure hostname
log_info "Step 4: Setting hostname to master-01..."
sudo hostnamectl set-hostname master-01
log_success "Hostname set to: master-01"

# Step 5: Load kernel modules
log_info "Step 5: Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
log_success "Kernel modules loaded"

# Step 6: Configure sysctl
log_info "Step 6: Configuring sysctl parameters..."
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

# Step 7: Install containerd
log_info "Step 7: Installing containerd..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
log_success "Containerd installed and configured"

# Step 8: Install Kubernetes tools
log_info "Step 8: Installing Kubernetes tools (v${K8S_VERSION})..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl enable kubelet
log_success "Kubernetes tools installed"

# Step 9: Update /etc/hosts with cluster nodes
log_info "Step 9: Updating /etc/hosts with cluster nodes..."
MASTER_IP="${NODES[master-01]}"

# Add master-01 entry
if ! sudo grep -q "master-01" /etc/hosts; then
    echo "$MASTER_IP  master-01" | sudo tee -a /etc/hosts > /dev/null
fi

log_success "/etc/hosts updated"

# Step 10: Verify installation
log_info "Step 10: Verifying installation..."
echo ""
log_info "Containerd version:"
containerd --version
echo ""

log_info "Kubelet version:"
kubelet --version
echo ""

log_info "Kubeadm version:"
kubeadm version
echo ""

log_info "Kubectl version:"
kubectl version --client
echo ""

log_success "========== NODE PREPARATION COMPLETE =========="
log_info "Next: Run 02-init-master.sh to initialize the cluster"