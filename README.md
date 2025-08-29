# End-to-End Kubernetes Cloud Infrastructure with Docker and Azure Automation 🚀

This project demonstrates a complete DevOps pipeline for deploying containerized applications to Azure Kubernetes Service (AKS) using Infrastructure as Code (IaC) with Terraform and automated CI/CD pipelines.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  Azure Pipeline │───▶│  Azure Cloud    │
│                 │    │                 │    │                 │
│ • Source Code   │    │ • Build & Test  │    │ • AKS Cluster   │
│ • Dockerfile    │    │ • Docker Build  │    │ • ACR Registry  │
│ • K8s Manifests │    │ • Deploy to AKS │    │ • Load Balancer │
│ • Terraform IaC │    │ • Infrastructure│    │ • Virtual Network│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
├── 📄 Dockerfile                     # Container definition
├── 📄 package.json                   # Node.js dependencies  
├── 📄 package-lock.json               # Locked dependency versions
├── 📄 server.js                      # Sample Express application
├── 📄 server.test.js                 # Jest test suite
├── � .dockerignore                  # Docker build exclusions
├── 📄 .gitignore                     # Git exclusions
├── �📂 k8s/                          # Kubernetes manifests
│   ├── 📄 deployment.yaml           # Application deployment
│   ├── 📄 service.yaml              # Service configuration
│   ├── 📄 ingress.yaml              # Ingress controller
│   └── 📄 configmap.yaml            # Configuration data
├── 📂 terraform/                    # Infrastructure as Code
│   ├── 📄 main.tf                   # Provider configuration
│   ├── 📄 variables.tf              # Input variables
│   ├── 📄 outputs.tf                # Output values
│   ├── 📄 aks.tf                    # AKS cluster configuration
│   ├── 📄 network.tf                # Network resources
│   └── 📄 terraform.tfvars.example  # Example variables
├── 📂 .github/workflows/            # GitHub Actions
│   ├── 📄 basic-ci.yml              # Basic validation (no secrets)
│   ├── 📄 ci-cd.yml                 # Full application pipeline
│   └── 📄 infrastructure.yml        # Infrastructure pipeline
├── 📂 azure-pipelines/              # Azure DevOps Pipelines
│   └── 📄 azure-pipelines.yml       # Alternative CI/CD
├── 📂 scripts/                      # Deployment scripts
│   ├── 📄 deploy.sh                 # Linux/Mac deployment
│   ├── 📄 deploy.bat                # Windows deployment
│   └── 📄 cleanup.sh                # Resource cleanup
├── 📄 GITHUB_SECRETS_SETUP.md       # Detailed secrets setup guide
└── 📄 README.md                     # This comprehensive guide
```

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have the following tools installed:

- **Azure CLI** - [Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Terraform** - [Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **kubectl** - [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- **Docker** - [Install Guide](https://docs.docker.com/get-docker/)
- **Git** - [Install Guide](https://git-scm.com/downloads)

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd "End-to-End Kubernetes Cloud Infrastructure with Docker and Azure Automation"
```

### 2. Initial Testing (No Azure Required)

Test the project locally first using the Basic CI validation:

```bash
# Install dependencies
npm install

# Run tests (Jest test suite)
npm test

# Build and test Docker container
docker build -t k8s-azure-app .
docker run -d -p 3000:3000 --name test-container k8s-azure-app

# Test application endpoints
curl http://localhost:3000
curl http://localhost:3000/health
curl http://localhost:3000/api/info

# Cleanup test container
docker stop test-container
docker rm test-container

# Validate Kubernetes manifests (requires kubectl)
kubectl --dry-run=client apply -f k8s/ --validate=false

# Check Basic CI workflow status
# → Visit your GitHub repository's Actions tab
# → "Basic CI" workflow should be ✅ passing
```

### 3. Configure GitHub Secrets

⚠️ **Important**: Before deploying to Azure, you need to configure GitHub secrets.

📋 **Follow the detailed guide**: [GitHub Secrets Setup Guide](./GITHUB_SECRETS_SETUP.md)

### 4. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "your-subscription-id"

# Create a service principal for Terraform (copy the output to GitHub secrets)
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/your-subscription-id" --sdk-auth
```

### 5. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 6. Deploy Infrastructure and Application

#### Option A: Using Deployment Script (Recommended)

**Linux/Mac:**
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

**Windows:**
```cmd
scripts\deploy.bat
```

#### Option B: Manual Deployment

```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 2. Get AKS credentials
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)

# 3. Build and push Docker image
ACR_NAME=$(terraform output -raw acr_name)
az acr login --name $ACR_NAME
docker build -t $ACR_NAME.azurecr.io/k8s-azure-app:latest .
docker push $ACR_NAME.azurecr.io/k8s-azure-app:latest

