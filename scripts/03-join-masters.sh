#!/bin/bash
# Run on master-02 and master-03
# Usage: ./03-join-masters.sh <join-command>

set -e
source "$(dirname "$0")/config.sh"

if [ -z "$1" ]; then
    log_error "Usage: ./03-join-masters.sh <master-join-command>"
    exit 1
fi

log_info "========== JOINING MASTER NODE =========="

# Execute join command
log_info "Joining cluster as master..."
$1

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

log_success "========== MASTER NODE JOINED =========="