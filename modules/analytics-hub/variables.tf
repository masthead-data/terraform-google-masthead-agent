variable "folder_id" {
  type        = string
  description = "GCP folder ID for folder-level IAM (optional, for enterprise mode)"
  default     = null
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID for organization-level custom roles (required for enterprise mode)"
  default     = null
}

variable "monitored_project_ids" {
  type        = list(string)
  description = "List of GCP project IDs to monitor (for integrated mode or hybrid mode)"
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
