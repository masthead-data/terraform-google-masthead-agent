# Validation: Ensure correct mode is selected
locals {
  has_folders       = length(var.monitored_folder_ids) > 0
  project_mode      = var.project_id != null && var.deployment_project_id == null
  organization_mode = var.deployment_project_id != null && var.project_id == null

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
