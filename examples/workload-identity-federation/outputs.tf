output "masthead_service_accounts" {
  description = "Service accounts to pass to the module's masthead_service_accounts input; the module ignores quality_sa"
  value       = local.masthead_service_accounts
}

output "masthead_federation" {
  description = "Federation details to share with Masthead"
  value = {
    provider         = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.masthead.name}"
    service_accounts = local.masthead_service_accounts
  }
}
