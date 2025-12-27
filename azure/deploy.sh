#!/bin/bash
# Azure deployment script for Comet Agentic Browser

set -e

# Configuration
RESOURCE_GROUP="comet-browser-rg"
LOCATION="eastus"
APP_NAME="comet-browser"

echo "🚀 Deploying Comet Agentic Browser to Azure"
echo "=============================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login to Azure (if not already logged in)
echo "📝 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "🔐 Please login to Azure..."
    az login
fi

# Create resource group
echo "📦 Creating resource group: $RESOURCE_GROUP"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Deploy using ARM template
echo "🔧 Deploying resources..."
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file azure/app-service.json \
    --parameters appName=$APP_NAME \
    --parameters location=$LOCATION

# Get the web app name
WEB_APP_NAME=$(az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name app-service \
    --query properties.outputs.webAppUrl.value \
    --output tsv)

echo "✅ Deployment complete!"
echo "🌐 Your app is available at: $WEB_APP_NAME"
echo ""
echo "Next steps:"
echo "1. Configure environment variables in Azure Portal"
echo "2. Set up your OpenAI API key (or deploy Ollama separately)"
echo "3. Configure custom domain (optional)"
