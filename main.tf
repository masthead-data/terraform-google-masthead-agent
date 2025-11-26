terraform {
  required_version = ">= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

# BigQuery Module - Logging Infrastructure + IAM
module "bigquery" {
  count  = var.enable_modules.bigquery ? 1 : 0
  source = "./modules/bigquery"

  # Infrastructure configuration
  pubsub_project_id     = local.pubsub_project_id
  monitored_folder_ids  = local.normalized_folder_ids
  monitored_project_ids = local.all_monitored_projects

  # Service account and permissions
  masthead_service_accounts    = var.masthead_service_accounts
  enable_privatelogviewer_role = var.enable_privatelogviewer_role

  # Resource configuration
  enable_apis = var.enable_apis
  labels      = var.labels
}

# Dataform Module - Logging Infrastructure + IAM
module "dataform" {
  count  = var.enable_modules.dataform ? 1 : 0
  source = "./modules/dataform"

  # Infrastructure configuration
  pubsub_project_id     = local.pubsub_project_id
  monitored_folder_ids  = local.normalized_folder_ids
  monitored_project_ids = local.all_monitored_projects

  # Service account
  masthead_service_accounts = var.masthead_service_accounts

  # Resource configuration
  enable_apis = var.enable_apis
  labels      = var.labels
}

# Dataplex Module - Logging Infrastructure + IAM
module "dataplex" {
  count  = var.enable_modules.dataplex ? 1 : 0
  source = "./modules/dataplex"

  # Infrastructure configuration
  pubsub_project_id     = local.pubsub_project_id
  monitored_folder_ids  = local.normalized_folder_ids
  monitored_project_ids = local.all_monitored_projects

  # Service account and permissions
  masthead_service_accounts = var.masthead_service_accounts
  enable_datascan_editing   = var.enable_datascan_editing

  # Resource configuration
  enable_apis = var.enable_apis
  labels      = var.labels
}

# Analytics Hub Module - IAM only (no logging infrastructure needed)
module "analytics_hub" {
  count  = var.enable_modules.analytics_hub ? 1 : 0
  source = "./modules/analytics-hub"

  # Infrastructure configuration
  monitored_folder_ids  = local.normalized_folder_ids
  organization_id       = local.numeric_organization_id
  monitored_project_ids = local.all_monitored_projects

  # Service account
  masthead_service_accounts = var.masthead_service_accounts

  # Resource configuration
  enable_apis = var.enable_apis
}
