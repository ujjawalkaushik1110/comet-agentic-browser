# Production Deployment Guide

## Quick Start

This guide covers deploying the Comet Agentic Browser to Azure using Terraform in a production-ready configuration.

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and configured
- Terraform 1.6+ installed
- Docker installed (for local testing)
- GitHub account (for CI/CD)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │  Development   │  │    Staging     │  │  Production   │ │
│  ├────────────────┤  ├────────────────┤  ├───────────────┤ │
│  │ App Service F1 │  │ App Service B1 │  │App Service S1 │ │
│  │ PostgreSQL B1  │  │ PostgreSQL GP2 │  │PostgreSQL GP2 │ │
│  │ No Redis       │  │ No Redis       │  │Redis Standard │ │
│  │ No VNet        │  │ No VNet        │  │VNet + Subnets │ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │           Shared Resources (Production)                  ││
│  │  • Container Registry (with geo-replication)             ││
│  │  • Key Vault (with purge protection)                     ││
│  │  • Application Insights                                  ││
│  │  • Log Analytics Workspace                               ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Step-by-Step Deployment

### 1. Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd comet-agentic-browser

# Set up environment variables
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
export ENVIRONMENT="production"  # or staging, development
```

### 2. Azure Login

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription $AZURE_SUBSCRIPTION_ID

# Verify
az account show
```

### 3. Configure Terraform Backend (Optional but Recommended)

```bash
# Create storage account for Terraform state
LOCATION="eastus2"
BACKEND_RG="rg-terraform-state"
BACKEND_SA="stterraformstate$(openssl rand -hex 4)"

az group create --name $BACKEND_RG --location $LOCATION

az storage account create \
  --name $BACKEND_SA \
  --resource-group $BACKEND_RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name tfstate \
  --account-name $BACKEND_SA
```

Update [terraform/environments/backend.tf](terraform/environments/backend.tf):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstateXXXX"  # Replace with actual name
    container_name       = "tfstate"
    key                  = "production.tfstate"
  }
}
```

### 4. Configure Environment Variables

Edit the appropriate `.tfvars` file:

```bash
# For production deployment
vim terraform/environments/production.tfvars
```

**Required Variables:**
- `admin_email` - Email for security alerts
- `allowed_origins` - CORS origins for your frontend
- `allowed_ips` - IP addresses allowed to access Key Vault

### 5. Deploy Infrastructure

```bash
cd terraform/environments

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="production.tfvars"

# Apply (creates all resources)
terraform apply -var-file="production.tfvars"
```

This will create:
- Resource Group
- App Service Plan
- App Service (Linux)
- PostgreSQL Database
- Redis Cache (production only)
- Container Registry
- Key Vault
- Virtual Network (production only)
- Application Insights
- Log Analytics Workspace
- Autoscaling Rules
- Monitoring Alerts

**Deployment Time:** ~15-20 minutes

### 6. Build and Push Docker Image

```bash
# Get ACR credentials
ACR_NAME=$(terraform output -raw acr_name)
az acr login --name $ACR_NAME

# Build image
docker build -t $ACR_NAME.azurecr.io/comet-browser:latest .

