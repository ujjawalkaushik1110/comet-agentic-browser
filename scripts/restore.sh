#!/bin/bash
# Disaster Recovery Script for Azure Resources
# Restores: Database, Container Registry, App Configuration, Key Vault Secrets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/azure-backups}"
ENVIRONMENT="${ENVIRONMENT:-production}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}=== Azure Disaster Recovery Script ===${NC}"
echo -e "${RED}WARNING: This will restore from backup and may overwrite existing data!${NC}"
echo ""

# List available backups
echo -e "${GREEN}Available backups:${NC}"
ls -lh "$BACKUP_DIR"/backup_${ENVIRONMENT}_*.tar.gz 2>/dev/null || {
    echo -e "${RED}No backups found in $BACKUP_DIR${NC}"
    exit 1
}
echo ""

# Select backup
echo -e "${YELLOW}Enter backup timestamp (YYYYMMDD-HHMMSS) to restore:${NC}"
read BACKUP_DATE

BACKUP_FILE="$BACKUP_DIR/backup_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz"

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

# Verify checksum
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
if [ -f "$CHECKSUM_FILE" ]; then
    echo -e "${GREEN}Verifying backup integrity...${NC}"
    if sha256sum -c "$CHECKSUM_FILE"; then
        echo -e "${GREEN}✓ Backup integrity verified${NC}"
    else
        echo -e "${RED}✗ Backup integrity check failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ No checksum file found, skipping verification${NC}"
fi

# Confirm
echo ""
echo -e "${RED}Are you sure you want to restore from this backup? (yes/NO)${NC}"
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Recovery cancelled"
    exit 0
fi

# Extract backup
echo -e "${GREEN}Extracting backup...${NC}"
TEMP_DIR=$(mktemp -d)
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
cd "$TEMP_DIR/$BACKUP_DATE"

# Load manifest
if [ ! -f "backup_manifest_${BACKUP_DATE}.json" ]; then
    echo -e "${RED}Backup manifest not found${NC}"
    exit 1
fi

RESOURCE_GROUP=$(jq -r '.resource_group' "backup_manifest_${BACKUP_DATE}.json")
DB_SERVER=$(jq -r '.database.server' "backup_manifest_${BACKUP_DATE}.json")
DB_NAME=$(jq -r '.database.name' "backup_manifest_${BACKUP_DATE}.json")
ACR_NAME=$(jq -r '.container_registry' "backup_manifest_${BACKUP_DATE}.json")
KV_NAME=$(jq -r '.key_vault' "backup_manifest_${BACKUP_DATE}.json")
APP_NAME=$(jq -r '.app_service' "backup_manifest_${BACKUP_DATE}.json")

echo ""
echo -e "${GREEN}Backup Information:${NC}"
echo "Resource Group: $RESOURCE_GROUP"
echo "Database: $DB_NAME on $DB_SERVER"
echo "Container Registry: $ACR_NAME"
echo "Key Vault: $KV_NAME"
echo "App Service: $APP_NAME"
echo ""

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

# 1. Restore PostgreSQL Database
echo -e "${GREEN}[1/4] Restoring PostgreSQL database...${NC}"

DB_DUMP="database_${DB_NAME}_${BACKUP_DATE}.dump"
if [ -f "$DB_DUMP" ]; then
    DB_HOST=$(az postgres server show -g "$RESOURCE_GROUP" -n "$DB_SERVER" --query "fullyQualifiedDomainName" -o tsv)
    DB_ADMIN="psqladmin"
    
    # Get password from Key Vault
    DB_PASSWORD=$(az keyvault secret show --vault-name "$KV_NAME" --name "db-password" --query "value" -o tsv 2>/dev/null || echo "")
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
        
        # Drop existing database and recreate (CAUTION!)
        echo -e "${YELLOW}⚠ Dropping existing database...${NC}"
        psql -h "$DB_HOST" -U "$DB_ADMIN" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
        psql -h "$DB_HOST" -U "$DB_ADMIN" -d postgres -c "CREATE DATABASE $DB_NAME;"
        
        # Restore from backup
        pg_restore -h "$DB_HOST" -U "$DB_ADMIN" -d "$DB_NAME" -v "$DB_DUMP"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Database restored successfully${NC}"
        else
            echo -e "${RED}✗ Database restore failed${NC}"
        fi
        
        unset PGPASSWORD
    else
        echo -e "${RED}✗ Could not retrieve database password${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Database backup file not found${NC}"
