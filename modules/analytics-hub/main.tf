# Enable required Google Cloud APIs (optional)
resource "google_project_service" "required_apis" {
  for_each = var.enable_apis ? toset([
    "analyticshub.googleapis.com"
  ]) : toset([])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Custom role for Analytics Hub subscription viewing
resource "google_project_iam_custom_role" "analyticshub_subscription_viewer" {
  project     = var.project_id
  role_id     = "analyticsHubSubscriptionViewer"
  title       = "Analytics Hub Subscription Viewer"
  description = "Custom role to view subscriptions for Analytics Hub listings"

  permissions = [
    "analyticshub.listings.viewSubscriptions"
  ]
}

# Grant Masthead service account required Analytics Hub roles
resource "google_project_iam_member" "masthead_analyticshub_roles" {
  depends_on = [google_project_service.required_apis]
  for_each = {
    viewer              = "roles/analyticshub.viewer"
    subscription_viewer = google_project_iam_custom_role.analyticshub_subscription_viewer.id
  }

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}
