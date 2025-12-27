# 🚀 Quick Start: Azure Deployment

**Deploy Comet Agentic Browser to Azure in 3 commands using your GitHub Student Pack ($100 free credit)**

## Prerequisites
- Azure for Students account activated
- OpenAI API key

## Deploy Now

```bash
# 1. Clone
git clone https://github.com/ujjawalkaushik1110/comet-agentic-browser.git
cd comet-agentic-browser

# 2. Configure (edit with your OpenAI key & email)
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add your openai_api_key and admin_email

# 3. Deploy
./deploy.sh
```

**That's it!** ✨

Your app will be live at: `https://comet-browser-xxxxx-app.azurewebsites.net`

## What Gets Deployed

- ✅ **App Service** (B1): Web application hosting
- ✅ **PostgreSQL Database**: Task storage
- ✅ **Container Registry**: Docker image hosting
- ✅ **Key Vault**: Secure secret management
- ✅ **Application Insights**: Monitoring & logging
- ✅ **CI/CD Pipeline**: Automated deployments

## Monthly Cost

```
App Service (B1):       $13/month
PostgreSQL (Basic):     $5/month
Container Registry:     $5/month
Monitoring:             FREE
─────────────────────────────────
Total:                  ~$23/month

With $100 student credit = 4+ months FREE! 🎓
```

## Next Steps

1. **Test your deployment**:
   ```bash
   curl https://your-app-url.azurewebsites.net/health
   ```

2. **View API docs**: Visit `https://your-app-url.azurewebsites.net/docs`

3. **Set up CI/CD**: Follow [AZURE_TERRAFORM_GUIDE.md](terraform/AZURE_TERRAFORM_GUIDE.md)

4. **Monitor costs**: Azure Portal → Cost Management

## Need Help?

- 📖 **Full Guide**: [terraform/AZURE_TERRAFORM_GUIDE.md](terraform/AZURE_TERRAFORM_GUIDE.md)
- ✅ **Checklist**: [terraform/DEPLOYMENT_CHECKLIST.md](terraform/DEPLOYMENT_CHECKLIST.md)
- 🐛 **Issues**: Create a GitHub issue

## Cleanup

When you're done:
```bash
cd terraform
terraform destroy  # Removes all resources
```

---

**Get Started**: [Apply for GitHub Student Pack](https://education.github.com/pack) → [Activate Azure](https://azure.microsoft.com/en-us/free/students/) → Deploy! 🚀
