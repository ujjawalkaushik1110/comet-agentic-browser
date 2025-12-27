#!/bin/bash
# Complete Azure Deployment Script with Terraform
# For GitHub Student Pack ($100 credit)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Comet Agentic Browser - Azure Deployment (Terraform)   ║${NC}"
echo -e "${BLUE}║              GitHub Student Pack Edition                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found${NC}"
    echo "Install: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi
echo -e "${GREEN}✓ Azure CLI installed${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found${NC}"
    echo "Install: https://www.terraform.io/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found${NC}"
    echo "Install: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed${NC}"

# Check Azure login
echo ""
echo -e "${YELLOW}🔐 Checking Azure authentication...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Logging in...${NC}"
    az login
fi

# Show current account
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✓ Logged in to Azure${NC}"
echo "  Subscription: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"

# Confirm subscription
echo ""
read -p "Is this the correct subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please set the correct subscription:"
    echo "  az account set --subscription \"Your Subscription Name\""
    exit 1
fi

# Get user inputs
echo ""
echo -e "${YELLOW}📝 Configuration${NC}"

# Check if terraform.tfvars exists
if [ -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
    echo -e "${GREEN}✓ Found existing terraform.tfvars${NC}"
    read -p "Use existing configuration? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        rm "$TERRAFORM_DIR/terraform.tfvars"
    fi
fi

# Create terraform.tfvars if it doesn't exist
if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
    echo "Creating terraform.tfvars..."
    
    read -p "Enter OpenAI API Key: " OPENAI_KEY
    read -p "Enter admin email: " ADMIN_EMAIL
    read -p "Enter Azure region (default: eastus): " LOCATION
    LOCATION=${LOCATION:-eastus}
    
    cat > "$TERRAFORM_DIR/terraform.tfvars" <<EOF
project_name = "comet-browser"
environment  = "production"
location     = "$LOCATION"

sku_name    = "B1"
db_sku_name = "B_Gen5_1"

openai_api_key = "$OPENAI_KEY"
admin_email    = "$ADMIN_EMAIL"

allowed_cors_origins = ["*"]
enable_monitoring    = true
enable_autoscale     = false

tags = {
  Owner      = "Student"
  ManagedBy  = "Terraform"
  Project    = "CometBrowser"
}
EOF
    echo -e "${GREEN}✓ Created terraform.tfvars${NC}"
fi

# Initialize Terraform
echo ""
echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
cd "$TERRAFORM_DIR"
terraform init

# Validate configuration
echo ""
echo -e "${YELLOW}✅ Validating Terraform configuration...${NC}"
terraform validate

# Plan deployment
echo ""
echo -e "${YELLOW}📊 Planning deployment...${NC}"
terraform plan -out=tfplan

# Review plan
echo ""
echo -e "${YELLOW}Review the deployment plan above.${NC}"
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Apply Terraform
echo ""
echo -e "${YELLOW}🚀 Deploying infrastructure to Azure...${NC}"
terraform apply tfplan
rm -f tfplan

# Get outputs
echo ""
echo -e "${YELLOW}📋 Retrieving deployment information...${NC}"
ACR_NAME=$(terraform output -raw container_registry_name)
ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
APP_NAME=$(terraform output -raw app_service_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
APP_URL=$(terraform output -raw app_service_url)

echo -e "${GREEN}✓ Infrastructure deployed successfully!${NC}"

# Build and push Docker image
echo ""
echo -e "${YELLOW}🐳 Building and pushing Docker image...${NC}"

# Login to ACR
echo "Logging in to Azure Container Registry..."
az acr login --name "$ACR_NAME"

# Build image
echo "Building Docker image..."
cd "$PROJECT_ROOT"
docker build -t "$ACR_LOGIN_SERVER/comet-browser:latest" .

# Push image
echo "Pushing image to ACR..."
docker push "$ACR_LOGIN_SERVER/comet-browser:latest"

echo -e "${GREEN}✓ Docker image pushed successfully!${NC}"

# Restart App Service
echo ""
echo -e "${YELLOW}🔄 Restarting App Service...${NC}"
az webapp restart --name "$APP_NAME" --resource-group "$RESOURCE_GROUP"

# Wait for app to be ready
echo ""
echo -e "${YELLOW}⏳ Waiting for application to be ready...${NC}"
sleep 30

# Test health endpoint
echo "Testing health endpoint..."
if curl -f -s "$APP_URL/health" > /dev/null; then
    echo -e "${GREEN}✓ Application is healthy!${NC}"
else
    echo -e "${YELLOW}⚠ Application may still be starting up...${NC}"
fi

# Display summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉 Deployment Successful! 🎉                ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "  Resource Group:      $RESOURCE_GROUP"
echo "  App Service:         $APP_NAME"
echo "  Container Registry:  $ACR_NAME"
echo ""
echo -e "${BLUE}🌐 Your Application:${NC}"
echo "  URL:                 $APP_URL"
echo "  API Docs:            $APP_URL/docs"
echo "  Health Check:        $APP_URL/health"
echo ""
echo -e "${BLUE}💰 Cost Estimate:${NC}"
echo "  App Service (B1):    ~\$13/month"
echo "  PostgreSQL (Basic):  ~\$5/month"
echo "  Container Registry:  ~\$5/month"
echo "  Total:               ~\$23/month"
echo "  Student Credit:      \$100 = ~4 months free!"
echo ""
echo -e "${BLUE}📚 Next Steps:${NC}"
echo "  1. Test your API:"
echo "     curl $APP_URL/health"
echo ""
echo "  2. View logs:"
echo "     az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "  3. Monitor in Azure Portal:"
echo "     https://portal.azure.com/#resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
echo ""
echo "  4. Set up custom domain (optional)"
echo "  5. Configure CI/CD with GitHub Actions"
echo ""
echo -e "${YELLOW}⚠ Important:${NC}"
echo "  - Keep terraform.tfvars secure (contains secrets)"
echo "  - Monitor your Azure spending in the portal"
echo "  - Set up cost alerts to track your \$100 credit"
echo ""
echo -e "${GREEN}✨ Happy browsing! ✨${NC}"
