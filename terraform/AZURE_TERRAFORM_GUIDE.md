# Azure Deployment with Terraform - Complete Guide

## 🎓 For GitHub Student Pack ($100 Credit)

This guide will help you deploy the Comet Agentic Browser to Azure using Infrastructure as Code (Terraform) with your GitHub Student Pack benefits.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Get GitHub Student Pack](#get-student-pack)
3. [Initial Setup](#initial-setup)
4. [Local Deployment](#local-deployment)
5. [CI/CD Deployment](#cicd-deployment)
6. [Monitoring & Management](#monitoring)
7. [Cost Optimization](#cost-optimization)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Verify Installation

```bash
az --version
terraform --version
docker --version
```

## Get GitHub Student Pack

### 1. Apply for Student Pack

1. Visit: https://education.github.com/pack
2. Click "Get your pack"
3. Verify with student email (.edu) or upload student ID
4. Wait for approval (usually instant)

### 2. Activate Azure for Students

1. Visit: https://azure.microsoft.com/en-us/free/students/
2. Sign in with Microsoft account
3. Verify student status (auto-fills from GitHub)
4. Get $100 credit (no credit card required!)

### 3. Verify Azure Credit

```bash
# Login to Azure
az login

# Check your subscription
az account show

# Verify credit balance
az consumption usage list --query "[0]"
```

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/ujjawalkaushik1110/comet-agentic-browser.git
cd comet-agentic-browser
```

### 2. Configure Terraform Variables

```bash
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required variables:**
```hcl
project_name   = "comet-browser"
environment    = "production"
location       = "eastus"  # Choose closest region
openai_api_key = "sk-your-key-here"
admin_email    = "your@email.com"
```

### 3. Get OpenAI API Key

1. Visit: https://platform.openai.com/api-keys
2. Create new secret key
3. Copy and save it (shown only once)
4. Add to terraform.tfvars

## Local Deployment

### Method 1: Automated Script (Recommended)

```bash
# Make script executable
chmod +x terraform/deploy.sh

# Run deployment
./terraform/deploy.sh
```

The script will:
- ✅ Check prerequisites
- ✅ Login to Azure
- ✅ Initialize Terraform
- ✅ Create Azure resources
- ✅ Build and push Docker image
- ✅ Deploy application
- ✅ Run health checks

### Method 2: Manual Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Apply configuration
terraform apply

# Get outputs
terraform output
```

### Deploy Docker Image

```bash
# Get ACR details from Terraform output
ACR_NAME=$(terraform output -raw container_registry_name)
ACR_LOGIN=$(terraform output -raw container_registry_login_server)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push
docker build -t $ACR_LOGIN/comet-browser:latest .
docker push $ACR_LOGIN/comet-browser:latest

# Restart app service
APP_NAME=$(terraform output -raw app_service_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP
```

## CI/CD Deployment

### Setup GitHub Actions

#### 1. Create Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "comet-browser-github" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth

# Save the entire JSON output
```

#### 2. Configure GitHub Secrets

Go to: GitHub repo → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `AZURE_CREDENTIALS` | Service principal JSON | From step 1 above |
| `AZURE_CLIENT_ID` | Client ID | From JSON: `clientId` |
| `AZURE_CLIENT_SECRET` | Client secret | From JSON: `clientSecret` |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID | `az account show --query id` |
| `AZURE_TENANT_ID` | Tenant ID | From JSON: `tenantId` |
| `OPENAI_API_KEY` | OpenAI API key | From OpenAI dashboard |
| `ADMIN_EMAIL` | Your email | Your email address |

#### 3. Enable GitHub Actions

The workflow is already configured at `.github/workflows/azure-terraform.yml`

Push to main branch to trigger deployment:

```bash
git add .
git commit -m "Deploy to Azure"
git push origin main
```

#### 4. Monitor Deployment

- Go to: GitHub repo → Actions
- Click on the running workflow
- Watch the deployment progress

### Workflow Features

The CI/CD pipeline includes:

- ✅ **Validation**: Checks Terraform syntax
- ✅ **Planning**: Shows what will change (on PRs)
- ✅ **Deployment**: Creates/updates infrastructure
- ✅ **Docker Build**: Builds and pushes container
- ✅ **Health Checks**: Verifies deployment
- ✅ **Testing**: Runs API tests

## Monitoring & Management

### View Application Logs

```bash
# Stream logs
az webapp log tail \
  --name $(terraform output -raw app_service_name) \
  --resource-group $(terraform output -raw resource_group_name)

# Download logs
az webapp log download \
  --name $(terraform output -raw app_service_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

### Access Application Insights

```bash
# Get instrumentation key
terraform output application_insights_instrumentation_key

# View in portal
APP_INSIGHTS_ID=$(az resource show \
  --resource-group $(terraform output -raw resource_group_name) \
  --name comet-browser-production-insights \
  --resource-type "Microsoft.Insights/components" \
  --query id -o tsv)

echo "View at: https://portal.azure.com/#resource$APP_INSIGHTS_ID"
```

### Database Management

```bash
# Connect to PostgreSQL
DB_HOST=$(terraform output -raw database_server_fqdn)
psql "host=$DB_HOST port=5432 dbname=comet_browser user=psqladmin sslmode=require"

# View connection string
terraform output database_connection_string
```

### Key Vault Secrets

```bash
# List secrets
az keyvault secret list \
  --vault-name $(terraform output -raw key_vault_name)

# Get secret value
az keyvault secret show \
  --vault-name $(terraform output -raw key_vault_name) \
  --name openai-api-key \
  --query value -o tsv
```

## Cost Optimization

### Monthly Cost Breakdown

| Resource | SKU | Cost/Month |
|----------|-----|------------|
| App Service | B1 (Basic) | $13.14 |
| PostgreSQL | B_Gen5_1 | $5.00 |
| Container Registry | Basic | $5.00 |
| Application Insights | Free tier | $0.00 |
| Key Vault | Standard | $0.00 |
| **Total** | | **~$23.14** |

**With $100 student credit = ~4.3 months free!**

### Reduce Costs

#### Option 1: Use Free Tier (Limited)

```hcl
# In terraform.tfvars
sku_name = "F1"  # Free tier
```

**Limitations:**
- No always-on
- 60 min/day compute
- 1GB storage
- No custom domains

#### Option 2: Stop When Not in Use

```bash
# Stop App Service
az webapp stop \
  --name $(terraform output -raw app_service_name) \
  --resource-group $(terraform output -raw resource_group_name)

# Start when needed
az webapp start \
  --name $(terraform output -raw app_service_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

#### Option 3: Destroy When Not Needed

```bash
# Destroy all resources
terraform destroy

# Deploy again when needed
terraform apply
```

### Set Up Cost Alerts

```bash
# Create budget alert
az consumption budget create \
  --budget-name comet-browser-budget \
  --amount 50 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date 2024-12-31 \
  --resource-group $(terraform output -raw resource_group_name)
```

## Troubleshooting

### Common Issues

#### 1. Terraform Init Fails

**Problem**: Backend configuration error

**Solution**:
```bash
# Remove backend state
rm -rf .terraform
rm .terraform.lock.hcl

# Re-initialize
terraform init
```

#### 2. Docker Push Fails

**Problem**: Authentication error

**Solution**:
```bash
# Re-login to ACR
az acr login --name $(terraform output -raw container_registry_name)

# Or use admin credentials
ACR_USERNAME=$(terraform output -raw container_registry_admin_username)
az acr login --name $(terraform output -raw container_registry_name) \
  --username $ACR_USERNAME
```

#### 3. App Not Starting

**Problem**: Container won't start

**Solution**:
```bash
# Check logs
az webapp log tail \
  --name $(terraform output -raw app_service_name) \
  --resource-group $(terraform output -raw resource_group_name)

# Verify environment variables
az webapp config appsettings list \
  --name $(terraform output -raw app_service_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

#### 4. Database Connection Error

**Problem**: Can't connect to PostgreSQL

**Solution**:
```bash
# Check firewall rules
az postgres server firewall-rule list \
  --resource-group $(terraform output -raw resource_group_name) \
  --server-name $(terraform output -raw database_server_name)

# Add your IP
az postgres server firewall-rule create \
  --resource-group $(terraform output -raw resource_group_name) \
  --server-name $(terraform output -raw database_server_name) \
  --name AllowMyIP \
  --start-ip-address $(curl -s ifconfig.me) \
  --end-ip-address $(curl -s ifconfig.me)
```

#### 5. Out of Memory

**Problem**: App crashes due to memory

**Solution**:
```hcl
# Upgrade to B2 tier (more memory)
# In terraform.tfvars
sku_name = "B2"  # $26/month

# Apply changes
terraform apply
```

### Get Help

1. **Check logs**: Application Insights and App Service logs
2. **Azure Portal**: https://portal.azure.com
3. **Terraform state**: `terraform show`
4. **Azure CLI**: `az webapp show --name <app> --resource-group <rg>`

## Next Steps

### After Deployment

1. ✅ **Test API**: 
   ```bash
   curl $(terraform output -raw app_service_url)/health
   ```

2. ✅ **View Docs**: 
   ```bash
   open $(terraform output -raw app_service_url)/docs
   ```

3. ✅ **Monitor Costs**:
   - Azure Portal → Cost Management
   - Set up budget alerts

4. ✅ **Configure Custom Domain** (optional):
   ```bash
   az webapp config hostname add \
     --webapp-name $(terraform output -raw app_service_name) \
     --resource-group $(terraform output -raw resource_group_name) \
     --hostname yourdomain.com
   ```

5. ✅ **Enable SSL**:
   ```bash
   az webapp config ssl bind \
     --certificate-thumbprint <thumbprint> \
     --ssl-type SNI \
     --name $(terraform output -raw app_service_name) \
     --resource-group $(terraform output -raw resource_group_name)
   ```

### Maintenance

- **Weekly**: Check logs and performance
- **Monthly**: Review costs and optimize
- **Quarterly**: Update dependencies and Terraform
- **Before credit expires**: Plan migration or destruction

## Resources

- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure CLI Reference**: https://docs.microsoft.com/en-us/cli/azure/
- **Azure for Students**: https://azure.microsoft.com/en-us/free/students/
- **GitHub Actions**: https://docs.github.com/en/actions

## Support

- **Documentation**: See `/docs` in repository
- **Issues**: GitHub Issues
- **Azure Support**: Azure Portal → Help + Support

---

**Congratulations! Your Comet Agentic Browser is now running on Azure! 🎉**

Monitor your costs and enjoy your free credits! 🎓
