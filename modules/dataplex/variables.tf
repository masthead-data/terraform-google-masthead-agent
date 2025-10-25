variable "project_id" {
  type        = string
  description = "GCP project ID where resources will be created"
}

variable "masthead_service_accounts" {
  type = object({
    dataplex_sa = string
  })
  description = "Masthead service account emails"
}

variable "enable_apis" {
  type        = bool
  description = "Enable required Google Cloud APIs"
  default     = true
}

variable "enable_datascan_editing" {
  type        = bool
  description = "Enable permissions for creating and editing Dataplex DataScans"
  default     = false
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
}
