#!/bin/bash
# Setup Cloudflare Tunnel
# Usage: ./11-setup-cloudflare-tunnel.sh <tunnel-id> <tunnel-token>

set -e
source "$(dirname "$0")/config.sh"

if [ -z "$1" ] || [ -z "$2" ]; then
    log_error "Usage: ./11-setup-cloudflare-tunnel.sh <tunnel-id> <tunnel-token>"
    log_error "Create tunnel at: https://dash.cloudflare.com/sign-up/teams"
    exit 1
fi

TUNNEL_ID=$1
TUNNEL_TOKEN=$2

log_info "========== SETTING UP CLOUDFLARE TUNNEL =========="

# Step 1: Create namespace
kubectl create namespace cloudflare-tunnel || log_warn "Namespace already exists"

# Step 2: Create credentials secret
log_info "Creating Cloudflare tunnel credentials secret..."
kubectl create secret generic cloudflare-tunnel-credentials \
  -n cloudflare-tunnel \
  --from-literal=token=$TUNNEL_TOKEN \
  --dry-run=client -o yaml | kubectl apply -f -

# Step 3: Create ConfigMap with tunnel config
log_info "Creating tunnel configuration..."
cat > /tmp/cloudflare-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflare-tunnel-config
  namespace: cloudflare-tunnel
data:
  config.yaml: |
    tunnel: ${CLOUDFLARE_TUNNEL_NAME}
    credentials-file: /etc/cloudflared/token
    
    ingress:
      - hostname: ${CLOUDFLARE_APP_SUBDOMAIN}.${CLOUDFLARE_DOMAIN}
        service: http://serviceexample.default.svc.cluster.local:5000
      - hostname: grafana.${CLOUDFLARE_DOMAIN}
        service: http://prometheus-stack-grafana.monitoring.svc.cluster.local:80
      - hostname: prometheus.${CLOUDFLARE_DOMAIN}
        service: http://prometheus-stack-kube-prom-prometheus.monitoring.svc.cluster.local:9090
      - service: http_status:404
EOF

kubectl apply -f /tmp/cloudflare-config.yaml

# Step 4: Create Deployment
log_info "Creating Cloudflare tunnel deployment..."
cat > /tmp/cloudflare-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflare-tunnel
  namespace: cloudflare-tunnel
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cloudflare-tunnel
  template:
    metadata:
      labels:
        app: cloudflare-tunnel
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - cloudflare-tunnel
              topologyKey: kubernetes.io/hostname
      containers:
      - name: cloudflared
        image: cloudflare/cloudflared:latest
        command:
          - cloudflared
          - tunnel
          - --config
          - /etc/cloudflared/config.yaml
          - run
        ports:
        - name: metrics
          containerPort: 8082
        livenessProbe:
          httpGet:
            path: /ready
            port: 8082
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8082
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: config
          mountPath: /etc/cloudflared
          readOnly: true
        - name: token
          mountPath: /etc/cloudflared
          readOnly: true
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 64Mi
      volumes:
      - name: config
        configMap:
          name: cloudflare-tunnel-config
      - name: token
        secret:
          secretName: cloudflare-tunnel-credentials
          items:
          - key: token
            path: token
EOF

kubectl apply -f /tmp/cloudflare-deployment.yaml

log_success "========== CLOUDFLARE TUNNEL SETUP COMPLETE =========="

log_info "Tunnel configuration:"
log_info "  App: https://${CLOUDFLARE_APP_SUBDOMAIN}.${CLOUDFLARE_DOMAIN}"
log_info "  Grafana: https://grafana.${CLOUDFLARE_DOMAIN}"
log_info "  Prometheus: https://prometheus.${CLOUDFLARE_DOMAIN}"