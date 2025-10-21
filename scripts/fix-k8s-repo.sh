#!/bin/bash
# Run on master-03 node to fix repository issues
set -e
# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_info "========== FIXING KUBERNETES REPOSITORY (MASTER-03) =========="
# Step 1: Remove old/broken Kubernetes repositories
log_info "Step 1: Removing old Kubernetes repositories..."
sudo rm -f /etc/apt/sources.list.d/kubernetes.list
sudo rm -f /etc/apt/sources.list.d/docker.list
log_success "Old repositories removed"
# Step 2: Clean apt cache
log_info "Step 2: Cleaning apt cache..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
log_success "Apt cache cleaned"
# Step 3: Add updated Docker repository
log_info "Step 3: Adding Docker repository..."
sudo mkdir -p /usr/share/keyrings
if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg 2>/dev/null | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null; then
    log_error "Failed to download Docker GPG key, trying alternative..."
    # Use the repository without GPG verification as fallback
    echo "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
else
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi
log_success "Docker repository added"
# Step 4: Add updated Kubernetes repository (v1.28)
log_info "Step 4: Adding Kubernetes repository (v1.28)..."
sudo mkdir -p /etc/apt/keyrings
if ! curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null; then
    log_error "Failed to download Kubernetes GPG key, trying alternative..."
    # Use the repository without GPG verification as fallback
    echo "deb https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
else
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
fi
log_success "Kubernetes repository added"
# Step 5: Update package lists
log_info "Step 5: Updating package lists..."
sudo apt-get update
log_success "Package lists updated"
# Step 6: Install/update Kubernetes tools
log_info "Step 6: Installing Kubernetes tools..."
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl
log_success "Kubernetes tools installed"
# Step 7: Enable and restart kubelet
log_info "Step 7: Enabling kubelet service..."
sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl restart kubelet
log_success "Kubelet service enabled and restarted"
# Step 8: Verify installation
log_info "Step 8: Verifying installation..."
echo ""
log_info "Kubeadm version:"
sudo kubeadm version
echo ""
log_info "Kubelet version:"
kubelet --version
echo ""
log_info "Kubectl version:"
kubectl version --client 2>/dev/null || true
echo ""
log_success "========== REPOSITORY FIX COMPLETE (MASTER-03) =========="