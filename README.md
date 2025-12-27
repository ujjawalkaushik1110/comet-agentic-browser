# Comet Agentic Browser 🚀

An autonomous web browsing agent powered by LLMs that can navigate, read, and interact with websites through natural language goals.

## ⚡ Production-Ready Azure Deployment

**Enterprise-grade deployment with complete DevOps automation:**

```bash
# Deploy multi-environment infrastructure in 3 commands
cd terraform/environments
terraform init
terraform apply -var-file="production.tfvars"
```

**✅ Multi-environment** | **✅ Auto-scaling** | **✅ Monitoring** | **✅ CI/CD** | **✅ Disaster Recovery**

📚 **[Complete Deployment Guide](docs/DEPLOYMENT.md)** | **Cost: ~$340/mo production, $0/mo dev**

## Features

### 🤖 Core Capabilities
✅ **Autonomous Navigation** - AI-driven web browsing with goal-oriented behavior  
✅ **Dual LLM Support** - Ollama (local) or OpenAI (cloud)  
✅ **RESTful API** - FastAPI with rate limiting and caching  
✅ **Async Architecture** - Modern Python async/await  

### 🚀 Production Infrastructure
✅ **Multi-Environment** - Isolated dev/staging/production with Terraform  
✅ **Auto-Scaling** - CPU/Memory-based scaling (2-10 instances)  
✅ **Redis Caching** - 5-minute TTL, 80%+ hit ratio target  
✅ **Rate Limiting** - Configurable per-endpoint (60 req/min default)  
✅ **Geo-Redundancy** - Container registry replication  

### 📊 Monitoring & Operations
✅ **Application Insights** - Real-time metrics and tracing  
✅ **Prometheus Metrics** - Request counts, duration, cache stats  
✅ **Automated Alerts** - App down, CPU, memory, error rate  
✅ **Health Checks** - App, database, Redis, readiness probes  
✅ **Log Analytics** - Centralized logging with retention policies  

### 🛡️ Security & Compliance
✅ **Key Vault Integration** - Secure secret management  
✅ **Network Isolation** - VNet with app/db subnets (production)  
✅ **TLS 1.2+** - Enforced encryption  
✅ **Database Threat Detection** - Real-time security monitoring  
✅ **Managed Identity** - Passwordless Azure authentication  
✅ **Soft-Delete Protection** - 90-day recovery window  

### 🔄 DevOps Automation
✅ **CI/CD Pipeline** - GitHub Actions multi-environment deployment  
✅ **Automated Testing** - pytest with coverage reports  
✅ **Security Scanning** - Trivy + Bandit in CI/CD  
✅ **Automated Backups** - Every 6 hours, 30-day retention  
✅ **Disaster Recovery** - RTO: 4h, RPO: 1h (production)  
✅ **One-Click Restore** - Automated recovery scripts  

## Tech Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| **LLM** | Ollama + Llama 2/Mistral | Free, local, no API costs |
| **Browser** | Chromium + Playwright | Open-source, lightweight |
| **Agent Framework** | LangChain | Open-source orchestration |
| **Runtime** | Python 3.10+ | Fast, well-documented |
| **API** | FastAPI | Async, modern framework |
| **Deployment** | Docker + GitHub Codespaces | Containerized, portable |

## Quick Start

