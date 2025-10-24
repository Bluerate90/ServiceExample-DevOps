# ServiceExample-DevOps

# Mirasys DevOps Interview Assignment

A complete DevOps solution demonstrating containerization, CI/CD, Kubernetes, GitOps, and security best practices.

## Prerequisites

- Docker and Docker Desktop
- Kubernetes cluster (self-managed or managed)
- Helm 3.x
- FluxCD CLI
- kubectl
- Git

## Quick Start

### 1. Local Development

Clone and build locally:
\`\`\`bash
git clone https://github.com/YOUR-USERNAME/mirasys-devops-assignment.git
cd mirasys-devops-assignment

# Run with Docker Compose (includes MongoDB, Redis, NATS)
docker-compose up

# Application runs on http://localhost:5000
\`\`\`

### 2. Build Application Locally

\`\`\`bash
cd src
dotnet restore
dotnet build
dotnet test
dotnet run
\`\`\`

### 3. Deploy to Kubernetes

#### Setup Kubernetes Cluster

\`\`\`bash
./scripts/setup-k8s.sh
\`\`\`

#### Setup GitOps with FluxCD

\`\`\`bash
./scripts/setup-flux.sh
\`\`\`

#### Deploy Application

\`\`\`bash
kubectl apply -f k8s/gitops/apps/mirasys-app/
\`\`\`

#### Access Application

\`\`\`bash
# Port forward
kubectl port-forward -n mirasys-app svc/mirasys-app 5000:80

# Visit http://localhost:5000
\`\`\`

## Project Structure

- **src/**: .NET application source code
- **docker/**: Docker configuration
- **helm/**: Helm chart for Kubernetes deployment
- **k8s/**: Kubernetes and GitOps configuration
- **scripts/**: Automation scripts

## CI/CD Pipeline

The GitHub Actions workflow automatically:
1. Runs unit tests
2. Builds Docker image
3. Pushes to container registry
4. Creates releases
5. Triggers GitOps sync

## Security Features

- Signed Docker images
- Signed Helm charts
- Sealed Secrets for sensitive data
- Network Policies
- Pod Security Policies
- TLS encryption between services

## Observability

Access Grafana dashboard:
\`\`\`bash
kubectl port-forward -n observability svc/grafana 3000:80
# Username: admin, Password: check helm values
\`\`\`

Metrics collected:
- Application metrics
- Redis metrics
- MongoDB metrics
- NATS metrics
- Kubernetes cluster metrics

## Storage

Longhorn provides persistent storage with:
- Automatic backups
- Replication
- Snapshots
- High availability

## Bonus Features Implemented

✅ Sealed Secrets for secure secret management
✅ Signed Docker images
✅ Signed Helm chart
✅ Multi-node Kubernetes cluster support
✅ High-availability MongoDB and Redis configuration
✅ Comprehensive monitoring dashboard
✅ Automated GitOps deployment

## Contributing

1. Create a feature branch
2. Commit changes
3. Push to branch
4. Create Pull Request

## License

MIT
