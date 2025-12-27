# Production Operations Guide

## Table of Contents

1. [Health Checks and Monitoring](#health-checks-and-monitoring)
2. [Service Level Agreements (SLA)](#service-level-agreements)
3. [Cost Optimization](#cost-optimization)
4. [Security Hardening](#security-hardening)
5. [Performance Tuning](#performance-tuning)
6. [Troubleshooting](#troubleshooting)

## Health Checks and Monitoring

### Health Check Endpoints

| Endpoint | Purpose | Expected Response Time | Success Criteria |
|----------|---------|----------------------|------------------|
| `/health` | Basic app health | <100ms | HTTP 200, status="healthy" |
| `/health/db` | Database connectivity | <500ms | HTTP 200, database="connected" |
| `/health/redis` | Cache connectivity | <200ms | HTTP 200, redis="connected" |
| `/health/ready` | Readiness probe | <1s | HTTP 200, ready=true |
| `/metrics` | Prometheus metrics | <200ms | HTTP 200, text/plain |

### Monitoring Dashboards

#### Azure Application Insights

1. **Availability Dashboard**
   - Uptime percentage (target: 99.9%)
   - Response time trends
   - Failed request rate

2. **Performance Dashboard**
   - Request duration (p50, p95, p99)
   - Database query performance
   - Cache hit ratio (target: >80%)
   - Active user sessions

3. **Infrastructure Dashboard**
   - App Service CPU/Memory usage
   - Database DTU/CPU usage
   - Redis memory usage
   - Network throughput

#### Key Metrics

```kusto
// Application Insights Query - Error Rate
requests
| where timestamp > ago(1h)
| summarize 
    Total = count(),
    Failed = countif(success == false),
    ErrorRate = todouble(countif(success == false)) / count() * 100
| project ErrorRate

// Response Time Percentiles
requests
| where timestamp > ago(1h)
| summarize 
    p50 = percentile(duration, 50),
    p95 = percentile(duration, 95),
    p99 = percentile(duration, 99)

// Cache Hit Rate
dependencies
| where type == "Redis"
| where name contains "GET"
| summarize 
    Total = count(),
    Hits = countif(resultCode == "200"),
    HitRate = todouble(countif(resultCode == "200")) / count() * 100
| project HitRate
```

### Alert Configuration

Critical alerts configured in Azure Monitor:

1. **App Down** (Severity 0)
   - Condition: Health check fails for 2 consecutive minutes
   - Action: SMS + Email to on-call + Auto-restart

2. **High CPU Usage** (Severity 2)
   - Condition: CPU > 70% for 5 minutes
   - Action: Email + Trigger autoscaling

3. **High Memory Usage** (Severity 2)
   - Condition: Memory > 80% for 5 minutes
   - Action: Email + Trigger autoscaling

4. **High Error Rate** (Severity 1)
   - Condition: HTTP 5xx > 5% for 3 minutes
   - Action: Email + Slack notification

5. **Database Connection Failures** (Severity 1)
   - Condition: DB health check fails
   - Action: Email + Page on-call

## Service Level Agreements (SLA)

### Availability SLA

| Environment | Target Uptime | Allowed Downtime |
|------------|---------------|------------------|
| Production | 99.9% | 43 minutes/month |
| Staging | 99.5% | 3.6 hours/month |
| Development | 99.0% | 7.2 hours/month |

### Performance SLA

| Metric | Target | Measurement |
|--------|--------|-------------|
| API Response Time (p95) | <500ms | 95th percentile |
| API Response Time (p99) | <1s | 99th percentile |
| Health Check Response | <100ms | Average |
| Database Query Time | <100ms | Average |
| Cache Hit Ratio | >80% | Percentage |

### Support SLA

| Severity | Response Time | Resolution Time |
|----------|--------------|-----------------|
| Critical (S0) | 15 minutes | 4 hours |
| High (S1) | 1 hour | 8 hours |
| Medium (S2) | 4 hours | 24 hours |
| Low (S3) | 1 business day | 5 business days |

### SLA Monitoring

```bash
# Generate monthly SLA report
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{app} \
  --metric "Http2xx,Http4xx,Http5xx" \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-31T23:59:59Z \
  --interval PT1H \
  --aggregation Total \
  --output table

# Calculate uptime percentage
total_requests=$(az monitor metrics list ... | jq '.value[0].timeseries[0].data | map(.total) | add')
failed_requests=$(az monitor metrics list ... | jq '.value[2].timeseries[0].data | map(.total) | add')
uptime=$(echo "scale=4; (1 - $failed_requests / $total_requests) * 100" | bc)
echo "Uptime: $uptime%"
```

## Cost Optimization

### Current Cost Breakdown (Production)

| Service | SKU | Monthly Cost (USD) | Optimization Opportunity |
|---------|-----|-------------------|------------------------|
| App Service | S1 | $70 | Reserved instances (-30%) |
| PostgreSQL | GP_Gen5_2 | $140 | Right-size to GP_Gen5_1 |
| Redis Cache | Standard C1 | $75 | Use only in production |
| Container Registry | Standard | $20 | Premium for geo-replication |
| Application Insights | Pay-as-you-go | $30 | Set daily cap |
| Key Vault | Standard | $5 | - |
| **Total** | | **~$340/month** | **Potential savings: ~$100** |

### Cost Optimization Strategies

1. **Auto-Scaling**
   - Scale down during off-peak hours (nights/weekends)
   - Current: 2-10 instances
   - Optimized: 1 instance off-peak, scale up on demand

2. **Reserved Instances**
   - Purchase 1-year reserved capacity for App Service
   - Savings: ~30% on compute costs
   - Break-even: 8 months

3. **Development Environment**
   - Auto-shutdown after business hours
   - Use F1 (free) tier
   - Current savings: $70/month

4. **Database Optimization**
   - Enable query performance insights
   - Optimize slow queries (>100ms)
   - Consider read replicas only if needed

5. **Storage Optimization**
   - Set blob lifecycle policies (delete after 90 days)
   - Use cool/archive tiers for old backups
   - Enable soft-delete only on production

### Cost Monitoring

```bash
# Get cost analysis for resource group
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --query "[?contains(instanceName, 'comet-browser')].{Service:meterCategory, Cost:pretaxCost}" \
  --output table

# Set budget alerts
az consumption budget create \
  --budget-name "comet-browser-monthly" \
  --amount 500 \
  --time-grain Monthly \
  --time-period start=2024-01-01 \
  --resource-group rg-comet-browser-prod \
  --notifications amount=400,operator=GreaterThan,contactEmails="devops@company.com"
```

### Auto-Shutdown Script

```bash
# Schedule for development environment
# Add to cron: 0 19 * * 1-5 (7 PM weekdays)

#!/bin/bash
RESOURCE_GROUP="rg-comet-browser-dev"
APP_NAME="app-comet-browser-dev"

# Check if Friday
if [ $(date +%u) -eq 5 ]; then
  echo "Friday - shutting down for weekend"
  az webapp stop --name $APP_NAME --resource-group $RESOURCE_GROUP
fi

# Auto-start on Monday morning
# 0 8 * * 1 (8 AM Monday)
if [ $(date +%u) -eq 1 ]; then
  echo "Monday - starting for week"
  az webapp start --name $APP_NAME --resource-group $RESOURCE_GROUP
fi
```

## Security Hardening

### Security Checklist

- [x] HTTPS enforced (TLS 1.2 minimum)
- [x] Key Vault for secrets management
- [x] Managed Identity for Azure resource access
- [x] Network isolation (VNet integration)
- [x] Database firewall rules
- [x] Redis SSL/TLS enabled
- [x] Container Registry admin user disabled
- [x] Application Insights connection via managed identity
- [x] Soft-delete enabled on Key Vault
- [x] Purge protection enabled (production)
- [x] Database threat detection enabled
- [x] Regular security patching
- [ ] WAF (Web Application Firewall) - recommended
- [ ] DDoS protection - optional
- [ ] Penetration testing - quarterly

### Security Best Practices

1. **Secret Management**
   ```bash
   # Never commit secrets to git
   git secrets --install
   git secrets --register-aws
   
   # Rotate secrets quarterly
   ./scripts/rotate-secrets.sh production
   ```

2. **Network Security**
   ```bash
   # Restrict database access to app subnet only
   az postgres server firewall-rule delete \
     --name AllowAllAzureIPs \
     --resource-group $RESOURCE_GROUP \
     --server-name $DB_SERVER
   
   # Add specific IP ranges
   az postgres server firewall-rule create \
     --name AllowAppSubnet \
     --resource-group $RESOURCE_GROUP \
     --server-name $DB_SERVER \
     --start-ip-address 10.0.1.0 \
     --end-ip-address 10.0.1.255
   ```

3. **Access Control**
   ```bash
   # Use Azure RBAC
   az role assignment create \
     --role "Reader" \
     --assignee user@company.com \
     --scope /subscriptions/{sub}/resourceGroups/{rg}
   
   # Principle of least privilege
   # Developers: Reader on production
   # DevOps: Contributor on all environments
   # Automated deployments: Use service principals with minimal scope
   ```

4. **Audit Logging**
   ```bash
   # Enable diagnostic settings
   az monitor diagnostic-settings create \
     --name audit-logs \
     --resource /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Web/sites/{app} \
     --logs '[{"category": "AppServiceAuditLogs", "enabled": true}]' \
     --workspace $LOG_ANALYTICS_ID
   ```

### Security Monitoring

```kusto
// Failed authentication attempts
AzureDiagnostics
| where Category == "AppServiceAuditLogs"
| where ResultType != "Success"
| summarize Count = count() by IPAddress, bin(TimeGenerated, 1h)
| where Count > 10

// Suspicious database queries
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.DBFORPOSTGRESQL"
| where Message contains "DROP" or Message contains "DELETE FROM" or Message contains "TRUNCATE"
| project TimeGenerated, Message, ClientIp
```

## Performance Tuning

### Application-Level Optimization

1. **Caching Strategy**
   - Cache frequently accessed data (5-minute TTL)
   - Use Redis for session storage
   - Implement cache invalidation on updates
   - Monitor cache hit ratio (target: >80%)

2. **Database Optimization**
   ```sql
   -- Create indexes for common queries
   CREATE INDEX idx_sessions_user_id ON browse_sessions(user_id);
   CREATE INDEX idx_sessions_created_at ON browse_sessions(created_at);
   
   -- Analyze query performance
   EXPLAIN ANALYZE SELECT * FROM browse_sessions WHERE user_id = 123;
   
   -- Optimize connection pooling
   ALTER SYSTEM SET max_connections = 100;
   ALTER SYSTEM SET shared_buffers = '256MB';
   ```

3. **API Optimization**
   - Enable GZip compression
   - Implement pagination for large datasets
   - Use async endpoints for long-running tasks
   - Rate limiting to prevent abuse

### Infrastructure Optimization

1. **Auto-Scaling Rules**
   ```bash
   # CPU-based scaling
   az monitor autoscale rule create \
     --resource-group $RESOURCE_GROUP \
     --autoscale-name autoscale-comet \
     --condition "Percentage CPU > 70 avg 5m" \
     --scale out 1
   
   # Memory-based scaling
   az monitor autoscale rule create \
     --resource-group $RESOURCE_GROUP \
     --autoscale-name autoscale-comet \
     --condition "Memory Percentage > 80 avg 5m" \
     --scale out 1
   ```

2. **CDN Configuration**
   ```bash
   # Add Azure CDN for static assets
   az cdn endpoint create \
     --resource-group $RESOURCE_GROUP \
     --name comet-browser-cdn \
     --profile-name cdn-profile \
     --origin $APP_NAME.azurewebsites.net
   ```

## Troubleshooting

### Common Issues

#### Issue: High Response Times

**Symptoms:**
- API response time > 1s
- Slow page loads
- Timeout errors

**Diagnosis:**
```bash
# Check app performance
az monitor metrics list \
  --resource $APP_ID \
  --metric "HttpResponseTime" \
  --interval PT1M

# Check database performance
az postgres server-logs list -g $RESOURCE_GROUP -s $DB_SERVER

# Check for slow queries
SELECT query, calls, total_time, min_time, max_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

**Resolution:**
1. Scale up app service temporarily
2. Optimize slow database queries
3. Increase cache TTL
4. Review and optimize code paths

#### Issue: Memory Leaks

**Symptoms:**
- Gradually increasing memory usage
- Eventual app crashes
- OOM errors in logs

**Diagnosis:**
```bash
# Monitor memory over time
az monitor metrics list \
  --resource $APP_ID \
  --metric "MemoryPercentage" \
  --start-time $(date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ') \
  --interval PT5M

# Check app logs for OOM
az webapp log tail -n $APP_NAME -g $RESOURCE_GROUP | grep -i "memory"
```

**Resolution:**
1. Restart app service
2. Review recent code changes
3. Add memory profiling
4. Implement proper cleanup in event handlers

#### Issue: Database Connection Pool Exhausted

**Symptoms:**
- "Too many connections" errors
- Slow database queries
- Intermittent failures

**Diagnosis:**
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- See connection details
SELECT pid, usename, application_name, client_addr, state
FROM pg_stat_activity
WHERE state = 'active';
```

**Resolution:**
```python
# Optimize connection pooling in app
DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(
    DATABASE_URL,
    pool_size=10,  # Reduce from default 20
    max_overflow=5,  # Limit max connections
    pool_pre_ping=True,  # Test connections
    pool_recycle=3600  # Recycle after 1 hour
)
```

### Emergency Procedures

#### Complete Service Outage

1. **Immediate Actions**
   ```bash
   # Check service status
   az webapp show -n $APP_NAME -g $RESOURCE_GROUP --query "state"
   
   # Restart app
   az webapp restart -n $APP_NAME -g $RESOURCE_GROUP
   ```

2. **If restart fails**
   ```bash
   # Restore from last known good deployment
   az webapp deployment source sync -n $APP_NAME -g $RESOURCE_GROUP
   ```

3. **If still failing**
   - Execute disaster recovery plan
   - See [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md)

### Support Contacts

- **On-Call Engineer:** See PagerDuty rotation
- **Platform Team:** platform-team@company.com
- **Azure Support:** 1-800-MICROSOFT (Premier Support)
- **Emergency Escalation:** CTO (emergency-only@company.com)

---

**Last Updated:** 2024-01-01  
**Document Owner:** DevOps Team  
**Review Schedule:** Quarterly
