variable "pubsub_project_id" {
  type        = string
  description = "GCP project ID where Pub/Sub resources will be created"
}

variable "monitored_folder_ids" {
  type        = list(string)
  description = "List of GCP folder IDs for folder-level log sinks (optional, for organization mode)"
  default     = []
}

variable "monitored_project_ids" {
  type        = list(string)
  description = "List of GCP project IDs to monitor (for project mode or hybrid mode)"
  default     = []
}

variable "masthead_service_accounts" {
  type = object({
    bigquery_sa = string
    retro_sa    = string
  })
  description = "Masthead service account emails"
}

variable "enable_privatelogviewer_role" {
  type        = bool
  description = "Enable privateLogViewer role for Masthead service account"
  default     = true
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
