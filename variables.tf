variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "The GCP region where regional resources will be created"
  default     = "us-central1"
}

variable "masthead_service_accounts" {
  type = object({
    bigquery_sa = string
    dataform_sa = string
    dataplex_sa = string
    retro_sa    = string
  })
  description = "Masthead service account emails for different services"
  default = {
    bigquery_sa = "masthead-data@masthead-prod.iam.gserviceaccount.com"
    dataform_sa = "masthead-dataform@masthead-prod.iam.gserviceaccount.com"
    dataplex_sa = "masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
    retro_sa    = "retro-data@masthead-prod.iam.gserviceaccount.com"
  }
}

variable "enable_modules" {
  type = object({
    bigquery      = bool
    dataform      = bool
    dataplex      = bool
    analytics_hub = bool
  })
  description = "Enable/disable specific modules"
  default = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names"
  default     = "masthead"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.resource_prefix))
    error_message = "Resource prefix must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and end with an alphanumeric character."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default = {
    managed_by = "terraform"
    module     = "masthead-agent"
  }
}
