variable "project_id" {
  type        = string
  description = <<-EOT
    [INTEGRATED MODE] GCP project ID where all resources (logs, Pub/Sub, IAM) will be created.
    Use this for smaller deployments or single-project setups.
    Cannot be used together with folder_id + deployment_project_id.
  EOT
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "folder_id" {
  type        = string
  description = <<-EOT
    [ENTERPRISE MODE] GCP folder ID for folder-level log sinks.
    Use this for enterprise deployments to capture logs from all projects under the folder.
    Must be used together with deployment_project_id.
    Format: folders/123456789 or just the numeric ID.
  EOT
  default     = null

  validation {
    condition     = var.folder_id == null || can(regex("^(folders/)?[0-9]+$", var.folder_id))
    error_message = "Folder ID must be numeric or in format 'folders/123456789'."
  }
}

variable "deployment_project_id" {
  type        = string
  description = <<-EOT
    [ENTERPRISE MODE] GCP project ID where Pub/Sub topics and subscriptions will be created.
    Required when using folder_id for enterprise deployments.
    This project will host the logging infrastructure for the entire folder.
  EOT
  default     = null

  validation {
    condition     = var.deployment_project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.deployment_project_id))
    error_message = "Deployment project ID must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "monitored_project_ids" {
  type        = list(string)
  description = <<-EOT
    [OPTIONAL] Additional GCP project IDs to monitor alongside folder or integrated project.
    Creates project-level sinks and IAM bindings for these projects.
    Pub/Sub infrastructure is created in deployment_project_id (enterprise) or project_id (integrated).
  EOT
  default     = []

  validation {
    condition     = alltrue([for p in var.monitored_project_ids : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", p))])
    error_message = "All monitored project IDs must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "organization_id" {
  type        = string
  description = <<-EOT
    [ENTERPRISE MODE] GCP organization ID for organization-level custom IAM roles.
    Required when using folder_id to create custom roles at the organization level.
    Format: organizations/123456789 or just the numeric ID.
  EOT
  default     = null

  validation {
    condition     = var.organization_id == null || can(regex("^(organizations/)?[0-9]+$", var.organization_id))
    error_message = "Organization ID must be numeric or in format 'organizations/123456789'."
  }
}

variable "masthead_service_accounts" {
  type = object({
    bigquery_sa = string
    dataform_sa = string
    dataplex_sa = string
    retro_sa    = string
  })
  description = "Masthead service account emails"
  default = {
    bigquery_sa = "masthead-data@masthead-prod.iam.gserviceaccount.com"
    dataform_sa = "masthead-dataform@masthead-prod.iam.gserviceaccount.com"
    dataplex_sa = "masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
    retro_sa    = "retro-data@masthead-prod.iam.gserviceaccount.com"
  }
}

variable "enable_modules" {
  type = object({
    bigquery      = bool
    dataform      = bool
    dataplex      = bool
    analytics_hub = bool
  })
  description = "Enable/disable specific modules"
  default = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}

variable "enable_privatelogviewer_role" {
  type        = bool
  description = "Enable Private Log Viewer role for Masthead service account in BigQuery module"
  default     = true
}

variable "enable_apis" {
  type        = bool
  description = "Enable required Google Cloud APIs in all modules"
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
  default = {
    service = "masthead-agent"
  }
}

# Validation: Ensure correct mode is selected
locals {
  integrated_mode = var.project_id != null && var.folder_id == null && var.deployment_project_id == null
  enterprise_mode = var.folder_id != null && var.deployment_project_id != null && var.project_id == null
  hybrid_mode     = var.folder_id != null && var.deployment_project_id != null && var.project_id != null

  # Determine which project hosts the Pub/Sub infrastructure
  pubsub_project_id = coalesce(var.deployment_project_id, var.project_id)

  # Normalize folder ID to include "folders/" prefix
  normalized_folder_id = var.folder_id != null ? (
    can(regex("^folders/", var.folder_id)) ? var.folder_id : "folders/${var.folder_id}"
  ) : null

  # Normalize organization ID to include "organizations/" prefix
  normalized_organization_id = var.organization_id != null ? (
    can(regex("^organizations/", var.organization_id)) ? var.organization_id : "organizations/${var.organization_id}"
  ) : null

  # Extract numeric organization ID for IAM custom roles
  numeric_organization_id = var.organization_id != null ? (
    can(regex("^organizations/", var.organization_id)) ? split("/", var.organization_id)[1] : var.organization_id
  ) : null

  # All projects that need IAM bindings (includes folder projects implicitly via folder IAM)
  all_monitored_projects = concat(
    var.project_id != null ? [var.project_id] : [],
    var.monitored_project_ids
  )
}

# Validation check
resource "null_resource" "validate_configuration" {
  lifecycle {
    precondition {
      condition     = local.integrated_mode || local.enterprise_mode || local.hybrid_mode
      error_message = <<-EOT
        Invalid configuration. Choose one of:
        1. INTEGRATED MODE: Set project_id only
        2. ENTERPRISE MODE: Set folder_id + deployment_project_id only
        3. HYBRID MODE: Set folder_id + deployment_project_id + monitored_project_ids
      EOT
    }

    precondition {
      condition     = local.pubsub_project_id != null
      error_message = "Either project_id or deployment_project_id must be specified."
    }
  }
}