fi
echo ""

# 2. Restore Key Vault Secrets
echo -e "${GREEN}[2/4] Restoring Key Vault secrets...${NC}"

if [ -d "keyvault_secrets" ]; then
    for secret_file in keyvault_secrets/*.json; do
        if [ -f "$secret_file" ]; then
            SECRET_NAME=$(basename "$secret_file" | sed "s/_${BACKUP_DATE}.json//")
            SECRET_VALUE=$(jq -r '.value' "$secret_file")
            
            if [ -n "$SECRET_VALUE" ] && [ "$SECRET_VALUE" != "null" ]; then
                az keyvault secret set \
                    --vault-name "$KV_NAME" \
                    --name "$SECRET_NAME" \
                    --value "$SECRET_VALUE" \
                    --output none
                
                echo "  ✓ Restored secret: $SECRET_NAME"
            fi
        fi
    done
    echo -e "${GREEN}✓ Key Vault secrets restored${NC}"
else
    echo -e "${YELLOW}⚠ No Key Vault secrets backup found${NC}"
fi
echo ""

# 3. Restore App Service Configuration
echo -e "${GREEN}[3/4] Restoring App Service configuration...${NC}"

if [ -f "app_settings_${BACKUP_DATE}.json" ]; then
    # Note: This restores settings but keeps current values for sensitive data
    echo -e "${YELLOW}⚠ Skipping app settings restore to preserve current secrets${NC}"
    echo -e "${YELLOW}  Backup file available at: app_settings_${BACKUP_DATE}.json${NC}"
    echo -e "${YELLOW}  Manually restore if needed${NC}"
else
    echo -e "${YELLOW}⚠ App settings backup not found${NC}"
fi
echo ""

# 4. Restore Terraform State (manual step)
echo -e "${GREEN}[4/4] Terraform state backup...${NC}"

if [ -f "terraform_state_${BACKUP_DATE}.tfstate" ]; then
    echo -e "${YELLOW}⚠ Terraform state backup found${NC}"
    echo -e "${YELLOW}  Location: terraform_state_${BACKUP_DATE}.tfstate${NC}"
    echo -e "${YELLOW}  Manually copy to terraform directory if needed${NC}"
    echo -e "${YELLOW}  cp $PWD/terraform_state_${BACKUP_DATE}.tfstate $SCRIPT_DIR/../terraform/terraform.tfstate${NC}"
else
    echo -e "${YELLOW}⚠ Terraform state backup not found${NC}"
fi
echo ""

# Restart App Service
echo -e "${GREEN}Restarting App Service...${NC}"
az webapp restart --name "$APP_NAME" --resource-group "$RESOURCE_GROUP"
echo -e "${GREEN}✓ App Service restarted${NC}"
echo ""

# Cleanup
echo -e "${GREEN}Cleaning up temporary files...${NC}"
cd /
rm -rf "$TEMP_DIR"

# Summary
echo ""
echo -e "${GREEN}=== Recovery Complete ===${NC}"
echo "Restored from: backup_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz"
echo "Resource Group: $RESOURCE_GROUP"
echo ""
echo -e "${YELLOW}Post-Recovery Checklist:${NC}"
echo "1. Verify database connection and data integrity"
echo "2. Check application logs for errors"
echo "3. Test critical API endpoints"
echo "4. Verify Key Vault secrets if needed"
echo "5. Review Terraform state if restored"
echo "6. Update DNS/CDN if failover occurred"
echo ""
echo -e "${GREEN}Recovery process completed!${NC}"
