terraform {
  required_version = ">= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13.0"
    }
  }
}

module "bigquery" {
  source = "./modules/bigquery"

  project_id = var.project_id
}

module "dataform" {
  source = "./modules/dataform"

  project_id = var.project_id
}

module "dataplex" {
  source = "./modules/dataplex"

  project_id = var.project_id
}

module "analytics_hub" {
  source = "./modules/analytics-hub"

  project_id = var.project_id
}
