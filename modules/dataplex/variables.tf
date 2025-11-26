variable "pubsub_project_id" {
  type        = string
  description = "GCP project ID where Pub/Sub resources will be created"
}

variable "monitored_folder_ids" {
  type        = list(string)
  description = "List of GCP folder IDs for folder-level log sinks (optional, for enterprise mode)"
  default     = []
}

variable "monitored_project_ids" {
  type        = list(string)
  description = "List of GCP project IDs to monitor (for integrated mode or hybrid mode)"
  default     = []
}

variable "masthead_service_accounts" {
  type = object({
    dataplex_sa = string
  })
  description = "Masthead service account emails"
}

variable "enable_datascan_editing" {
  type        = bool
  description = "Enable permissions for creating and editing Dataplex DataScans"
  default     = false
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
