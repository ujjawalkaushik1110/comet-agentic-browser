# Deployment Guide - Comet Agentic Browser

Complete deployment guide for Azure, AWS, and Heroku using GitHub Student Pack benefits.

## 🎓 GitHub Student Pack Benefits

Get free credits for cloud platforms:
- **Azure**: $100 credit via GitHub Student Developer Pack
- **AWS**: AWS Educate credits
- **Heroku**: Free tier + student credits

Apply at: https://education.github.com/pack

## 📋 Prerequisites

### Required
- Docker installed
- Git installed
- Domain name (optional)
- SSL certificate (optional, for production)

### Cloud-Specific
- **Azure**: Azure CLI (`az`)
- **AWS**: AWS CLI (`aws`)
- **Heroku**: Heroku CLI (`heroku`)

## 🚀 Quick Start (Local Docker)

```bash
# Clone the repository
git clone https://github.com/ujjawalkaushik1110/comet-agentic-browser.git
cd comet-agentic-browser

# Copy environment file
cp .env.example .env

# Edit .env with your settings
nano .env

# Start with Docker Compose
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f api

# Access API
curl http://localhost:8000/health
```

API will be available at:
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Ollama: http://localhost:11434

## ☁️ Cloud Deployments

### 1. Azure App Service (Recommended for Students)

#### Setup Azure CLI
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# Set subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

#### Deploy to Azure
```bash
# Make deployment script executable
chmod +x azure/deploy.sh

# Deploy
./azure/deploy.sh

# Or deploy manually
RESOURCE_GROUP="comet-browser-rg"
LOCATION="eastus"
APP_NAME="comet-browser"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy ARM template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file azure/app-service.json \
  --parameters appName=$APP_NAME
```

#### Configure Environment Variables
```bash
# Set environment variables in Azure
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings \
    PORT=8000 \
    BROWSER_HEADLESS=true \
    LLM_API_TYPE=openai \
    OPENAI_API_KEY="your-key-here"
```

#### View Logs
```bash
az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME
```

#### Cost Estimate
- **F1 (Free)**: $0/month - Good for testing
- **B1 (Basic)**: ~$13/month - Recommended for students
- **S1 (Standard)**: ~$70/month - Production

### 2. AWS ECS (Fargate)

#### Setup AWS CLI
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure
aws configure
```

#### Deploy to AWS
```bash
# Make deployment script executable
chmod +x aws/deploy.sh

# Edit task definition with your VPC/subnet/security group
nano aws/task-definition.json

# Deploy
./aws/deploy.sh
```

#### Manual Deployment Steps
```bash
# 1. Create ECR repository
aws ecr create-repository --repository-name comet-browser

# 2. Build and push image
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/comet-browser"

aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_URI

docker build -t comet-browser:latest .
docker tag comet-browser:latest $ECR_URI:latest
docker push $ECR_URI:latest

# 3. Create ECS cluster
aws ecs create-cluster --cluster-name comet-browser-cluster

# 4. Register task definition
aws ecs register-task-definition --cli-input-json file://aws/task-definition.json

# 5. Create service
aws ecs create-service \
  --cluster comet-browser-cluster \
  --service-name comet-browser-service \
  --task-definition comet-browser \
  --desired-count 1 \
  --launch-type FARGATE
```

#### Cost Estimate
- **Fargate**: ~$15-30/month (1 vCPU, 2GB RAM)
- **ECR**: Free tier: 500MB, then $0.10/GB/month
- **Data Transfer**: First 100GB free

### 3. Heroku (Easiest)

#### Setup Heroku CLI
```bash
# Install Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# Login
heroku login
```

#### Deploy to Heroku
```bash
# Create app
heroku create comet-browser-app

# Set buildpack for container
heroku stack:set container

# Add PostgreSQL (optional, for task storage)
heroku addons:create heroku-postgresql:mini

# Set environment variables
heroku config:set \
  LLM_API_TYPE=openai \
  OPENAI_API_KEY=your-key-here \
  BROWSER_HEADLESS=true

# Deploy
git push heroku main

# Open app
heroku open

# View logs
heroku logs --tail
```

#### Using Heroku Container Registry
```bash
# Login to container registry
heroku container:login

# Build and push
heroku container:push web

# Release
heroku container:release web
```

#### Cost Estimate
- **Free Tier**: $0/month (limited hours)
- **Hobby**: $7/month
- **Standard-1X**: $25/month (recommended)
- **Standard-2X**: $50/month

### 4. Docker Hub (For Any Platform)

```bash
# Login to Docker Hub
docker login

# Build and tag
docker build -t yourusername/comet-browser:latest .

# Push to Docker Hub
docker push yourusername/comet-browser:latest

# Deploy anywhere
docker run -p 8000:8000 \
  -e OPENAI_API_KEY=your-key \
  yourusername/comet-browser:latest