# Push image
docker push $ACR_NAME.azurecr.io/comet-browser:latest
```

### 7. Configure App Service

```bash
APP_NAME=$(terraform output -raw app_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Configure container
az webapp config container set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/comet-browser:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Restart app
az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP
```

### 8. Verify Deployment

```bash
# Get app URL
APP_URL=$(terraform output -raw app_url)

# Test health endpoints
curl $APP_URL/health
curl $APP_URL/health/db
curl $APP_URL/health/redis
curl $APP_URL/health/ready

# Test browse endpoint
curl -X POST $APP_URL/browse/sync \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

### 9. Set Up CI/CD (Optional)

#### GitHub Actions Setup

1. **Create Service Principal**

```bash
az ad sp create-for-rbac \
  --name "sp-comet-browser-$ENVIRONMENT" \
  --role contributor \
  --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth
```

2. **Add GitHub Secrets**

Go to GitHub repository → Settings → Secrets and add:

- `AZURE_CREDENTIALS_PROD` - Output from above command
- `ACR_LOGIN_SERVER` - `$ACR_NAME.azurecr.io`
- `ACR_USERNAME` - From `az acr credential show`
- `ACR_PASSWORD` - From `az acr credential show`
- `PROD_RESOURCE_GROUP` - Resource group name

3. **Enable Workflow**

The workflow at `.github/workflows/azure-deploy.yml` will automatically:
- Run tests on every push
- Build Docker images
- Deploy to dev (on develop branch)
- Deploy to staging (on main branch)
- Deploy to production (on main branch, after staging)

### 10. Configure Monitoring

```bash
# Get Application Insights instrumentation key
AI_KEY=$(terraform output -raw app_insights_key)

# Configure alerts (already done via Terraform)
# Verify alerts are created
az monitor metrics alert list \
  --resource-group $RESOURCE_GROUP \
  --output table
```

### 11. Set Up Backups

```bash
# Configure automated backups
chmod +x scripts/backup.sh

# Test backup
export ENVIRONMENT=production
export RESOURCE_GROUP=$RESOURCE_GROUP
./scripts/backup.sh

# Schedule via cron (every 6 hours)
crontab -e
# Add: 0 */6 * * * /path/to/scripts/backup.sh
```

### 12. Final Security Hardening

```bash
# Disable public access to Key Vault (if needed)
KV_NAME=$(terraform output -raw key_vault_name)
az keyvault update \
  --name $KV_NAME \
  --default-action Deny

# Enable soft-delete and purge protection (if not already)
az keyvault update \
  --name $KV_NAME \
  --enable-soft-delete true \
  --enable-purge-protection true

# Review database firewall rules
DB_SERVER=$(terraform output -raw db_server_name)
az postgres server firewall-rule list \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER \
  --output table
```

## Environment-Specific Configurations

### Development

```bash
terraform apply -var-file="dev.tfvars"
```

- **SKU:** F1 (Free tier)
- **Auto-shutdown:** After business hours
- **No Redis cache**
- **No VNet isolation**
- **Cost:** ~$0/month (free tier)

### Staging

```bash
terraform apply -var-file="staging.tfvars"
```

- **SKU:** B1 (Basic tier)
- **Autoscaling:** 1-3 instances
- **No Redis cache**
- **No VNet isolation**
- **Cost:** ~$55/month

### Production

```bash
terraform apply -var-file="production.tfvars"
```

- **SKU:** S1 (Standard tier)
- **Autoscaling:** 2-10 instances
- **Redis cache:** Standard C1
- **VNet isolation:** Enabled
- **Geo-redundancy:** Enabled
- **Cost:** ~$340/month

## Post-Deployment Checklist

- [ ] All health endpoints return 200 OK
- [ ] Database connectivity verified
- [ ] Redis connectivity verified (production)
- [ ] Application Insights receiving data
- [ ] Monitoring alerts configured and tested
- [ ] Backups running successfully
- [ ] CI/CD pipeline configured
- [ ] DNS/Custom domain configured (if applicable)
- [ ] SSL certificate configured
- [ ] Rate limiting tested
- [ ] Autoscaling rules validated
- [ ] Disaster recovery plan documented
- [ ] Team access configured
- [ ] Documentation updated

## Scaling Guide

### Vertical Scaling (Upgrade SKU)

```bash
# Scale up App Service
az appservice plan update \
  --resource-group $RESOURCE_GROUP \
  --name plan-comet-browser \
  --sku P1V2  # Premium v2

# Scale up Database
az postgres server update \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER \
  --sku-name GP_Gen5_4  # 4 vCores
```

### Horizontal Scaling (Add Instances)

```bash
# Manual scale
az appservice plan update \
  --resource-group $RESOURCE_GROUP \
  --name plan-comet-browser \
  --number-of-workers 5

# Autoscaling is configured via Terraform
# Modify autoscaling rules in production.tfvars
```

## Troubleshooting

### Deployment Fails

```bash
# Check Terraform state
terraform show

# View detailed error
terraform apply -var-file="production.tfvars" -debug

# Destroy and recreate specific resource
terraform taint azurerm_linux_web_app.app
terraform apply -var-file="production.tfvars"
```

### App Not Starting

```bash
# Check app logs
az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP

# Check container logs
az webapp log download --name $APP_NAME --resource-group $RESOURCE_GROUP

# Verify container image
az acr repository show-tags --name $ACR_NAME --repository comet-browser
```

### Database Connection Issues

```bash
# Test database connection
DB_HOST=$(terraform output -raw db_host)
DB_USER=$(terraform output -raw db_user)
DB_PASS=$(az keyvault secret show --vault-name $KV_NAME --name db-password --query value -o tsv)

psql "host=$DB_HOST port=5432 dbname=comet_browser user=$DB_USER password=$DB_PASS sslmode=require"

# Check firewall rules
az postgres server firewall-rule list \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER
```

## Cost Management

### Monitor Costs

```bash
# View current month costs
az consumption usage list \
  --start-date $(date -u -d '1 month ago' '+%Y-%m-%d') \
  --end-date $(date -u '+%Y-%m-%d') \
  --query "[?contains(instanceName, 'comet-browser')]" \
  --output table

# Set budget alert
az consumption budget create \
  --budget-name monthly-budget \
  --amount 500 \
  --time-grain Monthly \
  --resource-group $RESOURCE_GROUP
```

### Cost Optimization

1. **Use Reserved Instances** - Save 30-40%
2. **Auto-shutdown dev environment** - Save ~$70/month
3. **Right-size database** - Start small, scale as needed
4. **Use free tier for development** - $0/month

## Maintenance

### Regular Updates

```bash
# Update container image
docker build -t $ACR_NAME.azurecr.io/comet-browser:$(git rev-parse --short HEAD) .
docker push $ACR_NAME.azurecr.io/comet-browser:$(git rev-parse --short HEAD)

# Update app
az webapp config container set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/comet-browser:$(git rev-parse --short HEAD)
```

### Backup & Recovery

See [DISASTER_RECOVERY.md](../docs/DISASTER_RECOVERY.md) for detailed procedures.

```bash
# Manual backup
./scripts/backup.sh

# Manual restore
./scripts/restore.sh
```

## Support

- **Documentation:** `/docs`
- **Runbooks:** `/docs/runbooks`
- **Disaster Recovery:** `/docs/DISASTER_RECOVERY.md`
- **Operations Guide:** `/docs/PRODUCTION_OPERATIONS.md`
- **GitHub Issues:** <repository-issues-url>
- **Team Contact:** devops@company.com

## Next Steps

1. Configure custom domain and SSL
2. Set up CDN for static assets
3. Implement additional monitoring dashboards
4. Configure log aggregation
5. Set up status page
6. Conduct load testing
7. Perform security audit
8. Schedule DR drill

---

**Last Updated:** 2024-01-01  
**Version:** 1.0  
**Maintained by:** DevOps Team
