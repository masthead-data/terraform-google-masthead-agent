variable "pubsub_project_id" {
  type        = string
  description = "GCP project ID where Pub/Sub resources will be created"
}

variable "monitored_folder_ids" {
  type        = list(string)
  description = "List of GCP folder IDs for folder-level log sinks (optional, for folder mode)"
  default     = []
}

variable "monitored_project_ids" {
  type        = list(string)
  description = "List of GCP project IDs to create project-level log sinks for"
  default     = []
}

variable "component_name" {
  type        = string
  description = "Name of the component (e.g., 'bigquery', 'dataform', 'dataplex')"
}

variable "topic_name" {
  type        = string
  description = "Name for the Pub/Sub topic"
}

variable "subscription_name" {
  type        = string
  description = "Name for the Pub/Sub subscription"
}

variable "sink_name" {
  type        = string
  description = "Name for the logging sink(s)"
}

variable "log_filter" {
  type        = string
  description = "Log filter expression for the sink"
}

variable "masthead_service_account" {
  type        = string
  description = "Masthead service account email for this component"
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

variable "pii_redaction" {
  description = "PII redaction configuration using a Pub/Sub message transform (SMT) applied to the topic. When enabled, a JavaScript UDF redacts email addresses from BigQuery SQL query fields before messages are stored in the subscription backlog."
  type = object({
    enabled     = optional(bool, false)
    custom_code = optional(string, null)
  })
  default = {}
}
