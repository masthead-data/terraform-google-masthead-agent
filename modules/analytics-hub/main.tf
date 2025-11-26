# Analytics Hub module - handles IAM for Analytics Hub monitoring
# Supports both folder-level (enterprise) and project-level (integrated) configurations

locals {
  # Projects where IAM bindings need to be applied
  iam_target_projects = var.folder_id != null ? [] : var.monitored_project_ids
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
resource "google_organization_iam_custom_role" "analyticshub_subscription_viewer_folder" {
  count = var.folder_id != null && var.organization_id != null ? 1 : 0

  org_id      = var.organization_id
  role_id     = "analyticsHubSubscriptionViewer"
  title       = "Analytics Hub Subscription Viewer"
  description = "Custom role to view subscriptions for Analytics Hub listings"

  permissions = [
    "analyticshub.listings.viewSubscriptions"
  ]
}

# Custom role for Analytics Hub subscription viewing at project level
resource "google_project_iam_custom_role" "analyticshub_subscription_viewer_project" {
  for_each = var.folder_id == null ? toset(local.iam_target_projects) : toset([])

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
  for_each = var.folder_id != null ? toset([
    "roles/analyticshub.viewer"
  ]) : toset([])

  folder = var.folder_id
  role   = each.value
  member = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# IAM: Grant custom role at folder level
resource "google_folder_iam_member" "masthead_analyticshub_folder_custom_role" {
  count = var.folder_id != null && var.organization_id != null ? 1 : 0

  folder = var.folder_id
  role   = google_organization_iam_custom_role.analyticshub_subscription_viewer_folder[0].id
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
          role       = google_project_iam_custom_role.analyticshub_subscription_viewer_project[project_id].id
          key        = "${project_id}-custom"
        }
      ]
    ]) : pair.key => pair
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}
