#!/bin/bash

# Cleanup script to destroy all resources
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

echo -e "${RED}WARNING: This will destroy all Azure resources created by this project!${NC}"
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Navigate to terraform directory
cd terraform

# Check if terraform state exists
if [ ! -f terraform.tfstate ]; then
    print_error "No Terraform state found. Nothing to destroy."
    exit 1
fi

# Login to Azure
print_status "Logging into Azure..."
az login

# Destroy infrastructure
print_status "Destroying infrastructure with Terraform..."
terraform destroy -auto-approve

print_success "All resources have been destroyed!"

# Clean up local files
print_status "Cleaning up local files..."
rm -f terraform.tfstate*
rm -f tfplan
rm -f .terraform.lock.hcl

print_success "Cleanup completed successfully!"
