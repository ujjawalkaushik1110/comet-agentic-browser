# Terraform Outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.app.name
}

output "app_service_url" {
  description = "URL of the deployed application"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.app.default_hostname
}

output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "container_registry_login_server" {
  description = "Login server URL for Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for Container Registry"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "database_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_server.db.name
}

output "database_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_server.db.fqdn
  sensitive   = true
}

output "database_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://psqladmin:***@${azurerm_postgresql_server.db.fqdn}:5432/comet_browser?sslmode=require"
  sensitive   = true
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.insights.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.logs.id
}

output "api_endpoints" {
  description = "API endpoints"
  value = {
    health      = "https://${azurerm_linux_web_app.app.default_hostname}/health"
    docs        = "https://${azurerm_linux_web_app.app.default_hostname}/docs"
    browse      = "https://${azurerm_linux_web_app.app.default_hostname}/browse"
    browse_sync = "https://${azurerm_linux_web_app.app.default_hostname}/browse/sync"
    tasks       = "https://${azurerm_linux_web_app.app.default_hostname}/tasks"
  }
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    resource_group      = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
    app_service_url     = "https://${azurerm_linux_web_app.app.default_hostname}"
    container_registry  = azurerm_container_registry.acr.login_server
    database_server     = azurerm_postgresql_server.db.fqdn
    monitoring_enabled  = var.enable_monitoring
  }
}

output "cost_estimate" {
  description = "Monthly cost estimate"
  value = {
    app_service        = var.sku_name == "B1" ? "$13.14/mo" : var.sku_name == "F1" ? "Free" : "Variable"
    database           = "$5.00/mo (Basic tier)"
    container_registry = "$5.00/mo (Basic tier)"
    monitoring         = "Free tier"
    total_estimate     = "~$18-23/mo"
    student_credit     = "$100 = ~5 months free"
  }
}
