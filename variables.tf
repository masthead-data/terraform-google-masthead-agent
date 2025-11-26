variable "project_id" {
  type        = string
  description = <<-EOT
    [PROJECT MODE] GCP project ID where all resources (logs, Pub/Sub, IAM) will be created.
    Use this for single-project setups where Pub/Sub is deployed in the same project.
    For multi-project monitoring with centralized Pub/Sub, use deployment_project_id instead.
  EOT
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "monitored_folder_ids" {
  type        = list(string)
  description = <<-EOT
    [FOLDER MODE] List of GCP folder IDs for folder-level log sinks.
    Use this to capture logs from all projects under the specified folders.
    Must be used together with deployment_project_id.
    Format: Each folder ID can be "folders/123456789" or just the numeric ID.

    WARNING: Do not add projects that are inside these folders to monitored_project_ids,
    as this will cause duplicate log entries.
  EOT
  default     = []

  validation {
    condition     = alltrue([for f in var.monitored_folder_ids : can(regex("^(folders/)?[0-9]+$", f))])
    error_message = "Each folder ID must be numeric or in format 'folders/123456789'."
  }
}

variable "deployment_project_id" {
  type        = string
  description = <<-EOT
    [FOLDER MODE] GCP project ID where Pub/Sub topics and subscriptions will be created.
    Required when using monitored_folder_ids or monitored_project_ids for centralized deployments.
    This project will host the centralized logging infrastructure.
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
    [FOLDER/HYBRID MODE] Additional GCP project IDs to monitor.
    Creates project-level sinks and IAM bindings for these projects.
    Requires deployment_project_id to specify where centralized Pub/Sub will be created.

    WARNING: Do not include projects that are already inside a monitored_folder_ids folder,
    as this will cause duplicate log entries.
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
    [FOLDER MODE] GCP organization ID for organization-level custom IAM roles.
    Required when using monitored_folder_ids to create custom roles at the organization level.
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
  has_folders       = length(var.monitored_folder_ids) > 0
  has_projects      = length(var.monitored_project_ids) > 0
  project_mode      = var.project_id != null && !local.has_folders && var.deployment_project_id == null
  folder_mode       = var.deployment_project_id != null && (local.has_folders || local.has_projects) && var.project_id == null
  hybrid_mode       = var.deployment_project_id != null && local.has_folders && var.project_id != null

  # Determine which project hosts the Pub/Sub infrastructure
  # Using try() to handle linting when both values are null (validation will catch this at runtime)
  pubsub_project_id = try(coalesce(var.deployment_project_id, var.project_id), null)

  # Normalize folder IDs to include "folders/" prefix
  normalized_folder_ids = [
    for folder_id in var.monitored_folder_ids :
    can(regex("^folders/", folder_id)) ? folder_id : "folders/${folder_id}"
  ]

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
      condition     = local.project_mode || local.folder_mode || local.hybrid_mode
      error_message = <<-EOT
        Invalid configuration. Choose one of:
        1. PROJECT MODE: Set project_id only (Pub/Sub in same project)
        2. FOLDER MODE: Set deployment_project_id + monitored_folder_ids and/or monitored_project_ids
        3. HYBRID MODE: Set deployment_project_id + monitored_folder_ids + project_id (for additional project-level Pub/Sub)
      EOT
    }

    precondition {
      condition     = local.pubsub_project_id != null
      error_message = "Either project_id or deployment_project_id must be specified."
    }
  }
}
