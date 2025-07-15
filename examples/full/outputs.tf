output "bigquery" {
  description = "BigQuery module outputs"
  value       = module.masthead_agent.bigquery
  sensitive   = false
}

output "dataform" {
  description = "Dataform module outputs"
  value       = module.masthead_agent.dataform
  sensitive   = false
}

output "dataplex" {
  description = "Dataplex module outputs"
  value       = module.masthead_agent.dataplex
  sensitive   = false
}

output "analytics_hub" {
  description = "Analytics Hub module outputs"
  value       = module.masthead_agent.analytics_hub
  sensitive   = false
}

output "enabled_modules" {
  description = "List of enabled modules"
  value       = module.masthead_agent.enabled_modules
}

output "project_id" {
  description = "The GCP project ID where resources were created"
  value       = module.masthead_agent.project_id
}

output "full_configuration" {
  description = "Full configuration summary"
  value = {
    environment        = var.environment
    team               = var.team
    cost_center        = var.cost_center
    monitoring_enabled = var.monitoring_enabled
    business_unit      = var.business_unit
    enabled_modules = {
      bigquery      = var.enable_bigquery
      dataform      = var.enable_dataform
      dataplex      = var.enable_dataplex
      analytics_hub = var.enable_analytics_hub
    }
  }
}

output "resource_labels" {
  description = "Labels applied to all resources"
  value = {
    environment   = var.environment
    team          = var.team
    cost_center   = var.cost_center
    monitoring    = var.monitoring_enabled
    module        = "masthead-agent"
    business_unit = var.business_unit
    project_owner = var.project_owner
  }
}
