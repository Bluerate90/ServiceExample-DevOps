# Step 2: CI/CD Pipeline with Security Scanning & Image Signing

Complete guide for setting up automated testing, Docker builds, vulnerability scanning, and container signing.

## Quick Overview

When you push code to `main` branch:
1. ✅ Unit tests run automatically
2. 🐳 Docker image builds
3. 🔍 Trivy scans for vulnerabilities
4. 📦 Image pushes to DockerHub
5. 🔐 Image signed with Cosign
6. ✓ Signature verified

**Total time:** ~2-3 minutes

---

## Prerequisites

- GitHub account with repository access
- DockerHub account
- Basic git knowledge

---

## Step 1: Add GitHub Secrets

Go to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these 15 secrets:

### Docker Registry (Required)
```
DOCKER_HUB_USERNAME = your-dockerhub-username
DOCKER_HUB_TOKEN = dckr_pat_xxxxx (from DockerHub settings)
REGISTRY_URL = docker.io
```

### Cosign Keys (For Image Signing)
```
COSIGN_KEY = (base64-encoded private key - see below)
COSIGN_PASSWORD = (password you set when creating keys)
```

### MongoDB
```
MONGO_INITDB_ROOT_USERNAME = admin
MONGO_INITDB_ROOT_PASSWORD = YourSecurePassword@123
MONGO_INITDB_DATABASE = ServiceExampleDB
MONGODB_URI = mongodb://admin:YourSecurePassword@123@mongodb:27017/ServiceExampleDB?authSource=admin
```

### Redis (TLS=false for local)
```
REDIS_HOST = redis
REDIS_PORT = 6379
REDIS_TLS = false
REDIS_PASSWORD = (leave empty or set if required)
```

### NATS
```
NATS_URL = nats://nats:4222
NATS_JETSTREAM_ENABLED = true
```

### Application
```
ASPNETCORE_ENVIRONMENT = Development
ASPNETCORE_URLS = http://+:5000
```

---

## Step 2: Generate Cosign Keys (One-Time Setup)

### On Your Local Machine

```bash
# Install Cosign
brew install sigstore/tools/cosign  # macOS
# or see: https://github.com/sigstore/cosign/releases

# Generate key pair (saves cosign.key and cosign.pub)
cosign generate-key-pair

# You'll be prompted for a password - save this securely!
```

### Encode Private Key for GitHub

```bash
# Convert private key to base64
cat cosign.key | base64 -w 0

# Copy entire output to clipboard
# Paste into GitHub secret: COSIGN_KEY
```

### Add Public Key to Repository

```bash
# Copy public key to repo root
git add cosign.pub
git commit -m "Add Cosign public key for image verification"
git push origin main
```

---

## Step 3: Create Workflow File

Create `.github/workflows/ci-cd-pipeline.yml` - use the workflow from the guide provided

Or copy from the repository if already set up.

---

## Step 4: Protect Sensitive Files

Create `.gitignore` with:

```gitignore
# Environment - NEVER COMMIT
.env
.env.local
.env.*.local

# Secrets - NEVER COMMIT
cosign.key
*.key
*.pem
```

---

## Step 5: Test the Pipeline

### Option A: Push to Trigger Pipeline
```bash
git push origin main
```

### Option B: Manual Trigger
Go to **Actions** → **CI/CD - Build, Scan & Push** → **Run workflow**

---

## Monitoring the Pipeline

### View Workflow Status
1. Go to **Actions** tab
2. Click workflow name: **CI/CD - Build, Scan & Push**
3. Check the latest run

### What Each Step Does

| Step | Purpose | Duration |
|------|---------|----------|
| **Run Unit Tests** | Tests application code | 30s |
| **Build Docker image** | Creates container image | 20s |
| **Run Trivy scan** | Scans for vulnerabilities | 10s |
| **Upload Trivy results** | Reports to GitHub Security | 5s |
| **Push Docker image** | Uploads to DockerHub | 10s |
| **Sign with Cosign** | Cryptographically signs image | 5s |
| **Verify signature** | Confirms signature is valid | 5s |

