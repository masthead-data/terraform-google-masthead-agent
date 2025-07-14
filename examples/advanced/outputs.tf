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

output "production_configuration" {
  description = "Production configuration summary"
  value = {
    environment         = var.environment
    team               = var.team
    cost_center        = var.cost_center
    compliance_level   = var.compliance_level
    backup_policy      = var.backup_policy
    monitoring_enabled = var.monitoring_enabled
    module_version     = var.module_version
    business_unit      = var.business_unit
    enabled_modules = {
      bigquery      = var.enable_bigquery
      dataform      = var.enable_dataform
      dataplex      = var.enable_dataplex
      analytics_hub = var.enable_analytics_hub
    }
    privatelogviewer_enabled = var.enable_privatelogviewer_role
  }
}

output "resource_labels" {
  description = "Labels applied to all resources"
  value = {
    environment   = var.environment
    team          = var.team
    cost_center   = var.cost_center
    compliance    = var.compliance_level
    backup        = var.backup_policy
    monitoring    = var.monitoring_enabled
    managed_by    = "terraform"
    module        = "masthead-agent"
    version       = var.module_version
    business_unit = var.business_unit
    project_owner = var.project_owner
  }
}
