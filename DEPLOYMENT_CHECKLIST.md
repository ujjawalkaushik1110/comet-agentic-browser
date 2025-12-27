# 🚀 Deployment Checklist

Complete checklist for deploying Comet Agentic Browser to the cloud.

## ✅ Pre-Deployment

### 1. Local Testing
- [ ] Test the agentic browser locally
  ```bash
  python test.py
  ```
- [ ] Test the API locally
  ```bash
  python -m uvicorn api.app:app --reload
  python test_api.py
  ```
- [ ] Test with Docker
  ```bash
  docker-compose up -d
  docker-compose logs -f api
  ```

### 2. Code Quality
- [ ] No syntax errors
  ```bash
  python -m py_compile agent/core.py browser/automation.py api/app.py
  ```
- [ ] Environment variables configured
  ```bash
  cp .env.example .env
  nano .env
  ```
- [ ] Secrets not committed
  ```bash
  git status
  # Ensure .env is in .gitignore
  ```

### 3. Documentation
- [ ] README updated
- [ ] API documentation complete
- [ ] Deployment guide reviewed

## 🎓 GitHub Student Pack Setup

### 1. Apply for GitHub Student Pack
- [ ] Visit https://education.github.com/pack
- [ ] Verify student status
- [ ] Access cloud credits

### 2. Activate Benefits
- [ ] **Azure**: $100 credit
  - Sign up at https://azure.microsoft.com/en-us/free/students/
  - Verify with student email
- [ ] **AWS**: AWS Educate credits
  - Apply at https://aws.amazon.com/education/awseducate/
  - Complete student verification
- [ ] **Heroku**: Student credits
  - Check GitHub Student Pack dashboard

## ☁️ Azure Deployment

