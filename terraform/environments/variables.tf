# Multi-Environment Variables

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "comet-browser"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure region for geo-replication"
  type        = string
  default     = "westus2"
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Admin email for alerts"
  type        = string
}

variable "oncall_phone" {
  description = "On-call phone number for critical alerts"
  type        = string
  default     = ""
}

variable "sms_country_code" {
  description = "Country code for SMS alerts"
  type        = string
  default     = "1"
}

variable "allowed_cors_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "allowed_ips" {
  description = "Allowed IP addresses for Key Vault access (production)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
