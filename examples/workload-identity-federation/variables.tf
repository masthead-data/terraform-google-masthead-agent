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
  description = "Create one service account per Masthead identity (masthead-bigquery, masthead-dataform, masthead-dataplex, masthead-retro) instead of one shared"
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
