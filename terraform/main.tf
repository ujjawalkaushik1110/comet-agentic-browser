# Azure Terraform Configuration
# Comprehensive deployment for Comet Agentic Browser

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  
  # Store state in Azure Storage (recommended for production)
  # Uncomment after creating storage account
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstatestg"
  #   container_name       = "tfstate"
  #   key                  = "comet-browser.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Variables
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "comet-browser"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "sku_name" {
  description = "App Service SKU (F1=Free, B1=Basic $13/mo, S1=Standard $70/mo)"
  type        = string
  default     = "B1"  # Best value for students
}

variable "db_sku_name" {
  description = "Database SKU"
  type        = string
  default     = "B_Gen5_1"  # Cheapest tier
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Admin email for notifications"
  type        = string
}

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name}${random_string.suffix.result}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"  # $5/month
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# PostgreSQL Server
resource "azurerm_postgresql_server" "db" {
  name                = "${var.project_name}-${random_string.suffix.result}-psql"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  administrator_login          = "psqladmin"
  administrator_login_password = random_password.db_password.result

  sku_name   = var.db_sku_name
  version    = "11"
  storage_mb = 5120  # 5GB minimum

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled    = true
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# PostgreSQL Database
resource "azurerm_postgresql_database" "db" {
  name                = "comet_browser"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.db.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# PostgreSQL Firewall Rule - Allow Azure Services
resource "azurerm_postgresql_firewall_rule" "allow_azure" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Key Vault for secrets
resource "azurerm_key_vault" "kv" {
  name                       = "${var.project_name}-${random_string.suffix.result}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "openai_key" {
  name         = "openai-api-key"
  value        = var.openai_api_key
  key_vault_id = azurerm_key_vault.kv.id
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "${var.project_name}-${var.environment}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# App Service (Web App)
resource "azurerm_linux_web_app" "app" {
  name                = "${var.project_name}-${random_string.suffix.result}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = var.sku_name != "F1"  # Always on not available in free tier
    
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/comet-browser"
      docker_image_tag = "latest"
    }

    health_check_path = "/health"
  }

  app_settings = {
    # Application settings
    "PORT"                           = "8000"
    "WEBSITES_PORT"                  = "8000"
    "ENVIRONMENT"                    = var.environment
    "PYTHONUNBUFFERED"              = "1"
    
    # LLM settings
    "LLM_API_TYPE"                  = "openai"
    "OPENAI_API_KEY"                = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_key.id})"
    
    # Browser settings
    "BROWSER_HEADLESS"              = "true"
    "MAX_ITERATIONS"                = "15"
    
    # Database settings
    "DATABASE_URL"                  = "postgresql://psqladmin:${random_password.db_password.result}@${azurerm_postgresql_server.db.fqdn}:5432/comet_browser?sslmode=require"
    
    # Container Registry
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
    
    # Monitoring
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.insights.instrumentation_key
  }

  identity {
    type = "SystemAssigned"
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }

    application_logs {
      file_system_level = "Information"
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Application Insights for monitoring
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.project_name}-${var.environment}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Grant App Service access to Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Data source for current config
data "azurerm_client_config" "current" {}

# Outputs
output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group name"
}

output "app_service_name" {
  value       = azurerm_linux_web_app.app.name
  description = "App Service name"
}

output "app_service_url" {
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
  description = "App Service URL"
}

output "container_registry_name" {
  value       = azurerm_container_registry.acr.name
  description = "Container Registry name"
}

output "container_registry_url" {
  value       = azurerm_container_registry.acr.login_server
  description = "Container Registry URL"
}

output "database_host" {
  value       = azurerm_postgresql_server.db.fqdn
  description = "Database host"
  sensitive   = true
}

output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Key Vault name"
}

output "application_insights_key" {
  value       = azurerm_application_insights.insights.instrumentation_key
  description = "Application Insights key"
  sensitive   = true
}

output "deployment_instructions" {
  value = <<-EOT
  
  🎉 Azure Infrastructure Created Successfully!
  
  📋 Next Steps:
  1. Push Docker image to ACR:
     az acr login --name ${azurerm_container_registry.acr.name}
     docker build -t ${azurerm_container_registry.acr.login_server}/comet-browser:latest .
     docker push ${azurerm_container_registry.acr.login_server}/comet-browser:latest
  
  2. Restart App Service:
     az webapp restart --name ${azurerm_linux_web_app.app.name} --resource-group ${azurerm_resource_group.main.name}
  
  3. Access your app:
     https://${azurerm_linux_web_app.app.default_hostname}
     https://${azurerm_linux_web_app.app.default_hostname}/docs
  
  📊 Monitoring:
     Application Insights: https://portal.azure.com/#resource${azurerm_application_insights.insights.id}
     Logs: https://portal.azure.com/#resource${azurerm_log_analytics_workspace.logs.id}
  
  💰 Estimated Monthly Cost: ~$18-20
     - App Service (B1): $13.14/mo
     - PostgreSQL (B_Gen5_1): $5.00/mo
     - Container Registry (Basic): $5.00/mo
     - Application Insights: Free tier
  
  With $100 student credit = ~5 months free! 🎓
  EOT
}
