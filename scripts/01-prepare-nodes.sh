#!/bin/bash
# Run on ALL nodes (masters and workers)
# Usage: ./01-prepare-nodes.sh

set -e
source "$(dirname "$0")/config.sh"

log_info "========== PREPARING NODE FOR KUBERNETES =========="

# Step 1: Update system
log_info "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git vim build-essential net-tools

# Step 2: Disable swap
log_info "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
log_success "Swap disabled"

# Step 3: Configure hostname
HOSTNAME="k8s-$(hostname | grep -oE '(master|worker)-[0-9]+' || echo 'node')"
sudo hostnamectl set-hostname $HOSTNAME
log_success "Hostname set to: $HOSTNAME"

# Step 4: Load kernel modules
log_info "Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
log_success "Kernel modules loaded"

# Step 5: Configure sysctl
log_info "Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system > /dev/null
log_success "Sysctl parameters configured"

# Step 6: Install containerd
log_info "Installing containerd..."
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
log_success "Containerd installed"

# Step 7: Install kubeadm, kubelet, kubectl
log_info "Installing Kubernetes tools..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update
sudo apt-get install -y kubeadm=${K8S_VERSION}.* kubelet=${K8S_VERSION}.* kubectl=${K8S_VERSION}.*
sudo apt-mark hold kubeadm kubelet kubectl

sudo systemctl enable kubelet
log_success "Kubernetes tools installed"

# Step 8: Update /etc/hosts
log_info "Updating /etc/hosts..."
for node_name in "${!NODES[@]}"; do
    ip_addr="${NODES[$node_name]}"
    node_hostname="k8s-${node_name}"
    
    if ! sudo grep -q "$node_hostname" /etc/hosts; then
        echo "$ip_addr  $node_hostname" | sudo tee -a /etc/hosts > /dev/null
    fi
done
log_success "/etc/hosts updated"

log_success "========== NODE PREPARATION COMPLETE =========="