# 4. Deploy to Kubernetes
cd ../k8s
kubectl apply -f .
```

## 🔧 GitHub Actions Workflows

This project includes **three** GitHub Actions workflows for comprehensive testing and deployment:

### 1. Basic CI Workflow (`basic-ci.yml`)
- ✅ **Always runs** - No secrets required
- Tests Node.js application with Jest
- Validates Docker build and container functionality  
- Checks Kubernetes manifests syntax and structure
- Validates Terraform configuration (init, validate, fmt)
- Runs basic security scans
- **Purpose**: Immediate feedback on code quality without Azure dependencies

### 2. Full CI/CD Pipeline (`ci-cd.yml`)
- 🔐 **Requires secrets** - See [GitHub Secrets Setup Guide](./GITHUB_SECRETS_SETUP.md)
- Builds and pushes to Azure Container Registry (ACR)
- Deploys to Azure Kubernetes Service (AKS)
- Runs comprehensive security scans with Trivy
- Updates Kubernetes deployments with new images

### 3. Infrastructure Pipeline (`infrastructure.yml`)
- 🔐 **Requires secrets** - Terraform Azure credentials (ARM_*)
- Validates and deploys infrastructure with Terraform
- Manages Terraform state and plans
- Creates AKS cluster, ACR, networking, and monitoring resources

### Current Workflow Status

🎯 **What to expect:**

- ✅ **Basic CI** → Should pass immediately (validates code structure)
- ⚠️ **CI/CD Pipeline** → Will show warnings until ACR/AKS secrets configured
- ⚠️ **Infrastructure Deployment** → Will show warnings until ARM secrets configured

> **Note**: Failing workflows are expected until you configure the required Azure secrets. The Basic CI workflow provides immediate validation without any Azure dependencies.

## 🆕 Recent Updates & Fixes

### ✅ Latest Improvements (v2.0)

**GitHub Actions Enhancements:**
- ✅ Added **Basic CI workflow** for immediate validation without Azure dependencies
- ✅ Fixed deprecated GitHub Actions (upload/download-artifact v3 → v4)
- ✅ Resolved Terraform circular dependency issues in AKS role assignments
- ✅ Fixed Terraform formatting validation (fmt -check) with proper heredoc handling
- ✅ Enhanced Kubernetes manifest validation with kubectl + yq
- ✅ Added comprehensive container testing with health checks

**Infrastructure Improvements:**
- ✅ Removed problematic `depends_on` clauses causing Terraform cycles
- ✅ Improved Terraform file formatting and validation
- ✅ Enhanced error handling in deployment scripts
- ✅ Added proper working-directory usage in GitHub Actions

**Application Features:**
- ✅ Enhanced health check endpoints (`/health`, `/api/info`)
- ✅ Improved Docker multi-stage builds with security contexts
- ✅ Added comprehensive Jest testing suite
- ✅ Enhanced error handling and logging

### 🔧 Configuration

### Terraform Variables

Key variables you can customize in `terraform/terraform.tfvars`:

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Name of the project | `k8s-azure-project` |
| `location` | Azure region | `East US` |
| `environment` | Environment name | `dev` |
| `node_count` | Number of AKS nodes | `2` |
| `node_vm_size` | VM size for nodes | `Standard_D2s_v3` |
| `kubernetes_version` | Kubernetes version | `1.27.3` |
| `enable_auto_scaling` | Enable auto scaling | `true` |

### Environment Variables

For CI/CD pipelines, configure these secrets:

### GitHub Secrets

Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

#### For Infrastructure Pipeline (ARM - Azure Resource Manager)
- `ARM_CLIENT_ID` - Service principal application ID
- `ARM_CLIENT_SECRET` - Service principal secret  
- `ARM_SUBSCRIPTION_ID` - Azure subscription ID
- `ARM_TENANT_ID` - Azure AD tenant ID

#### For CI/CD Pipeline (ACR & AKS)
- `AZURE_CREDENTIALS` - Azure service principal JSON
- `ACR_NAME` - Container registry name
- `ACR_USERNAME` - Registry username  
- `ACR_PASSWORD` - Registry password
- `RESOURCE_GROUP` - Resource group name
- `CLUSTER_NAME` - AKS cluster name

> 📋 **See detailed setup guide**: [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md)

#### Azure Pipeline Variables
- `dockerRegistryServiceConnection`
- `kubernetesServiceConnection`
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

This project includes **three comprehensive workflows**:

#### 1. **Basic CI Pipeline** (`.github/workflows/basic-ci.yml`)
**Runs on every push/PR - No secrets required**
- ✅ Node.js testing with Jest
- ✅ Docker build and container testing
- ✅ Kubernetes manifest validation (kubectl + yq)
- ✅ Terraform configuration validation (init, validate, fmt)
- ✅ Basic security scanning
- ✅ Project setup verification

#### 2. **Application CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
**Requires Azure secrets for full deployment**
- 🔐 Builds and pushes Docker images to ACR
- 🔐 Deploys applications to AKS
- 🔐 Security scanning with Trivy
- 🔐 Rolling updates and health checks

#### 3. **Infrastructure Pipeline** (`.github/workflows/infrastructure.yml`)
**Requires Terraform Azure credentials**
- 🔐 Terraform plan and apply for infrastructure
- 🔐 Creates AKS cluster, ACR, networking
- 🔐 Infrastructure validation and state management

### Workflow Triggers

```yaml
# Basic CI - Always runs
on: [push, pull_request]

