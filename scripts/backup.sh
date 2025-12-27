#!/bin/bash
# Automated Backup Script for Azure Resources
# Backs up: Database, Container Registry, App Configuration, Key Vault Secrets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/azure-backups}"
DATE=$(date +%Y%m%d-%H%M%S)
ENVIRONMENT="${ENVIRONMENT:-production}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Azure Backup Script ===${NC}"
echo "Environment: $ENVIRONMENT"
echo "Backup Directory: $BACKUP_DIR"
echo "Timestamp: $DATE"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"
cd "$BACKUP_DIR/$DATE"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not found${NC}"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Logging in...${NC}"
    az login
fi

# Get resource group from Terraform output or argument
if [ -z "$RESOURCE_GROUP" ]; then
    if [ -f "$SCRIPT_DIR/../terraform/terraform.tfstate" ]; then
        RESOURCE_GROUP=$(cd "$SCRIPT_DIR/../terraform" && terraform output -raw resource_group_name 2>/dev/null || echo "")
    fi
fi

if [ -z "$RESOURCE_GROUP" ]; then
    echo -e "${YELLOW}Enter resource group name:${NC}"
    read RESOURCE_GROUP
fi

echo -e "${GREEN}Using resource group: $RESOURCE_GROUP${NC}"
echo ""

# 1. Backup PostgreSQL Database
echo -e "${GREEN}[1/5] Backing up PostgreSQL database...${NC}"

