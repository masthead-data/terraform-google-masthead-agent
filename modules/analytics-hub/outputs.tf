output "service_account_member" {
  description = "Service account member granted Analytics Hub viewer permissions"
  value       = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

output "granted_role" {
  description = "IAM role granted to the service account"
  value       = google_project_iam_member.masthead_analyticshub_permissions.role
}
