# Disaster Recovery Plan

## Overview

This document outlines the disaster recovery (DR) procedures for the Comet Agentic Browser application deployed on Azure.

## RTO and RPO Targets

| Environment | RTO (Recovery Time Objective) | RPO (Recovery Point Objective) |
|------------|-------------------------------|--------------------------------|
| Production | 4 hours | 1 hour |
| Staging | 8 hours | 4 hours |
| Development | 24 hours | 24 hours |

## Backup Strategy

### Automated Backups

1. **Database Backups**
   - Frequency: Every 6 hours
   - Retention: 30 days
   - Location: Azure Backup vault + geo-redundant storage
   - Script: `scripts/backup.sh`

2. **Container Registry**
   - Frequency: Daily
   - Retention: 90 days
   - Geo-replication: Enabled for production

3. **Key Vault**
   - Soft-delete: 90 days
   - Purge protection: Enabled (production)
   - Backup: Daily export of secret metadata

4. **Application Configuration**
   - Frequency: On every deployment
   - Storage: Version controlled in Git + Azure Storage

### Manual Backup Execution

```bash
# Set environment
export ENVIRONMENT=production
export RESOURCE_GROUP=rg-comet-browser-prod
export BACKUP_DIR=$HOME/azure-backups

# Run backup
./scripts/backup.sh

# Verify backup
ls -lh $BACKUP_DIR/backup_production_*.tar.gz
```

### Automated Backup Schedule

Configure GitHub Actions workflow or Azure Automation:

```bash
# Cron schedule (every 6 hours)
0 */6 * * * /path/to/scripts/backup.sh
```

## Disaster Scenarios

### Scenario 1: Database Corruption

**Symptoms:**
- Application errors related to database queries
- Data integrity issues
- PostgreSQL errors in logs

**Recovery Steps:**

1. **Identify Issue** (5-10 minutes)
   ```bash
   # Check database logs
   az postgres server-logs list -g $RESOURCE_GROUP -s $DB_SERVER
   
   # Verify connectivity
   psql -h $DB_HOST -U $DB_ADMIN -d $DB_NAME -c "SELECT version();"
   ```

2. **Stop Application** (2-5 minutes)
   ```bash
   # Stop app to prevent further corruption
   az webapp stop -n $APP_NAME -g $RESOURCE_GROUP
   ```

3. **Restore Database** (30-60 minutes)
   ```bash
   # Run restore script
   export ENVIRONMENT=production
   ./scripts/restore.sh
   
   # Select the most recent valid backup
   # Script will prompt for confirmation
   ```

4. **Verify Data** (10-15 minutes)
   ```bash
   # Check row counts
   psql -h $DB_HOST -U $DB_ADMIN -d $DB_NAME -c "
     SELECT schemaname, tablename, n_live_tup 
     FROM pg_stat_user_tables 
     ORDER BY n_live_tup DESC;
   "
   
   # Test critical queries
   psql -h $DB_HOST -U $DB_ADMIN -d $DB_NAME -c "
     SELECT COUNT(*) FROM browse_sessions WHERE created_at > NOW() - INTERVAL '24 hours';
   "
   ```

5. **Restart Application** (2-5 minutes)
   ```bash
   az webapp start -n $APP_NAME -g $RESOURCE_GROUP
   ```

6. **Monitor** (15-30 minutes)
   - Check Application Insights for errors
   - Verify health check endpoint
   - Test critical user flows

**Total Recovery Time:** ~1-2 hours

### Scenario 2: Regional Outage

**Symptoms:**
- Azure region unavailable
- All services in primary region down
- Network connectivity issues to primary region

**Recovery Steps:**

1. **Assess Outage** (5-10 minutes)
   ```bash
   # Check Azure status
   az account list-locations --query "[?name=='eastus'].{Name:name, Status:metadata.regionCategory}" -o table
   
   # Verify service health
   az resource list -g $RESOURCE_GROUP --query "[].{Name:name, Location:location, Status:provisioningState}" -o table
   ```

2. **Initiate Failover** (10-20 minutes)

   **For Database:**
   ```bash
   # Failover to geo-replica (if configured)
   az postgres server replica list -g $RESOURCE_GROUP -s $DB_SERVER
   az postgres server replica promote -g $RESOURCE_GROUP -s $DB_REPLICA_NAME
   ```

   **For Container Registry:**
   ```bash
   # Update Terraform to use secondary region
   cd terraform/environments
   terraform workspace select production
   
   # Update variables for secondary region
   terraform apply -var="primary_location=westus2" -var="use_secondary_region=true"
   ```

