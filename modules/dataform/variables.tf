variable "pubsub_project_id" {
  type        = string
  description = "GCP project ID where Pub/Sub resources will be created"
}

variable "folder_id" {
  type        = string
  description = "GCP folder ID for folder-level log sink (optional, for enterprise mode)"
  default     = null
}

variable "monitored_project_ids" {
  type        = list(string)
  description = "List of GCP project IDs to monitor (for integrated mode or hybrid mode)"
  default     = []
}

variable "masthead_service_accounts" {
  type = object({
    dataform_sa = string
  })
  description = "Masthead service account emails"
}

variable "enable_apis" {
  type        = bool
  description = "Enable required Google Cloud APIs"
  default     = true
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
}
