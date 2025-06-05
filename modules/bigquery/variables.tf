variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created"
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
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names"
  default     = "masthead"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default     = {}
}
