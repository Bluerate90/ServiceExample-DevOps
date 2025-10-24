# ServiceExample - DevOps Project

A complete DevOps implementation of a .NET application with MongoDB, Redis, and NATS integration. This project demonstrates containerization, CI/CD pipelines, Kubernetes deployment, GitOps, and security best practices.

---

## 📋 Project Overview

**ServiceExample** is a containerized .NET microservice that showcases production-ready DevOps practices:

- **Application**: .NET API with MongoDB persistence, Redis caching, and NATS event streaming
- **Container Registry**: Docker images published with cryptographic signatures
- **Orchestration**: Kubernetes deployment with Helm charts
- **GitOps**: Automated deployment using FluxCD
- **Observability**: Prometheus, Loki, and Grafana monitoring stack
- **Storage**: Longhorn for persistent volumes
- **Security**: Sealed secrets, signed images, and TLS encryption

---

## 📁 Project Structure

```
ServiceExample-DevOps/
│
├── 📄 README.md                              # Main project overview
├── 📄 azure-pipelines.yml                    # Azure CI/CD pipeline (optional)
├── 📄 LICENSE                                # License
│
├── 📁 src/                                   # Application source
│   └── ServiceExample/
│       ├── ServiceExample/                   # Main .NET app
│       │   ├── Program.cs                    # Entry point
│       │   ├── appsettings.json              # Config
│       │   ├── ServiceExample.csproj         # Project file
│       │   ├── Controllers/
│       │   │   └── PersonController.cs       # API endpoints
│       │   ├── Models/
│       │   │   └── Person.cs                 # Data model
│       │   ├── Services/
│       │   │   ├── Sender.cs                 # NATS sender
│       │   │   └── Receiver.cs               # NATS receiver
│       │   ├── Repository/
│       │   │   └── PersonContext.cs          # MongoDB context
│       │   └── Dockerfile
│       │
│       ├── UnitTests/
│       │   ├── UnitTests.csproj
│       │   └── UnitTests.cs
│       │
│       ├── docker/
│       │   ├── docker-compose.yml            # Local dev compose
│       │   ├── Dockerfile
│       │   └── certs/                        # TLS certificates
│       │       ├── mongodb.pem
│       │       ├── nats-cert.pem
│       │       ├── nats-key.pem
│       │       ├── redis-cert.pem
│       │       └── redis-key.pem
│       │
│       └── ServiceExample.sln
│
├── 📁 docker/                                # Docker configs
│   ├── Dockerfile                            # Production image
│   └── docker-compose.yml                    # Local stack
│
├── 📁 helm/                                  # Helm charts
│   └── serviceexample/
│       ├── Chart.yaml                        # Helm metadata
│       ├── values.yaml                       # Default values
│       ├── values.schema.json                # Validation schema
│       ├── artifacthub-pkg.yaml              # ArtifactHub metadata
│       │
│       ├── templates/
│       │   ├── deployment.yaml               # K8s deployment
│       │   ├── service.yaml                  # K8s service
│       │   ├── hpa.yaml                      # Auto-scaling
│       │   └── NOTES.txt                     # Post-install notes
│       │
│       ├── serviceexample-1.0.0.tgz          # Released chart
│       ├── serviceexample-1.0.0.tgz.prov     # GPG signature
│       ├── serviceexample-1.0.2.tgz          # Released chart
│       └── serviceexample-1.0.2.tgz.prov     # GPG signature
│
├── 📁 k8s/                                   # Kubernetes configs
│   └── gitops/
│       ├── kustomization.yaml                # Root kustomization
│       │
│       ├── infrastructure/                   # Storage & monitoring
│       │   ├── kustomization.yaml
│       │   ├── helmrepos.yaml                # Helm repos
│       │   ├── longhorn-helmrelease.yaml     # Storage
│       │   ├── prometheus-helmrelease.yaml   # Metrics
│       │   └── loki-helmrelease.yaml         # Logs
│       │
│       └── apps/
│           └── serviceexample/
│               ├── kustomization.yaml
│               ├── helmrelease.yaml          # App deployment
│               └── sealed-secret.yaml        # Encrypted secrets
│
├── 📁 .github/                               # GitHub Actions workflows
│   └── workflows/
│       ├── ci-cd.yml                         # Build, sign, publish
│       └── helm-chart.yml                    # Chart signing & publish
│
├── 📁 docs/                                  # Documentation
│   ├── Access App - Guide.md                 # ⭐ Quick access guide
│   ├── Security Best Practices & Implementation Guide.md
│   ├── Local Development Setup.md            # Local running
│   ├── Step2: CI-CD Pipeline.md              # CI/CD setup
│   ├── Helm Chart.md                         # Packaging & publish
│   ├── GitOps Kubernetes Deployment - Complete.md
│   └── Multi-Node Kubernetes Cluster Setup on VMware.md
│
└── .gitignore                                # Excludes private keys & secrets
```

### File Legend

- **📄** Document/Config file
- **📁** Folder/Directory
- **⭐** Start here (Quick guide)

### Key Files by Purpose

**Getting Started**
- `docs/Access App - Guide.md` - Quick access guide
- `docker/docker-compose.yml` - Local development

**Deployment**
- `helm/serviceexample/` - Package for K8s
- `k8s/gitops/` - GitOps automation

**CI/CD**
- `.github/workflows/` - GitHub Actions pipelines
- `azure-pipelines.yml` - Azure DevOps pipeline (alternative)
- `cosign.pub` - Public key for image verification

**Security**
- `k8s/gitops/apps/sealed-secret.yaml` - Encrypted secrets
- `src/docker/certs/` - TLS certificates

---

## 🚀 Quick Start

