# Multi-Environment Terraform Configuration
# Supports: dev, staging, production

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
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = var.environment == "production"
    }
  }
}

# Environment-specific configurations
locals {
  environment_config = {
    dev = {
      sku_name           = "F1"  # Free tier
      db_sku_name        = "B_Gen5_1"
      enable_autoscale   = false
      min_instances      = 1
      max_instances      = 1
      backup_retention   = 7
      ssl_enforcement    = true
      geo_redundant      = false
      enable_waf         = false
      log_retention_days = 30
    }
    staging = {
      sku_name           = "B1"  # Basic tier
      db_sku_name        = "B_Gen5_1"
      enable_autoscale   = true
      min_instances      = 1
      max_instances      = 3
      backup_retention   = 14
      ssl_enforcement    = true
      geo_redundant      = false
      enable_waf         = true
      log_retention_days = 60
    }
    production = {
      sku_name           = "S1"  # Standard tier
      db_sku_name        = "GP_Gen5_2"
      enable_autoscale   = true
      min_instances      = 2
      max_instances      = 10
      backup_retention   = 35
      ssl_enforcement    = true
      geo_redundant      = true
      enable_waf         = true
      log_retention_days = 90
    }
  }
  
  env_config = local.environment_config[var.environment]
  
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CostCenter  = "Engineering"
      Compliance  = var.environment == "production" ? "Required" : "Optional"
    }
  )
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
  tags     = local.common_tags
}

# Virtual Network (Production only)
resource "azurerm_virtual_network" "main" {
  count               = var.environment == "production" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "app" {
  count                = var.environment == "production" ? 1 : 0
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.1.0/24"]
  
  delegation {
    name = "app-service-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_subnet" "db" {
  count                = var.environment == "production" ? 1 : 0
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.2.0/24"]
  
  service_endpoints = ["Microsoft.Sql"]
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name}${var.environment}${random_string.suffix.result}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.environment == "production" ? "Premium" : "Basic"
  admin_enabled       = true
  
  dynamic "georeplications" {
    for_each = var.environment == "production" && local.env_config.geo_redundant ? [1] : []
    content {
      location = var.secondary_location
      tags     = local.common_tags
    }
  }
  
  tags = local.common_tags
}

# PostgreSQL Server
resource "azurerm_postgresql_server" "db" {
  name                = "${var.project_name}-${var.environment}-${random_string.suffix.result}-psql"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  administrator_login          = "psqladmin"
  administrator_login_password = random_password.db_password.result

  sku_name   = local.env_config.db_sku_name
  version    = "11"
  storage_mb = var.environment == "production" ? 102400 : 5120

  backup_retention_days        = local.env_config.backup_retention
  geo_redundant_backup_enabled = local.env_config.geo_redundant
  auto_grow_enabled            = true

  public_network_access_enabled    = var.environment != "production"
  ssl_enforcement_enabled          = local.env_config.ssl_enforcement
  ssl_minimal_tls_version_enforced = "TLS1_2"

  threat_detection_policy {
    enabled              = var.environment == "production"
    email_account_admins = var.environment == "production"
    email_addresses      = var.environment == "production" ? [var.admin_email] : []
  }

  tags = local.common_tags
}

# PostgreSQL Database
resource "azurerm_postgresql_database" "db" {
  name                = "comet_browser"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.db.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# PostgreSQL Firewall Rules
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

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = "${var.project_name}-${var.environment}-${random_string.suffix.result}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.environment == "production" ? "premium" : "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = var.environment == "production"

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = var.environment == "production"
  enabled_for_template_deployment = true

  network_acls {
    default_action = var.environment == "production" ? "Deny" : "Allow"
    bypass         = "AzureServices"
    
    dynamic "ip_rules" {
      for_each = var.environment == "production" ? var.allowed_ips : []
      content {
        value = ip_rules.value
      }
    }
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover", "Backup", "Restore"
    ]
    
    certificate_permissions = [
      "Get", "List", "Create", "Import", "Delete", "Purge"
    ]
  }

  tags = local.common_tags
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id
  
  content_type = "password"
  
  expiration_date = timeadd(timestamp(), "8760h") # 1 year
  
  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "openai_key" {
  name         = "openai-api-key"
  value        = var.openai_api_key
  key_vault_id = azurerm_key_vault.kv.id
  
  content_type = "api-key"
  
  tags = local.common_tags
}

# App Service Plan with autoscaling
resource "azurerm_service_plan" "plan" {
  name                = "${var.project_name}-${var.environment}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = local.env_config.sku_name
  
  zone_balancing_enabled = var.environment == "production"

  tags = local.common_tags
}

# Monitor Autoscale Settings
resource "azurerm_monitor_autoscale_setting" "app_autoscale" {
  count               = local.env_config.enable_autoscale ? 1 : 0
  name                = "${var.project_name}-${var.environment}-autoscale"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_service_plan.plan.id

  profile {
    name = "default-autoscale"

    capacity {
      default = local.env_config.min_instances
      minimum = local.env_config.min_instances
      maximum = local.env_config.max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = var.environment == "production"
      send_to_subscription_co_administrator = var.environment == "production"
      custom_emails                         = [var.admin_email]
    }
  }

  tags = local.common_tags
}

# App Service with advanced configuration
resource "azurerm_linux_web_app" "app" {
  name                = "${var.project_name}-${var.environment}-${random_string.suffix.result}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.plan.id
  
  https_only          = true
  client_affinity_enabled = false

  site_config {
    always_on = local.env_config.sku_name != "F1"
    
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/comet-browser"
      docker_image_tag = var.environment
    }

    health_check_path                 = "/health"
    health_check_eviction_time_in_min = var.environment == "production" ? 2 : 10
    
    http2_enabled       = true
    minimum_tls_version = "1.2"
    
    ftps_state = "Disabled"
    
    ip_restriction {
      action     = "Allow"
      priority   = 100
      name       = "AllowAll"
      ip_address = "0.0.0.0/0"
    }
    
    cors {
      allowed_origins = var.allowed_cors_origins
      support_credentials = false
    }
  }

  app_settings = {
    # Application settings
    "PORT"                              = "8000"
    "WEBSITES_PORT"                     = "8000"
    "ENVIRONMENT"                       = var.environment
    "PYTHONUNBUFFERED"                 = "1"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    
    # LLM settings
    "LLM_API_TYPE"                     = "openai"
    "OPENAI_API_KEY"                   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.openai_key.id})"
    
    # Browser settings
    "BROWSER_HEADLESS"                 = "true"
    "MAX_ITERATIONS"                   = var.environment == "production" ? "20" : "15"
    
    # Database settings
    "DATABASE_URL"                     = "postgresql://psqladmin:${random_password.db_password.result}@${azurerm_postgresql_server.db.fqdn}:5432/comet_browser?sslmode=require"
    
    # Container Registry
    "DOCKER_REGISTRY_SERVER_URL"       = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"  = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"  = azurerm_container_registry.acr.admin_password
    
    # Monitoring
    "APPINSIGHTS_INSTRUMENTATIONKEY"   = azurerm_application_insights.insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights.connection_string
    
    # Rate Limiting
    "RATE_LIMIT_ENABLED"               = var.environment != "dev"
    "RATE_LIMIT_PER_MINUTE"            = var.environment == "production" ? "100" : "50"
    
    # Caching
    "REDIS_ENABLED"                    = var.environment == "production" ? "true" : "false"
    "REDIS_URL"                        = var.environment == "production" ? azurerm_redis_cache.cache[0].primary_connection_string : ""
  }

  identity {
    type = "SystemAssigned"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    
    http_logs {
      file_system {
        retention_in_days = local.env_config.log_retention_days
        retention_in_mb   = 100
      }
    }

    application_logs {
      file_system_level = var.environment == "production" ? "Warning" : "Information"
    }
  }
  
  backup {
    name     = "${var.project_name}-${var.environment}-backup"
    enabled  = var.environment == "production"
    
    schedule {
      frequency_interval       = 1
      frequency_unit           = "Day"
      retention_period_days    = 30
      start_time              = "2024-01-01T02:00:00Z"
    }
  }

  tags = local.common_tags
}

