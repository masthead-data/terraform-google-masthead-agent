# Analytics Hub Module - IAM for Masthead Agent
# Supports both folder-level (organization) and project-level (project) configurations

locals {
  # Determine if we're operating at folder or project level
  has_folders = length(var.monitored_folder_ids) > 0

  # Projects where IAM bindings need to be applied (only when not using folders)
  iam_target_projects = local.has_folders ? [] : var.monitored_project_ids
}

# Enable Analytics Hub API in monitored projects
resource "google_project_service" "analyticshub_api" {
  for_each = var.enable_apis ? toset(var.monitored_project_ids) : toset([])

  project = each.value
  service = "analyticshub.googleapis.com"

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Custom role for Analytics Hub subscription viewing at folder level
resource "google_organization_iam_custom_role" "analyticshub_custom_role_folder" {
  count = local.has_folders && var.organization_id != null ? 1 : 0

  org_id      = var.organization_id
  role_id     = "analyticsHubSubscriptionViewer"
  title       = "Analytics Hub Subscription Viewer"
  description = "Custom role to view subscriptions for Analytics Hub listings"
  permissions = [
    "analyticshub.listings.viewSubscriptions"
  ]
  project     = var.project_id
  description = "Custom role to Masthead Analytics Hub integration"
}

# Custom role for Analytics Hub subscription viewing at project level
resource "google_project_iam_custom_role" "analyticshub_custom_role_project" {
  for_each = !local.has_folders ? toset(local.iam_target_projects) : toset([])

  project     = each.value
  role_id     = "analyticsHubSubscriptionViewer"
  title       = "Analytics Hub Subscription Viewer"
  description = "Custom role to view subscriptions for Analytics Hub listings"

  permissions = [
    "analyticshub.listings.viewSubscriptions"
  ]
}

# IAM: Grant Masthead service account Analytics Hub roles at folder level
resource "google_folder_iam_member" "masthead_analyticshub_folder_roles" {
  for_each = {
    for pair in flatten([
      for folder_id in var.monitored_folder_ids : [
        for role in ["roles/analyticshub.viewer"] : {
          folder_id = folder_id
          role      = role
          key       = "${folder_id}-${role}"
        }
      ]
    ]) : pair.key => pair
  }

  folder = each.value.folder_id
  role   = each.value.role
  member = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# IAM: Grant custom role at folder level
resource "google_folder_iam_member" "masthead_analyticshub_folder_custom_role" {
  for_each = local.has_folders && var.organization_id != null ? toset(var.monitored_folder_ids) : toset([])

  folder = each.value
  role   = google_organization_iam_custom_role.analyticshub_custom_role_folder[0].id
  member = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# IAM: Grant Masthead service account Analytics Hub roles at project level
resource "google_project_iam_member" "masthead_analyticshub_project_roles" {
  depends_on = [google_project_service.analyticshub_api]
  for_each = {
    for pair in flatten([
      for project_id in local.iam_target_projects : [
        {
          project_id = project_id
          role       = "roles/analyticshub.viewer"
          key        = "${project_id}-viewer"
        },
        {
          project_id = project_id
          role       = google_project_iam_custom_role.analyticshub_custom_role_project[project_id].id
          key        = "${project_id}-custom"
        }
      ]
    ]) : pair.key => pair
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}
