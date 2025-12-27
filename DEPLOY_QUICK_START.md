# 🚀 Cloud Deployment - Quick Reference

## 📁 Project Structure

```
comet-agentic-browser/
│
├── 🤖 Core Application
│   ├── agent/core.py           # Agentic browser engine
│   ├── browser/automation.py   # Playwright controller
│   └── api/app.py             # FastAPI REST API
│
├── 🐳 Docker
│   ├── Dockerfile             # Production container
│   ├── docker-compose.yml     # Local dev stack
│   ├── .dockerignore         # Build optimization
│   └── nginx.conf            # Reverse proxy
│
├── ☁️ Cloud Deployments
│   ├── azure/                # Azure App Service
│   │   ├── app-service.json  # ARM template
│   │   └── deploy.sh        # Deploy script
│   │
│   ├── aws/                  # AWS ECS Fargate
│   │   ├── task-definition.json
│   │   └── deploy.sh
│   │
│   └── heroku/               # Heroku Platform
│       ├── heroku.yml
│       └── Procfile
│
├── 🔄 CI/CD
│   └── .github/workflows/deploy.yml
│
├── 📚 Documentation
│   ├── DEPLOYMENT.md           # Full deployment guide
│   ├── DEPLOYMENT_CHECKLIST.md # Step-by-step checklist
│   ├── API_README.md          # API documentation
│   ├── CLOUD_DEPLOYMENT_SUMMARY.md
│   └── ... (more docs)
│
└── 🧪 Testing
    ├── test.py               # Core tests
    └── test_api.py          # API tests
```

## 🎯 Choose Your Platform

### For Students (Recommended Order)

1. **🥇 Azure** - Best value with $100 credit
   - Cost: ~$13/month (B1) = 7+ months free
   - Deployment time: ~20 minutes
   - Best for: Production apps

2. **🥈 Heroku** - Easiest to use
   - Cost: $7-25/month
   - Deployment time: ~15 minutes
   - Best for: Quick prototypes

3. **🥉 AWS** - Most powerful
   - Cost: ~$20/month
   - Deployment time: ~30 minutes
   - Best for: Enterprise apps

## ⚡ Quick Deploy Commands

### Azure
```bash
./azure/deploy.sh
```

### AWS
```bash
./aws/deploy.sh
```

### Heroku
```bash
heroku create && git push heroku main
```

### Docker (Local)
```bash
docker-compose up -d
```

## 📖 Documentation Map

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Complete guide | First-time deployment |
| **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** | Step-by-step | Following deployment |
| **[API_README.md](API_README.md)** | API reference | Using the API |
| **[CLOUD_DEPLOYMENT_SUMMARY.md](CLOUD_DEPLOYMENT_SUMMARY.md)** | Quick overview | Understanding setup |
| **[GETTING_STARTED.md](GETTING_STARTED.md)** | Local setup | Getting started |

## 🔑 Required Environment Variables

### For Cloud (Use OpenAI)
```bash
LLM_API_TYPE=openai
OPENAI_API_KEY=sk-your-key-here
BROWSER_HEADLESS=true
```

### For Local (Use Ollama)
```bash
LLM_API_TYPE=ollama
LLM_BASE_URL=http://localhost:11434
BROWSER_HEADLESS=true
```

## 🧪 Test Your Deployment

```bash
# Health check
curl https://your-app.com/health

# Submit task
curl -X POST https://your-app.com/browse/sync \
  -H "Content-Type: application/json" \
  -d '{"goal": "Go to example.com", "model": "gpt-4"}'

# View docs
open https://your-app.com/docs
```

## 💡 Pro Tips

1. **Start with Docker locally** - Test before deploying
2. **Use Azure for students** - Best value with credits
3. **Use OpenAI in cloud** - Simpler than self-hosting Ollama
4. **Enable GitHub Actions** - Auto-deploy on push
5. **Monitor your costs** - Set up billing alerts

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| API won't start | Check environment variables |
| Ollama not found | Use OpenAI for cloud deployments |
| Out of memory | Increase container size |
| Deployment fails | Check cloud platform logs |

## 📞 Get Help

1. Check **[DEPLOYMENT.md](DEPLOYMENT.md)** troubleshooting section
2. Review **logs** for your platform
3. Open GitHub issue
4. Check API docs at `/docs` endpoint

## ✅ Deployment Success Criteria

- [ ] Health check returns 200
- [ ] API docs accessible
- [ ] Can submit and complete tasks
- [ ] Logs are clean
- [ ] Monitoring configured

## 🎓 Student Resources

- **GitHub Student Pack**: https://education.github.com/pack
- **Azure Students**: https://azure.microsoft.com/free/students
- **AWS Educate**: https://aws.amazon.com/education/awseducate
- **Heroku Students**: Check GitHub Student Pack

---

## 🚀 Ready to Deploy?

1. Choose your platform above
2. Get your student credits
3. Follow the deployment guide
4. Test your deployment
5. Start building!

**Good luck! 🎉**
