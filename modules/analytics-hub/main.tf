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

# Grant Masthead service account required Analytics Hub roles
resource "google_project_iam_member" "masthead_analyticshub_roles" {
  depends_on = [google_project_service.required_apis]

  project = var.project_id
  role    = "roles/analyticshub.viewer"
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}