3. **Update DNS** (5-10 minutes)
   ```bash
   # If using Traffic Manager or Front Door
   az network traffic-manager endpoint update \
     --name production-endpoint \
     --profile-name comet-browser-tm \
     --resource-group $RESOURCE_GROUP \
     --type azureEndpoints \
     --target-resource-id $SECONDARY_APP_ID \
     --endpoint-status Enabled
   ```

4. **Verify Secondary Region** (10-15 minutes)
   - Test health check endpoint
   - Verify database connectivity
   - Check application logs
   - Test critical API endpoints

5. **Communication** (ongoing)
   - Notify stakeholders via status page
   - Update incident tracking system
   - Document timeline and actions taken

**Total Recovery Time:** ~2-4 hours (depending on data sync status)

### Scenario 3: Application Service Failure

**Symptoms:**
- App Service not responding
- Health check failures
- HTTP 503 errors

**Recovery Steps:**

1. **Quick Diagnostics** (2-5 minutes)
   ```bash
   # Check app status
   az webapp show -n $APP_NAME -g $RESOURCE_GROUP --query "state"
   
   # View recent logs
   az webapp log tail -n $APP_NAME -g $RESOURCE_GROUP
   ```

2. **Attempt Restart** (2-5 minutes)
   ```bash
   az webapp restart -n $APP_NAME -g $RESOURCE_GROUP
   
   # Wait 2 minutes, then check health
   sleep 120
   curl https://$APP_NAME.azurewebsites.net/health
   ```

3. **If Restart Fails - Redeploy** (10-20 minutes)
   ```bash
   # Redeploy from last known good image
   az webapp config container set \
     --name $APP_NAME \
     --resource-group $RESOURCE_GROUP \
     --docker-custom-image-name $ACR_NAME.azurecr.io/comet-browser:stable
   
   az webapp restart -n $APP_NAME -g $RESOURCE_GROUP
   ```

4. **If Redeploy Fails - Recreate** (30-45 minutes)
   ```bash
   # Use Terraform to recreate app service
   cd terraform/environments
   terraform workspace select production
   
   # Taint the app service resource
   terraform taint azurerm_linux_web_app.app
   terraform apply -var-file="production.tfvars"
   ```

5. **Verify Recovery** (5-10 minutes)
   - Check all health endpoints
   - Test API functionality
   - Review metrics in Application Insights

**Total Recovery Time:** ~20-60 minutes

### Scenario 4: Key Vault Compromise

**Symptoms:**
- Suspicious access patterns in Key Vault audit logs
- Unauthorized secret access alerts
- Security incident notification

**Recovery Steps:**

1. **Immediate Actions** (2-5 minutes)
   ```bash
   # Disable compromised keys
   az keyvault secret set-attributes \
     --vault-name $KV_NAME \
     --name compromised-secret \
     --enabled false
   
   # Review audit logs
   az monitor activity-log list \
     --resource-group $RESOURCE_GROUP \
     --namespace Microsoft.KeyVault \
     --start-time $(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')
   ```

2. **Rotate Credentials** (10-20 minutes)
   ```bash
   # Generate new database password
   NEW_DB_PASSWORD=$(openssl rand -base64 32)
   
   # Update in PostgreSQL
   psql -h $DB_HOST -U $DB_ADMIN -d postgres \
     -c "ALTER USER $DB_ADMIN WITH PASSWORD '$NEW_DB_PASSWORD';"
   
   # Update in Key Vault
   az keyvault secret set \
     --vault-name $KV_NAME \
     --name db-password \
     --value "$NEW_DB_PASSWORD"
   
   # Restart app to pick up new credentials
   az webapp restart -n $APP_NAME -g $RESOURCE_GROUP
   ```

3. **Update Network ACLs** (5-10 minutes)
   ```bash
   # Restrict Key Vault access
   az keyvault network-rule add \
     --name $KV_NAME \
     --ip-address $TRUSTED_IP_RANGE
   
   # Remove compromised IP ranges
   az keyvault network-rule remove \
     --name $KV_NAME \
     --ip-address $COMPROMISED_IP
   ```