### Local Development

Start the application with all dependencies using Docker Compose:

```bash
cd docker
docker-compose up -d
```

The application runs on `http://localhost:5000`

**Requirements**: Docker and Docker Compose installed

**Includes**: MongoDB, Redis, NATS, and the .NET application

---

## 🔧 Development & Testing

### Run Unit Tests

```bash
cd src/ServiceExample
dotnet test UnitTests/UnitTests.csproj
```

### Build Docker Image Locally

```bash
cd docker
docker build -t serviceexample:latest .
```

### Run Application Locally (without Docker)

```bash
cd src/ServiceExample/ServiceExample
dotnet run
```

Requires: MongoDB, Redis, NATS running separately

---

## 📦 Docker & Registry

**Image Registry**: Available on public container registry
**Image Signing**: All images signed with Cosign for verification
**Multi-stage Build**: Optimized production images

### Verify Signed Image

```bash
cosign verify --key cosign.pub <registry>/serviceexample:tag
```

---

## ☸️ Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3.10+
- FluxCD or GitOps controller installed

### Deploy via Helm (Single Command)

```bash
helm repo add serviceexample https://<repo-url>
helm install serviceexample serviceexample/serviceexample \
  --namespace production \
  --create-namespace
```

### Deploy via GitOps (Recommended)

GitOps automatically deploys updates from the repository. See **GitOps Setup** documentation.

---

## 🔐 Security Features

| Feature | Implementation | Location | Status |
|---------|-----------------|----------|--------|
| **Image Signing** | Cosign (ECDSA) | `cosign.pub` | ✅ Secure |
| **Helm Chart Signing** | GPG signatures | `*.tgz.prov` | ✅ Configured |
| **Secret Management** | Sealed Secrets | `k8s/gitops/apps/sealed-secret.yaml` | ✅ Encrypted |
| **TLS Encryption** | Service-to-service | `src/docker/certs/` | ✅ Enabled |
| **RBAC** | Kubernetes native | Helm chart templates | ✅ Implemented |
| **CI/CD Security** | GitHub Actions secrets | `.github/workflows/` | ✅ Best practices |

**⚠️ Important**: See `docs/Security Best Practices & Implementation Guide.md` for:
- How to properly store private keys (GitHub Secrets, not repository)
- Why `cosign.pub` is safe to commit
- How to implement signing in CI/CD
- Security verification checklist

---

## 📊 Monitoring & Observability

The cluster includes a complete observability stack:

- **Prometheus**: Metrics collection and alerting
- **Loki**: Log aggregation and search
- **Grafana**: Dashboards and visualization

**Access Grafana**: Included in GitOps deployment
**Dashboards**: Pre-configured for Redis, MongoDB, NATS, and application metrics

---

## 🌐 Access Application Without Public IP

The application is exposed safely without a public IP using Cloudflare Tunnel:

- **No Load Balancer Needed**: Secure tunnel to Cloudflare
- **Private Cluster**: Runs on internal network only
- **Zero Trust Access**: Cloudflare credentials required

See **Access App - Guide.md** documentation for setup.

---

## 📚 Documentation

Detailed guides available in the `docs/` folder:

| Document | Purpose |
|----------|---------|
| **Access App - Guide.md** | 🚀 **START HERE** - Quick access guide (Ubuntu 20) |
| **Security Best Practices & Implementation Guide.md** | 🔒 **IMPORTANT** - Secure your keys properly |
| **Local Development Setup.md** | Run on your machine |
| **Step2: CI-CD Pipeline.md** | Configure automated builds |
| **Helm Chart.md** | Package and publish |
| **GitOps Kubernetes Deployment - Complete.md** | Cluster setup & automation |
| **Multi-Node Kubernetes Cluster Setup on VMware.md** | Production cluster setup |

---

## 🔄 CI/CD Pipeline

### GitHub Actions (Recommended)

**Location**: `.github/workflows/ci-cd.yml`

**Triggers**: On every push to main branch and all tags

**Pipeline Steps**:
1. Run automated tests
2. Build Docker image
3. Sign image with Cosign (private key from secrets)
4. Push to container registry
5. Verify signature with public key
6. Package and sign Helm chart
7. Run security scans

### Azure DevOps (Optional)

**Location**: `azure-pipelines.yml`

Alternative CI/CD configuration. Can be used instead of GitHub Actions for enterprise environments.

---

## 📋 Checklist for Complete Setup

- [ ] Clone repository and review structure
- [ ] Run locally with Docker Compose
- [ ] Execute unit tests
- [ ] Configure GitHub Actions or Azure DevOps pipeline
- [ ] Push signed Docker image to registry
- [ ] Publish Helm chart to ArtifactHub
- [ ] Set up Kubernetes cluster (multi-node recommended)
- [ ] Install and configure FluxCD for GitOps
- [ ] Deploy storage solution (Longhorn)
- [ ] Deploy observability stack (Prometheus, Loki, Grafana)
- [ ] Deploy application via GitOps
- [ ] Configure Cloudflare Tunnel for secure access
- [ ] Verify sealed secrets configuration
- [ ] Test application and monitor dashboards

---

## 🤝 Contributing

1. Clone the repository
2. Create a feature branch
3. Make changes and test locally
4. Push to branch (triggers CI/CD)
5. Create pull request

---

## 📄 License

See LICENSE file for details.

---

## 📞 Support

For detailed setup instructions, refer to the documentation in the `docs/` folder. Each guide includes step-by-step instructions, troubleshooting, and best practices.

---

**DevOps Components**: Docker, Kubernetes, Helm, FluxCD, Prometheus, Grafana, Loki, Longhorn, GitHub Actions, Azure DevOps
