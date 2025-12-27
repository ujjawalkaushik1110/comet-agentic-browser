# Azure Terraform Deployment Checklist

## ✅ Pre-Deployment Checklist

### 1. Prerequisites
- [ ] Azure CLI installed (`az --version`)
- [ ] Terraform installed (`terraform --version`)
- [ ] Docker installed (`docker --version`)
- [ ] Git installed
- [ ] GitHub Student Pack activated
- [ ] Azure for Students subscription active ($100 credit)

### 2. Get Required Information
- [ ] OpenAI API key (https://platform.openai.com/api-keys)
- [ ] Admin email address
- [ ] Chosen Azure region (e.g., eastus, westus2)
- [ ] GitHub repository access

### 3. Azure Setup
- [ ] Azure CLI logged in (`az login`)
- [ ] Correct subscription selected (`az account show`)
- [ ] Verify $100 credit available

## 🚀 Local Deployment Steps

### Quick Deploy (Automated)
```bash
# 1. Clone repository
git clone https://github.com/ujjawalkaushik1110/comet-agentic-browser.git
cd comet-agentic-browser

# 2. Run deployment script
chmod +x terraform/deploy.sh
./terraform/deploy.sh
```

- [ ] Script completed successfully
- [ ] Application URL received
- [ ] Health check passed

### Manual Deploy (Step-by-Step)

#### Step 1: Configure Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Edit with your values:
- [ ] `openai_api_key` set
- [ ] `admin_email` set
- [ ] `location` set (default: eastus)
- [ ] Review other settings

#### Step 2: Initialize Terraform
```bash
terraform init
```

- [ ] Terraform initialized successfully
- [ ] Providers downloaded
- [ ] Backend configured

#### Step 3: Plan Deployment
```bash
terraform plan
```

Review the plan:
- [ ] Resource count looks correct (~15 resources)
- [ ] No errors in plan
- [ ] Cost estimate reviewed

#### Step 4: Apply Infrastructure
```bash
terraform apply
```

- [ ] Resources created successfully
- [ ] No errors during apply
- [ ] Outputs displayed

#### Step 5: Build and Deploy Docker Image
```bash
# Get ACR details
ACR_NAME=$(terraform output -raw container_registry_name)
ACR_LOGIN=$(terraform output -raw container_registry_login_server)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push
docker build -t $ACR_LOGIN/comet-browser:latest .
docker push $ACR_LOGIN/comet-browser:latest

# Restart app
APP_NAME=$(terraform output -raw app_service_name)
RG=$(terraform output -raw resource_group_name)
az webapp restart --name $APP_NAME --resource-group $RG
```

- [ ] ACR login successful
- [ ] Docker image built
- [ ] Image pushed to ACR
- [ ] App Service restarted

#### Step 6: Verify Deployment
```bash
APP_URL=$(terraform output -raw app_service_url)

# Test health endpoint
curl $APP_URL/health

# Open in browser
open $APP_URL/docs
```

- [ ] Health check returns 200 OK
- [ ] API docs accessible
- [ ] Can browse endpoints

## 🔄 CI/CD Deployment Steps

### Step 1: Create Azure Service Principal
```bash
az ad sp create-for-rbac \
  --name "comet-browser-github" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth
```

- [ ] Service principal created
- [ ] JSON output saved

### Step 2: Configure GitHub Secrets

Go to: `Settings → Secrets and variables → Actions`

Add these secrets:
- [ ] `AZURE_CREDENTIALS` (full JSON from step 1)
- [ ] `AZURE_CLIENT_ID` (from JSON: clientId)
- [ ] `AZURE_CLIENT_SECRET` (from JSON: clientSecret)
- [ ] `AZURE_SUBSCRIPTION_ID` (from `az account show --query id`)
- [ ] `AZURE_TENANT_ID` (from JSON: tenantId)
- [ ] `OPENAI_API_KEY` (your OpenAI key)
- [ ] `ADMIN_EMAIL` (your email)

### Step 3: Enable GitHub Actions
```bash
# Push to main branch
git add .
git commit -m "Setup Azure deployment"
git push origin main
```

- [ ] Workflow triggered
- [ ] All jobs passed
- [ ] Deployment successful

### Step 4: Verify CI/CD
- [ ] Check Actions tab on GitHub
- [ ] All workflow steps green
- [ ] Deployment artifact created
- [ ] Health check passed

## 📊 Post-Deployment Checklist

### 1. Verify All Services

#### App Service
- [ ] App running (`az webapp show`)
- [ ] Health endpoint responding
- [ ] API docs accessible
- [ ] Logs streaming

#### Database
- [ ] PostgreSQL server running
- [ ] Database created
- [ ] Firewall rules configured
- [ ] Can connect from app

#### Container Registry
- [ ] Registry accessible
- [ ] Image pushed successfully
- [ ] App Service pulling image

#### Key Vault
- [ ] Secrets stored
- [ ] App Service has access
- [ ] No secret leaks

#### Application Insights
- [ ] Telemetry flowing
- [ ] No errors logged
- [ ] Performance metrics visible

### 2. Security Checks
- [ ] SSL/TLS enabled
- [ ] Key Vault access restricted
- [ ] Database firewall configured
- [ ] Secrets not in code
- [ ] Admin passwords strong
- [ ] Service principal least privilege

### 3. Test API Endpoints
```bash
APP_URL=$(terraform output -raw app_service_url)

# Health check
curl $APP_URL/health

# List models (if using Ollama endpoint)
curl $APP_URL/models

# Test browse endpoint
curl -X POST $APP_URL/browse/sync \
  -H "Content-Type: application/json" \
  -d '{"goal": "Navigate to example.com", "llm_api_type": "openai"}'
```

- [ ] `/health` returns healthy status
- [ ] `/docs` shows OpenAPI documentation
- [ ] `/browse/sync` accepts requests
- [ ] `/browse` creates async tasks
- [ ] `/tasks` lists tasks

### 4. Monitoring Setup
- [ ] Application Insights configured
- [ ] Log streaming working
- [ ] Metrics visible in portal
- [ ] Alerts configured (optional)

### 5. Cost Management
- [ ] Budget created
- [ ] Cost alerts set
- [ ] Monthly cost estimate verified (~$23)
- [ ] Auto-shutdown scheduled (optional)

## 💰 Cost Tracking

### View Current Costs
```bash
# Get resource group
RG=$(terraform output -raw resource_group_name)

# View cost analysis
az consumption usage list \
  --start-date $(date -d "30 days ago" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?resourceGroup=='$RG']"
```

### Set Cost Alert
```bash
az consumption budget create \
  --budget-name comet-browser-alert \
  --amount 50 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date 2024-12-31 \
  --resource-group $RG
```

- [ ] Cost tracking enabled
- [ ] Alert threshold set
- [ ] Email notifications configured

## 🔧 Maintenance Checklist

### Daily
- [ ] Check application health
- [ ] Review error logs
- [ ] Monitor performance

### Weekly
- [ ] Review cost analysis
- [ ] Check resource utilization
- [ ] Update dependencies (if needed)

### Monthly
- [ ] Review Application Insights
- [ ] Optimize resources
- [ ] Check for security updates
- [ ] Backup important data

## 🚨 Troubleshooting

### If Deployment Fails

1. **Check Terraform errors**
```bash
terraform plan  # Review errors
terraform validate  # Check syntax
```

2. **Check Azure CLI**
```bash
az account show  # Verify login
az group list  # Check resource groups
```

3. **Check Docker**
```bash
docker images  # Verify build
docker logs <container>  # Check logs
```

4. **View detailed logs**
```bash
az webapp log tail --name $APP_NAME --resource-group $RG
```

### Common Issues
- [ ] Terraform state locked → `terraform force-unlock`
- [ ] Docker push fails → Re-login to ACR
- [ ] App won't start → Check environment variables
- [ ] Database connection error → Check firewall rules
- [ ] Out of memory → Upgrade to B2 tier

## 📚 Documentation

After deployment, document:
- [ ] Application URL
- [ ] Resource group name
- [ ] Database connection string (securely)
- [ ] Container registry details
- [ ] GitHub Actions setup
- [ ] Any custom configurations

## ✨ Success Criteria

Your deployment is successful when:
- ✅ All resources created in Azure
- ✅ Application accessible via HTTPS
- ✅ Health endpoint returns 200 OK
- ✅ API documentation visible
- ✅ Can execute browse requests
- ✅ Logs streaming properly
- ✅ Monitoring active
- ✅ Costs within budget
- ✅ CI/CD pipeline working
- ✅ No security warnings

## 🎓 Student Tips

1. **Monitor your credit**: Check Azure Portal daily
2. **Stop when not using**: Use `az webapp stop` to save costs
3. **Free tier when possible**: Switch to F1 for testing
4. **Delete unused resources**: Run `terraform destroy` when done
5. **Set spending limits**: Configure budget alerts
6. **Use GitHub Actions wisely**: Free minutes are limited

## 📞 Getting Help

If you encounter issues:
1. Check terraform/AZURE_TERRAFORM_GUIDE.md
2. Review Application Insights logs
3. Check GitHub Actions logs
4. Azure Portal → Support + troubleshooting
5. GitHub Issues in repository

---

**Estimated Time**: 
- Automated deployment: 15-20 minutes
- Manual deployment: 30-45 minutes
- CI/CD setup: 20-30 minutes

**Monthly Cost**: ~$23 with B1 tier
**With $100 credit**: ~4 months free! 🎉
