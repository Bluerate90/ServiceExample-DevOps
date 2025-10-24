#!/bin/bash
# Universal prepare nodes script - works on ALL nodes
# IMPORTANT: Hostname must be set FIRST on each node before running this script
# Example: sudo hostnamectl set-hostname master-01 (then reboot or source /etc/hostname)
# Usage: ./01-prepare-nodes.sh
set -e

# Source config file
source "$(dirname "$0")/config.sh"

# Get current hostname
CURRENT_HOSTNAME=$(hostname)

log_info "=========================================="
log_info "Current Hostname: $CURRENT_HOSTNAME"
log_info "=========================================="

# Detect node name from hostname
NODE_NAME=""
for node in "${!NODES[@]}"; do
    if [[ "$CURRENT_HOSTNAME" == "$node" ]]; then
        NODE_NAME="$node"
        break
    fi
done

# If no exact match found
if [[ -z "$NODE_NAME" ]]; then
    log_error "Hostname '$CURRENT_HOSTNAME' does not match any node in config.sh"
    log_error "Available nodes: ${!NODES[@]}"
    log_error ""
    log_error "Please set hostname first using:"
    log_error "  sudo hostnamectl set-hostname master-01  (or your node name)"
    log_error "  sudo reboot"
    log_error ""
    exit 1
fi

# Get node IP from config
NODE_IP="${NODES[$NODE_NAME]}"
NODE_TYPE=$(echo "$NODE_NAME" | sed 's/-[0-9]*$//')

log_info "========== PREPARING $NODE_NAME FOR KUBERNETES =========="
log_info "Node Name: $NODE_NAME"
log_info "Node IP (from config.sh): $NODE_IP"
log_info "Node Type: $NODE_TYPE"
log_info "==========================================================="
echo ""

# Step 1: Verify hostname matches node name
log_info "Step 1: Verifying hostname..."
if [[ "$CURRENT_HOSTNAME" != "$NODE_NAME" ]]; then
    log_warn "Hostname mismatch! Setting to $NODE_NAME..."
    sudo hostnamectl set-hostname "$NODE_NAME"
    log_success "Hostname set to: $NODE_NAME"
else
    log_success "Hostname verified: $NODE_NAME"
fi

# Step 2: Update system
log_info "Step 2: Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git vim build-essential net-tools
log_success "System updated"

# Step 3: Disable swap
log_info "Step 3: Disabling swap..."
sudo swapoff -a 2>/dev/null || true
sudo sed -i '/ swap / s/^/#/' /etc/fstab
log_success "Swap disabled"

# Step 4: Load kernel modules
log_info "Step 4: Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
log_success "Kernel modules loaded"

# Step 5: Configure sysctl
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

# Step 7: Install Kubernetes tools
log_info "Step 7: Installing Kubernetes tools (v${K8S_VERSION})..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl enable kubelet
log_success "Kubernetes tools installed"

# Step 8: Update /etc/hosts with all cluster nodes
log_info "Step 8: Updating /etc/hosts with all cluster nodes..."
for node in "${!NODES[@]}"; do
    node_ip="${NODES[$node]}"
    if ! sudo grep -q "^$node_ip.*$node" /etc/hosts; then
        echo "$node_ip  $node" | sudo tee -a /etc/hosts > /dev/null
    fi
done
log_success "/etc/hosts updated with all cluster nodes"

# Step 9: Verify installation
log_info "Step 9: Verifying installation..."
echo ""
echo "--- Containerd Version ---"
containerd --version
echo ""
echo "--- Kubelet Version ---"
kubelet --version
echo ""
echo "--- Kubeadm Version ---"
sudo kubeadm version 2>/dev/null | grep kubeadm || kubeadm version
echo ""
echo "--- Kubectl Version ---"
kubectl version --client 2>/dev/null
echo ""

# Final summary
if [[ "$NODE_TYPE" == "master" ]]; then
    log_success "========== MASTER NODE PREPARATION COMPLETE =========="
    log_info "Node: $NODE_NAME | IP: $NODE_IP"
    log_info "Next: Run 02-init-master.sh on master-01 to initialize the cluster"
else
    log_success "========== WORKER NODE PREPARATION COMPLETE =========="
    log_info "Node: $NODE_NAME | IP: $NODE_IP"
    log_info "Next: Join this worker node to the cluster using kubeadm join"
fi