### Prerequisites
- Azure subscription ([Get $100 free with GitHub Student Pack](https://education.github.com/pack))
- Azure CLI installed
- Terraform 1.6+
- Docker (for local testing)

### 1. Deploy Infrastructure

```bash
# Clone repository
git clone <repository-url>
cd comet-agentic-browser

# Login to Azure
az login
az account set --subscription <subscription-id>

# Deploy to production
cd terraform/environments
terraform init
terraform apply -var-file="production.tfvars"
```

### 2. Build and Deploy Application

```bash
# Get container registry name
ACR_NAME=$(terraform output -raw acr_name)

# Build and push image
az acr build --registry $ACR_NAME --image comet-browser:latest .

# Verify deployment
APP_URL=$(terraform output -raw app_url)
curl $APP_URL/health
```

### 3. Set Up CI/CD (Optional)

```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name "sp-comet-browser-prod" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# Add to GitHub Secrets:
# AZURE_CREDENTIALS_PROD, ACR_LOGIN_SERVER, ACR_USERNAME, ACR_PASSWORD
```

Push to `main` branch to trigger automated deployment to staging and production.

📚 **Detailed instructions:** [DEPLOYMENT.md](docs/DEPLOYMENT.md)

# 2. Configure (add your OpenAI key)
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# 3. Deploy!
./deploy.sh
```

**What you get:**
- ✅ Live HTTPS endpoint
- ✅ PostgreSQL database
- ✅ Container registry
- ✅ Application monitoring
- ✅ Automated CI/CD
- ✅ **~$23/month = 4+ months FREE with student credit**

📚 [Quick Start](QUICK_START_AZURE.md) | [Complete Guide](terraform/AZURE_TERRAFORM_GUIDE.md) | [Checklist](terraform/DEPLOYMENT_CHECKLIST.md)

### 💻 Option 2: Local Development

```bash
# Clone repository
git clone https://github.com/ujjawalkaushik1110/comet-agentic-browser.git
cd comet-agentic-browser

# Install dependencies
pip install -r requirements.txt
playwright install chromium

# Start Ollama (for local LLM)
ollama serve

# In another terminal, pull model
ollama pull mistral
```

### 🐳 Option 3: Docker Compose (All-in-One)

```bash
# Run complete stack (API, Ollama, Redis, Nginx)
docker-compose up -d

# Access application
open http://localhost
# API docs: http://localhost/docs
```

## 🚀 Usage

### Python Script
```python
from agent.core import browse

# Simple one-liner
result = browse("Navigate to example.com and read the page content")
print(result)
```

### REST API
```bash
# Start API server (if deployed to Azure, already running)
python -m api.app

# Or locally:
uvicorn api.app:app --reload

# Make request
curl -X POST http://localhost:8000/browse/sync \
  -H "Content-Type: application/json" \
  -d '{"goal": "Go to example.com", "llm_api_type": "openai"}'
```

### API Endpoints

- `GET /health` - Health check
- `POST /browse` - Async browsing task
- `POST /browse/sync` - Synchronous browsing
- `GET /tasks/{id}` - Get task status
- `GET /tasks` - List all tasks
- `GET /docs` - Interactive API documentation

## Project Structure

```
comet-agentic-browser/
├── agent/
│   ├── core.py           # Agent loop implementation
│   ├── tools.py          # Tool definitions for browser
│   └── prompts.py        # System prompts & instructions
├── browser/
│   ├── automation.py     # Chromium/Playwright wrapper
│   ├── reader.py         # Page content extraction
│   └── screenshots.py    # Screenshot handling
├── llm/
│   ├── ollama_client.py  # Ollama integration
│   └── prompting.py      # LLM communication
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── main.py              # Entry point
└── README.md
```

## Open Source LLM Options

### Mistral 7B (Recommended for Codespaces)
- **Size**: 7B parameters
- **Speed**: ⚡⚡⚡ Very fast
- **Quality**: ⭐⭐⭐⭐ Excellent
- **Memory**: ~16GB
- **Best for**: Quick inference, resource-limited environments

## 📦 What's Included

### Infrastructure (Terraform)
- **App Service** (B1): Scalable web app hosting  
- **PostgreSQL** (Basic): Managed database for task storage  
- **Container Registry**: Docker image hosting  
- **Key Vault**: Secure secrets management  
- **Application Insights**: Monitoring and analytics  
- **Log Analytics**: Centralized logging

### Application Stack
- **FastAPI**: Modern REST API with OpenAPI docs
- **Playwright**: Headless Chromium browser automation
- **Async/Await**: Full async Python architecture
- **Docker**: Multi-stage production builds

### DevOps Pipeline
- **Terraform**: Infrastructure as Code
- **GitHub Actions**: Automated CI/CD
- **Health Checks**: Continuous monitoring
- **Auto-scaling**: Ready for production traffic

## 💰 Cost Breakdown

| Resource | Tier | Monthly Cost |
|----------|------|--------------|
| App Service | B1 | $13.14 |
| PostgreSQL | Basic | $5.00 |
| Container Registry | Basic | $5.00 |
| Application Insights | Free tier | $0.00 |
| **Total** | | **~$23/mo** |

**GitHub Student Pack**: $100 credit = **4+ months FREE** 🎓

### 💡 Cost Saving Tips

1. **Free Tier**: Use F1 SKU for testing (limited resources)
2. **Stop when idle**: `az webapp stop --name <app-name>`  
3. **Destroy when done**: `cd terraform && terraform destroy`
4. **Set budget alerts**: Monitor your $100 credit usage

## 🎓 GitHub Student Pack Benefits

**Get $100 Azure credit + more:**

1. **GitHub Codespaces**: 60 free hours/month for development
2. **GitHub Copilot**: Free AI pair programming
3. **Azure for Students**: $100 credit (no credit card!)
4. **MongoDB Atlas**: $50 in credits
5. **DigitalOcean**: $200 credit

**→ [Apply for Student Pack](https://education.github.com/pack)**  
**→ [Activate Azure](https://azure.microsoft.com/en-us/free/students/)**

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Quick Start Azure](QUICK_START_AZURE.md) | Deploy in 3 commands |
| [Azure Terraform Guide](terraform/AZURE_TERRAFORM_GUIDE.md) | Complete deployment guide |
| [Deployment Checklist](terraform/DEPLOYMENT_CHECKLIST.md) | Step-by-step checklist |
| [API Documentation](API_README.md) | REST API reference |
| [Architecture](ARCHITECTURE.md) | System design details |

## 🔒 Security Best Practices

- ✅ Secrets stored in Azure Key Vault (never in code)
- ✅ SSL/TLS encryption for all traffic
- ✅ Managed identity authentication
- ✅ Database firewall rules configured
- ✅ No credentials committed to Git
- ✅ Environment variables for configuration

## 📊 Monitoring Your Deployment

### View Logs
```bash
# Stream application logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# Download logs
az webapp log download --name <app-name> --resource-group <rg-name>
```

### Application Insights
```bash
# View in Azure Portal
# Navigate to: Application Insights → Failures, Performance, Logs
```

### Cost Tracking
```bash
# View current costs
az consumption usage list --start-date <date> --end-date <date>

# Set budget alert (recommended!)
az consumption budget create --budget-name student-alert --amount 50
```

## 🚀 CI/CD Pipeline

**Automatic deployment on every push to main:**

1. Configure GitHub secrets ([full guide](terraform/AZURE_TERRAFORM_GUIDE.md#cicd-deployment))
2. Push code to main branch
3. GitHub Actions automatically:
   - Validates Terraform
   - Builds Docker image
   - Deploys to Azure
   - Runs health checks
   - Notifies on completion

## 🛠️ Development

### Local API Testing
```python
# Test with Python client
python test_api.py

# Or use curl
curl http://localhost:8000/health
```

### Run Tests
```bash
pytest tests/
```

### Format Code
```bash
black agent/ api/ browser/
ruff check --fix .
```

## 🎯 Project Structure

```
comet-agentic-browser/
├── agent/              # Core agentic browser logic
│   ├── core.py        # Main AgenticBrowser class
│   └── __init__.py
├── api/               # FastAPI REST API
│   └── app.py        # API endpoints
├── browser/           # Browser automation
│   └── automation.py # Playwright wrapper
├── terraform/         # Infrastructure as Code
│   ├── main.tf       # Azure resources
│   ├── variables.tf  # Configuration
│   ├── outputs.tf    # Resource outputs
│   └── deploy.sh     # Deployment script
├── .github/
│   └── workflows/
│       └── azure-terraform.yml  # CI/CD pipeline
├── Dockerfile         # Container definition
├── docker-compose.yml # Local development stack
├── requirements.txt   # Python dependencies
└── README.md         # This file
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

MIT License - See [LICENSE](LICENSE) for details

## 🆘 Support

- **Documentation**: Check the [guides](terraform/)
- **Issues**: [GitHub Issues](https://github.com/ujjawalkaushik1110/comet-agentic-browser/issues)
- **Azure Support**: [Azure Portal](https://portal.azure.com) → Support

## ⭐ Acknowledgments

Built with:
- [FastAPI](https://fastapi.tiangolo.com/)
- [Playwright](https://playwright.dev/)
- [Terraform](https://www.terraform.io/)
- [Azure](https://azure.microsoft.com/)
- [GitHub Education](https://education.github.com/)

---

**Ready to deploy?** → [Start here](QUICK_START_AZURE.md) 🚀
   python main.py
   ```

## API Endpoints

```bash
# Start the API server
python -m uvicorn api:app --reload
```

### POST /task
Run an agentic task

```json
{
  "instruction": "Navigate to GitHub and search for Python repositories",
  "max_iterations": 10
}
```

### GET /task/{task_id}
Get task status and results

### POST /browser/screenshot
Capture current page screenshot

## Architecture

```
┌─────────────────────────────────┐
│   Natural Language Task         │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Ollama LLM (Local)             │
│  - Mistral/Llama/Zephyr         │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Agentic Loop                   │
│  1. Read page content           │
│  2. LLM decides next action     │
│  3. Execute browser tools       │
│  4. Repeat until task complete  │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Browser Automation Tools       │
│  - navigate() - goto URL        │
│  - read_page() - extract text   │
│  - find() - locate elements     │
│  - screenshot() - capture page  │
│  - form_input() - fill forms    │
│  - click() - interact with page │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Chromium Browser               │
│  Headless + JavaScript support  │
└─────────────────────────────────┘
```

## Examples

### Example 1: Search GitHub

```python
task = "Search GitHub for 'machine learning' repositories and list the top 3"
result = agent.run(task)
```

### Example 2: Fill Form

```python
task = "Go to example.com/form and fill out with name='John' and email='john@example.com'"
result = agent.run(task)
```

### Example 3: Data Extraction

```python
task = "Visit news.ycombinator.com and extract the titles of top 10 stories"
result = agent.run(task)
```

## Deployment

### Local Development

```bash
docker-compose up
```

### DigitalOcean (with $200 student credit)

```bash
docker build -t comet-browser .
docker push your-registry/comet-browser:latest
# Deploy to DigitalOcean App Platform
```

### Microsoft Azure (with $100 student credit)

```bash
az containerapp create --resource-group myResourceGroup \\
  --name comet-browser \\
  --image your-registry/comet-browser:latest
```

## Security & Privacy

- ✅ All processing happens locally (no data sent to external APIs)
- ✅ Browser history is not logged
- ✅ Supports headless mode (no GUI)
- ✅ Can run on private networks
- ✅ Open source code for security audits

## Troubleshooting

### Ollama not connecting

```bash
# Make sure Ollama is running
ollama serve

# Test connection
curl http://localhost:11434/api/tags
```

### Out of memory errors

- Use smaller model: `mistral` instead of `llama2:13b`
- Increase swap space
- Run on machine with 16GB+ RAM

### Playwright issues

```bash
# Install browser binaries
python -m playwright install chromium
```

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Roadmap

- [ ] Multi-agent orchestration
- [ ] Memory system for long-term context
- [ ] Plugin architecture for custom tools
- [ ] Web UI dashboard
- [ ] Kubernetes deployment templates
- [ ] Performance benchmarks
- [ ] Multi-language support

## 📦 What's Included

### Infrastructure (Terraform)
- **App Service**: Scalable web app hosting (B1 tier)
- **PostgreSQL**: Managed database (Basic tier)
- **Container Registry**: Docker image storage
- **Key Vault**: Secure secrets management
- **Application Insights**: Monitoring and analytics
- **Log Analytics**: Centralized logging

### Application
- **FastAPI**: REST API with OpenAPI docs
- **Playwright**: Headless browser automation
- **Async**: Full async/await support
- **Docker**: Multi-stage production builds

### DevOps
- **Terraform**: Infrastructure as Code
- **GitHub Actions**: CI/CD pipeline
- **Health Checks**: Automated monitoring
- **Auto-scaling**: Ready for high traffic

## 💰 Cost Breakdown

| Resource | Tier | Cost/Month |
|----------|------|------------|
| App Service | B1 | $13.14 |
| PostgreSQL | Basic | $5.00 |
| Container Registry | Basic | $5.00 |
| Application Insights | Free | $0.00 |
| **Total** | | **~$23/mo** |

**GitHub Student Pack**: $100 credit = **4+ months FREE** 🎓

### Save Money

1. **Free Tier**: Use `F1` SKU (limited, good for testing)
2. **Stop when idle**: `az webapp stop --name <app-name>`
3. **Destroy when done**: `terraform destroy`

## 🎓 For Students

### Get $100 Azure Credit

1. **Apply**: [GitHub Student Pack](https://education.github.com/pack)
2. **Activate**: [Azure for Students](https://azure.microsoft.com/en-us/free/students/)
3. **Deploy**: Follow [Quick Start](QUICK_START_AZURE.md)

No credit card required! 🎉

## 📚 Documentation

- [Quick Start Azure](QUICK_START_AZURE.md) - Deploy in 3 commands
- [Azure Terraform Guide](terraform/AZURE_TERRAFORM_GUIDE.md) - Complete deployment guide
- [Deployment Checklist](terraform/DEPLOYMENT_CHECKLIST.md) - Step-by-step checklist
- [API Documentation](API_README.md) - REST API reference
- [Architecture](ARCHITECTURE.md) - System design

## 🔒 Security

- ✅ Secrets stored in Azure Key Vault
- ✅ SSL/TLS encryption
- ✅ Managed identity authentication
- ✅ Database firewall rules
- ✅ No secrets in code or Git

## 📊 Monitoring

Access your deployment:

```bash
# Stream logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# View in Azure Portal
# Application Insights → Failures, Performance, Logs
```

## 🚀 CI/CD

Automatic deployment on push to main:

1. Configure GitHub secrets (see [guide](terraform/AZURE_TERRAFORM_GUIDE.md#cicd-deployment))
2. Push to main branch
3. GitHub Actions deploys automatically
4. Health checks verify deployment

## License

MIT License - See [LICENSE](LICENSE) for details

## Support

- 📖 [Documentation](https://github.com/yourusername/comet-agentic-browser/wiki)
- 💬 [Discussions](https://github.com/yourusername/comet-agentic-browser/discussions)
- 🐛 [Issues](https://github.com/yourusername/comet-agentic-browser/issues)
- 📧 Contact: your-email@example.com

## Acknowledgments

- Built with [LangChain](https://python.langchain.com/)
- Browser automation via [Playwright](https://playwright.dev/)
- LLM inference through [Ollama](https://ollama.ai/)
- Inspired by autonomous agents and browser automation tools

---

**Made for the open-source community. Built with GitHub Student Pack benefits.** ❤️
