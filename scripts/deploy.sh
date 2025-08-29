#!/bin/bash

# Deploy infrastructure and application script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME=${PROJECT_NAME:-"k8s-azure-project"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
LOCATION=${LOCATION:-"East US"}
RESOURCE_GROUP="${PROJECT_NAME}-${ENVIRONMENT}-rg"

echo -e "${GREEN}Starting deployment of Azure infrastructure and Kubernetes application${NC}"

# Function to print status
print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install it first."
    exit 1
fi

print_success "All prerequisites are installed."

# Login to Azure
print_status "Logging into Azure..."
az login

# Deploy infrastructure with Terraform
print_status "Deploying infrastructure with Terraform..."
cd terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    print_status "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_status "Please edit terraform.tfvars with your specific values and run this script again."
    exit 0
fi

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan

# Get outputs
ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
AKS_CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

print_success "Infrastructure deployed successfully!"

cd ..

# Get AKS credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

# Login to ACR
print_status "Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Build and push Docker image
print_status "Building and pushing Docker image..."
IMAGE_TAG=$(date +%Y%m%d%H%M%S)
docker build -t $ACR_LOGIN_SERVER/k8s-azure-app:$IMAGE_TAG .
docker build -t $ACR_LOGIN_SERVER/k8s-azure-app:latest .
docker push $ACR_LOGIN_SERVER/k8s-azure-app:$IMAGE_TAG
docker push $ACR_LOGIN_SERVER/k8s-azure-app:latest

# Create ACR secret in Kubernetes
print_status "Creating ACR secret in Kubernetes..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

kubectl create secret docker-registry acr-secret \
    --docker-server=$ACR_LOGIN_SERVER \
    --docker-username=$ACR_USERNAME \
    --docker-password=$ACR_PASSWORD \
    --dry-run=client -o yaml | kubectl apply -f -

# Update deployment manifest with ACR details
print_status "Updating Kubernetes manifests..."
sed -i "s/\${ACR_NAME}/$ACR_NAME/g" k8s/deployment.yaml
sed -i "s/\${IMAGE_TAG}/$IMAGE_TAG/g" k8s/deployment.yaml

# Deploy to Kubernetes
print_status "Deploying application to Kubernetes..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for deployment
print_status "Waiting for deployment to complete..."
kubectl rollout status deployment/k8s-azure-app --timeout=300s

# Get service information
print_status "Getting service information..."
kubectl get pods -l app=k8s-azure-app
kubectl get services
kubectl get ingress

# Get external IP
print_status "Waiting for external IP..."
EXTERNAL_IP=""
while [ -z $EXTERNAL_IP ]; do
    print_status "Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get svc k8s-azure-app-loadbalancer --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

print_success "Deployment completed successfully!"
print_success "Application is available at: http://$EXTERNAL_IP"
print_success "Health check: http://$EXTERNAL_IP/health"
print_success "API info: http://$EXTERNAL_IP/api/info"

echo -e "${GREEN}Deployment Summary:${NC}"
echo -e "- Resource Group: $RESOURCE_GROUP"
echo -e "- AKS Cluster: $AKS_CLUSTER_NAME"
echo -e "- ACR: $ACR_NAME"
echo -e "- Application URL: http://$EXTERNAL_IP"