### Prerequisites
- [ ] Azure account created
- [ ] Azure CLI installed
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```
- [ ] Logged in to Azure
  ```bash
  az login
  az account set --subscription "Your Subscription"
  ```

### Deployment Steps
- [ ] Review Azure deployment script
  ```bash
  cat azure/deploy.sh
  ```
- [ ] Update configuration in `azure/app-service.json`
- [ ] Run deployment
  ```bash
  ./azure/deploy.sh
  ```
- [ ] Configure environment variables
  ```bash
  az webapp config appsettings set \
    --resource-group comet-browser-rg \
    --name comet-browser \
    --settings OPENAI_API_KEY="your-key"
  ```
- [ ] Test deployment
  ```bash
  curl https://your-app.azurewebsites.net/health
  ```

### Post-Deployment
- [ ] Configure custom domain (optional)
- [ ] Set up SSL certificate
- [ ] Configure monitoring
- [ ] Set up alerts

## 🔶 AWS Deployment

### Prerequisites
- [ ] AWS account created
- [ ] AWS CLI installed
  ```bash
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ```
- [ ] AWS credentials configured
  ```bash
  aws configure
  ```
- [ ] Docker installed

### Deployment Steps
- [ ] Review AWS deployment script
  ```bash
  cat aws/deploy.sh
  ```
- [ ] Update VPC/subnet/security group in `aws/task-definition.json`
- [ ] Create IAM roles
  - ecsTaskExecutionRole
  - ecsTaskRole
- [ ] Run deployment
  ```bash
  ./aws/deploy.sh
  ```
- [ ] Configure secrets in AWS Secrets Manager
  ```bash
  aws secretsmanager create-secret \
    --name openai-api-key \
    --secret-string "your-key"
  ```
- [ ] Test deployment
  ```bash
  # Get ALB URL from console or CLI
  curl https://your-alb-url.region.elb.amazonaws.com/health
  ```

### Post-Deployment
- [ ] Configure Application Load Balancer
- [ ] Set up Route 53 (DNS)
- [ ] Configure CloudWatch logs
- [ ] Set up auto-scaling

## 💜 Heroku Deployment

### Prerequisites
- [ ] Heroku account created
- [ ] Heroku CLI installed
  ```bash
  curl https://cli-assets.heroku.com/install.sh | sh
  ```
- [ ] Logged in to Heroku
  ```bash
  heroku login
  ```

### Deployment Steps
- [ ] Create Heroku app
  ```bash
  heroku create comet-browser-app
  ```
- [ ] Set stack to container
  ```bash
  heroku stack:set container
  ```
- [ ] Configure environment variables
  ```bash
  heroku config:set \
    LLM_API_TYPE=openai \
    OPENAI_API_KEY=your-key \
    BROWSER_HEADLESS=true
  ```
- [ ] Deploy
  ```bash
  git push heroku main
  ```
- [ ] Test deployment
  ```bash
  heroku open
  curl https://your-app.herokuapp.com/health
  ```

### Post-Deployment
- [ ] Configure custom domain
- [ ] Set up SSL (automatic)
- [ ] Configure logging
  ```bash
  heroku logs --tail
  ```
- [ ] Monitor dyno usage

## 🐳 Docker Hub

### Optional: Public Image
- [ ] Login to Docker Hub
  ```bash
  docker login
  ```
- [ ] Build image
  ```bash
  docker build -t yourusername/comet-browser:latest .
  ```
- [ ] Push to Docker Hub
  ```bash
  docker push yourusername/comet-browser:latest
  ```

## 🔄 GitHub Actions CI/CD

### Setup
- [ ] Create GitHub repository secrets
  - Go to: Settings → Secrets → Actions
  
- [ ] For Azure deployment:
  - [ ] `AZURE_CREDENTIALS`
    ```bash
    az ad sp create-for-rbac --name "comet-browser-sp" \
      --role contributor \
      --scopes /subscriptions/{subscription-id} \
      --sdk-auth
    ```
  
- [ ] For Heroku deployment:
  - [ ] `HEROKU_API_KEY`
  - [ ] `HEROKU_APP_NAME`
  - [ ] `HEROKU_EMAIL`
  
- [ ] For AWS deployment:
  - [ ] `AWS_ACCESS_KEY_ID`
  - [ ] `AWS_SECRET_ACCESS_KEY`
  - [ ] `AWS_REGION`

- [ ] Review workflow file
  ```bash
  cat .github/workflows/deploy.yml
  ```

- [ ] Enable GitHub Actions
  - Go to: Actions → Enable workflow

- [ ] Test workflow
  - Push to main branch
  - Check Actions tab

## 🔐 Security Configuration

### API Security
- [ ] Set API key
  ```bash
  # Generate random API key
  openssl rand -hex 32
  
  # Set in environment
  export API_KEY=your-generated-key
  ```

### CORS Configuration
- [ ] Update allowed origins in `api/app.py`
  ```python
  allow_origins=["https://yourdomain.com"]
  ```

### Rate Limiting
- [ ] Review Nginx rate limits
- [ ] Configure WAF (optional)

### Secrets Management
- [ ] Use environment variables for sensitive data
- [ ] Azure: Use Key Vault
- [ ] AWS: Use Secrets Manager
- [ ] Heroku: Use Config Vars
- [ ] Never commit `.env` file

## 📊 Monitoring & Logging

### Azure
- [ ] Enable Application Insights
- [ ] Configure log streaming
  ```bash
  az webapp log tail --resource-group rg --name app
  ```
- [ ] Set up alerts

### AWS
- [ ] Configure CloudWatch Logs
- [ ] Set up CloudWatch Alarms
- [ ] Enable X-Ray tracing (optional)

### Heroku
- [ ] View logs
  ```bash
  heroku logs --tail
  ```
- [ ] Add logging add-on (optional)

## 🧪 Post-Deployment Testing

### Health Check
- [ ] API responds
  ```bash
  curl https://your-app/health
  ```

### Endpoint Tests
- [ ] List models
  ```bash
  curl https://your-app/models
  ```
- [ ] Submit sync task
  ```bash
  curl -X POST https://your-app/browse/sync \
    -H "Content-Type: application/json" \
    -d '{"goal": "Go to example.com", "model": "gpt-4"}'
  ```
- [ ] Submit async task
  ```bash
  curl -X POST https://your-app/browse \
    -H "Content-Type: application/json" \
    -d '{"goal": "Go to github.com"}'
  ```

### Load Testing (Optional)
- [ ] Use Apache Bench
  ```bash
  ab -n 100 -c 10 https://your-app/health
  ```
- [ ] Use k6 or Artillery for API testing

## 📈 Optimization

### Performance
- [ ] Enable caching (if applicable)
- [ ] Configure CDN (optional)
- [ ] Optimize Docker image size
- [ ] Use production-grade WSGI server (Gunicorn)

### Cost Optimization
- [ ] Use appropriate instance sizes
- [ ] Configure auto-scaling
- [ ] Monitor resource usage
- [ ] Use free tiers when possible

### Monitoring
- [ ] Set up uptime monitoring (UptimeRobot, etc.)
- [ ] Configure error tracking (Sentry, optional)
- [ ] Review metrics regularly

## 📝 Documentation

### For Users
- [ ] API documentation accessible at `/docs`
- [ ] README updated with deployment URL
- [ ] Usage examples provided

### For Developers
- [ ] Deployment guide complete
- [ ] Environment variables documented
- [ ] Troubleshooting guide available

## 🎉 Launch Checklist

### Before Going Live
- [ ] All tests passing
- [ ] Security configured
- [ ] Monitoring set up
- [ ] Backup strategy in place
- [ ] Documentation complete

### Launch
- [ ] Deploy to production
- [ ] Verify health check
- [ ] Test all endpoints
- [ ] Monitor logs
- [ ] Announce availability

### Post-Launch
- [ ] Monitor for errors
- [ ] Track usage metrics
- [ ] Gather feedback
- [ ] Plan improvements

## 🆘 Troubleshooting

### Common Issues
- [ ] Browser not starting
  - Check `BROWSER_HEADLESS=true`
  - Verify Playwright dependencies
  
- [ ] Ollama not connecting
  - Use OpenAI instead for cloud deployments
  - Or deploy Ollama on separate server
  
- [ ] Out of memory
  - Increase container memory
  - Reduce `max_iterations`
  
- [ ] Slow responses
  - Check LLM response times
  - Optimize task complexity

### Get Help
- [ ] Check logs
- [ ] Review documentation
- [ ] Check GitHub issues
- [ ] Contact support

## ✅ Completion

Once all items are checked:
- [ ] Deployment is complete
- [ ] API is accessible
- [ ] Tests are passing
- [ ] Monitoring is active
- [ ] Documentation is updated

**Congratulations! Your Comet Agentic Browser is deployed! 🎉**

---

## 📞 Support Resources

- **Documentation**: `/docs` endpoint
- **GitHub**: https://github.com/ujjawalkaushik1110/comet-agentic-browser
- **Azure Docs**: https://docs.microsoft.com/azure
- **AWS Docs**: https://docs.aws.amazon.com
- **Heroku Docs**: https://devcenter.heroku.com
