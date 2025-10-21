#!/bin/bash
# Run on worker nodes
# Usage: ./04-join-workers.sh <join-command>

set -e
source "$(dirname "$0")/config.sh"

if [ -z "$1" ]; then
    log_error "Usage: ./04-join-workers.sh <worker-join-command>"
    exit 1
fi

log_info "========== JOINING WORKER NODE =========="

# Execute join command
log_info "Joining cluster as worker..."
$1

log_success "========== WORKER NODE JOINED =========="