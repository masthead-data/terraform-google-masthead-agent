variable "project_id" {
  type        = string
  description = "Project for the service account and the workload identity pool, for example the deployment project in Organization Mode"
}

variable "service_account_id" {
  type        = string
  description = "Account ID of the service account Masthead uses. With separate_service_accounts, the prefix of the per-identity account IDs"
  default     = "masthead"
}

variable "separate_service_accounts" {
  type        = bool
  description = "Create one service account per Masthead identity (masthead-bigquery, masthead-retro, and masthead-dataform, masthead-dataplex, masthead-quality when configured) instead of one shared. Recommended for least privilege"
  default     = false
}

variable "create_pool" {
  type        = bool
  description = "Create the workload identity pool. Set to false to add the Masthead provider to an existing pool with ID pool_id in pool_project_id"
  default     = true
}

variable "pool_id" {
  type        = string
  description = "Workload identity pool ID, created or existing. A deleted pool's ID stays reserved for 30 days"
  default     = "masthead"
}

variable "pool_project_id" {
  type        = string
  description = "Project of the workload identity pool and provider. Defaults to project_id"
  default     = null
}

variable "provider_id" {
  type        = string
  description = "Workload identity pool provider ID"
  default     = "masthead-google"
}

variable "enable_apis" {
  type        = bool
  description = "Enable the IAM, IAM Credentials and Security Token Service APIs in the project"
  default     = true
}

variable "enable_dataform" {
  type        = bool
  description = "Create the Dataform identity (dataform_sa). Set to false if you don't use Dataform with Masthead, and set enable_modules.dataform to false in the agent module"
  default     = true
}

variable "enable_dataplex" {
  type        = bool
  description = "Create the Dataplex identity (dataplex_sa). Set to false if you don't use Dataplex with Masthead, and set enable_modules.dataplex to false in the agent module"
  default     = true
}

variable "data_scan_dataset_ids" {
  type        = list(string)
  description = "Datasets in your projects that hold your data scan metrics, as project.dataset, conventionally masthead_dq. Creates the data scan identity (quality_sa) with roles/bigquery.dataViewer on each. Empty disables data scans"
  default     = []

  validation {
    condition     = alltrue([for id in var.data_scan_dataset_ids : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]\\.[A-Za-z0-9_]+$", id))])
    error_message = "Each data_scan_dataset_ids entry must be in the format project.dataset."
  }
}
