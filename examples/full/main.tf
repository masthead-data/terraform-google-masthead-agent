provider "google" {
  project = var.project_id
}

module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = var.module_version

  project_id = var.project_id

  enable_modules = {
    bigquery      = var.enable_bigquery
    dataform      = var.enable_dataform
    dataplex      = var.enable_dataplex
    analytics_hub = var.enable_analytics_hub
  }

  labels = {
    environment   = var.environment
    team          = var.team
    cost_center   = var.cost_center
    monitoring    = var.monitoring_enabled
    managed_by    = "terraform"
    module        = "masthead-agent"
    version       = var.module_version
    business_unit = var.business_unit
    project_owner = var.project_owner
  }
}
