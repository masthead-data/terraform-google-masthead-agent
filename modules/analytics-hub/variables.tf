variable "monitored_folder_ids" {
  type        = list(string)
  description = "List of GCP folder IDs for folder-level IAM (optional, for organization mode)"
  default     = []
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID for organization-level custom roles (required for organization mode)"
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
