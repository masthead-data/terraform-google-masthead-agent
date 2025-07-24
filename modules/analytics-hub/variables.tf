variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created"
}

variable "masthead_service_accounts" {
  type = object({
    bigquery_sa = string
    dataform_sa = string
    dataplex_sa = string
  })
  description = "Masthead service account emails for different services"
}

variable "enable_apis" {
  type        = bool
  description = "Whether to enable required Google Cloud APIs"
  default     = true
}
