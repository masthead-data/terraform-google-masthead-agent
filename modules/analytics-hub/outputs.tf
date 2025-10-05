output "analyticshub_subscription_viewer_custom_role_id" {
  description = "ID of the custom Analytics Hub Subscription Viewer role"
  value       = google_project_iam_custom_role.analyticshub_subscription_viewer.id
}
