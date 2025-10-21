#!/bin/bash
# Master deployment script - orchestrates all other scripts
# Usage: ./deploy-all.sh

set -e
source "$(dirname "$0")/config.sh"

log_info "========== SERVICEEXAMPLE DEPLOYMENT ORCHESTRATOR =========="
log_info "This script will guide you through the complete setup"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to run step on a node via SSH
run_on_node() {
    local node_ip=$1
    local script_path=$2
    local script_name=$(basename $2)
    
    log_info "Running $script_name on $node_ip..."
    scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ${SCRIPT_DIR}/* ${SSH_USER}@${node_ip}:/tmp/scripts/ 2>/dev/null || true
    
    ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ${SSH_USER}@${node_ip} "cd /tmp/scripts && bash $script_name"
}

# Menu function
show_menu() {
    echo ""
    echo "========== DEPLOYMENT OPTIONS =========="
    echo "1) Prepare all nodes (01-prepare-nodes.sh)"
    echo "2) Initialize master-01 (02-init-master-1.sh)"
    echo "3) Join all masters (03-join-masters.sh)"
    echo "4) Join all workers (04-join-workers.sh)"
    echo "5) Install Longhorn storage (05-install-longhorn.sh)"
    echo "6) Install Observability stack (06-install-observability.sh)"
    echo "7) Install FluxCD (07-install-flux.sh)"
    echo "8) Setup Sealed Secrets (08-setup-sealed-secrets.sh)"
    echo "9) Deploy databases (MongoDB, Redis, NATS)"
    echo "10) Deploy application via Helm"
    echo "11) Setup Cloudflare Tunnel (11-setup-cloudflare-tunnel.sh)"
    echo "12) Full automatic deployment (1-11)"
    echo "13) Verify deployment (verify-deployment.sh)"
    echo "0) Exit"
    echo "=========================================="
}

# Full deployment workflow
full_deployment() {
    log_info "Starting full automatic deployment..."
    
    # Step 1: Prepare all nodes
    log_info "Step 1: Preparing all nodes..."
    for node_name in "${!NODES[@]}"; do
        ip_addr="${NODES[$node_name]}"
        log_info "Preparing node: k8s-${node_name} (${ip_addr})"
        run_on_node $ip_addr "${SCRIPT_DIR}/01-prepare-nodes.sh"
    done
    log_success "All nodes prepared"
    
    # Step 2: Initialize master-01
    log_info "Step 2: Initializing cluster on master-01..."
    run_on_node "${NODES[master-01]}" "${SCRIPT_DIR}/02-init-master-1.sh"
    log_success "Cluster initialized"
    
    # Save join commands
    sleep 5
    scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ${SSH_USER}@${NODES[master-01]}:/tmp/*-join-command.sh ${SCRIPT_DIR}/ 2>/dev/null || true
    
    # Step 3: Join other masters
    log_info "Step 3: Joining other masters to cluster..."
    if [ -f "${SCRIPT_DIR}/master-join-command.sh" ]; then
        MASTER_CMD=$(cat ${SCRIPT_DIR}/master-join-command.sh)
        for master in "master-02" "master-03"; do
            log_info "Joining ${master}..."
            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                ${SSH_USER}@${NODES[$master]} "cd /tmp/scripts && bash 03-join-masters.sh '$MASTER_CMD'"
        done
    fi
    log_success "Master nodes joined"
    
    # Step 4: Join worker nodes
    log_info "Step 4: Joining worker nodes to cluster..."
    if [ -f "${SCRIPT_DIR}/worker-join-command.sh" ]; then
        WORKER_CMD=$(cat ${SCRIPT_DIR}/worker-join-command.sh)
        for worker in "worker-01" "worker-02"; do
            log_info "Joining ${worker}..."
            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                ${SSH_USER}@${NODES[$worker]} "cd /tmp/scripts && bash 04-join-workers.sh '$WORKER_CMD'"
        done
    fi
    log_success "Worker nodes joined"
    
    # Step 5: Install storage
    log_info "Step 5: Installing Longhorn storage..."
    bash ${SCRIPT_DIR}/05-install-longhorn.sh
    log_success "Longhorn installed"
    
    # Step 6: Install observability
    log_info "Step 6: Installing observability stack..."
    bash ${SCRIPT_DIR}/06-install-observability.sh
    log_success "Observability stack installed"
    
    # Step 7: Install FluxCD
    log_info "Step 7: Installing FluxCD..."
    read -p "Enter GitHub username: " GITHUB_USER
    read -sp "Enter GitHub token (or personal access token): " GITHUB_TOKEN
    echo ""
    bash ${SCRIPT_DIR}/07-install-flux.sh "$GITHUB_USER" "$GITHUB_TOKEN"
    log_success "FluxCD installed"
    
    # Step 8: Setup sealed secrets
    log_info "Step 8: Setting up sealed secrets..."
    bash ${SCRIPT_DIR}/08-setup-sealed-secrets.sh
    log_success "Sealed secrets configured"
    
    log_success "========== FULL DEPLOYMENT COMPLETE =========="
    log_info "Next steps:"
    log_info "1. Commit sealed-secret.yaml to GitHub"
    log_info "2. FluxCD will automatically deploy applications"
    log_info "3. Run verify-deployment.sh to check status"
}

# Main menu loop
while true; do
    show_menu
    read -p "Select option: " choice
    
    case $choice in
        1)
            log_info "Preparing all nodes..."
            for node_name in "${!NODES[@]}"; do
                ip_addr="${NODES[$node_name]}"
                run_on_node $ip_addr "${SCRIPT_DIR}/01-prepare-nodes.sh"
            done
            ;;
        2)
            run_on_node "${NODES[master-01]}" "${SCRIPT_DIR}/02-init-master-1.sh"
            ;;
        3)
            log_warn "Manual join command required. See master-join-command.sh"
            ;;
        4)
            log_warn "Manual join command required. See worker-join-command.sh"
            ;;
        5)
            bash ${SCRIPT_DIR}/05-install-longhorn.sh
            ;;
        6)
            bash ${SCRIPT_DIR}/06-install-observability.sh
            ;;
        7)
            read -p "Enter GitHub username: " GITHUB_USER
            read -sp "Enter GitHub token: " GITHUB_TOKEN
            echo ""
            bash ${SCRIPT_DIR}/07-install-flux.sh "$GITHUB_USER" "$GITHUB_TOKEN"
            ;;
        8)
            bash ${SCRIPT_DIR}/08-setup-sealed-secrets.sh
            ;;
        9)
            log_info "Databases will be deployed via FluxCD when configured"
            ;;
        10)
            log_info "Application will be deployed via FluxCD when configured"
            ;;
        11)
            read -p "Enter Cloudflare Tunnel ID: " TUNNEL_ID
            read -sp "Enter Cloudflare Tunnel Token: " TUNNEL_TOKEN
            echo ""
            bash ${SCRIPT_DIR}/11-setup-cloudflare-tunnel.sh "$TUNNEL_ID" "$TUNNEL_TOKEN"
            ;;
        12)
            full_deployment
            ;;
        13)
            bash ${SCRIPT_DIR}/verify-deployment.sh
            ;;
        0)
            log_info "Exiting deployment script"
            exit 0
            ;;
        *)
            log_error "Invalid option. Please try again."
            ;;
    esac
done