variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

# Module enablement variables
variable "enable_bigquery" {
  type        = bool
  description = "Enable BigQuery module"
  default     = true
}

variable "enable_dataform" {
  type        = bool
  description = "Enable Dataform module"
  default     = true
}

variable "enable_dataplex" {
  type        = bool
  description = "Enable Dataplex module"
  default     = true
}

variable "enable_analytics_hub" {
  type        = bool
  description = "Enable Analytics Hub module"
  default     = true
}

variable "enable_privatelogviewer_role" {
  type        = bool
  description = "Enable Private Log Viewer role for Masthead service account in BigQuery module"
  default     = true
}

# Labeling variables for production environments
variable "environment" {
  type        = string
  description = "Environment name (e.g., production, staging, development)"
  default     = ""

  validation {
    condition     = contains(["production", "staging", "development", "test"], var.environment)
    error_message = "Environment must be one of: production, staging, development, test."
  }
}

variable "team" {
  type        = string
  description = "Team responsible for the resources"
  default     = ""
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing purposes"
  default     = ""
}

variable "monitoring_enabled" {
  type        = string
  description = "Whether monitoring is enabled for the resources"
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.monitoring_enabled)
    error_message = "Monitoring must be either 'enabled' or 'disabled'."
  }
}

variable "module_version" {
  type        = string
  description = "Version of the masthead-agent module being deployed"
  default     = ""
}

variable "business_unit" {
  type        = string
  description = "Business unit that owns these resources"
  default     = ""
}

variable "project_owner" {
  type        = string
  description = "Email address of the project owner"
  default     = ""
}
