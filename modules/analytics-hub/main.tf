provider "google" {
  project = var.project_id
}

#1. Grant Masthead SA required roles: analyticshub.viewer;
resource "google_project_iam_member" "masthead-analyticshub-viewer-role" {
  project = var.project_id
  role    = "roles/analyticshub.viewer"
  member  = "serviceAccount:masthead-data@masthead-prod.iam.gserviceaccount.com"
}