### View Security Scan Results
Go to **Security** tab → **Code scanning** to see Trivy findings

---

## Local Development

### Setup Local Environment

```bash
# Copy template
cp .env.example .env

# Edit with your local values
nano .env

# Use docker-compose
docker-compose -f docker/docker-compose.yml up -d
```

### Verify .env is Protected

```bash
# Should return NOTHING (empty)
git ls-files | grep ".env"

# Should show .env is ignored
git check-ignore .env
```

---

## Troubleshooting

### Pipeline Failed: Tests Not Running
**Solution:** Verify .sln path is correct
```bash
ls src/ServiceExample/ServiceExample.sln
```

### Pipeline Failed: Docker Push Failed
**Solution:** Check DockerHub token
1. Go to DockerHub → Account Settings → Security
2. Verify token hasn't expired
3. Update `DOCKER_HUB_TOKEN` secret in GitHub

### Pipeline Failed: Cosign Sign Failed
**Solution:** Verify Cosign key is valid
1. Check `COSIGN_KEY` is base64-encoded
2. Check `COSIGN_PASSWORD` matches
3. Try regenerating keys locally

### Image Shows Vulnerabilities
**Solution:** This is normal for base images
1. Review vulnerabilities in GitHub Security tab
2. Update base image versions if needed
3. High/Critical stop the pipeline (by design)

---

## Best Practices

### Security
- ✅ Never commit `.env` files
- ✅ Rotate credentials every 90 days
- ✅ Use separate secrets for each environment
- ✅ Review Trivy scan results regularly

### Development
- ✅ Test locally before pushing
- ✅ Use meaningful commit messages
- ✅ Keep `.env.example` updated with new variables
- ✅ Review workflow runs after each push

### CI/CD
- ✅ Monitor build times
- ✅ Set up branch protection rules
- ✅ Require status checks before merge
- ✅ Archive scan results periodically

---

## What Gets Pushed to DockerHub?

### Image Tags
```
docker.io/your-username/serviceexample:main          # Latest on main
docker.io/your-username/serviceexample:latest        # Latest overall
docker.io/your-username/serviceexample:main-abc1234  # Specific commit
```

### Image Includes
- ✅ Compiled .NET 9 application
- ✅ Runtime only (optimized size)
- ✅ OpenContainer labels
- ✅ Cosign signature
- ✅ Build attestation

---

## Security Scanning Results

### Trivy Vulnerability Scan
- Reports all vulnerabilities found
- Blocks pipeline if CRITICAL vulnerabilities exist
- Results visible in GitHub Security → Code scanning
- Can be reviewed per severity level

### Image Signature
- Every image signed with Cosign private key
- Public key in repository for verification
- Prevents unauthorized image modifications
- Can verify locally: `cosign verify --key cosign.pub <image>`

---

## Next Steps

After Step 2 is working:
- **Step 3:** Deploy to Kubernetes
- **Step 4:** Setup GitOps with ArgoCD
- **Step 5:** Configure monitoring & logging

---

## Getting Help

### Check Workflow Logs
1. **Actions** tab
2. Click failed workflow
3. Click failed step
4. Expand logs

### Common Issues
- Secrets not set → Add to GitHub Secrets
- .env in git → Add to .gitignore and remove from history
- Image not pushed → Check DockerHub token validity
- Cosign key invalid → Regenerate and re-encode to base64

---

## File Structure

```
repository/
├── .github/
│   └── workflows/
│       └── ci-cd-pipeline.yml    ← Workflow file
├── .gitignore                      ← Blocks .env & keys
├── .env.example                    ← Template only
├── cosign.pub                      ← Public key
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── src/
└── tests/
```

---

## Summary

You now have a complete CI/CD pipeline that:
1. Automatically tests code changes
2. Builds secure Docker images
3. Scans for vulnerabilities
4. Signs images cryptographically
5. Deploys to DockerHub

All automated on every push to main branch.

**Status: Step 2 Complete ✓**
