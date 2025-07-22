# Masthead Data Terraform Module for Google Cloud

[![Terraform Module](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

[![Open in Google Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fterraform-google-masthead-agent)

This Terraform module deploys infrastructure for Masthead Data to monitor Google Cloud services (BigQuery, Dataform, Dataplex, Analytics Hub) using Pub/Sub topics, Cloud Logging sinks, and IAM bindings.

## Usage examples

- **Basic** - this example demonstrates minimal configuration using default settings, the simplest way to get started:

  - Deploys all modules (BigQuery, Dataform, Dataplex, Analytics Hub) with defaults
  - Uses minimal required variables
  - No custom labeling applied

    ```hcl
    variable "project_id" {
      type        = string
      description = "The GCP project ID where resources will be created"
    }

    provider "google" {
      project = var.project_id
    }

    module "masthead_agent" {
      source  = "masthead-data/masthead-agent/google"
      version = ">=0.2.3"

      project_id  = var.project_id
    }
    ```

- **Full** - a deployment with comprehensive configuration and governance:

  - Complete Module Suite: Enables BigQuery, Dataform, Dataplex, and Analytics Hub
  - Production Security: Private Log Viewer role or [retrospective log export](https://docs.mastheadata.com/set-up/saas-manual-resource-creation-google-cloud-+-bigquery#export-retrospective-logs)
  - Enterprise Governance: Comprehensive labeling for compliance and cost management

    ```hcl
    variable "project_id" {
      type        = string
      description = "The GCP project ID where resources will be created"
    }

    provider "google" {
      project = var.project_id
    }

    module "masthead_agent" {
      source                       = "masthead-data/masthead-agent/google"
      version                      = ">=0.2.3"

      project_id                   = var.project_id
      enable_apis                  = false
      enable_privatelogviewer_role = true
      enable_modules = {
        bigquery      = true
        dataform      = true
        dataplex      = true
        analytics_hub = true
      }
      labels = {
        environment = "production"
        team        = "data"
        cost_center = "engineering"
        monitoring  = true
        module      = "masthead-agent"
      }
    }
    ```

## References

- [Masthead Data Documentation](https://docs.mastheadata.com/saas-manual-resource-creation-google-cloud-+-bigquery)
- [Module in Terraform Registry](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)
