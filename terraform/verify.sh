#!/bin/bash
# Azure Terraform Deployment Verification Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Verifying Azure Terraform Deployment Setup"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Check required tools
echo "📋 Checking prerequisites..."

if command -v az &> /dev/null; then
    echo -e "${GREEN}✓${NC} Azure CLI installed: $(az version --query '\"azure-cli\"' -o tsv)"
else
    echo -e "${RED}✗${NC} Azure CLI not found"
    ((ERRORS++))
fi

if command -v terraform &> /dev/null; then
    echo -e "${GREEN}✓${NC} Terraform installed: $(terraform version | head -n1)"
else
    echo -e "${RED}✗${NC} Terraform not found"
    ((ERRORS++))
fi

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker installed: $(docker --version)"
else
    echo -e "${RED}✗${NC} Docker not found"
    ((ERRORS++))
fi

echo ""
echo "📁 Checking Terraform files..."

# Check Terraform files
TERRAFORM_FILES=(
    "$SCRIPT_DIR/main.tf"
    "$SCRIPT_DIR/variables.tf"
    "$SCRIPT_DIR/outputs.tf"
    "$SCRIPT_DIR/deploy.sh"
    "$SCRIPT_DIR/terraform.tfvars.example"
)

for file in "${TERRAFORM_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $(basename $file) exists"
    else
        echo -e "${RED}✗${NC} $(basename $file) missing"
        ((ERRORS++))
    fi
done

# Check if deploy.sh is executable
if [ -x "$SCRIPT_DIR/deploy.sh" ]; then
    echo -e "${GREEN}✓${NC} deploy.sh is executable"
else
    echo -e "${YELLOW}⚠${NC} deploy.sh is not executable (run: chmod +x deploy.sh)"
fi

echo ""
echo "📄 Checking documentation..."

DOCS=(
    "$SCRIPT_DIR/AZURE_TERRAFORM_GUIDE.md"
    "$SCRIPT_DIR/DEPLOYMENT_CHECKLIST.md"
    "$SCRIPT_DIR/../QUICK_START_AZURE.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓${NC} $(basename $doc) exists"
    else
        echo -e "${RED}✗${NC} $(basename $doc) missing"
        ((ERRORS++))
    fi
done

echo ""
echo "🔧 Validating Terraform configuration..."

cd "$SCRIPT_DIR"

# Check Terraform syntax
if terraform fmt -check -recursive > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Terraform formatting correct"
else
    echo -e "${YELLOW}⚠${NC} Terraform files need formatting (run: terraform fmt -recursive)"
fi

# Validate configuration (without backend)
if terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Terraform configuration valid"
else
    echo -e "${RED}✗${NC} Terraform validation failed"
    ((ERRORS++))
fi

# Clean up validation files
rm -rf .terraform terraform.tfstate* 2>/dev/null

echo ""
echo "🐳 Checking Docker files..."

if [ -f "$SCRIPT_DIR/../Dockerfile" ]; then
    echo -e "${GREEN}✓${NC} Dockerfile exists"
else
    echo -e "${RED}✗${NC} Dockerfile missing"
    ((ERRORS++))
fi

if [ -f "$SCRIPT_DIR/../docker-compose.yml" ]; then
    echo -e "${GREEN}✓${NC} docker-compose.yml exists"
else
    echo -e "${RED}✗${NC} docker-compose.yml missing"
    ((ERRORS++))
fi

echo ""
echo "🔐 Checking GitHub Actions workflow..."

if [ -f "$SCRIPT_DIR/../.github/workflows/azure-terraform.yml" ]; then
    echo -e "${GREEN}✓${NC} CI/CD workflow exists"
else
    echo -e "${RED}✗${NC} GitHub Actions workflow missing"
    ((ERRORS++))
fi

echo ""
echo "=============================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "🚀 Ready to deploy!"
    echo ""
    echo "Next steps:"
    echo "  1. Copy terraform.tfvars.example to terraform.tfvars"
    echo "  2. Edit terraform.tfvars with your OpenAI key and email"
    echo "  3. Run: ./deploy.sh"
    echo ""
    echo "📚 Documentation:"
    echo "  - Quick Start: ../QUICK_START_AZURE.md"
    echo "  - Full Guide: AZURE_TERRAFORM_GUIDE.md"
    echo "  - Checklist: DEPLOYMENT_CHECKLIST.md"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS error(s)${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi
