variable "project_id" {
  type        = string
  description = "GCP project ID where resources will be created"
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