DB_SERVER=$(az postgres server list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -n "$DB_SERVER" ]; then
    DB_ADMIN="psqladmin"
    DB_NAME="comet_browser"
    DB_HOST=$(az postgres server show -g "$RESOURCE_GROUP" -n "$DB_SERVER" --query "fullyQualifiedDomainName" -o tsv)
    
    echo "Database Server: $DB_SERVER"
    echo "Database: $DB_NAME"
    
    # Get password from Key Vault
    KV_NAME=$(az keyvault list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
    if [ -n "$KV_NAME" ]; then
        DB_PASSWORD=$(az keyvault secret show --vault-name "$KV_NAME" --name "db-password" --query "value" -o tsv 2>/dev/null || echo "")
    fi
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
        pg_dump -h "$DB_HOST" -U "$DB_ADMIN" -d "$DB_NAME" -F c -f "database_${DB_NAME}_${DATE}.dump"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Database backup completed: database_${DB_NAME}_${DATE}.dump${NC}"
        else
            echo -e "${RED}✗ Database backup failed${NC}"
        fi
        unset PGPASSWORD
    else
        echo -e "${YELLOW}⚠ Could not retrieve database password${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No PostgreSQL server found${NC}"
fi
echo ""

# 2. Export Container Registry Images
echo -e "${GREEN}[2/5] Backing up Container Registry...${NC}"

ACR_NAME=$(az acr list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -n "$ACR_NAME" ]; then
    echo "Container Registry: $ACR_NAME"
    
    # List all repositories and tags
    az acr repository list --name "$ACR_NAME" -o json > "acr_repositories_${DATE}.json"
    
    # Export images metadata
    for repo in $(az acr repository list --name "$ACR_NAME" -o tsv); do
        az acr repository show-tags --name "$ACR_NAME" --repository "$repo" -o json > "acr_${repo//\//_}_tags_${DATE}.json"
    done
    
    echo -e "${GREEN}✓ Container registry metadata backed up${NC}"
else
    echo -e "${YELLOW}⚠ No Container Registry found${NC}"
fi
echo ""

# 3. Backup Key Vault Secrets
echo -e "${GREEN}[3/5] Backing up Key Vault secrets...${NC}"

if [ -n "$KV_NAME" ]; then
    echo "Key Vault: $KV_NAME"
    
    # List all secrets
    az keyvault secret list --vault-name "$KV_NAME" -o json > "keyvault_secrets_list_${DATE}.json"
    
    # Backup secret values (encrypted)
    mkdir -p keyvault_secrets
    for secret in $(az keyvault secret list --vault-name "$KV_NAME" --query "[].name" -o tsv); do
        az keyvault secret show --vault-name "$KV_NAME" --name "$secret" -o json > "keyvault_secrets/${secret}_${DATE}.json"
    done
    
    echo -e "${GREEN}✓ Key Vault secrets backed up${NC}"
else
    echo -e "${YELLOW}⚠ No Key Vault found${NC}"
fi
echo ""

# 4. Export App Service Configuration
echo -e "${GREEN}[4/5] Backing up App Service configuration...${NC}"

APP_NAME=$(az webapp list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -n "$APP_NAME" ]; then
    echo "App Service: $APP_NAME"
    
    # Export app settings
    az webapp config appsettings list --name "$APP_NAME" -g "$RESOURCE_GROUP" -o json > "app_settings_${DATE}.json"
    
    # Export connection strings
    az webapp config connection-string list --name "$APP_NAME" -g "$RESOURCE_GROUP" -o json > "connection_strings_${DATE}.json"
    
    # Export deployment slots (if any)
    az webapp deployment slot list --name "$APP_NAME" -g "$RESOURCE_GROUP" -o json > "deployment_slots_${DATE}.json" 2>/dev/null || echo "[]" > "deployment_slots_${DATE}.json"
    
    echo -e "${GREEN}✓ App Service configuration backed up${NC}"
else
    echo -e "${YELLOW}⚠ No App Service found${NC}"
fi
echo ""

# 5. Export Terraform State
echo -e "${GREEN}[5/5] Backing up Terraform state...${NC}"

if [ -f "$SCRIPT_DIR/../terraform/terraform.tfstate" ]; then
    cp "$SCRIPT_DIR/../terraform/terraform.tfstate" "terraform_state_${DATE}.tfstate"
    cp "$SCRIPT_DIR/../terraform/terraform.tfstate.backup" "terraform_state_backup_${DATE}.tfstate" 2>/dev/null || true
    echo -e "${GREEN}✓ Terraform state backed up${NC}"
else
    echo -e "${YELLOW}⚠ No Terraform state found${NC}"
fi
echo ""

# Create backup manifest
echo -e "${GREEN}Creating backup manifest...${NC}"
cat > "backup_manifest_${DATE}.json" <<EOF
{
  "backup_date": "$DATE",
  "environment": "$ENVIRONMENT",
  "resource_group": "$RESOURCE_GROUP",
  "files": $(ls -1 | jq -R -s -c 'split("\n")[:-1]'),
  "database": {
    "server": "$DB_SERVER",
    "name": "$DB_NAME"
  },
  "container_registry": "$ACR_NAME",
  "key_vault": "$KV_NAME",
  "app_service": "$APP_NAME"
}
EOF

# Compress backup
echo -e "${GREEN}Compressing backup...${NC}"
cd "$BACKUP_DIR"
tar -czf "backup_${ENVIRONMENT}_${DATE}.tar.gz" "$DATE/"

# Calculate checksum
sha256sum "backup_${ENVIRONMENT}_${DATE}.tar.gz" > "backup_${ENVIRONMENT}_${DATE}.sha256"

# Cleanup old backups (keep last 30 days)
echo -e "${GREEN}Cleaning up old backups...${NC}"
find "$BACKUP_DIR" -name "backup_${ENVIRONMENT}_*.tar.gz" -mtime +30 -delete
find "$BACKUP_DIR" -type d -mtime +30 -empty -delete

# Summary
BACKUP_SIZE=$(du -h "backup_${ENVIRONMENT}_${DATE}.tar.gz" | cut -f1)
echo ""
echo -e "${GREEN}=== Backup Complete ===${NC}"
echo "Backup file: backup_${ENVIRONMENT}_${DATE}.tar.gz"
echo "Size: $BACKUP_SIZE"
echo "Location: $BACKUP_DIR"
echo "Checksum: backup_${ENVIRONMENT}_${DATE}.sha256"
echo ""

# Optional: Upload to Azure Storage
if [ -n "$BACKUP_STORAGE_ACCOUNT" ] && [ -n "$BACKUP_CONTAINER" ]; then
    echo -e "${GREEN}Uploading to Azure Storage...${NC}"
    az storage blob upload \
        --account-name "$BACKUP_STORAGE_ACCOUNT" \
        --container-name "$BACKUP_CONTAINER" \
        --name "backup_${ENVIRONMENT}_${DATE}.tar.gz" \
        --file "backup_${ENVIRONMENT}_${DATE}.tar.gz" \
        --auth-mode login
    
    echo -e "${GREEN}✓ Uploaded to Azure Storage${NC}"
fi

echo -e "${GREEN}Backup process completed successfully!${NC}"