```

## 🔧 GitHub Actions CI/CD

### Setup GitHub Secrets

Go to: Settings → Secrets and variables → Actions

Add these secrets:

#### For Azure
- `AZURE_CREDENTIALS`: Service principal credentials
  ```bash
  az ad sp create-for-rbac \
    --name "comet-browser-sp" \
    --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
    --sdk-auth
  ```

#### For Heroku
- `HEROKU_API_KEY`: From heroku auth:token
- `HEROKU_APP_NAME`: Your app name
- `HEROKU_EMAIL`: Your email

#### For AWS
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### Enable Workflow

The workflow file is at `.github/workflows/deploy.yml`

It will automatically:
1. Run tests on push/PR
2. Build Docker image
3. Push to GitHub Container Registry
4. Deploy to configured cloud providers

## 🔐 Security Best Practices

### 1. Environment Variables
Never commit sensitive data. Use:
- Azure: Key Vault
- AWS: Secrets Manager
- Heroku: Config Vars

### 2. API Authentication
Add API key authentication:

```python
# In api/app.py
from fastapi import Security, HTTPException
from fastapi.security import APIKeyHeader

API_KEY = os.getenv("API_KEY")
api_key_header = APIKeyHeader(name="X-API-Key")

async def verify_api_key(api_key: str = Security(api_key_header)):
    if api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")
    return api_key
```

### 3. CORS Configuration
Update allowed origins in `api/app.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 4. Rate Limiting
Already configured in `nginx.conf`:
- 10 requests per second
- Burst of 20 requests

## 📊 Monitoring

### Health Checks
```bash
# Check API health
curl https://your-app.azurewebsites.net/health

# Check Ollama (if self-hosted)
curl https://your-app.azurewebsites.net/models
```

### Logs

**Azure:**
```bash
az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME
```

**AWS:**
```bash
aws logs tail /ecs/comet-browser --follow
```

**Heroku:**
```bash
heroku logs --tail
```

**Docker:**
```bash
docker-compose logs -f api
```

## 🧪 Testing the Deployment

### Test API Endpoints

```bash
# Health check
curl https://your-app.com/health

# List tasks
curl https://your-app.com/tasks

# Submit task (async)
curl -X POST https://your-app.com/browse \
  -H "Content-Type: application/json" \
  -d '{
    "goal": "Go to example.com and describe it",
    "model": "gpt-4",
    "api_type": "openai"
  }'

# Get task status
curl https://your-app.com/tasks/{task-id}

# Sync request (blocking)
curl -X POST https://your-app.com/browse/sync \
  -H "Content-Type: application/json" \
  -d '{
    "goal": "Go to example.com",
    "model": "gpt-4"
  }'
```

### Using Python Client

```python
import requests

BASE_URL = "https://your-app.com"

# Submit task
response = requests.post(f"{BASE_URL}/browse", json={
    "goal": "Go to github.com and describe it",
    "model": "gpt-4",
    "api_type": "openai"
})

task_id = response.json()["task_id"]
print(f"Task ID: {task_id}")

# Check status
import time
while True:
    status = requests.get(f"{BASE_URL}/tasks/{task_id}").json()
    print(f"Status: {status['status']}")
    
    if status['status'] in ['completed', 'failed']:
        print(f"Result: {status.get('result')}")
        break
    
    time.sleep(2)
```

## 🎯 Student-Optimized Setup

### Recommended for GitHub Students

**Azure Free Tier:**
```bash
# Use F1 (Free) tier for testing
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan free-plan \
  --name $APP_NAME \
  --deployment-container-image-name ghcr.io/yourusername/comet-browser:latest \
  --sku F1
```

**Cost Optimization:**
- Use OpenAI API instead of self-hosting Ollama
- Use F1/Free tiers for development
- Scale up only for production
- Use serverless (Azure Functions/AWS Lambda) for sporadic use

## 📚 Additional Resources

- [Azure for Students](https://azure.microsoft.com/en-us/free/students/)
- [AWS Educate](https://aws.amazon.com/education/awseducate/)
- [Heroku Dev Center](https://devcenter.heroku.com/)
- [Docker Documentation](https://docs.docker.com/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)

## 🆘 Troubleshooting

### Browser not starting in Docker
- Ensure proper dependencies installed
- Check `BROWSER_HEADLESS=true`
- Verify sufficient memory allocation

### Ollama connection issues
- For cloud deployment, use OpenAI instead
- Or deploy Ollama on separate VM
- Check `LLM_BASE_URL` environment variable

### Port binding issues
- Azure/Heroku use `$PORT` environment variable
- Ensure app listens on `0.0.0.0`
- Check firewall rules

### Memory issues
- Increase container memory limits
- Use smaller LLM models
- Implement request queuing

## 🎉 Success!

Your Comet Agentic Browser is now deployed to the cloud!

Access your API at:
- Azure: `https://your-app.azurewebsites.net`
- AWS: `https://your-alb-url.region.elb.amazonaws.com`
- Heroku: `https://your-app.herokuapp.com`
- Docker: `http://your-server-ip:8000`

API Documentation: `https://your-url/docs`
