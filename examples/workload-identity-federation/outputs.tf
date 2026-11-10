output "masthead_service_accounts" {
  description = "Service accounts to pass to the module's masthead_service_accounts input. A disabled module is null: pass the enable_modules output to the module"
  value       = local.masthead_service_accounts
}

output "masthead_federation" {
  description = "Federation details to share with Masthead"
  value = {
    provider         = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.masthead.name}"
    service_accounts = local.masthead_federation_service_accounts
  }
}

output "enable_modules" {
  description = "The enable_modules input without data_scans, for the agent module's enable_modules"
  value       = { for k, v in var.enable_modules : k => v if k != "data_scans" }
}
