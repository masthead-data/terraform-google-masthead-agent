# Enable required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "analyticshub.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Grant Masthead service account Analytics Hub viewer permissions
resource "google_project_iam_member" "masthead_analyticshub_permissions" {
  depends_on = [google_project_service.required_apis]

  project = var.project_id
  role    = "roles/analyticshub.viewer"
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}