# Redis Cache (Production only)
resource "azurerm_redis_cache" "cache" {
  count               = var.environment == "production" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-${random_string.suffix.result}-redis"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  
  redis_configuration {
    maxmemory_policy = "allkeys-lru"
  }

  tags = local.common_tags
}

# Application Insights
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = local.env_config.log_retention_days
  
  daily_quota_gb = var.environment == "production" ? 10 : 1

  tags = local.common_tags
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.project_name}-${var.environment}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
  
  retention_in_days = local.env_config.log_retention_days
  sampling_percentage = var.environment == "production" ? 100 : 50

  tags = local.common_tags
}

# Grant App Service access to Key Vault
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.app.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

# Action Groups for Alerts
resource "azurerm_monitor_action_group" "critical" {
  name                = "${var.project_name}-${var.environment}-critical-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "critical"

  email_receiver {
    name          = "admin"
    email_address = var.admin_email
  }
  
  sms_receiver {
    name         = "oncall"
    country_code = var.sms_country_code
    phone_number = var.oncall_phone
  }

  tags = local.common_tags
}

resource "azurerm_monitor_action_group" "warning" {
  name                = "${var.project_name}-${var.environment}-warning-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "warning"

  email_receiver {
    name          = "team"
    email_address = var.admin_email
  }

  tags = local.common_tags
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "app_down" {
  name                = "${var.project_name}-${var.environment}-app-down"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.app.id]
  description         = "Alert when app is down"
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HealthCheckStatus"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${var.project_name}-${var.environment}-high-cpu"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_service_plan.plan.id]
  description         = "Alert when CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning.id
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "high_memory" {
  name                = "${var.project_name}-${var.environment}-high-memory"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_service_plan.plan.id]
  description         = "Alert when memory usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "MemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning.id
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "http_errors" {
  name                = "${var.project_name}-${var.environment}-http-errors"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.app.id]
  description         = "Alert when HTTP 5xx errors are high"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.environment == "production" ? 10 : 20
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = local.common_tags
}

# Data source
data "azurerm_client_config" "current" {}
