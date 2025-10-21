# CI/CD Pipeline with Security Scanning & Image Signing

Complete automated CI/CD pipeline using GitHub Actions with security scanning, vulnerability detection, and Docker image signing.

## Pipeline Overview

This GitHub Actions workflow runs on every push to `main` or `master` branches and performs:

### Stage 1: Build & Test ✅
- Install .NET 9
- Restore NuGet packages
- Build application
- Run unit tests with code coverage
- Publish test results and coverage reports

### Stage 2: Build & Push Docker Image ✅
- Build Docker image from Dockerfile
- Push to GitHub Container Registry (GHCR)
- Tags: `latest`, branch-specific, and commit SHA

### Stage 3: Security Scanning with Trivy ✅
- Scan Docker image for HIGH and CRITICAL vulnerabilities
- Generate SARIF report
- Upload to GitHub Security tab
- Display results in table format

### Stage 4: Sign Image with Cosign ✅
- Generate ephemeral signing keys
- Sign Docker image with Cosign
- Attach Software Bill of Materials (SBOM)
- Create verifiable signature

## File Structure

```
ServiceExample-DevOps/
├── .github/
│   └── workflows/
│       └── main.yml              # CI/CD Pipeline
├── src/
│   └── ServiceExample/
│       └── ServiceExample/
│           └── ServiceExample.csproj
├── docker/
│   └── Dockerfile
└── README.md
```

## Repository Settings Required

### 1. Enable Workflow Permissions
- Go to **Settings → Actions → General**
- Under "Workflow permissions", select: **"Read and write permissions"**
- ✅ Check: **"Allow GitHub Actions to create and approve pull requests"**

### 2. Container Registry Access
- GitHub Container Registry (GHCR) is automatically available
- Images stored at: `ghcr.io/your-username/serviceexample-devops`
- Tokens automatically generated from `${{ secrets.GITHUB_TOKEN }}`

## Accessing Results

### View Pipeline Runs
1. Go to **Actions** tab in your repository
2. Click on workflow runs to see details
3. Each job shows logs, output, and status

### View Security Scans
1. Go to **Security** tab → **Code scanning alerts**
2. See all HIGH and CRITICAL vulnerabilities found by Trivy
3. Vulnerabilities link to CVE details

### View Docker Images
1. Go to **Packages** section (right sidebar)
2. Click on `serviceexample-devops` package
3. See all tagged versions and push history

### Verify Image Signature

To verify the image was signed by your pipeline:

```bash
# Pull and verify
docker pull ghcr.io/bluerate90/serviceexample-devops:latest

# Check signature (requires cosign installed)
cosign verify --key cosign.pub ghcr.io/bluerate90/serviceexample-devops:latest
```

Or with keyless verification (if using Sigstore):
```bash
cosign verify --certificate-identity-regexp=".*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/bluerate90/serviceexample-devops:latest
```

## Environment Variables

All configurable in `.github/workflows/main.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `REGISTRY` | `ghcr.io` | Container registry |
| `IMAGE_NAME` | `Bluerate90/ServiceExample-DevOps` | Image repository name |
| `DOTNET_VERSION` | `9.0.x` | .NET version to use |

## Workflow Triggers

Pipeline runs on:
- ✅ Push to `main` branch
- ✅ Push to `master` branch
- ✅ Pull requests to `main` or `master`

## Performance

Typical execution times:
- Build & Test: 1-2 minutes
- Docker Build & Push: 2-3 minutes
- Trivy Scan: 1-2 minutes
- Cosign Signing: 30 seconds
- **Total: 5-8 minutes**

## Security Features

### Trivy Scanning
- Scans OS packages (Debian)
- Scans application dependencies (.NET)
- Reports HIGH and CRITICAL vulnerabilities
- Results available in GitHub Security dashboard

### Cosign Signing
- Signs images with ephemeral keys
- Stores signatures in registry
- Verifiable by anyone
- Protects supply chain integrity

### SBOM (Software Bill of Materials)
- Attached to image as attestation
- Lists all components and versions
- Helps track dependencies

## Troubleshooting

### Pipeline fails: "Project file does not exist"
- Verify path: `src/ServiceExample/ServiceExample/ServiceExample.csproj`
- Ensure file exists in repository

### Trivy scan shows image not found
- Wait for Docker push to complete first
- Check image lowercase in GHCR

### Cosign signing timeout
- Temporary Sigstore infrastructure issue
- Pipeline retries automatically
- Try pushing again if it fails

### Tests fail
- Check test output in Actions logs
- Review unit test code
- Ensure all dependencies are correct

## Next Steps

1. **Monitor Security Alerts**
   - Review HIGH/CRITICAL vulnerabilities regularly
   - Update dependencies when patches are available

2. **Store Signing Keys**
   - For production, store cosign keys in GitHub Secrets
   - Use Azure Key Vault or similar service

3. **Set Up Image Policies**
   - Require signature verification before deployment
   - Use image scanning results in deployment decisions

4. **Integrate with Deployment**
   - Use signed images in Kubernetes/Docker deployments
   - Add signature verification to deployment pipeline

## Useful Commands

```bash
# View logs locally
gh run view --log

# Download artifacts
gh run download

# List all workflow runs
gh run list

# Re-run failed jobs
gh run rerun <run-id>
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)
- [Cosign - Container Image Signing](https://github.com/sigstore/cosign)
- [Sigstore Project](https://www.sigstore.dev/)
- [SBOM Specification](https://cyclonedx.org/)

## Support

For issues or questions:
1. Check GitHub Actions logs
2. Review Trivy vulnerability reports
3. Verify GHCR access and permissions
4. Consult documentation links above
