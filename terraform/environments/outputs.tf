# Environment-specific outputs

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "app_service_name" {
  description = "App Service name"
  value       = azurerm_linux_web_app.app.name
}

output "app_service_url" {
  description = "App Service URL"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.acr.login_server
}

output "database_server_fqdn" {
  description = "Database server FQDN"
  value       = azurerm_postgresql_server.db.fqdn
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis endpoint (production only)"
  value       = var.environment == "production" ? azurerm_redis_cache.cache[0].hostname : null
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights key"
  value       = azurerm_application_insights.insights.instrumentation_key
  sensitive   = true
}

output "autoscaling_enabled" {
  description = "Autoscaling status"
  value       = local.env_config.enable_autoscale
}

output "min_instances" {
  description = "Minimum instances"
  value       = local.env_config.min_instances
}

output "max_instances" {
  description = "Maximum instances"
  value       = local.env_config.max_instances
}

output "backup_enabled" {
  description = "Backup status"
  value       = var.environment == "production"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment        = var.environment
    resource_group     = azurerm_resource_group.main.name
    app_url            = "https://${azurerm_linux_web_app.app.default_hostname}"
    sku                = local.env_config.sku_name
    autoscaling        = local.env_config.enable_autoscale
    instances          = "${local.env_config.min_instances}-${local.env_config.max_instances}"
    backup_retention   = local.env_config.backup_retention
    geo_redundant      = local.env_config.geo_redundant
    redis_enabled      = var.environment == "production"
  }
}
