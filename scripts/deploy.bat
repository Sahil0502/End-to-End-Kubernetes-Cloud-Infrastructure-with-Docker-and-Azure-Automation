@echo off
setlocal enabledelayedexpansion

:: PowerShell deployment script for Windows
echo Starting deployment of Azure infrastructure and Kubernetes application

:: Configuration
set PROJECT_NAME=k8s-azure-project
set ENVIRONMENT=dev
set LOCATION=East US

echo [INFO] Checking prerequisites...

:: Check if Azure CLI is installed
where az >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Azure CLI is not installed. Please install it first.
    exit /b 1
)

:: Check if Terraform is installed
where terraform >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Terraform is not installed. Please install it first.
    exit /b 1
)

:: Check if kubectl is installed
where kubectl >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] kubectl is not installed. Please install it first.
    exit /b 1
)

:: Check if Docker is installed
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install it first.
    exit /b 1
)

echo [SUCCESS] All prerequisites are installed.

:: Login to Azure
echo [INFO] Logging into Azure...
call az login

:: Deploy infrastructure with Terraform
echo [INFO] Deploying infrastructure with Terraform...
cd terraform

:: Initialize Terraform
call terraform init

:: Create terraform.tfvars if it doesn't exist
if not exist terraform.tfvars (
    echo [INFO] Creating terraform.tfvars from example...
    copy terraform.tfvars.example terraform.tfvars
    echo [INFO] Please edit terraform.tfvars with your specific values and run this script again.
    exit /b 0
)

:: Plan and apply
call terraform plan -out=tfplan
call terraform apply tfplan

:: Get outputs
for /f "tokens=*" %%i in ('terraform output -raw acr_name') do set ACR_NAME=%%i
for /f "tokens=*" %%i in ('terraform output -raw acr_login_server') do set ACR_LOGIN_SERVER=%%i
for /f "tokens=*" %%i in ('terraform output -raw aks_cluster_name') do set AKS_CLUSTER_NAME=%%i
for /f "tokens=*" %%i in ('terraform output -raw resource_group_name') do set RESOURCE_GROUP=%%i

echo [SUCCESS] Infrastructure deployed successfully!

cd ..

:: Get AKS credentials
echo [INFO] Getting AKS credentials...
call az aks get-credentials --resource-group %RESOURCE_GROUP% --name %AKS_CLUSTER_NAME% --overwrite-existing

:: Login to ACR
echo [INFO] Logging into Azure Container Registry...
call az acr login --name %ACR_NAME%

:: Build and push Docker image
echo [INFO] Building and pushing Docker image...
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set IMAGE_TAG=%dt:~0,14%
call docker build -t %ACR_LOGIN_SERVER%/k8s-azure-app:%IMAGE_TAG% .
call docker build -t %ACR_LOGIN_SERVER%/k8s-azure-app:latest .
call docker push %ACR_LOGIN_SERVER%/k8s-azure-app:%IMAGE_TAG%
call docker push %ACR_LOGIN_SERVER%/k8s-azure-app:latest

:: Create ACR secret in Kubernetes
echo [INFO] Creating ACR secret in Kubernetes...
for /f "tokens=*" %%i in ('az acr credential show --name %ACR_NAME% --query username -o tsv') do set ACR_USERNAME=%%i
for /f "tokens=*" %%i in ('az acr credential show --name %ACR_NAME% --query passwords[0].value -o tsv') do set ACR_PASSWORD=%%i

kubectl create secret docker-registry acr-secret --docker-server=%ACR_LOGIN_SERVER% --docker-username=%ACR_USERNAME% --docker-password=%ACR_PASSWORD% --dry-run=client -o yaml | kubectl apply -f -

:: Update deployment manifest with ACR details
echo [INFO] Updating Kubernetes manifests...
powershell -Command "(gc k8s\deployment.yaml) -replace '\${ACR_NAME}', '%ACR_NAME%' | Out-File -encoding UTF8 k8s\deployment.yaml"
powershell -Command "(gc k8s\deployment.yaml) -replace '\${IMAGE_TAG}', '%IMAGE_TAG%' | Out-File -encoding UTF8 k8s\deployment.yaml"

:: Deploy to Kubernetes
echo [INFO] Deploying application to Kubernetes...
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

:: Wait for deployment
echo [INFO] Waiting for deployment to complete...
kubectl rollout status deployment/k8s-azure-app --timeout=300s

:: Get service information
echo [INFO] Getting service information...
kubectl get pods -l app=k8s-azure-app
kubectl get services
kubectl get ingress

echo [SUCCESS] Deployment completed successfully!
echo Check the LoadBalancer service for the external IP address.

endlocal
