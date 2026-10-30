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

variable "pool_id" {
  type        = string
  description = "Workload identity pool ID. A deleted pool's ID stays reserved for 30 days"
  default     = "masthead"
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
