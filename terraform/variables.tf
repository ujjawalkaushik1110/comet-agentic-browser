# Azure Provider Variables

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "comet-browser"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "sku_name" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"
  
  validation {
    condition     = contains(["F1", "B1", "B2", "B3", "S1", "S2", "S3"], var.sku_name)
    error_message = "SKU must be one of: F1, B1, B2, B3, S1, S2, S3."
  }
}

variable "db_sku_name" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "B_Gen5_1"
}

variable "openai_api_key" {
  description = "OpenAI API Key for LLM"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Admin email for alerts and notifications"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "Must be a valid email address."
  }
}

variable "allowed_cors_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "enable_monitoring" {
  description = "Enable Application Insights monitoring"
  type        = bool
  default     = true
}

variable "enable_autoscale" {
  description = "Enable autoscaling (requires Standard or Premium tier)"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of instances (autoscale)"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances (autoscale)"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
