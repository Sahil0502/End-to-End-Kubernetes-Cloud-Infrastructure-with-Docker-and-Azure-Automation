# GitHub Secrets Setup Guide

This guide explains how to configure the required GitHub secrets for the CI/CD pipelines to work properly.

## 🔐 Required Secrets

### For Azure Infrastructure (Terraform)

Set these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `ARM_CLIENT_ID` | Azure Service Principal Application ID | `az ad sp create-for-rbac` output |
| `ARM_CLIENT_SECRET` | Azure Service Principal Password | `az ad sp create-for-rbac` output |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | `az account show --query id -o tsv` |
| `ARM_TENANT_ID` | Azure Tenant ID | `az account show --query tenantId -o tsv` |

### For Container Registry and AKS Deployment

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `ACR_NAME` | Azure Container Registry name | From Terraform output or Azure portal |
| `ACR_USERNAME` | ACR admin username | `az acr credential show --name <acr-name> --query username -o tsv` |
| `ACR_PASSWORD` | ACR admin password | `az acr credential show --name <acr-name> --query passwords[0].value -o tsv` |
| `RESOURCE_GROUP` | Azure Resource Group name | From Terraform output |
| `CLUSTER_NAME` | AKS cluster name | From Terraform output |
| `AZURE_CREDENTIALS` | Azure service principal JSON | See below |

## 🚀 Step-by-Step Setup

### 1. Create Azure Service Principal

```bash
# Login to Azure
az login

# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth
```

This will output JSON like:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

### 2. Set Up GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

**For Terraform (Infrastructure):**
- `ARM_CLIENT_ID`: Use `clientId` from the JSON
- `ARM_CLIENT_SECRET`: Use `clientSecret` from the JSON  
- `ARM_SUBSCRIPTION_ID`: Use `subscriptionId` from the JSON
- `ARM_TENANT_ID`: Use `tenantId` from the JSON

**For Azure Credentials:**
- `AZURE_CREDENTIALS`: Copy the entire JSON output from step 1

### 3. Deploy Infrastructure First

```bash
# Clone your repository
git clone <your-repo-url>
cd "End-to-End Kubernetes Cloud Infrastructure with Docker and Azure Automation"

# Deploy infrastructure using Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### 4. Get Container Registry Information

After Terraform deployment:

```bash
# Get ACR details
ACR_NAME=$(terraform output -raw acr_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)

# Get ACR credentials
az acr credential show --name $ACR_NAME

echo "Set these GitHub secrets:"
echo "ACR_NAME: $ACR_NAME"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"  
echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "ACR_USERNAME: $(az acr credential show --name $ACR_NAME --query username -o tsv)"
echo "ACR_PASSWORD: $(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)"
```

### 5. Add the Remaining Secrets

Add these to GitHub secrets:
- `ACR_NAME`: Your container registry name
- `ACR_USERNAME`: Container registry username
- `ACR_PASSWORD`: Container registry password
- `RESOURCE_GROUP`: Resource group name
- `CLUSTER_NAME`: AKS cluster name

## 🔍 Verification

After setting up secrets, push a change to trigger the workflows:

1. **Infrastructure Pipeline** - Should validate and plan Terraform
2. **CI/CD Pipeline** - Should build, test, and potentially deploy the application

## 🛠️ Troubleshooting

### Pipeline Fails with "Context access might be invalid"

This is a false positive from GitHub Actions linting. The secrets are valid and the pipeline will work correctly.

### Missing Secrets

If secrets are not configured, the pipelines will show warnings but won't fail. They'll skip the steps that require those secrets.

### Permission Issues

Make sure your service principal has the `Contributor` role on your Azure subscription.

### ACR Access Issues

Ensure ACR admin user is enabled:
```bash
az acr update --name <acr-name> --admin-enabled true
```

## 🔒 Security Best Practices

1. **Use least privilege**: Only grant necessary permissions
2. **Rotate secrets regularly**: Update service principal credentials periodically
3. **Use environments**: Consider using GitHub environments for production deployments
4. **Monitor access**: Review GitHub Actions logs regularly

## 📚 Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Azure Service Principal Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)
- [GitHub Actions for Azure](https://github.com/Azure/actions)