4. **Enable Enhanced Security** (5-10 minutes)
   ```bash
   # Enable soft-delete and purge protection
   az keyvault update \
     --name $KV_NAME \
     --enable-soft-delete true \
     --enable-purge-protection true
   
   # Configure diagnostic logging
   az monitor diagnostic-settings create \
     --name kv-diagnostics \
     --resource $KV_ID \
     --logs '[{"category": "AuditEvent", "enabled": true}]' \
     --workspace $LOG_ANALYTICS_ID
   ```

5. **Post-Incident Review** (ongoing)
   - Analyze attack vector
   - Review and update access policies
   - Update incident response procedures
   - Conduct security audit

**Total Recovery Time:** ~30-60 minutes

## Recovery Testing

### Quarterly DR Drills

Execute these tests every quarter:

1. **Database Restore Test** (Q1)
   ```bash
   # Restore to staging environment
   export ENVIRONMENT=staging
   ./scripts/restore.sh
   # Verify data integrity
   ```

2. **Regional Failover Test** (Q2)
   - Simulate primary region failure
   - Execute failover procedures
   - Measure actual RTO

3. **Complete System Recovery** (Q3)
   - Restore all components from backup
   - Validate end-to-end functionality
   - Document actual recovery time

4. **Security Incident Response** (Q4)
   - Simulate Key Vault compromise
   - Practice credential rotation
   - Test communication procedures

### Test Results Documentation

Document each test in:
```
docs/dr-tests/
├── 2024-Q1-database-restore.md
├── 2024-Q2-regional-failover.md
├── 2024-Q3-full-recovery.md
└── 2024-Q4-security-incident.md
```

## Monitoring and Alerts

### Critical Alerts

Configure these alerts in Azure Monitor:

1. **App Service Down**
   - Severity: 0 (Critical)
   - Notification: SMS + Email + PagerDuty
   - Auto-remediation: Restart app service

2. **Database Unavailable**
   - Severity: 0 (Critical)
   - Notification: SMS + Email
   - Escalation: After 5 minutes

3. **High Error Rate**
   - Severity: 1 (Error)
   - Threshold: >5% HTTP 5xx
   - Notification: Email + Slack

4. **Backup Failure**
   - Severity: 2 (Warning)
   - Notification: Email
   - Action: Retry backup, escalate if persistent

### Health Checks

Monitor these endpoints:

```bash
# Application health
curl https://$APP_NAME.azurewebsites.net/health

# Database health
curl https://$APP_NAME.azurewebsites.net/health/db

# Redis health
curl https://$APP_NAME.azurewebsites.net/health/redis

# Dependencies
curl https://$APP_NAME.azurewebsites.net/health/ready
```

## Contact Information

### Escalation Path

| Level | Role | Contact | Response Time |
|-------|------|---------|---------------|
| L1 | On-Call Engineer | oncall@company.com | 15 minutes |
| L2 | Platform Team Lead | platform-lead@company.com | 30 minutes |
| L3 | DevOps Manager | devops-mgr@company.com | 1 hour |
| L4 | CTO | cto@company.com | 2 hours |

### External Contacts

- **Azure Support:** 1-800-MICROSOFT
- **Support Plan:** Premier
- **Contract Number:** [Your Azure Support Contract]

## Documentation

- **Runbooks:** `/docs/runbooks/`
- **Architecture Diagrams:** `/docs/architecture/`
- **Change Log:** `/docs/CHANGELOG.md`
- **Incident Reports:** `/docs/incidents/`

## Post-Incident Procedures

After any disaster recovery event:

1. **Document Timeline** (within 24 hours)
   - What happened
   - When it was detected
   - Actions taken
   - Resolution time

2. **Root Cause Analysis** (within 3 days)
   - Identify root cause
   - Contributing factors
   - Why detection was delayed (if applicable)

3. **Remediation Plan** (within 1 week)
   - Preventive measures
   - Process improvements
   - Technical improvements
   - Update DR procedures

4. **Team Review** (within 2 weeks)
   - Share learnings
   - Update documentation
   - Conduct training if needed

## Regular Maintenance

### Weekly
- Review backup success logs
- Check storage consumption
- Verify retention policies

### Monthly
- Test restore procedure (non-production)
- Review and update contact information
- Audit access logs

### Quarterly
- Full DR drill
- Update RTO/RPO targets
- Review and update procedures
- Security audit

### Annually
- Complete DR plan review
- Update disaster scenarios
- Renew external support contracts
- Team DR training
