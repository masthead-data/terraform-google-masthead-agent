variable "monitored_folder_ids" {
  type        = list(string)
  description = "List of GCP folder IDs for folder-level IAM (optional, for folder mode)"
  default     = []
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID for organization-level custom roles (required for folder mode)"
  default     = null
}

variable "monitored_project_ids" {
  type        = list(string)
  description = "List of GCP project IDs to monitor (for project mode or hybrid mode)"
  default     = []
}

variable "masthead_service_accounts" {
  type = object({
    bigquery_sa = string
  })
  description = "Masthead service account emails"
}

variable "enable_apis" {
  type        = bool
  description = "Enable required Google Cloud APIs"
  default     = true
}

variable "create_organization_custom_roles" {
  type        = bool
  description = "Create the organization level custom roles (relevant only for monitored folders). Set to false if the organization level custom IAM roles are managed outside of this module."
  default     = true
}
