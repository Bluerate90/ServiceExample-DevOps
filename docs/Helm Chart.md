# ServiceExample-Chart: Complete Implementation Guide

## Overview

This document describes the complete process of creating, publishing, and using the ServiceExample Helm chart for the ServiceExample .NET Core REST API application.

---

## Table of Contents

1. [What is This Chart](#what-is-this-chart)
2. [Step 1: Chart Creation](#step-1-chart-creation)
3. [Step 2: Validation with Schema](#step-2-validation-with-schema)
4. [Step 3: GPG Signing](#step-3-gpg-signing)
5. [Step 4: Publishing to GitHub](#step-4-publishing-to-github)
6. [Step 5: Publishing to ArtifactHub](#step-5-publishing-to-artifacthub)
7. [For Users: How to Install](#for-users-how-to-install)
8. [For Users: Configuration](#for-users-configuration)
9. [For Users: Verification](#for-users-verification)

---

## What is This Chart

**ServiceExample-Chart** is a production-ready Helm chart for deploying the ServiceExample .NET Core REST API on Kubernetes.

- **Chart Name:** serviceexample-chart
- **Current Version:** 1.0.0
- **Application Version:** 1.0.0
- **Status:** Published on ArtifactHub and GitHub Pages
- **GPG Signed:** Yes

---

## Step 1: Chart Creation

### Files Created

```
helm/serviceexample/
├── Chart.yaml                 (Chart metadata)
├── values.yaml                (Default configuration)
├── values.schema.json         (Validation schema)
└── templates/
    ├── deployment.yaml        (Kubernetes Deployment)
    ├── service.yaml           (Kubernetes Service)
    ├── hpa.yaml               (Horizontal Pod Autoscaler)
    └── NOTES.txt              (Installation notes)
```

### Chart.yaml

Contains metadata about the chart:
- Chart name: `serviceexample`
- Chart version: `1.0.0`
- Application version: `1.0.0`
- Description and keywords
- Maintainer information
- Links to GitHub repository

### values.yaml

Default configuration values:
- `replicaCount: 3` - Three replicas by default
- `image.repository: serviceexample` - Docker image name
- `image.tag: latest` - Image tag
- `service.port: 9080` - Service port
- `autoscaling.enabled: true` - Auto-scaling enabled
- `autoscaling.minReplicas: 3` - Minimum 3 pods
- `autoscaling.maxReplicas: 10` - Maximum 10 pods
- `autoscaling.targetCPUUtilizationPercentage: 70` - Scale at 70% CPU

### values.schema.json

JSON schema file that validates:
- Replica count between 1-10
- Service port between 1-65535
- Image pull policies (IfNotPresent, Always, Never)
- Environment values (Production, Development, Staging)
- Resource requests and limits
- All required fields

### Templates

**deployment.yaml:**
- Creates Kubernetes Deployment
- Configures 3 replicas (configurable)
- Sets resource limits and requests
- Adds liveness and readiness probes
- Mounts TLS certificates for connections

**service.yaml:**
- Creates Kubernetes Service
- Type: ClusterIP
- Port: 9080 (configurable)
- Exposes the application internally

**hpa.yaml:**
- Creates Horizontal Pod Autoscaler
- Min replicas: 3
- Max replicas: 10
- Scales based on CPU utilization (70% threshold)

**NOTES.txt:**
- Displays post-installation instructions
- Shows how to port-forward
- Shows how to access the application
- Shows how to view logs

---

## Step 2: Validation with Schema

### Linting

```bash
cd helm/serviceexample
helm lint .
```

Output: `1 chart(s) linted, 0 error(s)`

This validates:
- YAML syntax
- Template validity
- Schema compliance
- All required fields present

### Template Rendering

```bash
helm template serviceexample-chart . --values values.yaml
```

This shows what Kubernetes manifests will be generated before installation.

### Schema Validation

The `values.schema.json` ensures:
- Users can't set invalid values
- Configuration is constrained to safe ranges
- IDEs provide autocomplete suggestions
- Installation fails early if values are invalid

Example validation:
```bash
# This would fail validation (replicaCount > 10):
helm install app chart --set replicaCount=999
# Error: replicaCount must be <= 10
```

---

## Step 3: Signing (GPG & Cosign)

### Option A: GPG Signing (Traditional)

#### Generate GPG Key

```bash
gpg --full-generate-key
```

Configuration:
- Key type: RSA and RSA
- Key size: 4096 bits
- Expiration: Never (0)
- Name: Tibyan Mustafa
- Email: tib9051@gmail.com

#### Sign the Chart

```bash
cd helm/serviceexample
helm package . --sign --key 'Tibyan Mustafa' --keyring ~/.gnupg/secring.gpg
```

Creates:
- `serviceexample-1.0.0.tgz` - Chart package
- `serviceexample-1.0.0.tgz.prov` - Provenance file (signature)

#### Export Public Key

```bash
gpg --export --armor 'Tibyan Mustafa' > serviceexample.asc
```

This allows users to verify the signature.

### Option B: Cosign Signing (Modern, Kubernetes-Native)

Cosign is the modern alternative for signing container images and Helm charts in Kubernetes environments.

#### Install Cosign

```bash
# On macOS
brew install cosign

# On Linux
wget https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
```

#### Generate Cosign Keys

```bash
# Generate keypair (creates cosign.key and cosign.pub)
cosign generate-key-pair

# Verify keys were created
ls -la cosign.*
```

#### Sign the Helm Chart with Cosign

```bash
cd helm/serviceexample

# Sign the chart package
cosign sign-blob --key cosign.key serviceexample-1.0.0.tgz > serviceexample-1.0.0.tgz.cosign.sig

# Verify signature was created
ls -la serviceexample-1.0.0.tgz.cosign.sig
```

#### Store Public Key

```bash
# Copy public key to repository for users
cp cosign.pub serviceexample.cosign.pub

# Commit to git
git add serviceexample.cosign.pub
git commit -m "Add Cosign public key"
```

#### Sign Container Images (Optional)

If you push your image to a registry, also sign it:

```bash
# Sign container image on Docker Hub or registry
cosign sign --key cosign.key yourusername/serviceexample:1.0.0
```

### Why Sign?

- **Authenticity:** Proves the chart/image came from you
- **Integrity:** Proves the chart/image hasn't been modified
- **Trust:** Users can verify before installation
- **Compliance:** Required for enterprise deployments
- **Security:** Prevents supply chain attacks

### GPG vs Cosign

| Feature | GPG | Cosign |
|---------|-----|--------|
| **Use Case** | Chart artifacts | Container images + charts |
| **Kubernetes Native** | No | Yes |
| **Cloud Registry Support** | No | Yes (OCI registries) |
| **Ease of Use** | Medium | Easy |
| **Verification** | `helm install --verify` | `cosign verify` |
| **Recommended For** | Traditional setups | Modern K8s workflows |

**Recommendation:** Use both:
- **GPG** for Helm chart signing (traditional, widely supported)
- **Cosign** for container image signing (modern, K8s-native)

---

## Step 4: Publishing to GitHub

### Push to GitHub

```bash
cd ~/mirasys-assignment/ServiceExample-DevOps

# Commit files
git add helm/serviceexample/
git commit -m "Add serviceexample-chart v1.0.0"

# Create tag
git tag v1.0.0-chart
git push origin v1.0.0-chart
```

### Create GitHub Release

```bash
gh release create v1.0.0-chart \
  helm/serviceexample/serviceexample-1.0.0.tgz \
  helm/serviceexample/serviceexample-1.0.0.tgz.prov \
  helm/serviceexample/serviceexample.asc \
  --title "ServiceExample Chart v1.0.0"
```

Release includes:
- Signed chart package
- Provenance file
- Public key for verification

### GitHub Pages Repository

Set up Helm repository on GitHub Pages:

```bash
git checkout --orphan gh-pages
git reset --hard
mkdir -p charts
cd charts

# Copy files
cp ../helm/serviceexample/serviceexample-1.0.0.tgz .
cp ../helm/serviceexample/serviceexample-1.0.0.tgz.prov .
cp ../helm/serviceexample/serviceexample.asc .

# Generate Helm index
helm repo index . --url https://Bluerate90.github.io/ServiceExample-DevOps/charts

# Push
git add .
git commit -m "Add Helm repository"
git push -u origin gh-pages
```

Repository URL: https://Bluerate90.github.io/ServiceExample-DevOps/charts

### Enable GitHub Pages

1. Go to Settings > Pages
2. Source: Deploy from a branch
3. Branch: gh-pages
4. Folder: / (root)

---

## Step 5: Publishing to ArtifactHub

### Add Repository to ArtifactHub

1. Go to: https://artifacthub.io
2. Sign in with GitHub
3. Go to: Control Panel > Repositories
4. Click "+ Add repository"
5. Fill in:
   - **URL:** https://Bluerate90.github.io/ServiceExample-DevOps/charts
   - **Name:** serviceexample-chart
   - **Kind:** Helm charts
6. Click "Add"

### ArtifactHub Processing

- Repository is queued for processing
- Takes 5-30 minutes to scan and index
- Chart becomes searchable on ArtifactHub
- Users can find it via search

### Repository Details

- **ID:** 64c39541-5c14-440e-b978-415093043483
- **URL:** https://artifacthub.io/packages/helm/serviceexample-chart
- **Status:** Published and searchable

---

## For Users: How to Install

### Add Helm Repository

```bash
helm repo add serviceexample-chart https://Bluerate90.github.io/ServiceExample-DevOps/charts
helm repo update
```

### Search for Chart

```bash
helm search repo serviceexample-chart
```

Output:
```
NAME                              CHART VERSION  APP VERSION
serviceexample-chart/serviceexample  1.0.0          1.0.0
```

### Install with Defaults

```bash
helm install my-app serviceexample-chart/serviceexample
```

This creates:
- 3 replicas of the application
- Kubernetes Service on port 9080
- Horizontal Pod Autoscaler
- Health checks

### Install with Custom Namespace

```bash
helm install my-app serviceexample-chart/serviceexample \
  --namespace my-namespace \
  --create-namespace
```

### Install with Custom Values

```bash
helm install my-app serviceexample-chart/serviceexample \
  --set replicaCount=5 \
  --set image.tag=v1.0.1 \
  --set env.LOG_LEVEL=Debug
```

---

## For Users: Configuration

### Common Configuration Options

```bash
# Change number of replicas
--set replicaCount=5

# Change image tag
--set image.tag=v1.0.1

# Change service port
--set service.port=8080

# Change environment
--set env.ASPNETCORE_ENVIRONMENT=Development

# Disable autoscaling
--set autoscaling.enabled=false

# Change autoscaling limits
--set autoscaling.minReplicas=2
--set autoscaling.maxReplicas=20
--set autoscaling.targetCPUUtilizationPercentage=80
```

### View Configurable Values

```bash
helm show values serviceexample-chart/serviceexample
```

### Install from Values File

Create `my-values.yaml`:
```yaml
replicaCount: 5
image:
  tag: v1.0.1
env:
  ASPNETCORE_ENVIRONMENT: Production
  LOG_LEVEL: Warning
autoscaling:
  minReplicas: 2
  maxReplicas: 20
```

Then install:
```bash
helm install my-app serviceexample-chart/serviceexample \
  -f my-values.yaml
```

---

## For Users: Verification

### Check Installation Status

```bash
helm status my-app
helm list
```

### Verify Pods are Running

```bash
kubectl get pods -l app=serviceexample
```

Expected output: All pods in Running status with 1/1 Ready

### Check Service

```bash
kubectl get svc serviceexample
```

### View Logs

```bash
kubectl logs -l app=serviceexample --tail=50
kubectl logs -l app=serviceexample -f  # Follow logs
```

### Access the Application

```bash
kubectl port-forward svc/serviceexample 9080:9080 &
```

Then visit:
- Swagger UI: http://localhost:9080/swagger/index.html
- API: http://localhost:9080/api/Person

### Verify GPG Signature

```bash
helm install my-app serviceexample-chart/serviceexample --verify
```

This verifies the chart was signed by the maintainer and hasn't been modified.

### Upgrade Release

```bash
helm upgrade my-app serviceexample-chart/serviceexample \
  --set replicaCount=10
```

### Rollback Release

```bash
helm history my-app
helm rollback my-app 1
```

### Uninstall Release

```bash
helm uninstall my-app
```

---

## Development: Creating Next Version

### Update Chart Version

Edit `helm/serviceexample/Chart.yaml`:
```yaml
version: 1.0.1
appVersion: "1.0.1"
```

### Re-package and Sign

```bash
cd helm/serviceexample
rm -f serviceexample-*.tgz serviceexample-*.tgz.prov
helm package . --sign --key 'Tibyan Mustafa' --keyring ~/.gnupg/secring.gpg
```

### Update GitHub Pages

```bash
git checkout gh-pages
cd charts
cp ../helm/serviceexample/serviceexample-1.0.1.tgz .
helm repo index . --url https://Bluerate90.github.io/ServiceExample-DevOps/charts
git add .
git commit -m "Add v1.0.1"
git push origin gh-pages
git checkout main
```

### Create GitHub Release

```bash
git tag v1.0.1-chart
git push origin v1.0.1-chart
gh release create v1.0.1-chart \
  helm/serviceexample/serviceexample-1.0.1.tgz \
  helm/serviceexample/serviceexample-1.0.1.tgz.prov
```

### ArtifactHub Auto-Updates

ArtifactHub automatically detects new versions and updates within minutes.

---

## Summary

### What Was Accomplished

✅ Created production-ready Helm chart
✅ Validated with JSON schema
✅ Signed with GPG for security
✅ Published to GitHub Pages
✅ Published to ArtifactHub
✅ Documented installation and usage
✅ Made publicly discoverable

### Chart Features

- Kubernetes Deployment with configurable replicas
- Service exposure on port 9080
- Horizontal Pod Autoscaler (3-10 replicas)
- Health checks (liveness and readiness probes)
- Configurable resources and environment
- GPG signed for authenticity
- Schema validated for safety

### How Users Get It

1. Search ArtifactHub: https://artifacthub.io/packages/helm/serviceexample-chart
2. Add repository: `helm repo add serviceexample-chart https://Bluerate90.github.io/ServiceExample-DevOps/charts`
3. Install: `helm install my-app serviceexample-chart/serviceexample`

### Support & Links

- **GitHub Repository:** https://github.com/Bluerate90/ServiceExample-DevOps
- **ArtifactHub:** https://artifacthub.io/packages/helm/serviceexample-chart
- **Helm Repository:** https://Bluerate90.github.io/ServiceExample-DevOps/charts
- **GitHub Release:** https://github.com/Bluerate90/ServiceExample-DevOps/releases/tag/v1.0.0-chart

---

## Conclusion

The ServiceExample-Chart is now ready for production use. Users can discover it on ArtifactHub, install it with a single command, and deploy the ServiceExample .NET Core REST API on any Kubernetes cluster.
