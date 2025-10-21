#!/bin/bash

# Shared configuration for all scripts
# ============ CLUSTER CONFIGURATION ============
CLUSTER_NAME="serviceexample-cluster"
K8S_VERSION="1.28"

# ============ VM CONFIGURATION ============
declare -A NODES=(
    [master-01]="192.168.43.10"
)

CONTROL_PLANE_ENDPOINT="192.168.43.10:6443"
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
DNS_SERVERS="8.8.8.8,8.8.4.4"
GATEWAY="192.168.43.1"
SUBNET="192.168.43.0/24"

# ============ CONTAINER REGISTRY ============
REGISTRY_NAME="mycontainerregistry"
REGISTRY_URL="${REGISTRY_NAME}.azurecr.io"
IMAGE_NAME="serviceexample"
IMAGE_VERSION="latest"

# ============ CREDENTIALS ============
MONGODB_USER="admin"
MONGODB_PASS="mongopassword"
REDIS_PASS="redispassword"
NATS_USER="admin"
NATS_PASS="natspassword"

# ============ STORAGE ============
STORAGE_CLASS="longhorn"
MONGODB_STORAGE="20Gi"
REDIS_STORAGE="10Gi"
NATS_STORAGE="5Gi"

# ============ MONITORING ============
GRAFANA_ADMIN="admin"
GRAFANA_PASS="admin123"
PROMETHEUS_RETENTION="15d"

# ============ CLOUDFLARE ============
CLOUDFLARE_DOMAIN="yourdomain.com"
CLOUDFLARE_TUNNEL_NAME="serviceexample"
CLOUDFLARE_APP_SUBDOMAIN="app"

# ============ SSH CONFIGURATION ============
SSH_USER="ubuntu"
SSH_KEY="$HOME/.ssh/id_rsa"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on correct node
check_node() {
    local expected_node=$1
    local current_hostname=$(hostname)
    
    if [[ "$current_hostname" != *"$expected_node"* ]]; then
        log_error "This script must be run on $expected_node (current: $current_hostname)"
        exit 1
    fi
}

# Verify prerequisites
check_prerequisites() {
    local prereqs=("$@")
    for cmd in "${prereqs[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            log_error "$cmd is not installed"
            return 1
        fi
    done
    return 0
}

# Execute with error handling
execute() {
    local cmd="$1"
    local error_msg="$2"
    
    if eval "$cmd"; then
        log_success "$error_msg (SUCCESS)"
    else
        log_error "$error_msg (FAILED)"
        return 1
    fi
}

export -f log_info log_success log_warn log_error check_node execute