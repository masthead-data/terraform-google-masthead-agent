# Analytics Hub Module - IAM for Masthead Agent
# Supports both folder-level (organization) and project-level (project) configurations

locals {
  # Determine if we're operating at folder or project level
  has_folders = length(var.monitored_folder_ids) > 0

  # Explicitly listed standalone projects always need project-level IAM bindings,
  # independent of whether folders are also monitored (they live outside the folders).
  iam_target_projects = var.monitored_project_ids
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
  count = var.create_organization_custom_roles && local.has_folders && var.organization_id != null ? 1 : 0

  org_id      = var.organization_id
  role_id     = "mastheadAnalyticsHubCustomRole"
  title       = "Masthead Analytics Hub Custom Role"
  description = "Custom role for Masthead Analytics Hub integration"
  permissions = [
    "analyticshub.listings.viewSubscriptions"
  ]
}

# Custom role for Analytics Hub subscription viewing at project level
resource "google_project_iam_custom_role" "analyticshub_custom_role_project" {
  for_each = toset(local.iam_target_projects)

  project     = each.value
  role_id     = "mastheadAnalyticsHubCustomRole"
  title       = "Masthead Analytics Hub Custom Role"
  description = "Custom role to Masthead Analytics Hub integration"

  permissions = [
    "analyticshub.listings.viewSubscriptions"
  ]
}

# IAM: Grant Masthead service account Analytics Hub roles at folder level
resource "google_folder_iam_member" "masthead_analyticshub_folder_roles" {
  for_each = {
    for pair in setproduct(var.monitored_folder_ids, ["roles/analyticshub.viewer"]) : "${pair[0]}-${pair[1]}" => {
      folder_id = pair[0]
      role      = pair[1]
    }
  }

  folder = each.value.folder_id
  role   = each.value.role
  member = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# IAM: Grant custom role at folder level
resource "google_folder_iam_member" "masthead_analyticshub_folder_custom_role" {
  for_each = var.create_organization_custom_roles && local.has_folders && var.organization_id != null ? toset(var.monitored_folder_ids) : toset([])

  folder = each.value
  role   = google_organization_iam_custom_role.analyticshub_custom_role_folder[0].id
  member = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# IAM: Grant Masthead service account Analytics Hub roles at project level
resource "google_project_iam_member" "masthead_analyticshub_project_roles" {
  depends_on = [google_project_service.analyticshub_api]
  for_each = {
    for pair in setproduct(local.iam_target_projects, ["viewer", "custom"]) : "${pair[0]}-${pair[1]}" => {
      project_id = pair[0]
      role       = pair[1] == "viewer" ? "roles/analyticshub.viewer" : google_project_iam_custom_role.analyticshub_custom_role_project[pair[0]].id
    }
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}