# CI/CD Pipeline - Runs on main branch
on:
  push:
    branches: [main]
  
# Infrastructure - Runs on terraform changes
on:
  push:
    paths: ['terraform/**']
```

### Azure Pipelines

Alternative pipeline configuration is available in `azure-pipelines/azure-pipelines.yml`.

## 🏃‍♂️ Running the Application

### Local Development

```bash
# Install dependencies
npm install

# Run locally
npm start

# Access the application
curl http://localhost:3000
curl http://localhost:3000/health
curl http://localhost:3000/api/info
```

### Docker

```bash
# Build locally
docker build -t k8s-azure-app .

# Run container
docker run -p 3000:3000 k8s-azure-app

# Access application
curl http://localhost:3000
```

### Kubernetes

After deployment, get the external IP:

```bash
kubectl get services k8s-azure-app-loadbalancer

# Access application
curl http://<EXTERNAL-IP>
curl http://<EXTERNAL-IP>/health
curl http://<EXTERNAL-IP>/api/info
```

## 📊 Monitoring and Observability

### Application Insights

The infrastructure includes Azure Log Analytics workspace for monitoring:

```bash
# View AKS cluster logs
az monitor log-analytics query \
  --workspace $(terraform output -raw log_analytics_workspace_id) \
  --analytics-query "ContainerLog | limit 100"
```

### Health Checks

The application includes built-in health endpoints:

- **Health Check**: `/health` - Application health status
- **Info Endpoint**: `/api/info` - System information
- **Root Endpoint**: `/` - Welcome message

### Kubernetes Monitoring

```bash
# Check pod status
kubectl get pods -l app=k8s-azure-app

# View application logs
kubectl logs -l app=k8s-azure-app

# Check deployment status
kubectl rollout status deployment/k8s-azure-app

# Monitor resources
kubectl top pods
kubectl top nodes
```

## 🔐 Security Features

### Container Security
- Non-root user execution
- Security contexts in Kubernetes
- Image vulnerability scanning with Trivy
- Multi-stage Docker builds

### Network Security
- Network Security Groups (NSGs)
- Private container registry (ACR)
- HTTPS ingress with SSL/TLS
- Network policies (can be enabled)

### RBAC and Authentication
- Azure AD integration
- Kubernetes RBAC enabled
- Service principal authentication
- Managed identity for AKS

## 🛠️ Troubleshooting

### Common Issues

1. **AKS Connection Issues**
   ```bash
   # Reset credentials
   az aks get-credentials --resource-group <rg-name> --name <cluster-name> --overwrite-existing
   ```

2. **ACR Authentication**
   ```bash
   # Login to ACR
   az acr login --name <acr-name>
   
   # Check credentials
   az acr credential show --name <acr-name>
   ```

3. **Terraform State Issues**
   ```bash
   # Refresh state
   terraform refresh
   
   # Import existing resources if needed
   terraform import azurerm_resource_group.main /subscriptions/<sub-id>/resourceGroups/<rg-name>
   ```

4. **Pod Startup Issues**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name>
   
   # Check logs
   kubectl logs <pod-name>
   
   # Check service endpoints
   kubectl get endpoints
   ```

### Debugging Commands

```bash
# AKS cluster info
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# All resources
kubectl get all

# Resource usage
kubectl top pods --all-namespaces
kubectl top nodes

# Events
kubectl get events --sort-by=.metadata.creationTimestamp

# Network connectivity test
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
```

## 🧹 Cleanup

To remove all resources and avoid charges:

```bash
# Using cleanup script
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh

# Or manually
cd terraform
terraform destroy
```

## 📝 Best Practices

### Docker
- Use multi-stage builds
- Run as non-root user
- Minimize image size
- Regular base image updates

### Kubernetes
- Use resource limits and requests
- Implement health checks
- Use secrets for sensitive data
- Apply security contexts

### Infrastructure
- Use remote state for Terraform
- Tag all resources
- Implement monitoring
- Regular security updates

### CI/CD
- Use pull request validation
- Implement security scanning
- Use environment-specific deployments
- Monitor pipeline performance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the troubleshooting section
- Review Azure and Kubernetes documentation

---

**Happy Deploying! 🚀**
